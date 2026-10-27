#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

IMAGE="ghcr.io/open-webui/open-webui:v0.9.5-ollama"
DATA_DIR="/etc/open-webui.d"
ENV_FILE="$DATA_DIR/open-webui.env"
ADMIN_EMAIL="${open_webui_user}"


## INSTALL REQUIRED PACKAGES
apt-get update
apt-get install -y -o Acquire::Retries=5 ca-certificates curl sqlite3 apache2-utils


## INSTALL DOCKER
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y -o Acquire::Retries=5 docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

## CREATE ADMIN ACCOUNT

# By default Open WebUI makes the first visitor the admin and the site is public
# so adding it to the SQLite db beforehand
mkdir -p "$DATA_DIR" "$DATA_DIR/ollama"
ADMIN_HASH=$(htpasswd -bnBC 10 "" "${open_webui_passwd}" | tr -d ':\n')
PROFILE_IMAGE='data:image/png;base64,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'

docker pull "$IMAGE"
docker run -d --rm -p 80:8080 \
  -v "$DATA_DIR:/root/.open_web_ui" -v "$DATA_DIR:/app/backend/data" \
  --name openwebui "$IMAGE"

echo "Waiting for Open WebUI to start..."
timeout 300 bash -c 'until curl -fs -o /dev/null localhost; do sleep 5; done' \
  || { echo "Open WebUI did not start within 300s" >&2; exit 1; }
docker stop openwebui

cat > "$DATA_DIR/webui.sql" <<EOF
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
INSERT INTO auth VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','$${ADMIN_EMAIL}','$${ADMIN_HASH}',1);
INSERT INTO user(id,name,email,role,profile_image_url,created_at,updated_at,last_active_at,username) VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','Admin User','$${ADMIN_EMAIL}','admin','$${PROFILE_IMAGE}',1719901984,1719901984,1719901984,'$${ADMIN_EMAIL}');
COMMIT;
EOF

sqlite3 "$DATA_DIR/webui.db" < "$DATA_DIR/webui.sql"
rm -f "$DATA_DIR/webui.sql"

## CONTAINER SETTINGS

# OpenAI is off unless a base URL is given so prompts stay on the local model
install -m 600 /dev/null "$ENV_FILE"
cat > "$ENV_FILE" <<'EOF'
RAG_EMBEDDING_MODEL_AUTO_UPDATE=true
%{ if openai_base != "" ~}
ENABLE_OPENAI_API=true
OPENAI_API_BASE_URLS=${openai_base}
OPENAI_API_KEY=${openai_key}
%{ else ~}
ENABLE_OPENAI_API=false
%{ endif ~}
EOF

## CREATE systemd UNIT

# %n is the service name so the container is named openwebui.service
cat > /etc/systemd/system/openwebui.service <<EOF
[Unit]
Description=Open WebUI
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Type=simple
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStart=/usr/bin/docker run --name %n -p 80:8080 --env-file $ENV_FILE -v $DATA_DIR:/root/.open_web_ui -v $DATA_DIR:/app/backend/data -v $DATA_DIR/ollama:/root/.ollama $IMAGE

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now openwebui.service

## DOWNLOAD MODEL
echo "Waiting for Ollama..."
timeout 600 bash -c 'until docker exec openwebui.service ollama list >/dev/null 2>&1; do sleep 5; done' \
  || { echo "Ollama did not become ready within 600s" >&2; exit 1; }
docker exec openwebui.service ollama pull "${ollama_model}"
echo "Done!"