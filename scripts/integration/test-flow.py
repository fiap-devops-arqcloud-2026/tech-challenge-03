"""Exercise real HTTP APIs, databases, Redis, and the asynchronous analytics path."""
import json
import os
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

COMPOSE = ["docker", "compose", "--env-file", ".env.example"]
run_id = "integration-" + uuid.uuid4().hex[:10]
expected_events = []


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def request(port, path, method="GET", body=None, key=None, status=200):
    headers = {"Content-Type": "application/json"}
    if key:
        headers["Authorization"] = "Bearer " + key
    req = urllib.request.Request(
        f"http://127.0.0.1:{port}{path}",
        data=None if body is None else json.dumps(body).encode(),
        headers=headers, method=method,
    )
    try:
        response = urllib.request.urlopen(req, timeout=15)
    except urllib.error.HTTPError as exc:
        response = exc
    with response:
        payload = response.read().decode()
        check(response.code == status, f"{method} {path}: expected {status}, got {response.code}")
        return json.loads(payload) if payload and status < 400 else None


def compose(*args, **kwargs):
    return subprocess.run(COMPOSE + list(args), check=True, text=True, **kwargs)


for port in range(8001, 8006):
    check(request(port, "/health")["status"] == "ok", f"Health failed on {port}")
print("PASS: all five services healthy", flush=True)

request(8001, "/admin/keys", "POST", {"name": run_id}, key="invalid", status=403)
request(8002, "/flags", status=401)
request(8003, "/rules/missing", key="invalid", status=401)
key = request(8001, "/admin/keys", "POST", {"name": run_id},
              key="local-master-key-change-me", status=201)["key"]
request(8001, "/validate", key=key)
# Keep the generated local key in process/container memory, never in logs or Git.
compose("up", "-d", "--no-deps", "--force-recreate", "--wait", "evaluation-service",
        env={**os.environ, "SERVICE_API_KEY": key})
print("PASS: authentication rejects invalid keys and accepts generated key", flush=True)


def create_flag(suffix, enabled=True, percentage=None):
    name = run_id + "-" + suffix
    request(8002, "/flags", "POST", {"name": name, "is_enabled": enabled}, key, 201)
    check(request(8002, "/flags/" + name, key=key)["is_enabled"] is enabled, "Flag persistence")
    if percentage is not None:
        request(8003, "/rules", "POST", {
            "flag_name": name, "rules": {"type": "PERCENTAGE", "value": percentage},
        }, key, 201)
        rule = request(8003, "/rules/" + name, key=key)
        check(rule["rules"]["value"] == percentage, "Rule persistence")
    return name


def evaluate(name, result, suffix):
    user = run_id + "-user-" + suffix
    query = urllib.parse.urlencode({"flag_name": name, "user_id": user})
    response = request(8004, "/evaluate?" + query)
    check(response == {"flag_name": name, "user_id": user, "result": result},
          f"Incorrect decision for {name}")
    expected_events.append({"flag_name": name, "user_id": user, "result": result})


enabled = create_flag("enabled")
disabled = create_flag("disabled", False)
zero = create_flag("zero", percentage=0)
hundred = create_flag("hundred", percentage=100)
evaluate(enabled, True, "enabled")
evaluate(enabled, True, "cached")
cache = compose("exec", "-T", "redis", "redis-cli", "GET", "flag_info:" + enabled,
                capture_output=True).stdout.strip()
check(json.loads(cache), "Redis cache must contain flag information")
ttl = int(compose("exec", "-T", "redis", "redis-cli", "TTL", "flag_info:" + enabled,
                  capture_output=True).stdout.strip())
check(0 < ttl <= 30, "Redis cache must expire within 30 seconds")
evaluate(disabled, False, "disabled")
evaluate(zero, False, "zero")
evaluate(hundred, True, "hundred")
evaluate(run_id + "-missing", False, "missing")
request(8004, "/evaluate", status=400)
print("PASS: persistence, enabled/disabled flags, 0%/100% targeting, missing flag, Redis cache", flush=True)

# A real update must become visible after the documented cache TTL.
request(8002, "/flags/" + enabled, "PUT", {"is_enabled": False}, key)
time.sleep(31)
evaluate(enabled, False, "after-update")
print("PASS: flag update becomes visible after cache expiration", flush=True)

compose("exec", "-T", "analytics-service", "python", "/tests/assert-events.py",
        json.dumps(expected_events))
print("PASS: end-to-end Compose integration completed", flush=True)
