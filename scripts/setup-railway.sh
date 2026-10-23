#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

command -v railway >/dev/null || { echo "Install the Railway CLI first: brew install railway"; exit 1; }
railway whoami >/dev/null 2>&1 || railway login

railway status >/dev/null 2>&1 || railway init --name personal-n8n

railway add --database postgres

railway add --service n8n
railway domain --service n8n

ENCRYPTION_KEY="$(openssl rand -hex 32)"
railway variables --service n8n \
  --set 'PORT=5678' \
  --set 'N8N_PORT=5678' \
  --set 'N8N_PROTOCOL=https' \
  --set 'N8N_HOST=${{RAILWAY_PUBLIC_DOMAIN}}' \
  --set 'WEBHOOK_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}/' \
  --set 'N8N_EDITOR_BASE_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}/' \
  --set 'N8N_PROXY_HOPS=1' \
  --set 'DB_TYPE=postgresdb' \
  --set 'DB_POSTGRESDB_HOST=${{Postgres.PGHOST}}' \
  --set 'DB_POSTGRESDB_PORT=${{Postgres.PGPORT}}' \
  --set 'DB_POSTGRESDB_DATABASE=${{Postgres.PGDATABASE}}' \
  --set 'DB_POSTGRESDB_USER=${{Postgres.PGUSER}}' \
  --set 'DB_POSTGRESDB_PASSWORD=${{Postgres.PGPASSWORD}}' \
  --set 'GENERIC_TIMEZONE=Asia/Kolkata' \
  --set 'TZ=Asia/Kolkata' \
  --set 'N8N_RUNNERS_ENABLED=true' \
  --set "N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}"

echo
echo "N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}"
echo "^ Save this somewhere safe. Losing it makes stored credentials unreadable."
echo

railway up --service n8n --detach

echo "Deploy started. Watch it with: railway logs --service n8n"
echo "n8n creates its own database tables on first boot."
