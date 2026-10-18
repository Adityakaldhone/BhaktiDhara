import logging
from pathlib import Path
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Header, HTTPException, Query
from fastapi.responses import FileResponse
import aiosqlite

from app.database import DB_PATH, get_device_subscription_status

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/granth", tags=["Granth & Sacred Scriptures"])


async def _is_user_premium(device_id: Optional[str]) -> bool:
    if not device_id:
        return False
    try:
        status = await get_device_subscription_status(device_id[:64])
        return bool(status.get("isActive"))
    except Exception as e:
        logger.warning(f"Error checking VIP status for {device_id}: {e}")
        return False


@router.get("/books")
async def get_granth_books(
    x_device_id: Optional[str] = Header(None, alias="X-Device-Id"),
) -> Dict[str, Any]:
    """Returns the list of all sacred scriptures (e.g. Bhagavad Gita, Garuda Purana, Dasbodh)."""
    is_vip = await _is_user_premium(x_device_id)

    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(
            """
            SELECT id, slug, title_mr, title_hi, title_en,
                   subtitle_mr, subtitle_hi, subtitle_en,
                   description_mr, description_hi, description_en,
                   total_chapters, total_verses, free_chapters,
                   cover_image, sort_order, is_active, pdf_url
            FROM granth_books
            ORDER BY sort_order ASC, id ASC
            """
        ) as cur:
            rows = await cur.fetchall()

    books = []
    for r in rows:
        books.append({
            "id": r["id"],
            "slug": r["slug"],
            "title": {
                "mr": r["title_mr"],
                "hi": r["title_hi"],
                "en": r["title_en"],
            },
            "subtitle": {
                "mr": r["subtitle_mr"],
                "hi": r["subtitle_hi"],
                "en": r["subtitle_en"],
            },
            "description": {
                "mr": r["description_mr"],
                "hi": r["description_hi"],
                "en": r["description_en"],
            },
            "totalChapters": r["total_chapters"],
            "totalVerses": r["total_verses"],
            "freeChapters": r["free_chapters"],
            "coverImage": r["cover_image"],
            "pdfUrl": r["pdf_url"] if "pdf_url" in r.keys() else None,
            "isActive": bool(r["is_active"]),
            "isUnlocked": is_vip or (r["free_chapters"] >= r["total_chapters"]),
        })

    return {
        "status": "ok",
        "isPremiumUser": is_vip,
        "books": books,
    }


@router.get("/books/{slug}/chapters")
async def get_granth_chapters(
    slug: str,
    x_device_id: Optional[str] = Header(None, alias="X-Device-Id"),
) -> Dict[str, Any]:
    """Returns the chapters of a sacred book with lock/unlock status."""
    is_vip = await _is_user_premium(x_device_id)

    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute("SELECT * FROM granth_books WHERE slug = ?", (slug,)) as cur:
            book = await cur.fetchone()

        if not book:
            raise HTTPException(status_code=404, detail="Book not found")

        free_chapters = book["free_chapters"]

        async with db.execute(
            """
            SELECT id, chapter_number, name_mr, name_hi, name_en, name_sanskrit,
                   summary_mr, summary_hi, summary_en, verses_count
            FROM granth_chapters
            WHERE book_slug = ?
            ORDER BY chapter_number ASC
            """,
            (slug,)
        ) as cur:
            rows = await cur.fetchall()

    chapters = []
    for r in rows:
        ch_num = r["chapter_number"]
        is_free = (ch_num <= free_chapters)
        is_unlocked = is_vip or is_free

        chapters.append({
            "id": r["id"],
            "chapterNumber": ch_num,
            "name": {
                "mr": r["name_mr"],
                "hi": r["name_hi"],
                "en": r["name_en"],
                "sanskrit": r["name_sanskrit"],
            },
            "summary": {
                "mr": r["summary_mr"],
                "hi": r["summary_hi"],
                "en": r["summary_en"],
            },
            "versesCount": r["verses_count"],
            "isFree": is_free,
            "isUnlocked": is_unlocked,
        })

    return {
        "status": "ok",
        "bookSlug": slug,
        "bookTitle": {
            "mr": book["title_mr"],
            "hi": book["title_hi"],
            "en": book["title_en"],
        },
        "coverImage": book["cover_image"] if "cover_image" in book.keys() else None,
        "pdfUrl": book["pdf_url"] if "pdf_url" in book.keys() else None,
        "freeChapters": free_chapters,
        "isPremiumUser": is_vip,
        "chapters": chapters,
    }


@router.get("/books/{slug}/chapter/{chapter_num}")
async def get_granth_chapter_verses(
    slug: str,
    chapter_num: int,
    x_device_id: Optional[str] = Header(None, alias="X-Device-Id"),
) -> Dict[str, Any]:
    """Returns the verses of a chapter.
    Free chapters are unlocked for all users.
    Locked chapters (chapter_num > free_chapters) require Premium.
    If non-premium, returns a teaser preview (first 2 verses) + paywall locked flag.
    """
    is_vip = await _is_user_premium(x_device_id)

    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row

        # Check book
        async with db.execute("SELECT * FROM granth_books WHERE slug = ?", (slug,)) as cur:
            book = await cur.fetchone()
        if not book:
            raise HTTPException(status_code=404, detail="Book not found")

        # Check chapter
        async with db.execute(
            "SELECT * FROM granth_chapters WHERE book_slug = ? AND chapter_number = ?",
            (slug, chapter_num)
        ) as cur:
            chapter = await cur.fetchone()
        if not chapter:
            raise HTTPException(status_code=404, detail="Chapter not found")

        free_chapters = book["free_chapters"]
        is_free_chapter = (chapter_num <= free_chapters)
        has_full_access = is_vip or is_free_chapter

        # Fetch verses
        async with db.execute(
            """
            SELECT verse_number, slok, transliteration, word_meanings,
                   meaning_mr, meaning_hi, meaning_en
            FROM granth_verses
            WHERE book_slug = ? AND chapter_number = ?
            ORDER BY verse_number ASC
            """,
            (slug, chapter_num)
        ) as cur:
            rows = await cur.fetchall()

    verses = []
    # If locked and not premium, provide only 2 teaser preview verses
    allowed_rows = rows if has_full_access else rows[:2]

    for r in allowed_rows:
        verses.append({
            "verseNumber": r["verse_number"],
            "slok": r["slok"],
            "transliteration": r["transliteration"],
            "wordMeanings": r["word_meanings"],
            "meaning": {
                "mr": r["meaning_mr"] or r["meaning_hi"],
                "hi": r["meaning_hi"],
                "en": r["meaning_en"],
            },
        })

    return {
        "status": "ok",
        "bookSlug": slug,
        "bookTitle": {
            "mr": book["title_mr"],
            "hi": book["title_hi"],
            "en": book["title_en"],
        },
        "chapterNumber": chapter_num,
        "chapterName": {
            "mr": chapter["name_mr"],
            "hi": chapter["name_hi"],
            "en": chapter["name_en"],
            "sanskrit": chapter["name_sanskrit"],
        },
        "chapterSummary": {
            "mr": chapter["summary_mr"],
            "hi": chapter["summary_hi"],
            "en": chapter["summary_en"],
        },
        "totalVerses": chapter["verses_count"],
        "isFree": is_free_chapter,
        "isLocked": not has_full_access,
        "isPremiumUser": is_vip,
        "verses": verses,
    }


POTHI_DIR = Path(__file__).resolve().parent.parent / "data" / "pothi"

POTHI_CATALOG = {
    "garuda-purana": {
        "title": {
            "mr": "सचित्र संपूर्ण गरुड महापुराण",
            "hi": "सचित्र संपूर्ण गरुड़ महापुराण",
            "en": "Sacred Garuda Mahapuranam (Illustrated)",
        },
        "subtitle": {
            "mr": "६३८ पृष्ठे • आचारकाण्ड, प्रेतकल्प व ब्रह्मकाण्ड",
            "hi": "६३८ पृष्ठ • आचारकाण्ड, प्रेतकल्प एवं ब्रह्मकाण्ड",
            "en": "638 Pages • Acharakhanda, Pretakalpa & Brahmakhanda",
        },
        "description": {
            "mr": "मूळ प्राचीन ग्रंथाचे सचित्र ६३८ पृष्ठांचे संपूर्ण वाचन. संस्कृत श्लोक, टीका आणि सविस्तर भावार्थ.",
            "hi": "मूल प्राचीन ग्रंथ के सचित्र ६३८ पृष्ठों का सम्पूर्ण अध्ययन। संस्कृत श्लोक, व्याख्या और विस्तृत भावार्थ।",
            "en": "Authentic complete 638-page sacred illustrated manuscript with Sanskrit verses and full commentary.",
        },
        "totalPages": 638,
        "freePages": 638,
        "attribution": {
            "mr": "प्राचीन ग्रंथ डिजिटल संकलन: Indic Journals / Internet Archive (CC BY-NC-ND 4.0 परवान्याअंतर्गत सर्व भाविकांसाठी विनामूल्य उपलब्ध).",
            "hi": "प्राचीन ग्रंथ डिजिटल संकलन: Indic Journals / Internet Archive (CC BY-NC-ND 4.0 लाइसेंस के अंतर्गत समस्त श्रद्धालुओं हेतु निःशुल्क उपलब्ध)।",
            "en": "Digital preservation courtesy of Indic Journals / Internet Archive under CC BY-NC-ND 4.0. Offered freely for non-commercial devotional study.",
        },
        "sections": [
            {"title": "मंगलाचरण एवं विषय-सूची", "startPage": 1},
            {"title": "आचारकाण्ड (प्रथम भाग)", "startPage": 15},
            {"title": "धर्मकाण्ड (प्रेतकल्प - मरणोत्तर यात्रा)", "startPage": 451},
            {"title": "ब्रह्मकाण्ड (परमज्ञान एवं मोक्ष)", "startPage": 585},
        ],
    },
    "dasbodh": {
        "title": {
            "mr": "सचित्र संपूर्ण श्रीमद् दासबोध",
            "hi": "सचित्र सम्पूर्ण श्रीमद् दासबोध",
            "en": "Sacred Shrimad Dasbodh (Illustrated)",
        },
        "subtitle": {
            "mr": "४६७ पृष्ठे • २० दशक, २०० समास व आरती",
            "hi": "४६७ पृष्ठ • २० दशक, २०० समास एवं आरती",
            "en": "467 Pages • 20 Dashakas, 200 Samasas & Aarti",
        },
        "description": {
            "mr": "समर्थ रामदास स्वामी विरचित अजरामर ग्रंथराज. ज्ञान, भक्ती, वैराग्य व समर्थ जीवनपद्धतीचे संपूर्ण मार्गदर्शन.",
            "hi": "समर्थ रामदास स्वामी विरचित अमर ग्रंथराज। ज्ञान, भक्ति, वैराग्य एवं जीवन जीने की कला का सम्पूर्ण मार्गदर्शन।",
            "en": "The monumental spiritual treatise by Samarth Ramdas Swami on devotion, wisdom, dispassion, and righteous action.",
        },
        "totalPages": 467,
        "freePages": 55,
        "attribution": {
            "mr": "सार्वजनिक कार्यक्षेत्र (Public Domain Mark 1.0) • समर्थ रामदास स्वामी विरचित प्रासादिक ग्रंथराज. सर्व भाविकांसाठी डिजिटल स्वरूपात सादर.",
            "hi": "सार्वजनिक कार्यक्षेत्र (Public Domain Mark 1.0) • समर्थ रामदास स्वामी विरचित पावन ग्रंथराज। सर्व भक्तों के लिए डिजिटल स्वरूप में उपलब्ध।",
            "en": "Public Domain Mark 1.0 • Unrestricted spiritual heritage by Samarth Ramdas Swami. Offered freely in high-definition digital format.",
        },
        "sections": [
            {"title": "प्रस्तावना व ग्रंथारंभ", "startPage": 1},
            {"title": "श्रीसमर्थांचे अल्प चरित्र", "startPage": 4},
            {"title": "श्रीसमर्थांची शिकवण व राष्ट्रकार्य", "startPage": 17},
            {"title": "दशक १ - स्तवन", "startPage": 36},
            {"title": "दशक २ - मूर्खलक्षण", "startPage": 56},
            {"title": "दशक ३ - स्वगुणपरीक्षा", "startPage": 79},
            {"title": "दशक ४ - नवविधा भक्ती", "startPage": 105},
            {"title": "दशक ५ - मंत्रज्ञान", "startPage": 134},
            {"title": "दशक ६ - देवशोधन", "startPage": 161},
            {"title": "दशक ७ - साधन", "startPage": 189},
            {"title": "दशक ८ - आत्मदर्शन", "startPage": 218},
            {"title": "दशक ९ - निस्पृहता", "startPage": 246},
            {"title": "दशक १० - अर्वाचीन", "startPage": 275},
            {"title": "दशक ११ - भीमदशक", "startPage": 295},
            {"title": "दशक १२ - विवेकवैराग्य", "startPage": 311},
            {"title": "दशक १३ - उत्तमपुरुष", "startPage": 327},
            {"title": "दशक १४ - अखंड ध्यान", "startPage": 343},
            {"title": "दशक १५ - आत्मनिवेदन", "startPage": 365},
            {"title": "दशक १६ - सप्ततीर्थ", "startPage": 384},
            {"title": "दशक १७ - प्रकृती पुरुष", "startPage": 402},
            {"title": "दशक १८ - बहुधिश्रुत", "startPage": 418},
            {"title": "दशक १९ - शिकवण", "startPage": 434},
            {"title": "दशक २० - पूर्णदशक", "startPage": 449},
            {"title": "दासबोधाची आरती", "startPage": 467},
        ],
    },
}


@router.get("/books/{slug}/pothi")
async def get_granth_pothi_info(
    slug: str,
    x_device_id: Optional[str] = Header(None, alias="X-Device-Id"),
) -> Dict[str, Any]:
    """Returns Pothi (scanned sacred book) metadata, section checkpoints, and VIP lock status."""
    if slug not in POTHI_CATALOG:
        raise HTTPException(status_code=404, detail="Pothi not found for this book")

    is_vip = await _is_user_premium(x_device_id)
    info = POTHI_CATALOG[slug]

    return {
        "status": "ok",
        "bookSlug": slug,
        "isPremiumUser": is_vip,
        "title": info["title"],
        "subtitle": info["subtitle"],
        "description": info["description"],
        "totalPages": info["totalPages"],
        "freePages": info["freePages"],
        "attribution": info.get("attribution", {}),
        "sections": info["sections"],
    }


@router.get("/books/{slug}/pothi/page/{page_number}")
async def get_granth_pothi_page(
    slug: str,
    page_number: int,
    x_device_id: Optional[str] = Header(None, alias="X-Device-Id"),
):
    """Serves high-resolution, compressed WebP page image with strong browser caching."""
    if slug not in POTHI_CATALOG:
        raise HTTPException(status_code=404, detail="Book not found")

    info = POTHI_CATALOG[slug]
    if page_number < 1 or page_number > info["totalPages"]:
        raise HTTPException(status_code=400, detail="Page number out of range")

    file_path = POTHI_DIR / slug / f"page_{page_number:04d}.webp"
    if not file_path.exists():
        raise HTTPException(status_code=404, detail=f"Page {page_number} not found on server")

    return FileResponse(
        file_path,
        media_type="image/webp",
        headers={
            "Cache-Control": "public, max-age=31536000, immutable",
        },
    )
