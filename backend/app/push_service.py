"""Firebase Cloud Messaging (HTTP v1) sender for BhaktiDhara push campaigns."""
import asyncio
import json
import logging
import os
import time
from typing import Any, Dict, List, Optional

import httpx

logger = logging.getLogger("bhaktidhara.push")

SERVICE_ACCOUNT_PATH = os.getenv("FIREBASE_SERVICE_ACCOUNT", "/app/data/firebase-service-account.json")
FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
ANDROID_CHANNEL_ID = "bhaktidhara_general"
MAX_CONCURRENT_SENDS = 20

_credentials = None
_project_id: Optional[str] = None
_token_cache: Dict[str, Any] = {"token": None, "expires_at": 0.0}


class PushNotConfigured(Exception):
    pass


def _load_credentials():
    global _credentials, _project_id
    if _credentials is not None:
        return _credentials
    # pyrefly: ignore [missing-import]
    from google.oauth2 import service_account

    raw_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
    if raw_json:
        info = json.loads(raw_json)
    elif os.path.exists(SERVICE_ACCOUNT_PATH):
        with open(SERVICE_ACCOUNT_PATH, encoding="utf-8") as f:
            info = json.load(f)
    else:
        raise PushNotConfigured(
            f"Firebase service account not found. Place it at {SERVICE_ACCOUNT_PATH} "
            "or set FIREBASE_SERVICE_ACCOUNT_JSON."
        )
    _credentials = service_account.Credentials.from_service_account_info(info, scopes=[FCM_SCOPE])
    _project_id = info.get("project_id")
    return _credentials


def push_status() -> Dict[str, Any]:
    try:
        _load_credentials()
        return {"configured": True, "project_id": _project_id}
    except PushNotConfigured as e:
        return {"configured": False, "error": str(e)}
    except Exception as e:
        return {"configured": False, "error": f"Invalid service account: {e}"}


def _refresh_token_sync() -> str:
    # pyrefly: ignore [missing-import]
    from google.auth.transport.requests import Request

    creds = _load_credentials()
    creds.refresh(Request())
    _token_cache["token"] = creds.token
    _token_cache["expires_at"] = time.time() + 50 * 60
    return creds.token


async def _access_token() -> str:
    if _token_cache["token"] and time.time() < _token_cache["expires_at"]:
        return _token_cache["token"]
    return await asyncio.to_thread(_refresh_token_sync)


def build_topic_target(audience: str, locale: str, platform: str) -> Dict[str, str]:
    """Maps dashboard targeting to an FCM `topic` or `condition`.

    Topics are maintained by the app: all, lang_{mr|hi|en}, vip, free, android, ios.
    """
    topics = []
    if audience in ("vip", "free"):
        topics.append(audience)
    if locale in ("mr", "hi", "en"):
        topics.append(f"lang_{locale}")
    if platform in ("android", "ios"):
        topics.append(platform)
    if not topics:
        return {"topic": "all"}
    if len(topics) == 1:
        return {"topic": topics[0]}
    return {"condition": " && ".join(f"'{t}' in topics" for t in topics)}


def _build_message(campaign: Dict[str, Any], target: Dict[str, str]) -> Dict[str, Any]:
    data = {"campaignId": str(campaign["id"])}
    if campaign.get("route"):
        data["route"] = campaign["route"]
    if campaign.get("aarti_id"):
        data["aartiId"] = campaign["aarti_id"]

    notification: Dict[str, Any] = {"title": campaign["title"], "body": campaign["body"]}
    image = (campaign.get("image_url") or "").strip()
    if image:
        notification["image"] = image

    message: Dict[str, Any] = {
        **target,
        "notification": notification,
        "data": data,
        "android": {
            "priority": "HIGH",
            "notification": {
                "channel_id": ANDROID_CHANNEL_ID,
                "color": "#FF9933",
                "sound": "default",
            },
        },
        "apns": {
            "payload": {"aps": {"sound": "default", "mutable-content": 1}},
            **({"fcm_options": {"image": image}} if image else {}),
        },
    }
    return message


async def _post_message(client: httpx.AsyncClient, message: Dict[str, Any]) -> Dict[str, Any]:
    token = await _access_token()
    url = f"https://fcm.googleapis.com/v1/projects/{_project_id}/messages:send"
    try:
        resp = await client.post(
            url,
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            json={"message": message},
            timeout=15,
        )
    except httpx.HTTPError as e:
        return {"ok": False, "error": f"network: {e}", "unregistered": False}
    if resp.status_code == 200:
        return {"ok": True, "name": resp.json().get("name")}
    try:
        err = resp.json().get("error", {})
    except Exception:
        err = {}
    codes = {d.get("errorCode") for d in err.get("details", []) if isinstance(d, dict)}
    unregistered = "UNREGISTERED" in codes or (resp.status_code == 404)
    return {
        "ok": False,
        "error": f"{resp.status_code} {err.get('status', '')}: {err.get('message', resp.text[:200])}",
        "unregistered": unregistered,
    }


async def send_to_topic_target(campaign: Dict[str, Any], target: Dict[str, str]) -> Dict[str, Any]:
    _load_credentials()
    async with httpx.AsyncClient() as client:
        result = await _post_message(client, _build_message(campaign, target))
    return {
        "success": 1 if result["ok"] else 0,
        "failure": 0 if result["ok"] else 1,
        "error": result.get("error", ""),
        "invalid_tokens": [],
    }


async def send_to_tokens(campaign: Dict[str, Any], tokens: List[str]) -> Dict[str, Any]:
    _load_credentials()
    if not tokens:
        return {"success": 0, "failure": 0, "error": "No devices with push tokens match this audience", "invalid_tokens": []}
    sem = asyncio.Semaphore(MAX_CONCURRENT_SENDS)
    invalid: List[str] = []
    errors: List[str] = []

    async with httpx.AsyncClient() as client:
        async def send_one(tok: str) -> bool:
            async with sem:
                result = await _post_message(client, _build_message(campaign, {"token": tok}))
            if not result["ok"]:
                if result.get("unregistered"):
                    invalid.append(tok)
                elif len(errors) < 3:
                    errors.append(result["error"])
            return result["ok"]

        results = await asyncio.gather(*(send_one(t) for t in tokens))

    success = sum(1 for r in results if r)
    return {
        "success": success,
        "failure": len(results) - success,
        "error": "; ".join(errors),
        "invalid_tokens": invalid,
    }
