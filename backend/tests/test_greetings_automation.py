import asyncio
import io
import sys
from datetime import date
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest
from PIL import Image

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

import app.database as database
import app.festival_greetings as fg
import app.greeting_generator as gg
import app.greetings as gr


def _make_png_bytes(width: int = 400, height: int = 600, color=(20, 40, 80)) -> bytes:
    img = Image.new("RGB", (width, height), color=color)
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


@pytest.fixture()
def temp_greetings_env(tmp_path, monkeypatch):
    db_file = str(tmp_path / "test_greetings.db")
    media_dir = tmp_path / "media" / "greetings"
    monkeypatch.setattr(database, "DB_PATH", db_file)
    monkeypatch.setattr(gr, "DB_PATH", db_file)
    monkeypatch.setattr(gg, "DB_PATH", db_file)
    monkeypatch.setattr(fg, "DB_PATH", db_file)
    monkeypatch.setattr(gr, "MEDIA_DIR", media_dir)
    monkeypatch.setattr(gr, "USE_R2_STORAGE", False)
    return db_file, media_dir


def test_festivals_cover_post_dev_deepawali_and_exclude_amavasya_pradosh(temp_greetings_env, monkeypatch):
    async def run():
        await database.init_db()
        await gr.init_greetings_db()

        # Ensure Amavasya and Pradosh Vrat are excluded as requested.
        for slug in fg.FESTIVALS:
            assert "amavasya" not in slug
            assert "pradosh" not in slug

        # Simulate 2026-11-27 (3 days after Dev Deepawali 2026-11-24).
        monkeypatch.setattr(fg, "_today_ist", lambda: date(2026, 11, 27))
        await fg.sync_festival_categories()

        plan = await fg._plan(budget=24)
        planned_slugs = {slug for slug, _, _ in plan}
        assert len(plan) == 24
        # Soonest upcoming Panchang observances within the 10-day window from 2026-11-27:
        # sankashti_chaturthi (Nov 27), ekadashi (Dec 4), masik_shivaratri (Dec 7).
        assert "sankashti_chaturthi" in planned_slugs
        assert "ekadashi" in planned_slugs
        assert "tripuri_purnima" not in planned_slugs

    asyncio.run(run())


def test_sync_hides_far_future_festivals_even_with_existing_images(temp_greetings_env, monkeypatch):
    async def run():
        await database.init_db()
        await gr.init_greetings_db()
        await fg.sync_festival_categories()

        # Seed an image into diwali (next date in 2027) and ekadashi (2026-12-04).
        raw = _make_png_bytes()
        await gg._save_greeting_to_db(raw, lang="mr", category_slug="diwali")
        await gg._save_greeting_to_db(raw, lang="mr", category_slug="ekadashi")

        # On 2026-12-02, ekadashi (Dec 4, 2 days away <= 3) is visible, diwali (331 days away) is hidden.
        monkeypatch.setattr(fg, "_today_ist", lambda: date(2026, 12, 2))
        await fg.sync_festival_categories()

        cats = (await gr.public_categories(lang="en"))["categories"]
        slugs = [c["slug"] for c in cats]
        assert "ekadashi" in slugs
        assert "diwali" not in slugs

        # On 2026-11-27, ekadashi (Dec 4, 7 days away > 3 recurring window) stays hidden until Dec 1.
        monkeypatch.setattr(fg, "_today_ist", lambda: date(2026, 11, 27))
        await fg.sync_festival_categories()
        cats_early = (await gr.public_categories(lang="en"))["categories"]
        assert "ekadashi" not in [c["slug"] for c in cats_early]

    asyncio.run(run())


def test_good_night_category_themes_prompt_and_pipeline(temp_greetings_env):
    async def run():
        await database.init_db()
        await gr.init_greetings_db()

        # Good Night must exist, be active, and sit right after Good Morning.
        cats = (await gr.public_categories(lang="mr"))["categories"]
        slugs = [c["slug"] for c in cats]
        assert "morning" in slugs
        assert "night" in slugs
        assert slugs.index("night") == slugs.index("morning") + 1
        night_cat = next(c for c in cats if c["slug"] == "night")
        assert night_cat["name"] == "शुभ रात्री"
        assert night_cat["emoji"] == "🌙"

        # Prompt and themes should reflect Good Night.
        assert len(gg.NIGHT_THEME_ARCHETYPES_HI) == 10
        assert len(gg.NIGHT_THEME_ARCHETYPES_MR) == 10
        assert len(gg.NIGHT_THEME_ARCHETYPES_EN) == 10
        night_prompt = gg.build_image_prompt(
            gg.NIGHT_THEME_ARCHETYPES_EN[0], "en", for_overlay=True, category="night"
        )
        assert "moonlight" in night_prompt.lower()
        assert "morning sun rays" not in night_prompt.lower()

        # Run Good Night pipeline with mocked AI image generator.
        sample_png = _make_png_bytes()
        with patch.object(gg, "generate_single_greeting_image", new=AsyncMock(return_value=sample_png)):
            res = await gg.run_daily_night_greetings_pipeline(
                languages=["mr", "hi", "en"],
                images_per_lang=2,
                is_manual_trigger=True,
            )

        assert res["status"] == "success"
        assert res["category"] == "night"
        assert res["success"] == 6
        assert await gg.get_category_image_count("night") == 6

        cats_after = (await gr.public_categories(lang="hi"))["categories"]
        night_after = next(c for c in cats_after if c["slug"] == "night")
        assert night_after["name"] == "शुभ रात्रि"
        assert night_after["count"] == 6
        assert night_after["coverUrl"] is not None

    asyncio.run(run())
