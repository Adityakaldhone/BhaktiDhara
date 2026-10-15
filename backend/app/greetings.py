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
import boto3
from botocore.config import Config
from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse, RedirectResponse
from PIL import Image, ImageOps, UnidentifiedImageError
from pydantic import BaseModel, Field

from app.database import DB_PATH, get_app_config, get_device_subscription_status, log_admin_action, utc_now_iso

logger = logging.getLogger("bhaktidhara.greetings")

MEDIA_DIR = Path(os.getenv("MEDIA_DIR", str(Path(DB_PATH).resolve().parent / "media"))) / "greetings"
# Under /api/ because nginx on the server only forwards /api/ and /admin here.
MEDIA_URL_PREFIX = "/api/v1/greetings/media"

# Cloudflare R2 Object Storage configuration
USE_R2_STORAGE = os.getenv("USE_R2_STORAGE", "false").strip().lower() in ("true", "1", "yes")
R2_BUCKET_NAME = os.getenv("R2_BUCKET_NAME", "bhaktidharabucket").strip()
R2_ACCOUNT_ID = os.getenv("R2_ACCOUNT_ID", "").strip()
R2_ACCESS_KEY_ID = os.getenv("R2_ACCESS_KEY_ID", "").strip()
R2_SECRET_ACCESS_KEY = os.getenv("R2_SECRET_ACCESS_KEY", "").strip()
R2_PUBLIC_URL = os.getenv("R2_PUBLIC_URL", "").strip().rstrip("/")
if R2_PUBLIC_URL and not R2_PUBLIC_URL.startswith("http"):
    R2_PUBLIC_URL = f"https://{R2_PUBLIC_URL}"

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

def _is_r2_active() -> bool:
    return bool(
        USE_R2_STORAGE
        and R2_BUCKET_NAME
        and R2_ACCOUNT_ID
        and R2_ACCESS_KEY_ID
        and R2_SECRET_ACCESS_KEY
    )


_r2_client = None


def _get_r2_client():
    global _r2_client
    if not _is_r2_active():
        return None
    if _r2_client is None:
        try:
            _r2_client = boto3.client(
                service_name="s3",
                endpoint_url=f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com",
                aws_access_key_id=R2_ACCESS_KEY_ID,
                aws_secret_access_key=R2_SECRET_ACCESS_KEY,
                region_name="auto",
                config=Config(s3={"addressing_style": "path"}, signature_version="s3v4"),
            )
        except Exception as e:
            logger.error("Failed to initialize Cloudflare R2 client: %s", e)
            return None
    return _r2_client


def _upload_to_r2(local_path: Path, object_key: str, content_type: str) -> bool:
    client = _get_r2_client()
    if not client:
        return False
    try:
        with open(local_path, "rb") as f:
            client.upload_fileobj(
                f,
                R2_BUCKET_NAME,
                object_key,
                ExtraArgs={
                    "ContentType": content_type,
                    "CacheControl": "public, max-age=31536000, immutable",
                },
            )
        logger.info("Uploaded %s to R2 (%s/%s)", local_path.name, R2_BUCKET_NAME, object_key)
        return True
    except Exception as e:
        logger.error("Failed to upload %s to R2: %s", local_path.name, e)
        return False


def _delete_from_r2(*object_keys: str) -> None:
    client = _get_r2_client()
    if not client:
        return
    for key in object_keys:
        if not key:
            continue
        try:
            client.delete_object(Bucket=R2_BUCKET_NAME, Key=key)
            logger.info("Deleted %s from R2 bucket %s", key, R2_BUCKET_NAME)
        except Exception as e:
            logger.warning("Failed to delete %s from R2: %s", key, e)


def _sync_local_to_r2() -> Dict[str, Any]:
    if not _is_r2_active():
        return {"status": "error", "message": "R2 storage is not active or credentials missing"}
    files = [p for p in MEDIA_DIR.iterdir() if p.is_file() and FILE_RE.match(p.name)] if MEDIA_DIR.exists() else []
    uploaded = 0
    errors = 0
    for f in files:
        ct = "image/webp" if f.name.endswith(".webp") else "image/jpeg"
        ok = _upload_to_r2(f, f"greetings/{f.name}", ct)
        if ok:
            uploaded += 1
        else:
            errors += 1
    return {"status": "ok", "total": len(files), "uploaded": uploaded, "errors": errors}


def _media_url(file_name: str) -> str:
    if _is_r2_active() and R2_PUBLIC_URL:
        return f"{R2_PUBLIC_URL}/greetings/{file_name}"
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
    hd_path = MEDIA_DIR / hd_name
    thumb_path = MEDIA_DIR / thumb_name
    hd.save(hd_path, "JPEG", quality=88, optimize=True, progressive=True)
    thumb.save(thumb_path, "WEBP", quality=78, method=6)

    # Upload to Cloudflare R2 bucket
    if _is_r2_active():
        _upload_to_r2(hd_path, f"greetings/{hd_name}", "image/jpeg")
        _upload_to_r2(thumb_path, f"greetings/{thumb_name}", "image/webp")

    return {"hd_file": hd_name, "thumb_file": thumb_name, "width": hd.width, "height": hd.height}


def _delete_files(*names: str) -> None:
    for name in names:
        if name and FILE_RE.match(name):
            try:
                (MEDIA_DIR / name).unlink(missing_ok=True)
            except OSError as e:
                logger.warning("Could not delete %s: %s", name, e)
    if _is_r2_active():
        r2_keys = [f"greetings/{name}" for name in names if name and FILE_RE.match(name)]
        if r2_keys:
            _delete_from_r2(*r2_keys)


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
    if path.is_file():
        return FileResponse(
            path,
            media_type="image/webp" if file_name.endswith(".webp") else "image/jpeg",
            headers={"Cache-Control": "public, max-age=31536000, immutable"},
        )
    if _is_r2_active() and R2_PUBLIC_URL:
        return RedirectResponse(url=f"{R2_PUBLIC_URL}/greetings/{file_name}", status_code=307)
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)


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

    @router.get("/auto-gen/status")
    async def admin_autogen_status():
        from app.greeting_generator import get_generator_status
        return get_generator_status()

    @router.post("/auto-gen/trigger")
    async def admin_autogen_trigger(
        images_per_lang: int = Query(10, ge=1, le=20),
        languages: Optional[str] = Query("hi,mr,en"),
    ):
        from app.greeting_generator import run_daily_morning_greetings_pipeline, get_generator_status
        status = get_generator_status()
        if status.get("running"):
            raise HTTPException(status_code=409, detail="A generation job is already running.")
        langs = [l.strip().lower() for l in (languages or "hi,mr,en").split(",") if l.strip()]
        asyncio.create_task(
            run_daily_morning_greetings_pipeline(
                languages=langs,
                images_per_lang=images_per_lang,
                is_manual_trigger=True,
            )
        )
        return {"status": "started", "languages": langs, "images_per_lang": images_per_lang}

    @router.post("/auto-gen/test")
    async def admin_autogen_test(lang: str = Query("hi", description="hi, mr, or en")):
        from app.greeting_generator import (
            THEME_ARCHETYPES_HI, THEME_ARCHETYPES_MR, THEME_ARCHETYPES_EN,
            build_image_prompt, generate_single_greeting_image, _save_greeting_to_db
        )
        import random
        banks = {"hi": THEME_ARCHETYPES_HI, "mr": THEME_ARCHETYPES_MR, "en": THEME_ARCHETYPES_EN}
        chosen_bank = banks.get(lang.lower(), THEME_ARCHETYPES_HI)
        theme = random.choice(chosen_bank)
        prompt = build_image_prompt(theme, lang.lower())
        try:
            raw_bytes = await generate_single_greeting_image(prompt)
            img_id = await _save_greeting_to_db(raw_bytes, lang=lang.lower(), category_slug="morning")
            return {
                "status": "ok",
                "imageId": img_id,
                "theme": theme.get("theme"),
                "deity": theme.get("deity"),
                "heading": theme.get("heading"),
                "quote": theme.get("quote"),
                "lang": lang.lower(),
            }
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    @router.get("/r2-status")
    async def admin_r2_status():
        active = _is_r2_active()
        test_ok = False
        test_err = None
        if active:
            try:
                client = _get_r2_client()
                if client:
                    client.head_bucket(Bucket=R2_BUCKET_NAME)
                    test_ok = True
            except Exception as e:
                test_err = str(e)
        return {
            "active": active,
            "connected": test_ok,
            "bucket": R2_BUCKET_NAME if active else None,
            "publicUrl": R2_PUBLIC_URL if active else None,
            "error": test_err,
        }

    @router.post("/sync-r2")
    async def admin_sync_r2():
        return await asyncio.to_thread(_sync_local_to_r2)

    return router


def _storage_usage() -> Dict[str, Any]:
    files = [p for p in MEDIA_DIR.iterdir() if p.is_file()] if MEDIA_DIR.exists() else []
    return {
        "files": len(files),
        "bytes": sum(p.stat().st_size for p in files),
        "r2_active": _is_r2_active(),
        "r2_bucket": R2_BUCKET_NAME if _is_r2_active() else None,
        "r2_public_url": R2_PUBLIC_URL if _is_r2_active() else None,
    }
