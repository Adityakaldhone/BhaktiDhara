"""Remote aarti + deity catalog stored in SQLite and served to the app."""

from __future__ import annotations

import hashlib
import json
from typing import Any, Dict, List, Optional, Tuple

import aiosqlite

from app.database import DB_PATH, utc_now_iso


REQUIRED_AARTI_FIELDS = ("id", "title", "deity", "youtubeVideoId", "lyrics")
DEFAULT_AARTI_SORT_PINS: Dict[str, int] = {
    "vishnu_om_jai_jagdish_hare": -10,
}


def _as_bool(value: Any, default: bool = True) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return bool(value)
    return str(value).strip().lower() in ("1", "true", "yes", "on")


def validate_aarti_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize and validate an aarti JSON body. Raises ValueError on bad input."""
    if not isinstance(payload, dict):
        raise ValueError("Aarti payload must be an object")

    aarti_id = str(payload.get("id") or "").strip()
    title = str(payload.get("title") or "").strip()
    deity = str(payload.get("deity") or "").strip()
    video_id = str(payload.get("youtubeVideoId") or "").strip()
    lyrics = payload.get("lyrics")

    if not aarti_id:
        raise ValueError("id is required")
    if not title:
        raise ValueError("title is required")
    if not deity:
        raise ValueError("deity is required")
    if not video_id:
        raise ValueError("youtubeVideoId is required")
    if not isinstance(lyrics, list) or not lyrics:
        raise ValueError("lyrics must be a non-empty array")

    clean_lyrics: List[Dict[str, Any]] = []
    for i, stanza in enumerate(lyrics):
        if not isinstance(stanza, dict):
            raise ValueError(f"lyrics[{i}] must be an object")
        dev = str(stanza.get("devanagari") or "").strip()
        if not dev:
            raise ValueError(f"lyrics[{i}].devanagari is required")
        try:
            start_ms = int(stanza.get("startTimeMs") or 0)
        except (TypeError, ValueError) as exc:
            raise ValueError(f"lyrics[{i}].startTimeMs must be an integer") from exc
        clean_lyrics.append(
            {
                "startTimeMs": max(0, start_ms),
                "devanagari": dev,
                "transliteration": str(stanza.get("transliteration") or ""),
            }
        )

    backups = payload.get("backupVideoIds") or []
    if not isinstance(backups, list):
        raise ValueError("backupVideoIds must be an array")
    tags = payload.get("tags") or ["Aarti"]
    if not isinstance(tags, list):
        raise ValueError("tags must be an array")

    return {
        "id": aarti_id[:128],
        "title": title[:200],
        "titleHi": str(payload.get("titleHi") or "")[:200],
        "titleMr": str(payload.get("titleMr") or "")[:200],
        "deity": deity[:128],
        "deityHi": str(payload.get("deityHi") or "")[:128],
        "deityMr": str(payload.get("deityMr") or "")[:128],
        "singer": str(payload.get("singer") or "Traditional")[:128],
        "youtubeVideoId": video_id[:64],
        "backupVideoIds": [str(b).strip() for b in backups if str(b).strip()][:8],
        "durationText": str(payload.get("durationText") or "")[:32],
        "accentColorHex": str(payload.get("accentColorHex") or "#8B1D18")[:16],
        "deityEmoji": str(payload.get("deityEmoji") or "🙏")[:8],
        "tags": [str(t).strip() for t in tags if str(t).strip()][:16] or ["Aarti"],
        "about": str(payload.get("about") or "")[:2000],
        "aboutHi": str(payload.get("aboutHi") or "")[:2000],
        "aboutMr": str(payload.get("aboutMr") or "")[:2000],
        "lyrics": clean_lyrics,
    }


def validate_deity_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize and validate a deity JSON body. Raises ValueError on bad input."""
    if not isinstance(payload, dict):
        raise ValueError("Deity payload must be an object")

    key = str(payload.get("key") or "").strip()
    name_en = str(payload.get("nameEn") or "").strip()
    if not key:
        raise ValueError("key is required")
    if not name_en:
        raise ValueError("nameEn is required")

    aliases = payload.get("aliases") or []
    if not isinstance(aliases, list):
        raise ValueError("aliases must be an array")

    image_asset = str(payload.get("imageAsset") or "assets/bhakti/durga.webp").strip()
    image_url = str(payload.get("imageUrl") or "").strip()

    return {
        "key": key[:128],
        "aliases": [str(a).strip() for a in aliases if str(a).strip()][:32],
        "nameEn": name_en[:128],
        "nameHi": str(payload.get("nameHi") or name_en)[:128],
        "nameMr": str(payload.get("nameMr") or name_en)[:128],
        "imageAsset": image_asset[:256] or "assets/bhakti/durga.webp",
        "imageUrl": image_url[:512],
    }


async def ensure_remote_catalog_tables(db: aiosqlite.Connection) -> None:
    await db.execute(
        """
        CREATE TABLE IF NOT EXISTS remote_aartis (
            id TEXT PRIMARY KEY,
            payload_json TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
        )
        """
    )
    await db.execute(
        """
        CREATE TABLE IF NOT EXISTS remote_deities (
            key TEXT PRIMARY KEY,
            payload_json TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
        )
        """
    )
    # Older installs created remote_deities without sort_order.
    async with db.execute("PRAGMA table_info(remote_deities)") as cur:
        cols = {row[1] for row in await cur.fetchall()}
    if "sort_order" not in cols:
        await db.execute(
            "ALTER TABLE remote_deities ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0"
        )
    # Explicit pins for any aarti id / deity key (including bundled local ones).
    await db.execute(
        """
        CREATE TABLE IF NOT EXISTS catalog_sort_overrides (
            target_type TEXT NOT NULL,
            target_id TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (target_type, target_id)
        )
        """
    )


async def list_remote_aartis(include_disabled: bool = True) -> List[Dict[str, Any]]:
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        sql = "SELECT id, payload_json, enabled, sort_order, updated_at FROM remote_aartis"
        if not include_disabled:
            sql += " WHERE enabled = 1"
        sql += " ORDER BY sort_order ASC, updated_at DESC"
        async with db.execute(sql) as cur:
            rows = await cur.fetchall()
    out: List[Dict[str, Any]] = []
    for aarti_id, payload_json, enabled, sort_order, updated_at in rows:
        try:
            payload = json.loads(payload_json)
        except json.JSONDecodeError:
            continue
        if not isinstance(payload, dict):
            continue
        payload["id"] = aarti_id
        payload["sortOrder"] = int(sort_order or 0)
        out.append(
            {
                "id": aarti_id,
                "enabled": bool(enabled),
                "sortOrder": int(sort_order or 0),
                "updatedAt": updated_at,
                "aarti": payload,
            }
        )
    return out


async def list_remote_deities(include_disabled: bool = True) -> List[Dict[str, Any]]:
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        sql = "SELECT key, payload_json, enabled, sort_order, updated_at FROM remote_deities"
        if not include_disabled:
            sql += " WHERE enabled = 1"
        sql += " ORDER BY sort_order ASC, updated_at DESC"
        async with db.execute(sql) as cur:
            rows = await cur.fetchall()
    out: List[Dict[str, Any]] = []
    for key, payload_json, enabled, sort_order, updated_at in rows:
        try:
            payload = json.loads(payload_json)
        except json.JSONDecodeError:
            continue
        if not isinstance(payload, dict):
            continue
        payload["key"] = key
        payload["sortOrder"] = int(sort_order or 0)
        out.append(
            {
                "key": key,
                "enabled": bool(enabled),
                "sortOrder": int(sort_order or 0),
                "updatedAt": updated_at,
                "deity": payload,
            }
        )
    return out


async def upsert_remote_aarti(
    payload: Dict[str, Any],
    *,
    enabled: bool = True,
    sort_order: int = 0,
) -> Dict[str, Any]:
    clean = validate_aarti_payload(payload)
    now = utc_now_iso()
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        await db.execute(
            """
            INSERT INTO remote_aartis (id, payload_json, enabled, sort_order, updated_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                payload_json = excluded.payload_json,
                enabled = excluded.enabled,
                sort_order = excluded.sort_order,
                updated_at = excluded.updated_at
            """,
            (clean["id"], json.dumps(clean, ensure_ascii=False), 1 if enabled else 0, int(sort_order), now),
        )
        await db.commit()
    return {
        "id": clean["id"],
        "enabled": enabled,
        "sortOrder": int(sort_order),
        "updatedAt": now,
        "aarti": clean,
    }


async def set_remote_aarti_enabled(aarti_id: str, enabled: bool) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        cur = await db.execute(
            "UPDATE remote_aartis SET enabled = ?, updated_at = ? WHERE id = ?",
            (1 if enabled else 0, utc_now_iso(), aarti_id),
        )
        await db.commit()
        return cur.rowcount > 0


async def delete_remote_aarti(aarti_id: str) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        cur = await db.execute("DELETE FROM remote_aartis WHERE id = ?", (aarti_id,))
        await db.commit()
        return cur.rowcount > 0


async def upsert_remote_deity(
    payload: Dict[str, Any],
    *,
    enabled: bool = True,
    sort_order: int = 0,
) -> Dict[str, Any]:
    clean = validate_deity_payload(payload)
    now = utc_now_iso()
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        await db.execute(
            """
            INSERT INTO remote_deities (key, payload_json, enabled, sort_order, updated_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET
                payload_json = excluded.payload_json,
                enabled = excluded.enabled,
                sort_order = excluded.sort_order,
                updated_at = excluded.updated_at
            """,
            (
                clean["key"],
                json.dumps(clean, ensure_ascii=False),
                1 if enabled else 0,
                int(sort_order),
                now,
            ),
        )
        await db.commit()
    clean["sortOrder"] = int(sort_order)
    return {
        "key": clean["key"],
        "enabled": enabled,
        "sortOrder": int(sort_order),
        "updatedAt": now,
        "deity": clean,
    }


async def list_sort_overrides() -> List[Dict[str, Any]]:
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        async with db.execute(
            "SELECT target_type, target_id, sort_order, updated_at "
            "FROM catalog_sort_overrides ORDER BY target_type, sort_order ASC, target_id"
        ) as cur:
            rows = await cur.fetchall()
    return [
        {
            "targetType": r[0],
            "targetId": r[1],
            "sortOrder": int(r[2] or 0),
            "updatedAt": r[3],
        }
        for r in rows
    ]


async def upsert_sort_override(target_type: str, target_id: str, sort_order: int) -> Dict[str, Any]:
    kind = (target_type or "").strip().lower()
    if kind not in ("aarti", "deity"):
        raise ValueError("targetType must be 'aarti' or 'deity'")
    tid = (target_id or "").strip()
    if not tid:
        raise ValueError("targetId is required")
    now = utc_now_iso()
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        await db.execute(
            """
            INSERT INTO catalog_sort_overrides (target_type, target_id, sort_order, updated_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(target_type, target_id) DO UPDATE SET
                sort_order = excluded.sort_order,
                updated_at = excluded.updated_at
            """,
            (kind, tid[:128], int(sort_order), now),
        )
        await db.commit()
    return {
        "targetType": kind,
        "targetId": tid[:128],
        "sortOrder": int(sort_order),
        "updatedAt": now,
    }


async def delete_sort_override(target_type: str, target_id: str) -> bool:
    kind = (target_type or "").strip().lower()
    tid = (target_id or "").strip()
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        cur = await db.execute(
            "DELETE FROM catalog_sort_overrides WHERE target_type = ? AND target_id = ?",
            (kind, tid),
        )
        await db.commit()
        return cur.rowcount > 0


async def set_remote_deity_enabled(key: str, enabled: bool) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        cur = await db.execute(
            "UPDATE remote_deities SET enabled = ?, updated_at = ? WHERE key = ?",
            (1 if enabled else 0, utc_now_iso(), key),
        )
        await db.commit()
        return cur.rowcount > 0


async def delete_remote_deity(key: str) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        await ensure_remote_catalog_tables(db)
        cur = await db.execute("DELETE FROM remote_deities WHERE key = ?", (key,))
        await db.commit()
        return cur.rowcount > 0


async def public_catalog_payload() -> Tuple[Dict[str, Any], str]:
    """Returns (body, etag) for enabled remote catalog items + sort maps."""
    aartis_rows = await list_remote_aartis(include_disabled=False)
    deities_rows = await list_remote_deities(include_disabled=False)
    overrides = await list_sort_overrides()

    aarti_sort: Dict[str, int] = dict(DEFAULT_AARTI_SORT_PINS)
    deity_sort: Dict[str, int] = {}
    for row in aartis_rows:
        aarti_sort[row["id"]] = int(row.get("sortOrder") or 0)
    for row in deities_rows:
        deity_sort[row["key"]] = int(row.get("sortOrder") or 0)
    for ov in overrides:
        if ov["targetType"] == "aarti":
            aarti_sort[ov["targetId"]] = int(ov["sortOrder"])
        elif ov["targetType"] == "deity":
            deity_sort[ov["targetId"]] = int(ov["sortOrder"])

    aartis: List[Dict[str, Any]] = []
    for row in aartis_rows:
        payload = dict(row["aarti"] or {})
        payload["sortOrder"] = aarti_sort.get(row["id"], int(row.get("sortOrder") or 0))
        aartis.append(payload)

    deities: List[Dict[str, Any]] = []
    for row in deities_rows:
        payload = dict(row["deity"] or {})
        payload["sortOrder"] = deity_sort.get(row["key"], int(row.get("sortOrder") or 0))
        deities.append(payload)

    stamp_parts = [f"a:{r['id']}:{r['updatedAt']}:{r['sortOrder']}" for r in aartis_rows]
    stamp_parts += [f"d:{r['key']}:{r['updatedAt']}:{r.get('sortOrder', 0)}" for r in deities_rows]
    stamp_parts += [f"o:{o['targetType']}:{o['targetId']}:{o['sortOrder']}" for o in overrides]
    version_src = "|".join(stamp_parts) if stamp_parts else "empty"
    version = hashlib.sha1(version_src.encode("utf-8")).hexdigest()[:16]
    etag = f'"{version}"'

    body = {
        "version": version,
        "aartis": aartis,
        "deities": deities,
        "sort": {"aartis": aarti_sort, "deities": deity_sort},
    }
    return body, etag
