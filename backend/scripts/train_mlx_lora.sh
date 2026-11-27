#!/usr/bin/env bash
# Fine-tune BhaktiDhara voice intent model on Apple Silicon with MLX LoRA.
# Safe defaults for MacBook Pro M4 16GB.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

VENV="${ROOT}/backend/.venv-mlx"
ADAPTER_DIR="${BHAKTI_MLX_OUTPUT:-${ROOT}/backend/data/training/mlx_candidate_$(date +%Y%m%d_%H%M%S)}"
export BHAKTI_TRAIN_DIR="${BHAKTI_TRAIN_DIR:-${ADAPTER_DIR}/dataset}"
DATA_DIR="${BHAKTI_TRAIN_DIR}/mlx"
MODEL="${BHAKTI_MLX_MODEL:-mlx-community/Qwen3-4B-Instruct-2507-4bit}"
ITERS="${BHAKTI_MLX_ITERS:-400}"
BATCH="${BHAKTI_MLX_BATCH:-1}"
LEARNING_RATE="${BHAKTI_MLX_LEARNING_RATE:-1e-4}"

dataset_options=()
if [[ "${BHAKTI_MLX_BALANCED:-0}" == "1" ]]; then
  dataset_options+=(--balance-actions)
fi
if [[ -n "${BHAKTI_MLX_FOCUS_ACTIONS:-}" ]]; then
  IFS=, read -ra focus_actions <<< "$BHAKTI_MLX_FOCUS_ACTIONS"
  for action in "${focus_actions[@]}"; do
    dataset_options+=(--focus-action "$action")
  done
fi
resume_options=()
if [[ -n "${BHAKTI_MLX_RESUME_ADAPTER:-}" ]]; then
  resume_options+=(--resume-adapter-file "$BHAKTI_MLX_RESUME_ADAPTER")
fi

echo "==> Ensuring knowledge + SFT dataset"
if [[ "${BHAKTI_REFRESH_KNOWLEDGE:-1}" == "1" ]]; then
  python3 backend/scripts/extract_voice_knowledge.py
fi
if [[ "${BHAKTI_MLX_HOME_ONLY:-0}" == "1" ]]; then
  python3 backend/scripts/prepare_home_adapter.py
elif [[ "${BHAKTI_MLX_FEATURE_INTENTS:-0}" == "1" ]]; then
  BHAKTI_MLX_OUTPUT="$ADAPTER_DIR" python3 backend/scripts/prepare_feature_adapter.py
else
  python3 backend/scripts/generate_training_dataset.py
  python3 backend/scripts/prepare_mlx_dataset.py ${dataset_options[@]+"${dataset_options[@]}"}
fi
cp backend/data/voice_knowledge.json "$BHAKTI_TRAIN_DIR/voice_knowledge.json"
cp backend/app/voice_agent/app_help.json "$BHAKTI_TRAIN_DIR/app_help.json"

echo "==> Python venv + mlx-lm"
if [[ ! -d "$VENV" ]]; then
  python3 -m venv "$VENV"
fi
# shellcheck disable=SC1091
source "$VENV/bin/activate"
if ! python -m pip show mlx-lm >/dev/null 2>&1; then
  python -m pip install mlx-lm
fi

mkdir -p "$ADAPTER_DIR"

echo "==> Training LoRA"
echo "    model=$MODEL"
echo "    data=$DATA_DIR"
echo "    adapters=$ADAPTER_DIR"
echo "    iters=$ITERS batch=$BATCH"
echo "    Tip: close Chrome/Android Studio if memory pressure is high."

# Cap MLX allocator growth on 16GB machines
export MLX_MAX_OPS_PER_BUFFER="${MLX_MAX_OPS_PER_BUFFER:-20}"

python -m mlx_lm lora \
  --model "$MODEL" \
  --train \
  --data "$DATA_DIR" \
  --fine-tune-type lora \
  --mask-prompt \
  --num-layers 16 \
  --batch-size "$BATCH" \
  --iters "$ITERS" \
  --learning-rate "$LEARNING_RATE" \
  --max-seq-length "${BHAKTI_MLX_MAX_SEQ_LENGTH:-1024}" \
  --grad-checkpoint \
  --steps-per-report 10 \
  --steps-per-eval 50 \
  --val-batches "${BHAKTI_MLX_VAL_BATCHES:-24}" \
  --save-every 100 \
  --adapter-path "$ADAPTER_DIR" \
  --seed 42 ${resume_options[@]+"${resume_options[@]}"}

if [[ "${BHAKTI_MLX_FEATURE_INTENTS:-0}" != "1" ]]; then
  PYTHONPATH="$ROOT/backend" BHAKTI_MLX_ADAPTER="$ADAPTER_DIR" BHAKTI_MLX_MODEL="$MODEL" \
    python -u backend/scripts/evaluate_voice_adapter.py --suite home | tee "$ADAPTER_DIR/home-evaluation.txt"
fi

if [[ "${BHAKTI_MLX_HOME_ONLY:-0}" == "1" ]]; then
  echo "Home adapter saved at $ADAPTER_DIR"
  exit 0
fi

echo "==> Evaluating candidate on held-out commands"
PYTHONPATH="$ROOT/backend" BHAKTI_MLX_ADAPTER="$ADAPTER_DIR" BHAKTI_MLX_MODEL="$MODEL" \
  python -u backend/scripts/evaluate_voice_adapter.py --suite "${BHAKTI_MLX_EVAL_SUITE:-all}" | tee "$ADAPTER_DIR/evaluation.txt"

echo ""
echo "Done. Adapter saved at: $ADAPTER_DIR"
echo "To try this candidate in a local backend, set BHAKTI_MLX_ADAPTER=$ADAPTER_DIR."

