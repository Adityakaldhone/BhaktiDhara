"""
Lazy MLX LoRA classifier for local Mac demos.
Uses the fine-tuned adapter under backend/data/training/mlx_adapters.
"""

from __future__ import annotations

import json
import os
import re
import threading
from pathlib import Path
from typing import Any, Dict, Optional

DATA_DIR = Path(__file__).resolve().parent.parent.parent / "data"
ADAPTER_DIR = Path(
    os.environ.get(
        "BHAKTI_MLX_ADAPTER",
        str(DATA_DIR / "training" / "mlx_adapters"),
    )
)
MODEL_ID = os.environ.get(
    "BHAKTI_MLX_MODEL",
    "mlx-community/Qwen3-4B-Instruct-2507-4bit",
)
ENABLE_MLX = os.environ.get("BHAKTI_ENABLE_MLX", "1") != "0"

_lock = threading.Lock()
_model = None
_tokenizer = None
_load_error: Optional[str] = None
_active_weights = "adapters.safetensors"

from .prompt import SYSTEM_PROMPT, HOME_PROMPT, HOME_CONTROL_PROMPT
from .app_help import BIRTH_RASHI, TOPICS, ROUTES
from .mandir_agent import MANDIR_GUIDE


def mlx_available() -> bool:
    if not ENABLE_MLX:
        return False
    if not (ADAPTER_DIR / "adapters.safetensors").exists():
        return False
    try:
        import mlx_lm  # noqa: F401
        return True
    except Exception:
        return False


def _ensure_loaded() -> bool:
    global _model, _tokenizer, _load_error
    if _model is not None and _tokenizer is not None:
        return True
    if _load_error:
        return False
    with _lock:
        if _model is not None and _tokenizer is not None:
            return True
        try:
            from mlx_lm import load

            print(f"[voice-mlx] Loading {MODEL_ID} + adapter {ADAPTER_DIR}")
            _model, _tokenizer = load(MODEL_ID, adapter_path=str(ADAPTER_DIR))
            print("[voice-mlx] Model ready")
            return True
        except Exception as e:
            _load_error = str(e)
            print(f"[voice-mlx] Load failed: {e}")
            return False


def _extract_json(text: str) -> Optional[Dict[str, Any]]:
    if not text:
        return None
    cleaned = text.strip()
    # Drop optional <think> blocks from Qwen3
    cleaned = re.sub(r"<think>[\s\S]*?</think>", "", cleaned).strip()
    try:
        return json.loads(cleaned)
    except Exception:
        pass
    match = re.search(r"\{[\s\S]*\}", cleaned)
    if not match:
        return None
    try:
        return json.loads(match.group(0))
    except Exception:
        return None


def classify_with_mlx(text: str, locale: str = "mr-IN", *, home_screen: bool = False, mandir_screen: bool = False, navigation: bool = False,
                      app_questions: bool = False, feature_intents: bool = False, pending_action: str | None = None) -> Optional[Dict[str, Any]]:
    """Classify with the selected adapter and its corresponding training prompt."""
    global _active_weights
    if not mlx_available():
        return None
    if not _ensure_loaded():
        return None

    from mlx_lm import generate

    try:
        profile = "navigation" if navigation else "app_questions" if app_questions else None
        if feature_intents:
            profile = "feature_intents"
        weights = ADAPTER_DIR / "adapters.safetensors"
        prompt_file = ADAPTER_DIR / "prompt.txt"
        system = prompt_file.read_text(encoding="utf-8") if prompt_file.is_file() else SYSTEM_PROMPT
        if profile:
            candidate = ADAPTER_DIR / f"{profile}.safetensors"
            prompt_file = ADAPTER_DIR / f"{profile}_prompt.txt"
            if candidate.is_file() and prompt_file.is_file():
                weights = candidate
                system = prompt_file.read_text(encoding="utf-8")
        if mandir_screen:
            candidate = ADAPTER_DIR / "mandir.safetensors"
            if candidate.is_file():
                weights = candidate
            elif not (ADAPTER_DIR / "mandir-training.json").is_file():
                return None
            system = MANDIR_GUIDE["prompt"]
        elif home_screen:
            # Route positional requests to the specialist; the earlier Home adapter
            # retains its better search and screen-state performance.
            positional = re.search(
                r"\b(?:first|second|third|fourth|fifth|slot|position|number|\d+(?:st|nd|rd|th)?)\b|"
                r"pehl|pahil|dusr|doosr|tisr|chauth|paanchv|पहिल|पहल|दूसर|दुसर|तीसर|तिसर|चौथ|पाँचव|पाचव|क्रमांक|नंबर|[०-९]",
                text.casefold(),
            )
            specialist = ADAPTER_DIR / "home_controls.safetensors"
            home_general = ADAPTER_DIR / "home_general.safetensors"
            if positional and specialist.is_file():
                weights = specialist
                system = HOME_CONTROL_PROMPT
            elif home_general.is_file():
                weights = home_general
                system = HOME_PROMPT
            elif (ADAPTER_DIR / "home_control_prompt.txt").is_file():
                system = (ADAPTER_DIR / "home_control_prompt.txt").read_text(encoding="utf-8")
            else:
                system = HOME_PROMPT
        with _lock:
            # All checkpoints adapt the same layers in one shared base model.
            if weights.name != _active_weights:
                _model.load_weights(str(weights), strict=False)
                _active_weights = weights.name
            content = text.strip()
            followup = pending_action == "ask_rashi"
            if followup:
                system = "Read the conversation and answer a multiple-choice comprehension question with a single letter."
                content = ("Assistant: Which zodiac sign would you like the horoscope for?\n"
                           f"User: {content}\nWhat does the user mean? A: I need help finding out my birth sign. "
                           "B: I named a sign, asked about another topic, or am saying something else. Answer with A or B.")
            messages = [{"role": "system", "content": system}, {"role": "user", "content": content}]
            prompt = _tokenizer.apply_chat_template(
                messages,
                tokenize=False, add_generation_prompt=True,
            )
            raw = generate(
                _model, _tokenizer, prompt=prompt, max_tokens=4 if followup else 160, verbose=False,
            )
        if followup:
            if raw.strip().rstrip(".") == "A":
                return {"action": "find_birth_rashi", "response_text": BIRTH_RASHI["replies"]["start"].get(locale[:2], BIRTH_RASHI["replies"]["start"]["mr"])}
            return {"action": "none", "response_text": ""}
        parsed = _extract_json(raw if isinstance(raw, str) else str(raw))
        if not isinstance(parsed, dict):
            return None
        action = parsed.get("action")
        fields = action if isinstance(action, dict) else parsed
        kind = fields.get("type") or fields.get("action")
        if not isinstance(kind, str):
            return None
        reply = parsed.get("response_text") or fields.get("response_text") or ""
        lang = locale[:2] if locale[:2] in ("en", "hi", "mr") else "mr"
        topic_key = fields.get("feature_key")
        if kind == "answer_app_question" and isinstance(topic_key, str) and topic_key in TOPICS:
            reply = TOPICS[topic_key]["reply"][lang]
        elif not reply and kind in ROUTES:
            reply = ROUTES[kind]["reply"][lang]
        elif not reply and feature_intents:
            screen = next((info for info in TOPICS.values() if info.get("screen_action") == kind), None)
            if screen:
                name = screen["labels"][lang]
                reply = {"en": f"Opening {name}.", "hi": f"{name} खोल रहे हैं।", "mr": f"{name} उघडत आहे."}[lang]
            elif kind == "none":
                reply = {"en": "I couldn’t find a matching BhaktiDhara feature.",
                         "hi": "भक्तिधारा में इसका विकल्प नहीं मिला।",
                         "mr": "भक्तिधारामध्ये यासाठी पर्याय सापडला नाही."}[lang]
        return {
            **{key: fields.get(key) for key in (
                "region", "position", "section", "rashi_id", "query", "aarti_id", "title", "feature_key", "language_code", "mantra_id", "field",
            )},
            "action": kind,
            "response_text": reply,
        }
    except Exception as e:
        print(f"[voice-mlx] generate failed: {e}")
        return None
