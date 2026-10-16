"""Automated Daily Good Morning Greeting Generator.

Generates 30 ultra-high-quality, non-duplicated Good Morning greeting cards every night at 12:00 AM IST:
- 10 in Hindi (सुप्रभात + authentic quotes/suvichar)
- 10 in Marathi (शुभ सकाळ + authentic quotes/suvichar)
- 10 in English (Good Morning + inspirational/devotional quotes)

Visual diversity is strictly enforced:
- Spiritual & Sacred: Swami Samarth, Mahadev Shiva, Lord Ganesha, Shri Krishna, Lord Rama, Hanuman, Vitthal-Rukmini, Sai Baba, Maa Durga, Maa Lakshmi
- Zen & Nature: Bamboo water fountains, smooth river pebbles, blooming lotus ponds, frangipani / champa blossoms, morning dew on green leaves
- Traditional Vedic: Sacred Tulsi Vrindavan, traditional courtyards, brass diya lamps, temple river ghats at dawn, hanging temple bells, incense smoke
- Cozy Morning Warmth: Steaming earthen kulhad tea, handcrafted ceramic coffee mugs on sunlit balconies, books and morning sunbeams

Supports dual AI engines:
1. OpenAI DALL-E 3 (Exact visual style of ChatGPT, 1024x1792 portrait 9:16)
2. Google Imagen 3 (Via Gemini API, 9:16 aspect ratio)
Configurable via IMAGE_AI_PROVIDER and OPENAI_API_KEY / GEMINI_API_KEY in .env.
"""

import asyncio
import base64
import json
import logging
import os
import random
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import aiosqlite
import httpx

from app.database import (
    DB_PATH,
    finish_job_run,
    log_admin_action,
    start_job_run,
    update_job_run_detail,
    utc_now_iso,
)
from app.greetings import _process_upload

from dotenv import load_dotenv

# Ensure environment variables are loaded
load_dotenv()

logger = logging.getLogger("bhaktidhara.greeting_gen")

def _get_provider() -> str:
    return os.getenv("IMAGE_AI_PROVIDER", "cloudflare").strip().lower()

def _get_cf_token() -> str:
    return os.getenv("CLOUDFLARE_API_TOKEN", "").strip().strip('"').strip("'")

def _get_cf_account_id() -> str:
    return os.getenv("CLOUDFLARE_ACCOUNT_ID", "").strip().strip('"').strip("'") or os.getenv("R2_ACCOUNT_ID", "").strip().strip('"').strip("'")

def _get_gemini_key() -> str:
    return os.getenv("GEMINI_API_KEY", "").strip().strip('"').strip("'")

def _get_openai_key() -> str:
    return os.getenv("OPENAI_API_KEY", "").strip().strip('"').strip("'")

# Concurrency lock to prevent multiple generation jobs running simultaneously
_generator_lock = asyncio.Lock()
_last_job_status: Dict[str, Any] = {
    "running": False,
    "last_run": None,
    "last_success": None,
    "total_generated": 0,
    "current_progress": "",
    "errors": [],
}


def get_generator_status() -> Dict[str, Any]:
    """Returns the live status of the automated greeting generator."""
    return {
        **_last_job_status,
        "provider": _get_provider(),
        "cloudflare_configured": bool(_get_cf_token() and _get_cf_account_id()),
        "gemini_configured": bool(_get_gemini_key()),
        "openai_configured": bool(_get_openai_key()),
    }


# ── Curated Scene & Quote Archetypes for High Diversity ──────────────────────

THEME_ARCHETYPES_HI: List[Dict[str, str]] = [
    {
        "deity": "Morning Nature",
        "theme": "Misty Alpine Valley Sunrise with Dewy Wildflowers",
        "scene": "Breathtaking panoramic mountain valley filled with soft morning fog, radiant golden sun breaking over rolling pine peaks, foreground meadow covered with wild chamomile and lavender flowers glistening with diamond dewdrops, birds gliding across amber pastel sky.",
        "badge": "Subtle morning sunburst",
        "heading": "सुप्रभात",
        "quote": "सुबह की नई किरणें आपके जीवन में नई उम्मीदें, नया आत्मविश्वास और ढेर सारी खुशियां लेकर आएं।",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Cozy Morning",
        "theme": "Steaming Earthen Kulhad Chai by Sunlit Window",
        "scene": "A steaming terracotta clay kulhad of authentic Indian spiced tea with cinnamon and cardamom on a rustic dark teak wood table by an open window. Window reveals blooming morning garden bathed in golden sunlight. Fresh orange marigold blossoms and delicate jasmine petals beside the cup, golden morning steam rising.",
        "badge": "Warm earthen morning aesthetic",
        "heading": "सुप्रभात",
        "quote": "एक प्यारी सी मुस्कान और एक कप चाय के साथ, आपका दिन ताजगी, उमंग और नई ऊर्जा से भरा रहे।",
        "layout_style": "top_banner",
    },
    {
        "deity": "Zen Nature",
        "theme": "Zen Bamboo Water Fountain & Fresh Champa Flowers",
        "scene": "A natural cut bamboo water spout pouring pure crystal-clear morning water over smooth black river pebbles into a stone basin with gentle water ripples. Floating white and yellow frangipani (champa) flowers, lush emerald green bamboo stalks with sparkling morning dewdrops, soft warm golden bokeh lighting.",
        "badge": "Zen botanical elegance",
        "heading": "सुप्रभात",
        "quote": "मन में सकारात्मक विचार, व्यवहार में मिठास, और हर परिस्थिति में धैर्य यही एक खुशहाल जीवन की पहचान है।",
        "layout_style": "magazine_minimal",
    },
    {
        "deity": "Morning Freshness",
        "theme": "Lush Tropical Green Leaves with Sparkling Dewdrops",
        "scene": "Lush tropical green monstera leaves and fern fronds glistening with crystalline morning dewdrops magnified under warm golden sunbeams, gentle morning mist in background, vibrant morning freshness.",
        "badge": "Pure nature freshness",
        "heading": "सुप्रभात",
        "quote": "हर नया दिन जीवन में एक नया अवसर लेकर आता है, मुस्कुराइए और आत्मविश्वास के साथ आगे बढ़िए।",
        "layout_style": "center_card",
    },
    {
        "deity": "Scenic Balcony",
        "theme": "Artisanal Coffee Mug on Mountain Balcony Overlooking Forest",
        "scene": "An artisanal handcrafted ceramic coffee cup with creamy latte art resting on a natural live-edge wood balcony railing. Panoramic view of rolling misty pine hills with dramatic golden sunbeams piercing through clouds, an open journal and fountain pen beside the mug.",
        "badge": "Contemporary morning comfort",
        "heading": "सुप्रभात",
        "quote": "आज का दिन एक नया अवसर है, अपने सपनों को पंख दें और हर पल को खुशी व कृतज्ञता से जिएं।",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Tranquil Waters",
        "theme": "Mirror Lake at Sunrise with Rustic Wooden Pier",
        "scene": "A crystal clear mirror lake surrounded by ancient pine trees at sunrise. Calm water reflecting pastel pink and golden dawn clouds, a rustic wooden pier in foreground, peaceful morning silence, birds soaring in distance.",
        "badge": "Peaceful lake serenity",
        "heading": "सुप्रभात",
        "quote": "शांति बाहर नहीं, आपके भीतर है। आज अपने दिन की शुरुआत शांत मन और संतुष्ट हृदय से करें।",
        "layout_style": "top_banner",
    },
    {
        "deity": "Golden Fields",
        "theme": "Golden Wheat Field Swaying in Dawn Breeze",
        "scene": "Endless golden wheat stalks gently swaying in cool dawn breeze under a soft amber sky. Warm sun cresting the horizon, glistening dewdrops on wheat ears, a peaceful rustic countryside view.",
        "badge": "Golden harvest glow",
        "heading": "सुप्रभात",
        "quote": "सच्ची खुशी छोटी-छोटी बातों में है, आज का दिन आपके और आपके परिवार के लिए मंगलमय हो।",
        "layout_style": "magazine_minimal",
    },
    {
        "deity": "Botanical Garden",
        "theme": "Blooming Rose Garden with Morning Dew & Butterfly",
        "scene": "Stunning close-up of velvety pink and peach roses blooming in a lush garden, covered with sparkling morning dewdrops. Warm morning golden hour backlighting, soft dreamy bokeh, a fluttering colorful butterfly nearby.",
        "badge": "Floral freshness",
        "heading": "सुप्रभात",
        "quote": "गुलाब की तरह खुद भी महकिए और अपने अच्छे विचारों से दूसरों के जीवन को भी महकाइए।",
        "layout_style": "center_card",
    },
    {
        "deity": "Morning Path",
        "theme": "Scenic Countryside Cobblestone Trail through Mist",
        "scene": "A charming cobblestone path winding through sun-dappled morning forest. Golden sunlight filtering through tall oak trees, soft ground fog, cheerful wild yellow flowers along the trail edge.",
        "badge": "New paths and beginnings",
        "heading": "सुप्रभात",
        "quote": "मंजिल चाहे कितनी भी दूर हो, एक सही और सकारात्मक कदम आपको हमेशा आगे ले जाता है।",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Coastal Horizon",
        "theme": "Pastel Coastal Beach Horizon with Gentle Sunrise Waves",
        "scene": "Serene ocean shoreline at golden sunrise with gentle turquoise waves washing over clean wet sand. Pastel peach and lavender clouds, silhouette of tall palm fronds in foreground catching warm morning light.",
        "badge": "Calm coastal sunrise",
        "heading": "सुप्रभात",
        "quote": "सकारात्मक सोच और आत्मविश्वास के साथ नए दिन का स्वागत करें। आपका दिन बेहद सुखद रहे।",
        "layout_style": "magazine_minimal",
    },
]

THEME_ARCHETYPES_MR: List[Dict[str, str]] = [
    {
        "deity": "Morning Nature",
        "theme": "शांत निसर्गरम्य तलाव आणि कोवळे सोनेरी सूर्यकिरण",
        "scene": "Tranquil scenic mountain lake at sunrise, gentle water ripples reflecting golden and pink morning sky, lush green pine trees, morning mist rising over mountains, birds flying in distance, pure calm natural atmosphere.",
        "badge": "शांत निसर्ग सौंदर्य",
        "heading": "शुभ सकाळ",
        "quote": "प्रत्येक नवी सकाळ जीवनात एक नवीन उमेद आणि सकारात्मक ऊर्जा घेऊन येते. आपला आजचा दिवस आनंदात जावो!",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Cozy Morning",
        "theme": "वाफाळलेला आल्याचा चहा आणि खिडकीतून येणारे कोवळे ऊन",
        "scene": "Traditional authentic brass cup of steaming hot ginger cardamom tea resting on a rustic wooden table by a sunny window. Fresh yellow marigold flowers, soft morning breeze, warm steam rising in golden morning sunlight.",
        "badge": "उबदार चहा व प्रसन्न सकाळ",
        "heading": "शुभ सकाळ",
        "quote": "सकाळचा गोड चहा आणि आपल्या माणसांचे प्रेमळ विचार, आयुष्याला एक वेगळाच गोडवा आणि उत्साह देतात!",
        "layout_style": "top_banner",
    },
    {
        "deity": "Sahyadri Mountains",
        "theme": "हिरवेगार सह्याद्रीचे डोंगर आणि धुक्याची सुंदर चादर",
        "scene": "Magnificent sunrise over rugged green Sahyadri mountain cliffs of Maharashtra, floating sea of clouds in valley below, golden sunlight breaking over hilltops, wild yellow wildflowers swaying in morning breeze.",
        "badge": "सह्याद्रीची रम्य प्रभात",
        "heading": "शुभ सकाळ",
        "quote": "मन शांत, विचार शुद्ध आणि चेहऱ्यावर सुंदर हास्य... हीच एका यशस्वी आणि आनंदी दिवसाची सुरुवात असते.",
        "layout_style": "magazine_minimal",
    },
    {
        "deity": "Zen Nature",
        "theme": "पानावरील चमकणारे दवबिंदू आणि सुवासिक सोनचाफा फुले",
        "scene": "Lush green tropical leaves with glistening diamond-like morning dewdrops, fresh yellow fragrant Sonchafa (champak) and white Mogra flowers resting on wet dark river stones, soft golden sun rays filtering through foliage.",
        "badge": "दवबिंदू आणि चाफा",
        "heading": "शुभ सकाळ",
        "quote": "सोनचाफ्यासारखा सुगंध आणि निसर्गासारखी प्रसन्नता आज दिवसभर तुमच्या आयुष्यात दरवळत राहो!",
        "layout_style": "center_card",
    },
    {
        "deity": "Scenic Balcony",
        "theme": "बाल्कनीतील कॉफी आणि दूरवर पसरलेली निसर्गाची शांतता",
        "scene": "A warm ceramic mug of morning coffee on a balcony table overlooking lush green misty valley, soft pink bougainvillea flowers along railing, morning sparrows chirping, peaceful morning daylight.",
        "badge": "शांत बाल्कनी सकाळ",
        "heading": "शुभ सकाळ",
        "quote": "आयुष्य खूप सुंदर आहे, प्रत्येक नवीन दिवसाची सुरुवात एका गोड हास्याने आणि कृतज्ञतेने करा.",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Zen Water",
        "theme": "बांबूचे शांत पाण्याचे कारंजे आणि हिरवीगार निसर्गसंपदा",
        "scene": "Minimalist Zen cut bamboo water fountain pouring crystal water into a stone basin with gentle ripples, smooth river pebbles, floating white flowers, lush green bamboo forest in background bathed in golden light.",
        "badge": "निर्मळ पाण्याचा प्रवाह",
        "heading": "शुभ सकाळ",
        "quote": "सकारात्मक विचारांची ताकद माणसाला संकटांवर मात करून यशाच्या शिखरावर पोहोचवते. शुभ दिवस!",
        "layout_style": "magazine_minimal",
    },
    {
        "deity": "Golden Fields",
        "theme": "सोनेरी सूर्योदयाच्या प्रकाशात डोलणारी शेतं आणि मंद पहाटेचा वारा",
        "scene": "Lush green and golden farmland stretching to the horizon, bathed in warm orange-golden sunrise light, cool dawn breeze, birds flying across pastel sky, picturesque countryside tranquility.",
        "badge": "हिरवेगार शेतमळे",
        "heading": "शुभ सकाळ",
        "quote": "सूर्याच्या सोनेरी किरणांप्रमाणे तुमचे आयुष्य नेहमी प्रकाशमय, निरोगी आणि समृद्ध राहो!",
        "layout_style": "top_banner",
    },
    {
        "deity": "Botanical Garden",
        "theme": "निसर्गरम्य बागेतील टवटवीत ताजी गुलाबाची फुले",
        "scene": "Vibrant garden with velvety pink and red roses covered with morning dewdrops, glistening in morning sun, background filled with soft bokeh and fluttering butterflies, pure fresh morning aroma.",
        "badge": "टवटवीत गुलाब",
        "heading": "शुभ सकाळ",
        "quote": "माणुसकीच्या नात्यांची फुले नेहमी प्रेमाने फुलवा, दिवस आपोआपच सुंदर आणि आनंददायी बनेल.",
        "layout_style": "center_card",
    },
    {
        "deity": "Valley Sunrise",
        "theme": "शांत डोंगराळ दरीतील पहाटेचा सूर्योदय आणि सोनेरी किरणे",
        "scene": "Dramatic sunbeams breaking through misty mountain valley, tall forest trees, emerald hills, golden hour haze, pristine untouched wilderness.",
        "badge": "डोंगराळ प्रभात",
        "heading": "शुभ सकाळ",
        "quote": "ध्येय मोठे ठेवा, कष्टांवर विश्वास ठेवा आणि प्रत्येक क्षणाचा पुरेपूर आनंद घ्या. सुंदर दिवसाच्या शुभेच्छा!",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Tea Garden Trail",
        "theme": "हिरवेगार चहाचे मळे आणि धुक्यात हरवलेली सकाळची पायवाट",
        "scene": "Rolling emerald green tea plantation hills covered in soft white morning mist, curving stone pathway, warm golden sun peeking over the ridge, fresh tea leaf sprouts with dewdrops.",
        "badge": "चहाचे हिरवेगार मळे",
        "heading": "शुभ सकाळ",
        "quote": "नव्या दिवसाच्या नव्या वाटा तुमच्यासाठी आनंदाच्या, यशाच्या आणि समाधानाच्या ठरोत!",
        "layout_style": "magazine_minimal",
    },
]

THEME_ARCHETYPES_EN: List[Dict[str, str]] = [
    {
        "deity": "Alpine Sunrise",
        "theme": "Panoramic Alpine Valley Sunrise with Pine Forest",
        "scene": "Panoramic alpine mountain valley at dawn with golden sunbeams piercing through majestic pine trees, morning mist rising over lush meadows, wild purple wildflowers glistening with dewdrops, birds soaring across pastel sky.",
        "badge": "Alpine dawn splendour",
        "heading": "Good Morning",
        "quote": "Every sunrise is an invitation to brighten someone's day, embrace gratitude, and start afresh.",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Artisan Coffee",
        "theme": "Steaming Artisanal Latte by Sunlit Cottage Window",
        "scene": "An artisanal handcrafted ceramic mug with creamy latte art on an aged oak table next to a large sunlit window with sheer curtains. Fresh pink peonies in a glass vase and an open hardbound journal beside the mug, golden morning steam.",
        "badge": "Cozy cafe aesthetic",
        "heading": "Good Morning",
        "quote": "Take a deep breath, smile, and embrace today with warmth, kindness, and quiet confidence.",
        "layout_style": "top_banner",
    },
    {
        "deity": "Zen Nature",
        "theme": "Minimalist Zen Bamboo Spout with Frangipani Water Basin",
        "scene": "A tranquil Zen rock garden with a cut bamboo water spout trickling crystal water into a dark basalt basin. Smooth river pebbles, floating white and yellow frangipani blossoms, emerald green bamboo stalks with dewdrops, soft warm morning bokeh.",
        "badge": "Zen serenity",
        "heading": "Good Morning",
        "quote": "Peace begins from within. Approach today with a calm mind, gentle patience, and positive energy.",
        "layout_style": "magazine_minimal",
    },
    {
        "deity": "Dewy Botanical",
        "theme": "Sunlit Emerald Fern with Sparkling Crystal Dewdrops",
        "scene": "A lush tropical botanical sanctuary with large green monstera and fern fronds, crystal water droplets magnified in golden morning sunbeams, blooming white orchids, soft dreamy morning light.",
        "badge": "Botanical dewdrop wonder",
        "heading": "Good Morning",
        "quote": "Small positive thoughts in the morning can change your entire day. Shine bright and stay inspired.",
        "layout_style": "center_card",
    },
    {
        "deity": "Mountain Balcony",
        "theme": "Cedar Porch with Morning Tea Overlooking Rolling Hills",
        "scene": "A warm textured stoneware mug of tea on a rustic wooden balcony table with a cozy cream knitted throw, open view of rolling sunrise hills with golden light flooding across the horizon.",
        "badge": "Rustic mountain tranquility",
        "heading": "Good Morning",
        "quote": "Today is full of endless possibilities. Believe in yourself, keep growing, and make it count.",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Serene Mirror Lake",
        "theme": "Tranquil Forest Lake with Glassy Sunrise Reflection",
        "scene": "Serene glass-like forest lake reflecting pink and peach dawn sky. Gentle morning mist hovering over water, silhouette of weeping willows and pines, soft warm glow illuminating the landscape.",
        "badge": "Mirror lake serenity",
        "heading": "Good Morning",
        "quote": "May your morning be as peaceful as calm waters and your heart as warm as the rising sun.",
        "layout_style": "top_banner",
    },
    {
        "deity": "Wildflower Meadow",
        "theme": "Vibrant Wildflower Meadow Swaying in Dawn Light",
        "scene": "Sun-drenched wildflower meadow filled with buttercups, poppies, and daisies glistening with dewdrops. Warm morning sunbeams breaking over rolling meadows, soft breeze, fluttering swallows.",
        "badge": "Wildflower bloom",
        "heading": "Good Morning",
        "quote": "Bloom where you are planted. Bring joy, spread kindness, and make today wonderful.",
        "layout_style": "magazine_minimal",
    },
    {
        "deity": "Botanical Garden",
        "theme": "Blooming English Rose Garden with Dew & Morning Glow",
        "scene": "Close-up of radiant pink and coral roses in full bloom in a serene garden. Diamond-like dewdrops glistening on petals, soft morning bokeh, golden sunlight filtering through leaves.",
        "badge": "English rose elegance",
        "heading": "Good Morning",
        "quote": "Start every day with a grateful heart. Count your blessings and cherish the simple joys.",
        "layout_style": "center_card",
    },
    {
        "deity": "Country Trail",
        "theme": "Sunlit Country Trail through Misty Morning Woods",
        "scene": "A peaceful cobblestone pathway winding through sun-dappled woods. Golden rays piercing through mist, green mossy stones, fresh morning air, birds flying overhead.",
        "badge": "Morning woodland path",
        "heading": "Good Morning",
        "quote": "Step into today with courage and hope. Great things take time, but every single step matters.",
        "layout_style": "bottom_gradient",
    },
    {
        "deity": "Coastal Horizon",
        "theme": "Tranquil Coastal Beach Horizon at Sunrise",
        "scene": "Calm coastal sunrise with gentle turquoise waves lapping against smooth wet sand, pastel watercolor sky in blush pink and peach, silhouette of palm fronds in foreground catching warm golden light.",
        "badge": "Coastal sunrise calm",
        "heading": "Good Morning",
        "quote": "Let go of yesterday's worries. Today brings a fresh tide of hope, energy, and opportunity.",
        "layout_style": "magazine_minimal",
    },
]


def build_image_prompt(theme: Dict[str, str], lang: str, for_overlay: bool = False) -> str:
    """Constructs a prompt tailored for portrait 9:16 vertical greeting cards.
    If using an overlay compositor (e.g. Cloudflare FLUX), prompts for clean photorealistic morning scenery without text."""
    heading = theme["heading"]
    quote = theme["quote"]
    scene = theme["scene"]
    badge = theme.get("badge", "morning light")

    if for_overlay or _get_provider() == "cloudflare":
        return (
            f"Magnificent vertical mobile wallpaper. Photorealistic 8k quality, cinematic morning lighting with warm golden sun rays and soft bokeh. "
            f"{scene}. Serene peaceful morning atmosphere, natural uplifting mood, hyper-detailed textures, perfectly balanced composition, vertical mobile aspect ratio (9:16), clean background, no text, no watermark, no writing."
        )

    return (
        f"A magnificent vertical 9:16 mobile wallpaper greeting card. "
        f"Photorealistic 8k quality, cinematic morning lighting with warm golden sun rays and soft bokeh. "
        f"{scene} "
        f"In the center or upper-middle section, placed tastefully on a {badge}, "
        f"is large, elegant, stylized calligraphy text clearly displaying the heading '{heading}'. "
        f"Directly below the heading '{heading}', in clean, legible, beautifully spaced typography, "
        f"the following inspirational quote is displayed: '{quote}'. "
        f"Uplifting morning atmosphere, hyper-detailed textures, perfectly balanced composition, "
        f"captivating visual aesthetic, vertical mobile aspect ratio (9:16)."
    )


# ── HarfBuzz Typography Compositor (100% Accurate Devanagari) ─────────────────

FONTS_DIR = Path(__file__).resolve().parent / "fonts"
TITLE_FONT_PATH = str(FONTS_DIR / "YatraOne-Regular.ttf")
BODY_FONT_PATH = str(FONTS_DIR / "Mukta-SemiBold.ttf")


def _draw_devanagari_text(
    canvas: Any,
    text: str,
    font_path: str,
    font_size: int,
    color_rgba: Tuple[int, int, int, int],
    pos_x: int,
    baseline_y: int,
    align: str = "center",
) -> None:
    """Renders complex Devanagari text with 100% correct ligature shaping using HarfBuzz and FreeType."""
    try:
        import freetype
        import uharfbuzz as hb
        from PIL import Image
    except ImportError:
        logger.warning("freetype-py or uharfbuzz not available; text shaping skipped.")
        return

    try:
        if not os.path.exists(font_path) or not text:
            return

        with open(font_path, "rb") as f:
            font_data = f.read()

        blob = hb.Blob(font_data)
        face = hb.Face(blob)
        font = hb.Font(face)
        font.scale = (font_size * 64, font_size * 64)

        buf = hb.Buffer()
        buf.add_str(text)
        buf.guess_segment_properties()
        hb.shape(font, buf)

        infos = buf.glyph_infos
        positions = buf.glyph_positions

        ft_face = freetype.Face(font_path)
        ft_face.set_char_size(font_size * 64)

        total_width = sum(pos.x_advance for pos in positions) >> 6
        if align == "center":
            start_x = pos_x - (total_width // 2)
        elif align == "right":
            start_x = pos_x - total_width
        else:  # left
            start_x = pos_x

        cur_x = start_x
        for info, pos in zip(infos, positions):
            gid = info.codepoint
            x_adv = pos.x_advance >> 6
            x_off = pos.x_offset >> 6
            y_off = pos.y_offset >> 6

            ft_face.load_glyph(gid, freetype.FT_LOAD_RENDER)
            bitmap = ft_face.glyph.bitmap
            bx = ft_face.glyph.bitmap_left
            by = ft_face.glyph.bitmap_top

            if bitmap.width > 0 and bitmap.rows > 0:
                glyph_mask = Image.frombytes("L", (bitmap.width, bitmap.rows), bytes(bitmap.buffer))
                gx = cur_x + x_off + bx
                gy = baseline_y - y_off - by

                color_layer = Image.new("RGBA", glyph_mask.size, color_rgba)
                canvas.paste(color_layer, (gx, gy), mask=glyph_mask)

            cur_x += x_adv
    except Exception as e:
        logger.warning(f"Error shaping text '{text}': {e}")


def _wrap_quote_text(text: str, max_chars: int = 32) -> List[str]:
    """Splits a quote into nicely balanced lines avoiding word truncation."""
    words = text.split()
    lines = []
    cur = []
    cur_len = 0
    for w in words:
        if cur_len + len(w) + 1 <= max_chars:
            cur.append(w)
            cur_len += len(w) + 1
        else:
            if cur:
                lines.append(" ".join(cur))
            cur = [w]
            cur_len = len(w)
    if cur:
        lines.append(" ".join(cur))
    return lines


def compose_greeting_typography(
    raw_bytes: bytes,
    heading: str,
    quote: str,
    layout_style: str = "bottom_gradient",
) -> bytes:
    """Overlays authentic, perfectly shaped Devanagari/English typography onto the background image.
    Supports 4 distinct layout styles to prevent user fatigue:
      - 'bottom_gradient': Cinematic dark gradient at the bottom; top 65% scenery fully open.
      - 'top_banner': Delicate atmospheric dark header gradient at the top; center and bottom scenery open.
      - 'magazine_minimal': Luxury editorial left-aligned typography with vertical gold accent line.
      - 'center_card': Elegant floating frosted glass card in lower-middle section.
    """
    try:
        import io
        from PIL import Image, ImageDraw

        base = Image.open(io.BytesIO(raw_bytes)).convert("RGBA")
        target_w, target_h = 1080, 1920

        # Aspect fill to 1080x1920 (9:16)
        orig_w, orig_h = base.size
        scale = max(target_w / orig_w, target_h / orig_h)
        new_w, new_h = int(orig_w * scale), int(orig_h * scale)
        base = base.resize((new_w, new_h), Image.Resampling.LANCZOS)
        left = (new_w - target_w) // 2
        top = (new_h - target_h) // 2
        base = base.crop((left, top, left + target_w, top + target_h))

        overlay = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        quote_lines = _wrap_quote_text(quote, max_chars=32 if layout_style != "magazine_minimal" else 30) if quote else []

        # ── 1. Top Banner Layout ──────────────────────────────────────────────
        if layout_style == "top_banner":
            if not quote_lines:
                # Compact top gradient for title-only
                for y in range(0, 480):
                    progress = y / 480.0
                    alpha = int(210 * ((1.0 - progress) ** 1.5))
                    draw.line([(0, y), (target_w, y)], fill=(12, 10, 8, alpha))

                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 96, (0, 0, 0, 220), target_w // 2 + 2, 232, align="center")
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 96, (255, 225, 120, 255), target_w // 2, 230, align="center")

                div_w = 240
                draw.line([(target_w - div_w) // 2, 280, (target_w + div_w) // 2, 280], fill=(245, 205, 120, 160), width=2)
            else:
                # Smooth dark gradient at top fading out downwards
                for y in range(0, 720):
                    progress = y / 720.0
                    alpha = int(215 * ((1.0 - progress) ** 1.5))
                    draw.line([(0, y), (target_w, y)], fill=(12, 10, 8, alpha))

                # Heading at top
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 88, (0, 0, 0, 220), target_w // 2 + 2, 222, align="center")
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 88, (255, 225, 120, 255), target_w // 2, 220, align="center")

                div_w = 220
                draw.line([(target_w - div_w) // 2, 265, (target_w + div_w) // 2, 265], fill=(245, 205, 120, 160), width=2)

                start_y = 340
                for i, line in enumerate(quote_lines):
                    ly = start_y + (i * 68)
                    _draw_devanagari_text(overlay, line, BODY_FONT_PATH, 42, (0, 0, 0, 220), target_w // 2 + 1, ly + 1, align="center")
                    _draw_devanagari_text(overlay, line, BODY_FONT_PATH, 42, (255, 255, 255, 255), target_w // 2, ly, align="center")

        # ── 2. Magazine Minimal (Left-Aligned Editorial) ──────────────────────
        elif layout_style == "magazine_minimal":
            if not quote_lines:
                for y in range(1450, target_h):
                    prog_y = (y - 1450) / (target_h - 1450)
                    alpha = int(210 * (prog_y ** 1.2))
                    draw.line([(0, y), (target_w, y)], fill=(10, 12, 16, alpha))

                bar_x = 70
                draw.line([(bar_x, 1610), (bar_x, 1750)], fill=(245, 205, 120, 230), width=4)
                text_x = bar_x + 36
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 90, (0, 0, 0, 220), text_x + 2, 1682, align="left")
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 90, (255, 225, 120, 255), text_x, 1680, align="left")
            else:
                # Semi-translucent dark wash at bottom left
                for y in range(1100, target_h):
                    prog_y = (y - 1100) / (target_h - 1100)
                    alpha = int(215 * (prog_y ** 1.2))
                    draw.line([(0, y), (target_w, y)], fill=(10, 12, 16, alpha))

                # Vertical gold accent bar on the left
                bar_x = 70
                bar_top = 1380
                bar_bot = 1380 + (len(quote_lines) * 65) + 120
                draw.line([(bar_x, bar_top), (bar_x, bar_bot)], fill=(245, 205, 120, 230), width=4)

                # Left-aligned heading
                text_x = bar_x + 36
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 82, (0, 0, 0, 220), text_x + 2, 1432, align="left")
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 82, (255, 225, 120, 255), text_x, 1430, align="left")

                # Left-aligned quote
                start_y = 1520
                for i, line in enumerate(quote_lines):
                    ly = start_y + (i * 64)
                    _draw_devanagari_text(overlay, line, BODY_FONT_PATH, 40, (0, 0, 0, 220), text_x + 1, ly + 1, align="left")
                    _draw_devanagari_text(overlay, line, BODY_FONT_PATH, 40, (250, 250, 250, 255), text_x, ly, align="left")

        # ── 3. Center Card (Frosted Glass Floating Card) ──────────────────────
        elif layout_style == "center_card":
            if not quote_lines:
                # Compact pill card for title-only
                card_w, card_h = 760, 240
                card_x = (target_w - card_w) // 2
                card_y = 1420

                draw.rounded_rectangle([card_x - 3, card_y - 3, card_x + card_w + 3, card_y + card_h + 3], radius=32, fill=(0, 0, 0, 90))
                draw.rounded_rectangle([card_x, card_y, card_x + card_w, card_y + card_h], radius=30, fill=(16, 18, 22, 175), outline=(245, 205, 120, 200), width=2)
                draw.rounded_rectangle([card_x + 8, card_y + 8, card_x + card_w - 8, card_y + card_h - 8], radius=22, outline=(245, 205, 120, 50), width=1)

                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 92, (0, 0, 0, 220), target_w // 2 + 2, card_y + 132, align="center")
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 92, (255, 225, 120, 255), target_w // 2, card_y + 130, align="center")

                div_w = 200
                draw.line([(target_w - div_w) // 2, card_y + 175, (target_w + div_w) // 2, card_y + 175], fill=(245, 205, 120, 160), width=2)
            else:
                card_w, card_h = 940, 480
                card_x = (target_w - card_w) // 2
                card_y = 1180

                # Elegant rounded frosted glass card
                draw.rounded_rectangle([card_x - 3, card_y - 3, card_x + card_w + 3, card_y + card_h + 3], radius=32, fill=(0, 0, 0, 90))
                draw.rounded_rectangle([card_x, card_y, card_x + card_w, card_y + card_h], radius=30, fill=(16, 18, 22, 175), outline=(245, 205, 120, 200), width=2)
                draw.rounded_rectangle([card_x + 10, card_y + 10, card_x + card_w - 10, card_y + card_h - 10], radius=22, outline=(245, 205, 120, 50), width=1)

                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 88, (0, 0, 0, 220), target_w // 2 + 2, card_y + 112, align="center")
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 88, (255, 225, 120, 255), target_w // 2, card_y + 110, align="center")

                div_w = 240
                draw.line([(target_w - div_w) // 2, card_y + 160, (target_w + div_w) // 2, card_y + 160], fill=(245, 205, 120, 160), width=2)

                start_y = card_y + 240
                for i, line in enumerate(quote_lines):
                    ly = start_y + (i * 66)
                    _draw_devanagari_text(overlay, line, BODY_FONT_PATH, 40, (0, 0, 0, 220), target_w // 2 + 1, ly + 1, align="center")
                    _draw_devanagari_text(overlay, line, BODY_FONT_PATH, 40, (255, 255, 255, 255), target_w // 2, ly, align="center")

        # ── 4. Bottom Gradient (Default - Cinematic Open View) ────────────────
        else:
            if not quote_lines:
                for y in range(1400, target_h):
                    prog_y = (y - 1400) / (target_h - 1400)
                    alpha = int(220 * (prog_y ** 1.3))
                    draw.line([(0, y), (target_w, y)], fill=(12, 10, 8, alpha))

                draw.ellipse([target_w // 2 - 4, 1580, target_w // 2 + 4, 1588], fill=(245, 205, 120, 220))

                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 96, (0, 0, 0, 230), target_w // 2 + 2, 1682, align="center")
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 96, (255, 225, 120, 255), target_w // 2, 1680, align="center")

                div_w = 220
                draw.line([(target_w - div_w) // 2, 1725, (target_w + div_w) // 2, 1725], fill=(245, 205, 120, 160), width=2)
            else:
                for y in range(1120, target_h):
                    prog_y = (y - 1120) / (target_h - 1120)
                    alpha = int(225 * (prog_y ** 1.3))
                    draw.line([(0, y), (target_w, y)], fill=(12, 10, 8, alpha))

                # Delicate top accent dot
                draw.ellipse([target_w // 2 - 4, 1370, target_w // 2 + 4, 1378], fill=(245, 205, 120, 220))

                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 92, (0, 0, 0, 230), target_w // 2 + 2, 1472, align="center")
                _draw_devanagari_text(overlay, heading, TITLE_FONT_PATH, 92, (255, 225, 120, 255), target_w // 2, 1470, align="center")

                div_w = 200
                draw.line([(target_w - div_w) // 2, 1515, (target_w + div_w) // 2, 1515], fill=(245, 205, 120, 160), width=2)

                start_y = 1590
                for i, line in enumerate(quote_lines):
                    ly = start_y + (i * 66)
                    _draw_devanagari_text(overlay, line, BODY_FONT_PATH, 42, (0, 0, 0, 230), target_w // 2 + 1, ly + 1, align="center")
                    _draw_devanagari_text(overlay, line, BODY_FONT_PATH, 42, (255, 255, 255, 255), target_w // 2, ly, align="center")

        final = Image.alpha_composite(base, overlay).convert("RGB")
        out = io.BytesIO()
        final.save(out, format="JPEG", quality=95)
        return out.getvalue()
    except Exception as e:
        logger.error(f"Error in compose_greeting_typography: {e}")
        return raw_bytes



# ── AI Generation Backends ────────────────────────────────────────────────────

async def _generate_openai_dalle3(prompt: str) -> bytes:
    """Generates an image via OpenAI DALL-E 3 API."""
    key = _get_openai_key()
    if not key:
        raise ValueError("OPENAI_API_KEY is not configured in backend/.env")

    url = "https://api.openai.com/v1/images/generations"
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    }
    # Use model from environment or try gpt-image-2 / chatgpt-image-latest / dall-e-3
    preferred_model = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-2").strip()
    candidate_models = [preferred_model] + [m for m in ["chatgpt-image-latest", "dall-e-3", "gpt-image-1.5"] if m != preferred_model]

    last_error = ""
    async with httpx.AsyncClient(timeout=120.0) as client:
        for model_name in candidate_models:
            payload = {
                "model": model_name,
                "prompt": prompt,
                "n": 1,
                "size": "1024x1792",
            }
            res = await client.post(url, headers=headers, json=payload)
            if res.status_code == 200:
                data = res.json()
                b64_data = data["data"][0].get("b64_json")
                if not b64_data:
                    img_url = data["data"][0].get("url")
                    if img_url:
                        img_res = await client.get(img_url)
                        return img_res.content
                else:
                    return base64.b64decode(b64_data)
            
            error_msg = res.text[:300]
            last_error = f"HTTP {res.status_code}: {error_msg}"
            if "does not exist" not in error_msg:
                break
        
        raise RuntimeError(f"OpenAI Image API returned {last_error}")


async def _generate_gemini_image(prompt: str) -> bytes:
    """Generates an image via Google Gemini Image (Flash Image / Imagen) API using GEMINI_API_KEY."""
    gemini_key = _get_gemini_key()
    if not gemini_key:
        raise ValueError("GEMINI_API_KEY is not configured in backend/.env")

    candidate_models = [
        "gemini-2.5-flash-image",
        "gemini-3.1-flash-image",
        "gemini-3-pro-image",
    ]

    last_error = ""
    async with httpx.AsyncClient(timeout=120.0) as client:
        for model in candidate_models:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={gemini_key}"
            payload = {
                "contents": [
                    {
                        "parts": [
                            {"text": prompt}
                        ]
                    }
                ],
                "generationConfig": {
                    "responseModalities": ["TEXT", "IMAGE"],
                },
            }
            res = await client.post(url, json=payload)
            if res.status_code == 200:
                data = res.json()
                candidates = data.get("candidates", [])
                if candidates:
                    parts = candidates[0].get("content", {}).get("parts", [])
                    for part in parts:
                        if "inlineData" in part and part["inlineData"].get("data"):
                            return base64.b64decode(part["inlineData"]["data"])
                raise RuntimeError(f"No inline image data in response from {model}: {str(data)[:200]}")

            last_error = f"{model} returned HTTP {res.status_code}: {res.text[:300]}"
            if "limit: 0" in res.text or "RESOURCE_EXHAUSTED" in res.text:
                break

        # Fallback: legacy Imagen 3 predict endpoint
        url = f"https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key={gemini_key}"
        headers = {"Content-Type": "application/json"}
        payload = {
            "instances": [{"prompt": prompt}],
            "parameters": {
                "sampleCount": 1,
                "aspectRatio": "9:16",
                "outputMimeType": "image/jpeg",
            },
        }
        res = await client.post(url, headers=headers, json=payload)
        if res.status_code == 200:
            data = res.json()
            predictions = data.get("predictions", [])
            if predictions and predictions[0].get("bytesBase64Encoded"):
                return base64.b64decode(predictions[0]["bytesBase64Encoded"])

        raise RuntimeError(f"Google Image API failed. Last error: {last_error}")


async def _generate_cloudflare_flux(prompt: str) -> bytes:
    """Generates an image via Cloudflare Workers AI FLUX.1 Schnell API (100% Free, 10,000 neurons/day)."""
    token = _get_cf_token()
    account_id = _get_cf_account_id()
    if not token:
        raise ValueError("CLOUDFLARE_API_TOKEN is not configured in backend/.env")
    if not account_id:
        raise ValueError("CLOUDFLARE_ACCOUNT_ID or R2_ACCOUNT_ID is not configured in backend/.env")

    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/run/@cf/black-forest-labs/flux-1-schnell"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    payload = {
        "prompt": prompt,
        "steps": 4,
    }

    async with httpx.AsyncClient(timeout=120.0) as client:
        res = await client.post(url, headers=headers, json=payload)
        if res.status_code != 200:
            error_msg = res.text[:300]
            raise RuntimeError(f"Cloudflare Workers AI returned HTTP {res.status_code}: {error_msg}")
        data = res.json()
        if not data.get("success"):
            raise RuntimeError(f"Cloudflare Workers AI error: {data.get('errors')}")
        img_b64 = data.get("result", {}).get("image")
        if not img_b64:
            raise RuntimeError(f"No image returned from Cloudflare Workers AI: {str(data)[:200]}")
        return base64.b64decode(img_b64)


async def generate_single_greeting_image(
    prompt: str,
    theme: Optional[Dict[str, str]] = None,
    lang: str = "en",
) -> bytes:
    """Generates an image using Cloudflare FLUX, Google Gemini Image, or OpenAI with automatic fallback.
    When using Cloudflare FLUX, automatically composites 100% accurate HarfBuzz typography on top."""
    primary = _get_provider()
    gemini_key = _get_gemini_key()
    openai_key = _get_openai_key()
    cf_token = _get_cf_token()
    cf_account = _get_cf_account_id()

    raw_bytes: Optional[bytes] = None
    used_provider = primary

    if primary == "cloudflare":
        try:
            raw_bytes = await _generate_cloudflare_flux(prompt)
        except Exception as e:
            logger.warning(f"Cloudflare Workers AI FLUX failed: {e}. Attempting fallback to Gemini / OpenAI...")
            if gemini_key:
                try:
                    raw_bytes = await _generate_gemini_image(prompt)
                    used_provider = "gemini"
                except Exception:
                    pass
            if not raw_bytes and openai_key:
                raw_bytes = await _generate_openai_dalle3(prompt)
                used_provider = "openai"
            if not raw_bytes:
                raise
    elif primary == "gemini":
        try:
            raw_bytes = await _generate_gemini_image(prompt)
        except Exception as e:
            logger.warning(f"Google Gemini Image failed: {e}. Attempting fallback to Cloudflare FLUX...")
            if cf_token and cf_account:
                raw_bytes = await _generate_cloudflare_flux(prompt)
                used_provider = "cloudflare"
            elif openai_key:
                raw_bytes = await _generate_openai_dalle3(prompt)
                used_provider = "openai"
            else:
                raise
    else:
        try:
            raw_bytes = await _generate_openai_dalle3(prompt)
        except Exception as e:
            logger.warning(f"OpenAI failed: {e}. Attempting fallback to Cloudflare FLUX...")
            if cf_token and cf_account:
                raw_bytes = await _generate_cloudflare_flux(prompt)
                used_provider = "cloudflare"
            elif gemini_key:
                raw_bytes = await _generate_gemini_image(prompt)
                used_provider = "gemini"
            else:
                raise

    # If the image was generated by Cloudflare (or if clean background was used),
    # overlay authentic, perfectly shaped HarfBuzz calligraphy onto the image.
    if used_provider == "cloudflare" and theme and theme.get("heading"):
        layout_style = theme.get("layout_style", "bottom_gradient")
        raw_bytes = compose_greeting_typography(
            raw_bytes,
            theme["heading"],
            theme.get("quote", ""),
            layout_style=layout_style,
        )

    return raw_bytes


# ── Database Ingestion Helper ─────────────────────────────────────────────────

async def _save_greeting_to_db(raw_bytes: bytes, lang: str, category_slug: str = "morning") -> int:
    """Processes raw image bytes into 1080w HD JPEG and 480w WebP thumbnail,
    and inserts a record into greeting_images table."""
    stored = await asyncio.to_thread(_process_upload, raw_bytes)

    async with aiosqlite.connect(DB_PATH) as db:
        async with db.execute("SELECT id FROM greeting_categories WHERE slug = ?", (category_slug,)) as cur:
            row = await cur.fetchone()
        if not row:
            raise ValueError(f"Category '{category_slug}' does not exist in greeting_categories table")
        category_id = row[0]

        cur = await db.execute(
            """INSERT INTO greeting_images
               (category_id, thumb_file, hd_file, width, height, lang, premium, active, sort_order, created_at)
               VALUES (?, ?, ?, ?, ?, ?, 0, 1, 0, ?)""",
            (
                category_id,
                stored["thumb_file"],
                stored["hd_file"],
                stored["width"],
                stored["height"],
                lang,
                utc_now_iso(),
            ),
        )
        await db.commit()
        return cur.lastrowid


# ── Batch Generation Pipeline ─────────────────────────────────────────────────

async def run_daily_morning_greetings_pipeline(
    languages: Optional[List[str]] = None,
    images_per_lang: int = 8,
    is_manual_trigger: bool = False,
) -> Dict[str, Any]:
    """Generates Good Morning greeting cards for each language and stores them on the server.
    Target: 24 total images (8 per language: 5 with quote, 3 title-only without quote).
    Ensures zero duplicate themes in the batch and paces calls to stay well within Cloudflare free limits.
    """
    if _generator_lock.locked():
        msg = "Greeting generation job is already running; skipping concurrent trigger."
        logger.info(msg)
        return {"status": "skipped", "message": msg}

    languages = languages or ["hi", "mr", "en"]
    total_target = len(languages) * images_per_lang

    async with _generator_lock:
        run_id = await start_job_run("morning_greetings_generation")
        _last_job_status["running"] = True
        _last_job_status["last_run"] = utc_now_iso()
        _last_job_status["errors"] = []

        logger.info(
            f"🌅 Starting Automated Morning Greetings Pipeline: {images_per_lang} images each for {languages} (Total: {total_target} images: {len(languages) * 5} with quotes, {len(languages) * 3} title-only)"
        )

        success_count = 0
        failed_count = 0
        details: List[str] = []

        theme_banks = {
            "hi": list(THEME_ARCHETYPES_HI),
            "mr": list(THEME_ARCHETYPES_MR),
            "en": list(THEME_ARCHETYPES_EN),
        }

        # Shuffle each theme bank so every day's order is different
        for l in theme_banks:
            random.shuffle(theme_banks[l])

        idx = 0
        for lang in languages:
            themes = theme_banks.get(lang, THEME_ARCHETYPES_EN)

            for i in range(images_per_lang):
                idx += 1
                theme = dict(themes[i % len(themes)])
                theme_name = theme.get("theme", f"Theme #{i+1}")
                layout_style = theme.get("layout_style", "bottom_gradient")

                # The last 3 images in each language are title-only (no quote, only heading)
                is_title_only = (i >= (images_per_lang - 3))
                if is_title_only:
                    theme["quote"] = ""
                    card_mode = "Title-Only"
                else:
                    card_mode = "Quote"

                progress_msg = f"[{idx}/{total_target}] Generating {lang.upper()} ({theme_name} [{layout_style}] [{card_mode}])..."
                _last_job_status["current_progress"] = progress_msg
                logger.info(progress_msg)
                await update_job_run_detail(run_id, progress_msg)

                prompt = build_image_prompt(theme, lang)

                try:
                    # Generate with primary or fallback AI engine
                    raw_bytes = await generate_single_greeting_image(prompt, theme=theme, lang=lang)

                    # Store and process
                    img_id = await _save_greeting_to_db(raw_bytes, lang=lang, category_slug="morning")
                    success_count += 1
                    details.append(f"✓ {lang} #{img_id}: {theme_name}")
                    logger.info(f"✅ Saved {lang.upper()} image #{img_id} to database.")

                except Exception as e:
                    failed_count += 1
                    err_entry = f"✗ Error generating {lang} ({theme_name}): {str(e)}"
                    logger.error(err_entry)
                    _last_job_status["errors"].append(err_entry)
                    details.append(err_entry)

                # Pace calls (sleep 3-5s between calls to prevent 429 rate limit triggers)
                if idx < total_target:
                    await asyncio.sleep(4)

        summary_msg = f"Completed: {success_count} generated, {failed_count} failed out of {total_target}."
        _last_job_status["running"] = False
        _last_job_status["current_progress"] = summary_msg
        _last_job_status["total_generated"] += success_count
        if success_count > 0:
            _last_job_status["last_success"] = utc_now_iso()

        job_status = "success" if failed_count == 0 else ("partial" if success_count > 0 else "failed")
        await finish_job_run(run_id, job_status, summary_msg)
        await log_admin_action(
            "morning_greetings_auto_generated",
            f"Trigger: {'manual' if is_manual_trigger else 'cron_midnight'}, Success: {success_count}/{total_target}",
        )

        logger.info(f"🏁 Morning Greetings Pipeline Finished: {summary_msg}")
        return {
            "status": job_status,
            "success": success_count,
            "failed": failed_count,
            "total": total_target,
            "details": details,
        }
