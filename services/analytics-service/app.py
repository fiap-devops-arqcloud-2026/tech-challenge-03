import json
import logging
import os
import sys
import threading
import time
import uuid

import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from dotenv import load_dotenv
from flask import Flask, jsonify

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
log = logging.getLogger(__name__)

load_dotenv()

# --- Configuração ---
AWS_REGION = os.getenv("AWS_REGION")
SQS_QUEUE_URL = os.getenv("AWS_SQS_URL")
DYNAMODB_TABLE_NAME = os.getenv("AWS_DYNAMODB_TABLE")

# SQS_ENABLED é True apenas quando a URL da fila foi realmente informada.
# Em desenvolvimento local, AWS_SQS_URL fica vazia — o worker simplesmente não sobe,
# mas o /health continua respondendo normalmente.
SQS_ENABLED = bool(SQS_QUEUE_URL)

if not AWS_REGION:
    log.critical("Erro: AWS_REGION deve ser definida.")
    sys.exit(1)

# Clientes Boto3 são criados apenas quando SQS está habilitado.
# Em modo local, não precisamos de nenhum cliente AWS.
sqs_client = None
dynamodb_client = None

if SQS_ENABLED:
    # Em produção (EKS), todas as variáveis são obrigatórias
    if not DYNAMODB_TABLE_NAME:
        log.critical("Erro: AWS_DYNAMODB_TABLE deve ser definida quando AWS_SQS_URL está configurada.")
        sys.exit(1)
    try:
        session = boto3.Session(region_name=AWS_REGION)
        sqs_client = session.client("sqs")
        dynamodb_client = session.client("dynamodb")
        log.info(f"Clientes Boto3 inicializados na região {AWS_REGION}.")
    except NoCredentialsError:
        log.critical("Credenciais da AWS não encontradas. Verifique seu ambiente.")
        sys.exit(1)
    except Exception as e:
        log.critical(f"Erro ao inicializar o Boto3: {e}")
        sys.exit(1)
else:
    # Aviso claro no log para quem inspecionar o container localmente
    log.warning("AWS_SQS_URL não configurada — worker SQS desabilitado (modo local/desenvolvimento).")


# --- SQS Worker ---

def process_message(message):
    """Processa uma única mensagem SQS e insere o evento no DynamoDB."""
    try:
        log.info(f"Processando mensagem ID: {message['MessageId']}")
        body = json.loads(message['Body'])

        event_id = str(uuid.uuid4())

        item = {
            'event_id': {'S': event_id},
            'user_id':  {'S': body['user_id']},
            'flag_name':{'S': body['flag_name']},
            'result':   {'BOOL': body['result']},
            'timestamp':{'S': body['timestamp']}
        }

        dynamodb_client.put_item(TableName=DYNAMODB_TABLE_NAME, Item=item)
        log.info(f"Evento {event_id} (Flag: {body['flag_name']}) salvo no DynamoDB.")

        # Só deleta da fila após salvar com sucesso no DynamoDB
        sqs_client.delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=message['ReceiptHandle']
        )

    except json.JSONDecodeError:
        log.error(f"Erro ao decodificar JSON da mensagem ID: {message['MessageId']}")
        # Não deleta: mensagem volta para a fila após o timeout de visibilidade
    except ClientError as e:
        log.error(f"Erro Boto3 ao processar {message['MessageId']}: {e}")
    except Exception as e:
        log.error(f"Erro inesperado ao processar {message['MessageId']}: {e}")


def sqs_worker_loop():
    """Loop infinito que faz long-polling na fila SQS."""
    log.info("Iniciando o worker SQS...")
    while True:
        try:
            # WaitTimeSeconds=20 → long-polling: só retorna quando há mensagem ou após 20s
            response = sqs_client.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20
            )

            messages = response.get('Messages', [])
            if not messages:
                continue

            log.info(f"Recebidas {len(messages)} mensagens.")
            for message in messages:
                process_message(message)

        except ClientError as e:
            log.error(f"Erro Boto3 no loop SQS: {e}")
            time.sleep(10)
        except Exception as e:
            log.error(f"Erro inesperado no loop SQS: {e}")
            time.sleep(10)


# --- Servidor Flask (apenas para health check) ---

app = Flask(__name__)

@app.route('/health')
def health():
    """ Verificação de saúde — usada pelos probes do Kubernetes e do docker compose """
    return jsonify({"status": "ok"})


# --- Inicialização ---

def start_worker():
    """Inicia o worker SQS em thread separada — apenas se SQS estiver configurado."""
    if not SQS_ENABLED:
        # Modo local: não inicia o worker, mas o Flask continua rodando normalmente
        return
    worker_thread = threading.Thread(target=sqs_worker_loop, daemon=True)
    worker_thread.start()


start_worker()

if __name__ == '__main__':
    port = int(os.getenv("PORT", "8005"))
    app.run(host='0.0.0.0', port=port, debug=False)  # nosec B104
