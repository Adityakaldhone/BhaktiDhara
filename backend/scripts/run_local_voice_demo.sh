#!/usr/bin/env bash
# Start local BhaktiDhara backend with voice agent + MLX adapter for demo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/backend"

VENV="$ROOT/backend/.venv-mlx"
if [[ ! -d "$VENV" ]]; then
  echo "Missing $VENV — create it and install mlx-lm + requirements first."
  exit 1
fi

# shellcheck disable=SC1091
source "$VENV/bin/activate"
export BHAKTI_ENABLE_MLX="${BHAKTI_ENABLE_MLX:-1}"
port="${BHAKTI_VOICE_PORT:-8000}"
base_url="http://127.0.0.1:$port"
if curl --noproxy '*' --max-time 3 --silent --fail "$base_url/api/v1/voice-agent/health" |
    python -c 'import json,sys; sys.exit(json.load(sys.stdin).get("service") != "bhaktidhara-voice-agent")' 2>/dev/null; then
  echo "BhaktiDhara voice backend is already running at $base_url"
  exit 0
fi
if command -v lsof >/dev/null && lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $port is occupied. Use BHAKTI_VOICE_PORT=8010 bash backend/scripts/run_local_voice_demo.sh and flutter run --dart-define=BHAKTI_VOICE_PORT=8010." >&2
  exit 1
fi

python "$ROOT/backend/scripts/extract_voice_knowledge.py" || true

lan_ip="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
echo "Starting uvicorn on http://0.0.0.0:$port"
echo "Flutter simulator/emulator: $base_url  (and http://10.0.2.2:$port)"
if [[ -n "${lan_ip:-}" ]]; then
  echo "Physical phone on same Wi‑Fi:"
  echo "  flutter run --dart-define=BHAKTI_VOICE_HOST=$lan_ip --dart-define=BHAKTI_VOICE_PORT=$port"
fi
echo "Try: curl -X POST $base_url/api/v1/voice-agent/text -H 'Content-Type: application/json' -d '{\"text\":\"rashi sanga\"}'"
exec uvicorn app.main:app --host 0.0.0.0 --port "$port" --reload
