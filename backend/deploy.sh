#!/bin/bash
set -e

SERVER_IP="46.225.142.210"
SERVER_PATH="/root/bhaktidhara-backend"

echo "🚀 Syncing backend code to Hetzner ($SERVER_IP)..."
rsync -avz --exclude '__pycache__' --exclude '*.pyc' --exclude '.env' --exclude 'data/*.db*' "$(dirname "$0")/" "root@$SERVER_IP:$SERVER_PATH/"

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
