"""Greeting image library: categories and HD images uploaded from the admin
dashboard, stored on the server disk and served to the app.

Each upload is stored twice: a small WebP thumbnail for the grid and a
1080px-wide JPEG for viewing and sharing. File names are random tokens, so a
premium image's HD URL can't be guessed from its thumbnail.
"""
import asyncio
import io
import logging
import os
import re
import secrets
from pathlib import Path
from typing import Any, Dict, List, Optional

# pyrefly: ignore [missing-import]
import aiosqlite
from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from PIL import Image, ImageOps, UnidentifiedImageError
from pydantic import BaseModel, Field

from app.database import DB_PATH, get_app_config, get_device_subscription_status, log_admin_action, utc_now_iso

logger = logging.getLogger("bhaktidhara.greetings")

MEDIA_DIR = Path(os.getenv("MEDIA_DIR", str(Path(DB_PATH).resolve().parent / "media"))) / "greetings"
# Under /api/ because nginx on the server only forwards /api/ and /admin here.
MEDIA_URL_PREFIX = "/api/v1/greetings/media"

HD_WIDTH = 1080
THUMB_WIDTH = 480
MAX_UPLOAD_BYTES = int(2.5 * 1024 * 1024)  # 2.5 MB
MAX_PIXELS = 40_000_000
LANGS = {"all", "mr", "hi", "en"}
SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9_-]{0,39}$")
FILE_RE = re.compile(r"^[a-f0-9]{32}\.(jpg|webp)$")

Image.MAX_IMAGE_PIXELS = MAX_PIXELS

DEFAULT_CATEGORIES = [
    ("morning", "शुभ सकाळ", "सुप्रभात", "Good Morning", "🌅"),
    ("motivation", "प्रेरणा", "मोटिवेशन", "Motivation", "💪"),
    ("love", "प्रेम", "लव", "Love", "❤️"),
    ("friendship", "मैत्री", "दोस्ती", "Friendship", "🤝"),
    ("devotional", "भक्ती", "भक्ति", "Devotional", "🙏"),
    ("night", "शुभ रात्री", "शुभ रात्रि", "Good Night", "🌙"),
]


# ── Schema ───────────────────────────────────────────────────────────────────

async def init_greetings_db() -> None:
    MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS greeting_categories (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                slug TEXT NOT NULL UNIQUE,
                name_mr TEXT NOT NULL,
                name_hi TEXT NOT NULL,
                name_en TEXT NOT NULL,
                emoji TEXT DEFAULT '',
                sort_order INTEGER DEFAULT 0,
                active INTEGER DEFAULT 1,
                created_at TIMESTAMP NOT NULL
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS greeting_images (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category_id INTEGER NOT NULL,
                thumb_file TEXT NOT NULL,
                hd_file TEXT NOT NULL,
                width INTEGER NOT NULL,
                height INTEGER NOT NULL,
                lang TEXT DEFAULT 'all',
                premium INTEGER DEFAULT 0,
                active INTEGER DEFAULT 1,
                sort_order INTEGER DEFAULT 0,
                share_count INTEGER DEFAULT 0,
                created_at TIMESTAMP NOT NULL
            )
        """)
        await db.execute(
            "CREATE INDEX IF NOT EXISTS idx_greeting_images_cat ON greeting_images(category_id, active, sort_order)"
        )
        async with db.execute("SELECT COUNT(*) FROM greeting_categories") as cur:
            empty = (await cur.fetchone())[0] == 0
        if empty:
            now = utc_now_iso()
            await db.executemany(
                """INSERT INTO greeting_categories (slug, name_mr, name_hi, name_en, emoji, sort_order, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?)""",
                [(slug, mr, hi, en, emoji, i * 10, now) for i, (slug, mr, hi, en, emoji) in enumerate(DEFAULT_CATEGORIES)],
            )
        await db.commit()


# ── Helpers ──────────────────────────────────────────────────────────────────

def _media_url(file_name: str) -> str:
    return f"{MEDIA_URL_PREFIX}/{file_name}"


def _clean_lang(lang: str) -> str:
    lang = (lang or "all").lower().strip()
    return lang if lang in LANGS else "all"


def _process_upload(raw: bytes) -> Dict[str, Any]:
    """Decodes, auto-rotates and writes the HD JPEG and WebP thumbnail.
    Re-encoding also strips EXIF metadata such as GPS location."""
    try:
        with Image.open(io.BytesIO(raw)) as src:
            src.load()
            img = ImageOps.exif_transpose(src)
    except (UnidentifiedImageError, Image.DecompressionBombError, OSError) as e:
        raise ValueError("Not a valid image") from e

    if img.mode in ("RGBA", "LA", "P"):
        img = img.convert("RGBA")
        bg = Image.new("RGB", img.size, (255, 255, 255))
        bg.paste(img, mask=img.split()[-1])
        img = bg
    else:
        img = img.convert("RGB")

    if img.width < 300 or img.height < 300:
        raise ValueError("Image is too small (min 300×300)")

    hd = img
    if img.width > HD_WIDTH:
        hd = img.resize((HD_WIDTH, round(img.height * HD_WIDTH / img.width)), Image.LANCZOS)
    thumb = img.resize((THUMB_WIDTH, round(img.height * THUMB_WIDTH / img.width)), Image.LANCZOS)

    hd_name = f"{secrets.token_hex(16)}.jpg"
    thumb_name = f"{secrets.token_hex(16)}.webp"
    MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    hd.save(MEDIA_DIR / hd_name, "JPEG", quality=88, optimize=True, progressive=True)
    thumb.save(MEDIA_DIR / thumb_name, "WEBP", quality=78, method=6)
    return {"hd_file": hd_name, "thumb_file": thumb_name, "width": hd.width, "height": hd.height}


def _delete_files(*names: str) -> None:
    for name in names:
        if name and FILE_RE.match(name):
            try:
                (MEDIA_DIR / name).unlink(missing_ok=True)
            except OSError as e:
                logger.warning("Could not delete %s: %s", name, e)


async def _has_premium_access(device_id: str) -> bool:
    config = await get_app_config()
    if not config.get("feature_flags", {}).get("premium_paywall", True):
        return True
    if not device_id:
        return False
    return bool((await get_device_subscription_status(device_id[:64])).get("isActive"))


def _category_json(row, lang: str) -> Dict[str, Any]:
    name = {"mr": row["name_mr"], "hi": row["name_hi"], "en": row["name_en"]}.get(lang, row["name_en"])
    return {
        "slug": row["slug"],
        "name": name,
        "emoji": row["emoji"] or "",
        "count": row["image_count"],
        "coverUrl": _media_url(row["cover_file"]) if row["cover_file"] else None,
    }


# ── Models ───────────────────────────────────────────────────────────────────

class CategoryCreate(BaseModel):
    slug: str
    nameMr: str
    nameHi: str
    nameEn: str
    emoji: str = ""
    sortOrder: int = 0


class CategoryUpdate(BaseModel):
    nameMr: Optional[str] = None
    nameHi: Optional[str] = None
    nameEn: Optional[str] = None
    emoji: Optional[str] = None
    sortOrder: Optional[int] = None
    active: Optional[bool] = None


class ImageUpdate(BaseModel):
    lang: Optional[str] = None
    premium: Optional[bool] = None
    active: Optional[bool] = None
    sortOrder: Optional[int] = None
    categorySlug: Optional[str] = None


# ── Public API ───────────────────────────────────────────────────────────────

public_router = APIRouter()

_COVER_SQL = """
    (SELECT gi.thumb_file FROM greeting_images gi
     WHERE gi.category_id = c.id AND gi.active = 1
     ORDER BY gi.premium, CASE gi.lang WHEN ? THEN 0 WHEN 'all' THEN 1 ELSE 2 END, gi.sort_order, gi.id DESC
     LIMIT 1)
"""


@public_router.get("/api/v1/greetings/categories")
async def public_categories(lang: str = Query("mr", description="mr, hi, en")):
    lang = _clean_lang(lang)
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            f"""
            SELECT c.*, {_COVER_SQL} AS cover_file,
                   (SELECT COUNT(*) FROM greeting_images gi WHERE gi.category_id = c.id AND gi.active = 1) AS image_count
            FROM greeting_categories c
            WHERE c.active = 1
            ORDER BY c.sort_order, c.id
            """,
            (lang,),
        ) as cur:
            rows = await cur.fetchall()
    return {"categories": [_category_json(r, lang) for r in rows]}


@public_router.get("/api/v1/greetings/images")
async def public_images(
    category: str = Query(..., description="Category slug, e.g. morning"),
    lang: str = Query("mr", description="Images in this language come first"),
    deviceId: str = Query("", description="Unlocks HD URLs of premium images for VIP devices"),
    offset: int = Query(0, ge=0),
    limit: int = Query(24, ge=1, le=60),
):
    lang = _clean_lang(lang)
    unlocked = await _has_premium_access(deviceId)
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            """
            SELECT gi.* FROM greeting_images gi
            JOIN greeting_categories c ON c.id = gi.category_id
            WHERE c.slug = ? AND c.active = 1 AND gi.active = 1
            ORDER BY CASE gi.lang WHEN ? THEN 0 WHEN 'all' THEN 1 ELSE 2 END, gi.sort_order, gi.id DESC
            LIMIT ? OFFSET ?
            """,
            (category.lower(), lang, limit + 1, offset),
        ) as cur:
            rows = await cur.fetchall()

    images = []
    for r in rows[:limit]:
        locked = bool(r["premium"]) and not unlocked
        images.append({
            "id": r["id"],
            "category": category.lower(),
            "thumbUrl": _media_url(r["thumb_file"]),
            "hdUrl": None if locked else _media_url(r["hd_file"]),
            "width": r["width"],
            "height": r["height"],
            "lang": r["lang"],
            "premium": bool(r["premium"]),
            "locked": locked,
        })
    return {"images": images, "hasMore": len(rows) > limit, "nextOffset": offset + len(images)}


@public_router.post("/api/v1/greetings/images/{image_id}/share")
async def public_record_share(image_id: int):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE greeting_images SET share_count = share_count + 1 WHERE id = ?", (image_id,))
        await db.commit()
    return {"status": "ok"}


@public_router.get(MEDIA_URL_PREFIX + "/{file_name}", include_in_schema=False)
async def serve_greeting_media(file_name: str):
    if not FILE_RE.match(file_name):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    path = MEDIA_DIR / file_name
    if not path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    return FileResponse(
        path,
        media_type="image/webp" if file_name.endswith(".webp") else "image/jpeg",
        headers={"Cache-Control": "public, max-age=31536000, immutable"},
    )


# ── Admin API ────────────────────────────────────────────────────────────────

def build_admin_router(require_admin) -> APIRouter:
    router = APIRouter(prefix="/api/v1/admin/greetings", dependencies=[Depends(require_admin)])

    @router.get("/categories")
    async def admin_categories():
        async with aiosqlite.connect(DB_PATH) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                """
                SELECT c.*,
                       (SELECT COUNT(*) FROM greeting_images gi WHERE gi.category_id = c.id) AS image_count,
                       (SELECT COUNT(*) FROM greeting_images gi WHERE gi.category_id = c.id AND gi.active = 1) AS live_count,
                       (SELECT COALESCE(SUM(share_count), 0) FROM greeting_images gi WHERE gi.category_id = c.id) AS shares
                FROM greeting_categories c ORDER BY c.sort_order, c.id
                """
            ) as cur:
                rows = await cur.fetchall()
        return {"categories": [
            {
                "id": r["id"], "slug": r["slug"], "nameMr": r["name_mr"], "nameHi": r["name_hi"],
                "nameEn": r["name_en"], "emoji": r["emoji"], "sortOrder": r["sort_order"],
                "active": bool(r["active"]), "imageCount": r["image_count"],
                "liveCount": r["live_count"], "shares": r["shares"],
            }
            for r in rows
        ], "storage": await asyncio.to_thread(_storage_usage)}

    @router.post("/categories")
    async def admin_create_category(payload: CategoryCreate):
        slug = payload.slug.strip().lower()
        if not SLUG_RE.match(slug):
            raise HTTPException(status_code=400, detail="Slug must be lowercase letters, digits, - or _")
        names = [payload.nameMr.strip(), payload.nameHi.strip(), payload.nameEn.strip()]
        if not all(names):
            raise HTTPException(status_code=400, detail="All three names are required")
        try:
            async with aiosqlite.connect(DB_PATH) as db:
                await db.execute(
                    """INSERT INTO greeting_categories (slug, name_mr, name_hi, name_en, emoji, sort_order, created_at)
                       VALUES (?, ?, ?, ?, ?, ?, ?)""",
                    (slug, *(n[:60] for n in names), payload.emoji.strip()[:8], payload.sortOrder, utc_now_iso()),
                )
                await db.commit()
        except aiosqlite.IntegrityError:
            raise HTTPException(status_code=409, detail=f"Category '{slug}' already exists")
        await log_admin_action("greeting_category_create", slug)
        return {"status": "ok"}

    @router.patch("/categories/{category_id}")
    async def admin_update_category(category_id: int, payload: CategoryUpdate):
        fields = {
            "name_mr": payload.nameMr, "name_hi": payload.nameHi, "name_en": payload.nameEn,
            "emoji": payload.emoji, "sort_order": payload.sortOrder,
            "active": None if payload.active is None else int(payload.active),
        }
        updates = {k: v for k, v in fields.items() if v is not None}
        if not updates:
            return {"status": "ok"}
        async with aiosqlite.connect(DB_PATH) as db:
            await db.execute(
                f"UPDATE greeting_categories SET {', '.join(f'{k} = ?' for k in updates)} WHERE id = ?",
                (*updates.values(), category_id),
            )
            await db.commit()
        await log_admin_action("greeting_category_update", f"{category_id}: {updates}")
        return {"status": "ok"}

    @router.delete("/categories/{category_id}")
    async def admin_delete_category(category_id: int):
        async with aiosqlite.connect(DB_PATH) as db:
            async with db.execute("SELECT COUNT(*) FROM greeting_images WHERE category_id = ?", (category_id,)) as cur:
                if (await cur.fetchone())[0]:
                    raise HTTPException(status_code=400, detail="Delete or move this category's images first")
            await db.execute("DELETE FROM greeting_categories WHERE id = ?", (category_id,))
            await db.commit()
        await log_admin_action("greeting_category_delete", str(category_id))
        return {"status": "ok"}

    @router.get("/images")
    async def admin_images(category: str = Query(...)):
        async with aiosqlite.connect(DB_PATH) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute(
                """
                SELECT gi.* FROM greeting_images gi JOIN greeting_categories c ON c.id = gi.category_id
                WHERE c.slug = ? ORDER BY gi.sort_order, gi.id DESC
                """,
                (category.lower(),),
            ) as cur:
                rows = await cur.fetchall()
        return {"images": [
            {
                "id": r["id"], "thumbUrl": _media_url(r["thumb_file"]), "hdUrl": _media_url(r["hd_file"]),
                "width": r["width"], "height": r["height"], "lang": r["lang"], "premium": bool(r["premium"]),
                "active": bool(r["active"]), "sortOrder": r["sort_order"], "shares": r["share_count"],
                "createdAt": r["created_at"],
            }
            for r in rows
        ]}

    @router.post("/images")
    async def admin_upload_image(
        file: UploadFile = File(...),
        category: str = Form(...),
        lang: str = Form("all"),
        premium: bool = Form(False),
        sortOrder: int = Form(0),
    ):
        raw = await file.read(MAX_UPLOAD_BYTES + 1)
        if len(raw) > MAX_UPLOAD_BYTES:
            raise HTTPException(status_code=413, detail="Image is larger than 2.5 MB")
        async with aiosqlite.connect(DB_PATH) as db:
            async with db.execute("SELECT id FROM greeting_categories WHERE slug = ?", (category.lower(),)) as cur:
                row = await cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Unknown category")
        try:
            stored = await asyncio.to_thread(_process_upload, raw)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=f"{file.filename}: {e}")

        async with aiosqlite.connect(DB_PATH) as db:
            cur = await db.execute(
                """INSERT INTO greeting_images
                   (category_id, thumb_file, hd_file, width, height, lang, premium, sort_order, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (row[0], stored["thumb_file"], stored["hd_file"], stored["width"], stored["height"],
                 _clean_lang(lang), int(premium), sortOrder, utc_now_iso()),
            )
            await db.commit()
            image_id = cur.lastrowid
        await log_admin_action("greeting_image_upload", f"{category}#{image_id} ({file.filename})")
        return {"status": "ok", "id": image_id}

    @router.patch("/images/{image_id}")
    async def admin_update_image(image_id: int, payload: ImageUpdate):
        updates: Dict[str, Any] = {}
        if payload.lang is not None:
            updates["lang"] = _clean_lang(payload.lang)
        if payload.premium is not None:
            updates["premium"] = int(payload.premium)
        if payload.active is not None:
            updates["active"] = int(payload.active)
        if payload.sortOrder is not None:
            updates["sort_order"] = payload.sortOrder
        async with aiosqlite.connect(DB_PATH) as db:
            if payload.categorySlug:
                async with db.execute(
                    "SELECT id FROM greeting_categories WHERE slug = ?", (payload.categorySlug.lower(),)
                ) as cur:
                    row = await cur.fetchone()
                if not row:
                    raise HTTPException(status_code=404, detail="Unknown category")
                updates["category_id"] = row[0]
            if updates:
                await db.execute(
                    f"UPDATE greeting_images SET {', '.join(f'{k} = ?' for k in updates)} WHERE id = ?",
                    (*updates.values(), image_id),
                )
                await db.commit()
        return {"status": "ok"}

    @router.delete("/images/{image_id}")
    async def admin_delete_image(image_id: int):
        async with aiosqlite.connect(DB_PATH) as db:
            async with db.execute(
                "SELECT thumb_file, hd_file FROM greeting_images WHERE id = ?", (image_id,)
            ) as cur:
                row = await cur.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="Image not found")
            await db.execute("DELETE FROM greeting_images WHERE id = ?", (image_id,))
            await db.commit()
        _delete_files(row[0], row[1])
        await log_admin_action("greeting_image_delete", str(image_id))
        return {"status": "ok"}

    return router


def _storage_usage() -> Dict[str, int]:
    files = [p for p in MEDIA_DIR.iterdir() if p.is_file()] if MEDIA_DIR.exists() else []
    return {"files": len(files), "bytes": sum(p.stat().st_size for p in files)}
