#!/usr/bin/env bash
# Fuse MLX LoRA adapter and create a local Ollama model: bhaktidhara-voice
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

VENV="${ROOT}/backend/.venv-mlx"
ADAPTER_DIR="${ROOT}/backend/data/training/mlx_adapters"
FUSED_DIR="${ROOT}/backend/data/training/mlx_fused"
MODEL="${BHAKTI_MLX_MODEL:-mlx-community/Qwen3-4B-Instruct-2507-4bit}"
OLLAMA_NAME="${BHAKTI_OLLAMA_NAME:-bhaktidhara-voice}"

if [[ ! -d "$ADAPTER_DIR" ]]; then
  echo "Missing adapters at $ADAPTER_DIR — run train_mlx_lora.sh first."
  exit 1
fi

# shellcheck disable=SC1091
source "$VENV/bin/activate"

mkdir -p "$FUSED_DIR"
echo "==> Fusing adapter into model (MLX)"
python -m mlx_lm fuse \
  --model "$MODEL" \
  --adapter-path "$ADAPTER_DIR" \
  --save-path "$FUSED_DIR"

echo "==> Creating Ollama model $OLLAMA_NAME"
# Prefer GGUF export if available; otherwise point Ollama at fused MLX via Modelfile SYSTEM
# and keep serving through mlx for now. For Ollama, convert with llama.cpp/gguf when ready.
MODELFILE="${ROOT}/backend/data/training/Modelfile.bhaktidhara"
cat > "$MODELFILE" <<EOF
FROM qwen3:4b-instruct-2507-q4_K_M
PARAMETER temperature 0.1
PARAMETER top_p 0.9
SYSTEM """You are the BhaktiDhara Devotional App Voice Assistant. Classify devotee commands into JSON actions only. Use Flutter rashi ids (aries..pisces / aquarius for कुंभ). Never invent aarti ids. Prefer open_kundali for kundali/birth chart."""
EOF

if command -v ollama >/dev/null 2>&1; then
  ollama pull qwen3:4b-instruct-2507-q4_K_M || ollama pull qwen2.5:3b || true
  ollama create "$OLLAMA_NAME" -f "$MODELFILE"
  echo "Created Ollama model: $OLLAMA_NAME"
  echo "Set OLLAMA_MODEL=$OLLAMA_NAME in backend env."
else
  echo "ollama not found; fused MLX model is at $FUSED_DIR"
fi

echo "Note: Full GGUF export of fused MLX weights may need an extra convert step."
echo "You can already test adapters with: python -m mlx_lm generate --model $MODEL --adapter-path $ADAPTER_DIR"
