#!/bin/bash
set -e

SERVER_IP="46.225.142.210"
SERVER_PATH="/root/bhaktidhara-backend"
LANDING_PATH="/var/www/bhaktidhara-landing"

echo "🚀 Syncing backend code to Hetzner ($SERVER_IP)..."
rsync -avz --exclude '__pycache__' --exclude '*.pyc' --exclude '.env' --exclude 'data/' --exclude 'bhaktidhara.db' "$(dirname "$0")/" "root@$SERVER_IP:$SERVER_PATH/"

echo "🌐 Syncing static landing pages to Nginx web root ($LANDING_PATH)..."
rsync -avz "$(dirname "$0")/app/static/" "root@$SERVER_IP:$LANDING_PATH/"
ssh root@$SERVER_IP "chown -R www-data:www-data $LANDING_PATH && chmod -R 755 $LANDING_PATH && systemctl reload nginx"

echo "🐳 Rebuilding and recreating container on server..."
ssh root@$SERVER_IP "cd $SERVER_PATH && docker compose build && docker compose up -d --force-recreate"

echo "⏳ Waiting for backend to become healthy..."
for i in {1..10}; do
    if curl -s -f "http://$SERVER_IP/api/health" > /dev/null 2>&1; then
        echo "✅ Deployment complete! Server is live and healthy:"
        curl -s "http://$SERVER_IP/api/health"
        echo ""
        exit 0
    fi
    sleep 1
done

echo "⚠️ Server started, but healthcheck took longer than 10s. Check logs with:"
echo "ssh root@$SERVER_IP 'docker logs --tail 30 bhaktidhara_backend'"
