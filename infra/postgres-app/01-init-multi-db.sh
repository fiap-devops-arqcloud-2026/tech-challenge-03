#!/usr/bin/env bash
set -euo pipefail

# POSTGRES_DB already creates FLAGS_DB. Create the second database safely.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$FLAGS_DB" \
  --set=targeting_db="$TARGETING_DB" <<'SQL'
SELECT format('CREATE DATABASE %I', :'targeting_db')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'targeting_db')\gexec
SQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$FLAGS_DB" -f /opt/schema/flags.sql
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$TARGETING_DB" -f /opt/schema/targeting.sql
