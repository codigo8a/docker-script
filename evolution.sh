#!/bin/bash
# Credenciales fijas para PostgreSQL
pg_user="postgres"
pg_password="typebot"
pg_database="evolution_db"

# Actualizando la VPS e instalando dependencias
echo "Actualizando la VPS + Instalando dependencias"
sudo apt update -y && sudo apt upgrade -y
sudo apt install git docker-compose nginx certbot python3-certbot-nginx -y

# Clonando el repositorio Evolution API en la rama v2.0.0
echo "Clonando el repositorio Evolution API en la rama v2.0.0"
git clone -b v2.0.0 https://github.com/EvolutionAPI/evolution-api.git
cd evolution-api

# Creando el archivo .env en la carpeta raíz
cat > .env << EOL
# [Las variables del entorno se mantienen sin traducción, ya que son técnicas]
SERVER_TYPE=http
SERVER_PORT=8080
SERVER_URL=http://localhost:8080

SENTRY_DSN=

CORS_ORIGIN=*
CORS_METHODS=GET,POST,PUT,DELETE
CORS_CREDENTIALS=true

LOG_LEVEL=ERROR,WARN,DEBUG,INFO,LOG,VERBOSE,DARK,WEBHOOKS
LOG_COLOR=true
LOG_BAILEYS=error

DEL_INSTANCE=false

DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=postgresql://${pg_user}:${pg_password}@postgres:5432/${pg_database}?schema=public
DATABASE_CONNECTION_CLIENT_NAME=evolution_exchange

DATABASE_SAVE_DATA_INSTANCE=true
DATABASE_SAVE_DATA_NEW_MESSAGE=true
DATABASE_SAVE_MESSAGE_UPDATE=true
DATABASE_SAVE_DATA_CONTACTS=true
DATABASE_SAVE_DATA_CHATS=true
DATABASE_SAVE_DATA_LABELS=true
DATABASE_SAVE_DATA_HISTORIC=true

RABBITMQ_ENABLED=false
RABBITMQ_URI=amqp://localhost
RABBITMQ_EXCHANGE_NAME=evolution
RABBITMQ_GLOBAL_ENABLED=false
RABBITMQ_EVENTS_APPLICATION_STARTUP=false
RABBITMQ_EVENTS_INSTANCE_CREATE=false
RABBITMQ_EVENTS_INSTANCE_DELETE=false
RABBITMQ_EVENTS_QRCODE_UPDATED=false
RABBITMQ_EVENTS_MESSAGES_SET=false
RABBITMQ_EVENTS_MESSAGES_UPSERT=false
RABBITMQ_EVENTS_MESSAGES_EDITED=false
RABBITMQ_EVENTS_MESSAGES_UPDATE=false
RABBITMQ_EVENTS_MESSAGES_DELETE=false
RABBITMQ_EVENTS_SEND_MESSAGE=false
RABBITMQ_EVENTS_CONTACTS_SET=false
RABBITMQ_EVENTS_CONTACTS_UPSERT=false
RABBITMQ_EVENTS_CONTACTS_UPDATE=false
RABBITMQ_EVENTS_PRESENCE_UPDATE=false
RABBITMQ_EVENTS_CHATS_SET=false
RABBITMQ_EVENTS_CHATS_UPSERT=false
RABBITMQ_EVENTS_CHATS_UPDATE=false
RABBITMQ_EVENTS_CHATS_DELETE=false
RABBITMQ_EVENTS_GROUPS_UPSERT=false
RABBITMQ_EVENTS_GROUP_UPDATE=false
RABBITMQ_EVENTS_GROUP_PARTICIPANTS_UPDATE=false
RABBITMQ_EVENTS_CONNECTION_UPDATE=false
RABBITMQ_EVENTS_CALL=false
RABBITMQ_EVENTS_TYPEBOT_START=false
RABBITMQ_EVENTS_TYPEBOT_CHANGE_STATUS=false

SQS_ENABLED=false
SQS_ACCESS_KEY_ID=
SQS_SECRET_ACCESS_KEY=
SQS_ACCOUNT_ID=
SQS_REGION=

WEBSOCKET_ENABLED=false
WEBSOCKET_GLOBAL_EVENTS=false

WA_BUSINESS_TOKEN_WEBHOOK=evolution
WA_BUSINESS_URL=https://graph.facebook.com
WA_BUSINESS_VERSION=v20.0
WA_BUSINESS_LANGUAGE=en_US

WEBHOOK_GLOBAL_ENABLED=false
WEBHOOK_GLOBAL_URL=''
WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=false
WEBHOOK_EVENTS_APPLICATION_STARTUP=false
WEBHOOK_EVENTS_QRCODE_UPDATED=true
WEBHOOK_EVENTS_MESSAGES_SET=true
WEBHOOK_EVENTS_MESSAGES_UPSERT=true
WEBHOOK_EVENTS_MESSAGES_EDITED=true
WEBHOOK_EVENTS_MESSAGES_UPDATE=true
WEBHOOK_EVENTS_MESSAGES_DELETE=true
WEBHOOK_EVENTS_SEND_MESSAGE=true
WEBHOOK_EVENTS_CONTACTS_SET=true
WEBHOOK_EVENTS_CONTACTS_UPSERT=true
WEBHOOK_EVENTS_CONTACTS_UPDATE=true
WEBHOOK_EVENTS_PRESENCE_UPDATE=true
WEBHOOK_EVENTS_CHATS_SET=true
WEBHOOK_EVENTS_CHATS_UPSERT=true
WEBHOOK_EVENTS_CHATS_UPDATE=true
WEBHOOK_EVENTS_CHATS_DELETE=true
WEBHOOK_EVENTS_GROUPS_UPSERT=true
WEBHOOK_EVENTS_GROUPS_UPDATE=true
WEBHOOK_EVENTS_GROUP_PARTICIPANTS_UPDATE=true
WEBHOOK_EVENTS_CONNECTION_UPDATE=true
WEBHOOK_EVENTS_LABELS_EDIT=true
WEBHOOK_EVENTS_LABELS_ASSOCIATION=true
WEBHOOK_EVENTS_CALL=true
WEBHOOK_EVENTS_TYPEBOT_START=false
WEBHOOK_EVENTS_TYPEBOT_CHANGE_STATUS=false
WEBHOOK_EVENTS_ERRORS=false
WEBHOOK_EVENTS_ERRORS_WEBHOOK=

CONFIG_SESSION_PHONE_CLIENT=Evolution API
CONFIG_SESSION_PHONE_NAME=Chrome

QRCODE_LIMIT=30
QRCODE_COLOR='#175197'

TYPEBOT_ENABLED=true
TYPEBOT_API_VERSION=latest

CHATWOOT_ENABLED=false
CHATWOOT_MESSAGE_READ=true
CHATWOOT_MESSAGE_DELETE=true
CHATWOOT_IMPORT_DATABASE_CONNECTION_URI=postgresql://user:password@host:5432/chatwoot?sslmode=disable
CHATWOOT_IMPORT_PLACEHOLDER_MEDIA_MESSAGE=true

OPENAI_ENABLED=false

DIFY_ENABLED=false

CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://redis:6379/2
CACHE_REDIS_PREFIX_KEY=evolution
CACHE_REDIS_SAVE_INSTANCES=false
CACHE_LOCAL_ENABLED=false

S3_ENABLED=false
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_BUCKET=evolution
S3_PORT=443
S3_ENDPOINT=s3.domain.com
S3_REGION=eu-west-3
S3_USE_SSL=true

CONFIG_SESSION_PHONE_VERSION=2.3000.1023204200
AUTHENTICATION_API_KEY=429683C4C977415CAAFCCE10F7D57E11
AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
LANGUAGE=en
EOL

# Configurando docker-compose.yml para PostgreSQL y Redis
cat > docker-compose.yml << EOL
version: '3.3'

services:
  api:
    container_name: evolution_api
    image: atendai/evolution-api:latest
    restart: always
    ports:
      - 8081:8080
    volumes:
      - evolution_instances:/evolution/instances
    networks:
      - evolution-net
    env_file:
      - .env

  postgres:
    image: postgres:13
    restart: always
    environment:
      POSTGRES_USER: ${pg_user}
      POSTGRES_PASSWORD: ${pg_password}
      POSTGRES_DB: ${pg_database}
    volumes:
      - pg_data:/var/lib/postgresql/data
    networks:
      - evolution-net
      - default

  redis:
    image: redis:alpine
    restart: always
    ports:
      - "6380:6379"
    networks:
      - evolution-net
      - default

volumes:
  evolution_instances:
  pg_data:

networks:
  evolution-net:
    driver: bridge
EOL

# Iniciando los contenedores con Docker Compose
echo "Iniciando contenedores con Docker Compose"
docker-compose up -d

echo "¡Configuración completada exitosamente!"
