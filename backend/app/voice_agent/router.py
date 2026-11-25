"""
FastAPI Router for BhaktiDhara Voice Agent.
"""

import edge_tts
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import Response
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from .home_controls import validated_action
from .intent_resolver import resolve_voice_turn, resolve_with_local_llm, detect_locale

router = APIRouter(prefix="/api/v1/voice-agent", tags=["voice-agent"])

class TextCommandRequest(BaseModel):
    text: str = Field(..., description="User voice transcript or typed query")
    locale_hint: Optional[str] = Field("mr-IN", description="Preferred locale hint: mr-IN, hi-IN, en-IN")
    pending_action: Optional[str] = Field(None, description="Clarification requested on the previous turn")
    birth_details: Optional[Dict[str, str]] = Field(None, max_length=4)
    session_id: Optional[str] = Field(None, description="Client session ID")
    catalog_version: Optional[str] = Field(None, description="Client catalog version")

class VoiceAction(BaseModel):
    type: str
    rashi_id: Optional[str] = None
    rashi_name: Optional[str] = None
    aarti_id: Optional[str] = None
    song_id: Optional[str] = None
    title: Optional[str] = None
    youtube_video_id: Optional[str] = None
    has_audio: Optional[bool] = None
    field: Optional[str] = None
    feature_key: Optional[str] = None
    chapter: Optional[int] = None
    query: Optional[str] = None
    mantra_id: Optional[str] = None
    language_code: Optional[str] = None

class VoiceAgentResponse(BaseModel):
    status: str
    transcript: str
    locale: str
    response_text: str
    action: VoiceAction
    choices: List[Dict[str, Any]] = []
    birth_details: Optional[Dict[str, str]] = None
    audio_id: Optional[str] = None

@router.post("/text", response_model=VoiceAgentResponse)
async def process_text_command(payload: TextCommandRequest):
    """
    Process a voice transcript or text query, returning an action-ready execution payload.
    """
    if not payload.text or not payload.text.strip():
        raise HTTPException(status_code=400, detail="Empty text command")
        
    result = await resolve_voice_turn(payload.text, payload.locale_hint, pending_action=payload.pending_action,
                                      birth_details=payload.birth_details)
    return result

@router.post("/home-control")
async def home_control(payload: TextCommandRequest):
    """Classify a Home utterance. Flutter resolves positions and values on the active screen."""
    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Empty text command")
    proposal = await resolve_with_local_llm(text, detect_locale(text, payload.locale_hint), home_screen=True)
    return {"action": validated_action(proposal or {}, text) or {"type": "none"}}


@router.get("/health")
async def voice_agent_health():
    """Health check for voice agent service and catalog readiness."""
    mlx_ready = False
    try:
        from .mlx_classifier import mlx_available

        mlx_ready = mlx_available()
    except Exception:
        mlx_ready = False
    return {
        "status": "ready",
        "service": "bhaktidhara-voice-agent",
        "mlx_adapter": mlx_ready,
    }

@router.get("/tts")
async def synthesize_speech(text: str, locale: str = "mr-IN"):
    """
    Synthesize human-grade fluent Indic speech using neural voices.
    mr-IN: Aarohi, hi-IN: Swara, en-IN: Neerja
    """
    if not text or not text.strip():
        raise HTTPException(status_code=400, detail="Empty text")

    voice_map = {
        "mr-IN": "mr-IN-AarohiNeural",
        "mr": "mr-IN-AarohiNeural",
        "hi-IN": "hi-IN-SwaraNeural",
        "hi": "hi-IN-SwaraNeural",
        "en-IN": "en-IN-NeerjaExpressiveNeural",
        "en": "en-IN-NeerjaExpressiveNeural",
    }
    voice = voice_map.get(locale, "mr-IN-AarohiNeural")
    try:
        # Slightly brisker than default so replies feel conversational, not robotic.
        communicate = edge_tts.Communicate(text.strip(), voice, rate="+8%", pitch="+2Hz")
        audio_data = b""
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                audio_data += chunk["data"]
        return Response(content=audio_data, media_type="audio/mpeg")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS synthesis error: {e}")
