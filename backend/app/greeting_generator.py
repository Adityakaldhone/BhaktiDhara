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

logger = logging.getLogger("bhaktidhara.greeting_gen")

IMAGE_AI_PROVIDER = os.getenv("IMAGE_AI_PROVIDER", "openai").strip().lower()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip().strip('"').strip("'")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip().strip('"').strip("'")

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
        "provider": IMAGE_AI_PROVIDER,
        "openai_configured": bool(OPENAI_API_KEY),
        "gemini_configured": bool(GEMINI_API_KEY),
    }


# ── Curated Scene & Quote Archetypes for High Diversity ──────────────────────

THEME_ARCHETYPES_HI: List[Dict[str, str]] = [
    {
        "deity": "Shri Swami Samarth",
        "theme": "Sacred River Ghat at Sunrise with Glowing Diya",
        "scene": "Divine presence of revered Shri Swami Samarth of Akkalkot with radiant golden aura. Foreground features ancient stone temple steps by a tranquil sacred river, with a glowing brass diya lamp surrounded by fresh fragrant pink rose and white jasmine petals, a traditional brass lota, and a carved stone temple pillar with hanging brass bell. Morning golden sunbeams reflect on the rippling river water.",
        "badge": "Subtle divine aura and sun rays",
        "heading": "सुप्रभात",
        "quote": "हर सुबह एक नई शुरुआत है, ईश्वर की असीम कृपा से हर दिन कुछ शुभ और मंगलकारी जरूर होता है।",
    },
    {
        "deity": "None (Zen Nature)",
        "theme": "Zen Bamboo Water Fountain & Fresh Champa Flowers",
        "scene": "A natural cut bamboo water spout pouring pure crystal-clear morning water over smooth black river pebbles into a stone basin with gentle water ripples. Floating white and yellow frangipani (champa) flowers, lush emerald green bamboo stalks with sparkling morning dewdrops, soft warm golden morning bokeh lighting.",
        "badge": "Translucent circular frosted glass badge with thin gold rim and small leaf motif",
        "heading": "सुप्रभात",
        "quote": "मन में सकारात्मक विचार, व्यवहार में मिठास, और हर परिस्थिति में धैर्य यही एक खुशहाल जीवन की पहचान है।",
    },
    {
        "deity": "Mahadev Shiva",
        "theme": "Himalayan Sunrise at Kedarnath Dawn",
        "scene": "Graceful benevolent silhouette of Lord Shiva in calm dhyana meditation, snow-capped Himalayan peaks catching first pink and golden rays of dawn, pure flowing Ganga, sacred trishul with damru, fragrant blue incense smoke curls, fresh bilva leaves.",
        "badge": "Sacred trishul and crescent moon emblem",
        "heading": "सुप्रभात",
        "quote": "महादेव की कृपा आप पर सदा बनी रहे। आपका आज का दिन सुख, शांति और सकारात्मक ऊर्जा से परिपूर्ण हो।",
    },
    {
        "deity": "None (Cozy Morning)",
        "theme": "Steaming Earthen Kulhad Chai by Sunlit Window",
        "scene": "A steaming terracotta clay kulhad of authentic Indian spiced tea with cinnamon and cardamom on a rustic dark teak wood table by an open window. Window reveals blooming morning garden bathed in golden sunlight. Brass coaster, fresh orange marigold blossoms, and a string of white mogra flowers beside the cup.",
        "badge": "Warm terracotta ornamental arch",
        "heading": "सुप्रभात",
        "quote": "एक प्यारी सी मुस्कान और एक कप चाय के साथ, आपका दिन ताजगी, उमंग और नई ऊर्जा से भरा रहे।",
    },
    {
        "deity": "Lord Ganesha",
        "theme": "Auspicious Temple Mandap with Modak & Hibiscus",
        "scene": "Gleaming golden murti of Lord Ganesha in an intricately carved ancient stone temple mandap. Glowing brass samai oil lamps, fresh vibrant red hibiscus flowers, sweet modak offerings, yellow marigold garlands, warm golden sunlight streaming through ornate stone lattice jali.",
        "badge": "Golden modak and lotus motif",
        "heading": "सुप्रभात",
        "quote": "विघ्नहर्ता श्री गणेश आपके जीवन के सभी विघ्न दूर करें और आपके हर प्रयास को सफलता से भर दें।",
    },
    {
        "deity": "None (Misty Mountain)",
        "theme": "Misty Alpine Valley Sunrise with Dewy Meadow",
        "scene": "Breathtaking panoramic mountain valley filled with soft morning fog, radiant golden sun breaking over rolling peaks, foreground meadow covered with wild chamomile and lavender flowers glistening with diamond dewdrops, birds gliding across amber pastel sky.",
        "badge": "Minimalist gold-framed rectangular card",
        "heading": "सुप्रभात",
        "quote": "सुबह की नई किरणें आपके जीवन में नई उम्मीदें, नया आत्मविश्वास और ढेर सारी खुशियां लेकर आएं।",
    },
    {
        "deity": "Shri Ram & Ayodhya",
        "theme": "Sacred Saryu River Ghat with Morning Aarti",
        "scene": "Grand temple silhouette of Ayodhya at sunrise on the banks of holy Saryu river. Floating floral clay diyas with steady warm flames, marigold garlands on carved stone steps, divine golden glow spreading across misty dawn horizon.",
        "badge": "Royal bow and lotus emblem",
        "heading": "सुप्रभात",
        "quote": "मर्यादा पुरुषोत्तम प्रभु श्री राम की कृपा से आपके घर-परिवार में सदा सुख, शांति और धर्म का वास रहे।",
    },
    {
        "deity": "None (Sacred Courtyard)",
        "theme": "Traditional Tulsi Vrindavan with Rangoli & Jal Arghya",
        "scene": "An authentic terracotta Tulsi Vrindavan in a traditional red-brick courtyard. Crisp hand-drawn white and yellow rangoli, a polished brass lota offering jal arghya, a glowing clay diya lamp at the base of the sacred holy basil plant, warm morning sunbeams casting long shadows.",
        "badge": "Auspicious swastik and tulsi leaf design",
        "heading": "सुप्रभात",
        "quote": "तुलसी महारानी और प्रभु नारायण की कृपा से आपके घर में सदैव सुख, शांति और आरोग्य का वास हो।",
    },
    {
        "deity": "Lord Krishna",
        "theme": "Yamuna Riverbank with Flute & Lotus",
        "scene": "Enchanting silhouette of Shri Krishna playing divine bansuri under a flowering kadamba tree by serene Yamuna river. Peacock feather in his crown catching dawn rays, sacred white calf resting nearby, pink lotus flowers blooming on morning water.",
        "badge": "Peacock feather and bansuri flourish",
        "heading": "सुप्रभात",
        "quote": "राधे कृष्णा! आपका हर क्षण प्रेम, आनंद और आत्मिक शांति से महकता रहे। आपका दिन मंगलमय हो।",
    },
    {
        "deity": "None (Artisan Coffee)",
        "theme": "Glazed Ceramic Coffee Mug on Balcony Overlooking Forest",
        "scene": "An artisanal handcrafted turquoise ceramic coffee cup with latte art on a natural live-edge wood balcony railing. Panoramic view of misty pine forest with dramatic golden sunbeams piercing through tall trees, an open journal and fountain pen beside the mug.",
        "badge": "Contemporary minimalist warm wood card",
        "heading": "सुप्रभात",
        "quote": "आज का दिन एक नया अवसर है, अपने सपनों को पंख दें और हर पल को खुशी व कृतज्ञता से जिएं।",
    },
]

THEME_ARCHETYPES_MR: List[Dict[str, str]] = [
    {
        "deity": "Shri Vitthal-Rukmini",
        "theme": "Pandharpur Chandrabhaga Dawn with Warkari Bhakti",
        "scene": "Divine celestial darshan of Lord Vitthal and Rakhumai with fragrant tulsi haar and chandan tilak. Sacred Chandrabhaga riverbank at sunrise, warkari devotees in distance, golden morning glow on the temple kalash, holy tulsi leaves and brass samai lamp.",
        "badge": "वारकरी पताका व तुळशीपत्र सुशोभन",
        "heading": "शुभ सकाळ",
        "quote": "विठू माऊलींची कृपा आपल्या संपूर्ण कुटुंबावर सदैव राहो. आपला आजचा दिवस अतिशय आनंदात आणि समाधानात जावो!",
    },
    {
        "deity": "Shri Swami Samarth",
        "theme": "Akkalkot Vatavriksha with Divine Oil Lamp",
        "scene": "Graceful darshan of Akkalkot Niwasi Shri Swami Samarth Maharaj under the sacred banyan tree. Earthen diya emitting warm divine light, fresh dhoop incense smoke, sacred bel patra, golden morning sunrays filtering through dense banyan leaves.",
        "badge": "स्वामी पादुका व सुवर्ण किनार",
        "heading": "शुभ सकाळ",
        "quote": "'भिऊ नकोस मी तुझ्या पाठीशी आहे!' स्वामींच्या कृपाशीर्वादाने आज तुमचे सर्व कार्य निर्विघ्नपणे पार पडो.",
    },
    {
        "deity": "None (Zen Water & Sonchafa)",
        "theme": "Tiered Stone Waterfall with Sonchafa Flowers",
        "scene": "Natural slate stone mini-waterfall surrounded by lush wild ferns and wet black stones. Fresh fragrant yellow Sonchafa (champak) and white Bakul flowers resting on wet pebbles, glistening morning dewdrops on monstera leaves, peaceful sunlight glow.",
        "badge": "पारदर्शक गोलाकार काचेची फ्रेम व सुवर्ण वेलबुट्टी",
        "heading": "शुभ सकाळ",
        "quote": "मन शांत, विचार शुद्ध आणि चेहऱ्यावर गोड हास्य... हीच एका सुंदर आणि यशस्वी दिवसाची सुरुवात असते.",
    },
    {
        "deity": "None (Maharashtrian Wada)",
        "theme": "Traditional Wada Courtyard with Rangoli & Tulsi",
        "scene": "Historic Maharashtrian Wada with carved teakwood pillars, brass hanging bell, authentic Tulsi Vrindavan in stone courtyard decorated with traditional Chaitra rangoli, copper lota, golden morning sunlight illuminating the verandah.",
        "badge": "पारंपरिक मराठमोळी सुवर्ण किनार",
        "heading": "शुभ सकाळ",
        "quote": "सकाळच्या प्रसन्न वातावरणात आपले मन सकारात्मक विचारांनी बहरून जावो. सुंदर दिवसाच्या मनःपूर्वक शुभेच्छा!",
    },
    {
        "deity": "Lord Shiva (Trimbakeshwar)",
        "theme": "Ancient Trimbakeshwar Mandir at Dawn",
        "scene": "Ancient Jyotirlinga shrine surrounded by white datura flowers, bilva patra, silver trishul, holy bhasma, drops of holy jal dripping from brass jaladhari, morning mist drifting through grand ancient temple corridors.",
        "badge": "त्रिशूळ व बिल्वपत्र सुशोभन",
        "heading": "शुभ सकाळ",
        "quote": "हर हर महादेव! देवाधिदेव शंकरांच्या कृपेने आपल्या आयुष्यातील सर्व संकट दूर होऊन सुखाचे दिवस येवोत.",
    },
    {
        "deity": "None (Village Morning Tea)",
        "theme": "Traditional Foaming Gawrani Tea in Brass Cup",
        "scene": "Traditional authentic brass davara-tumbler of steaming hot ginger cardamom milk tea resting on a wooden bench. Fresh yellow Shevanti (chrysanthemum) flowers, morning Marathi pothi book, beautiful golden sunrise over coconut trees.",
        "badge": "उबदार चॉकलेटी व केशरी पार्श्वभूमी",
        "heading": "शुभ सकाळ",
        "quote": "सकाळचा गोड चहा आणि आपल्या माणसांचे प्रेमळ विचार, आयुष्याला एक वेगळाच गोडवा आणि उत्साह देतात!",
    },
    {
        "deity": "Lord Ganesha (Ashtavinayak)",
        "theme": "Ashtavinayak Ganpati with Durva & Jaswand",
        "scene": "Glorious Ashtavinayak style Ganpati murti adorned with orange sindoor, fresh green durva grass sprouts, bright red hibiscus (jaswand) flowers, brass aarti thali with burning camphor, golden dawn lighting.",
        "badge": "दुर्वा व मोदक सुवर्ण प्रतीक",
        "heading": "शुभ सकाळ",
        "quote": "श्री गणरायाच्या कृपेने आजचा दिवस तुमच्यासाठी सुख, भरभराट, समृद्धी आणि नवी संधी घेऊन येवो.",
    },
    {
        "deity": "None (Sahyadri Mountain)",
        "theme": "Misty Sahyadri Mountain Ridge Sunrise",
        "scene": "Magnificent sunrise over rugged green Sahyadri mountain cliffs of Maharashtra, floating sea of clouds in valley below, golden sunlight breaking over hilltops, wild yellow Sonki flowers swaying in morning breeze.",
        "badge": "आधुनिक सोन्याच्या नक्षीची फ्रेम",
        "heading": "शुभ सकाळ",
        "quote": "प्रत्येक नवी सकाळ जीवनात एक नवीन उमेद घेऊन येते, स्वप्नांना कष्टांची जोड द्या आणि ध्येय गाठा!",
    },
    {
        "deity": "Maa Renuka / Durga",
        "theme": "Mahur Gad Temple at Golden Dawn",
        "scene": "Divine temple sanctum of Goddess Renuka at sunrise. Glowing brass lamps, yellow turmeric (bhandara), red kumkum, fragrant mogra flower garlands, golden dawn rays spreading divine light over the temple hilltop.",
        "badge": "कमळ व कुंकुम मंगल कलश",
        "heading": "शुभ सकाळ",
        "quote": "आई जगदंबेच्या आशीर्वादाने तुमचे घर सदैव सुख-शांती, समाधान आणि वैभवाने भरलेले राहो.",
    },
    {
        "deity": "None (Porch Garden Coffee)",
        "theme": "Ceramic Mug on Garden Porch with Pink Bougainvillea",
        "scene": "A warm pastel ceramic mug of morning coffee resting on an outdoor wooden table with an inspiring book. Vibrant cascading pink bougainvillea flowers against stone wall, warm morning sunbeams, morning sparrows chirping.",
        "badge": "कलात्मक निसर्गप्रेमी डिझाइन",
        "heading": "शुभ सकाळ",
        "quote": "आयुष्य खूप सुंदर आहे, फक्त प्रत्येक नवीन दिवसाची सुरुवात एका गोड हसऱ्या चेहऱ्याने आणि समाधानाने करा!",
    },
]

THEME_ARCHETYPES_EN: List[Dict[str, str]] = [
    {
        "deity": "Sacred Temple / Divine Light",
        "theme": "Sacred Temple Steps with Floating Diyas & Jasmine",
        "scene": "An ancient stone temple courtyard at dawn with ornate carved pillars. Polished brass bells hanging from arches, a glowing brass diya on stone steps surrounded by fresh white jasmine petals, serene river reflecting the golden morning sky.",
        "badge": "Ornate royal gold floral arch",
        "heading": "Good Morning",
        "quote": "May divine light illuminate your path, fill your heart with peace, and bless your day with endless joy and abundance.",
    },
    {
        "deity": "None (Zen Water Garden)",
        "theme": "Minimalist Zen Bamboo Spout with Frangipani",
        "scene": "A tranquil Zen rock garden with a cut bamboo water spout trickling crystal water into a dark basalt basin. Smooth river pebbles, floating white and yellow frangipani blossoms, emerald green bamboo stalks with dewdrops, soft warm morning bokeh.",
        "badge": "Translucent circular frosted glass badge with delicate gold rim",
        "heading": "Good Morning",
        "quote": "Peace begins from within. Start today with a calm mind, a grateful heart, and pure positive energy.",
    },
    {
        "deity": "None (Alpine Sunrise)",
        "theme": "Pine Forest Mountain Valley with Golden Sunbeams",
        "scene": "Panoramic alpine mountain valley at dawn with golden sunbeams piercing through majestic pine trees, morning mist rising over lush meadows, wild purple wildflowers glistening with dewdrops, birds soaring across pastel sky.",
        "badge": "Clean modern gold-bordered card",
        "heading": "Good Morning",
        "quote": "Every sunrise is a fresh reminder that life is full of new beginnings, endless hope, and infinite possibilities.",
    },
    {
        "deity": "None (Artisan Coffee & Books)",
        "theme": "Glazed Ceramic Latte Mug beside Sunlit Window",
        "scene": "An artisanal handcrafted ceramic mug with steaming creamy latte art on an aged oak table next to a large sunlit window with sheer curtains. Fresh pink peonies in a glass vase and an open hardbound journal beside the mug.",
        "badge": "Warm minimalist contemporary card",
        "heading": "Good Morning",
        "quote": "Take a deep breath, smile, and embrace today with warmth, kindness, and gratitude for all the little blessings.",
    },
    {
        "deity": "Divine Lotus & River",
        "theme": "Sacred Lotus Pond with Floating Diya at Dawn",
        "scene": "Pristine pink and white sacred lotus flowers in full bloom upon calm mirror-like pond water. A small brass lamp floating with steady warm flame, golden dawn sky reflected in water ripples, soft morning mist.",
        "badge": "Sacred lotus and gold filigree border",
        "heading": "Good Morning",
        "quote": "Like a lotus blooming in water, rise above every challenge with grace, dignity, and unwavering confidence.",
    },
    {
        "deity": "None (Rustic Porch Tea)",
        "theme": "Cedar Porch with Herbal Tea & Wildflower Meadow",
        "scene": "A clear glass cup of golden herbal tea with lemon and honey on a weathered cedar wood porch railing. Overlooking a sun-drenched wildflower meadow filled with buttercups and daisies, soft morning sunbeams.",
        "badge": "Rustic natural wood grain banner",
        "heading": "Good Morning",
        "quote": "Today is a blank canvas. Paint it with bright smiles, meaningful moments, and generous acts of love.",
    },
    {
        "deity": "Ocean Serenity",
        "theme": "Tranquil Coastal Horizon at Sunrise",
        "scene": "Calm coastal sunrise with gentle gentle waves lapping against smooth wet sand, pastel watercolor sky in blush pink and peach, silhouette of palm fronds in foreground catching warm golden light.",
        "badge": "Elegant coastal minimalist card",
        "heading": "Good Morning",
        "quote": "Let go of yesterday's worries and step forward into today with hope, enthusiasm, and a peaceful soul.",
    },
    {
        "deity": "Traditional Indian Pooja",
        "theme": "Carved Brass Thali with Incense & Marigold Garlands",
        "scene": "An ornate brass pooja thali holding fresh yellow marigolds, red kumkum, sandalwood paste, and fragrant burning incense sticks with soft curling smoke, golden morning sunrays streaming through temple stone arch.",
        "badge": "Luminous temple gold ornament",
        "heading": "Good Morning",
        "quote": "Start your day with prayer, humility, and positive purpose. You are divinely protected and blessed always.",
    },
    {
        "deity": "None (Lush Greenery)",
        "theme": "Sunlit Botanical Greenhouse with Dewy Monstera Leaves",
        "scene": "A lush tropical botanical sanctuary with large green monstera and palm leaves, crystal water droplets magnified in golden morning sunbeams, blooming white orchids, soft dreamy morning light.",
        "badge": "Fresh botanical gold-embossed badge",
        "heading": "Good Morning",
        "quote": "Grow with courage, shine with positivity, and let your kindness make a difference in someone's day.",
    },
    {
        "deity": "None (Cozy Morning Comfort)",
        "theme": "Stoneware Tea Mug with Knitted Blanket by Sunrise Balcony",
        "scene": "A warm textured stoneware mug of tea on a rustic wooden balcony table with a cozy cream knitted throw, open view of rolling sunrise hills with golden light flooding across the horizon.",
        "badge": "Cozy handcrafted gold-trimmed vignette",
        "heading": "Good Morning",
        "quote": "A grateful heart is a magnet for miracles. Wishing you a peaceful, joyful, and deeply blessed morning.",
    },
]


def build_image_prompt(theme: Dict[str, str], lang: str) -> str:
    """Constructs an ultra-high-detail prompt tailored for portrait 9:16 vertical greeting cards.
    Specifically requests legible calligraphy and matching text layout."""
    heading = theme["heading"]
    quote = theme["quote"]
    scene = theme["scene"]
    badge = theme["badge"]

    return (
        f"A magnificent vertical 9:16 mobile wallpaper greeting card. "
        f"Photorealistic 8k quality, cinematic morning lighting with warm golden sun rays and soft bokeh. "
        f"{scene} "
        f"In the center or upper-middle section, placed tastefully on a {badge}, "
        f"is large, elegant, stylized calligraphy text clearly displaying the heading '{heading}'. "
        f"Directly below the heading '{heading}', in clean, legible, beautifully spaced typography, "
        f"the following inspirational quote is displayed: '{quote}'. "
        f"Ornate decorative flourishes, sacred golden aura, hyper-detailed textures, perfectly balanced composition, "
        f"captivating visual aesthetic, vertical mobile aspect ratio (9:16)."
    )


# ── AI Generation Backends ────────────────────────────────────────────────────

async def _generate_openai_dalle3(prompt: str) -> bytes:
    """Generates an image via OpenAI DALL-E 3 API."""
    if not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY is not configured in backend/.env")

    url = "https://api.openai.com/v1/images/generations"
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
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
            # If error is model not found, try next candidate model
            if "does not exist" not in error_msg:
                break
        
        raise RuntimeError(f"OpenAI Image API returned {last_error}")


async def _generate_gemini_imagen3(prompt: str) -> bytes:
    """Generates an image via Google Imagen 3 API using GEMINI_API_KEY."""
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY is not configured in backend/.env")

    # REST endpoint for Imagen 3 on Google Generative AI
    url = f"https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key={GEMINI_API_KEY}"
    headers = {"Content-Type": "application/json"}
    payload = {
        "instances": [{"prompt": prompt}],
        "parameters": {
            "sampleCount": 1,
            "aspectRatio": "9:16",
            "outputMimeType": "image/jpeg",
        },
    }

    async with httpx.AsyncClient(timeout=120.0) as client:
        res = await client.post(url, headers=headers, json=payload)
        if res.status_code != 200:
            error_msg = res.text[:300]
            raise RuntimeError(f"Google Imagen 3 returned HTTP {res.status_code}: {error_msg}")
        data = res.json()
        predictions = data.get("predictions", [])
        if not predictions or not predictions[0].get("bytesBase64Encoded"):
            raise RuntimeError(f"Unexpected response structure from Imagen 3: {str(data)[:200]}")
        return base64.b64decode(predictions[0]["bytesBase64Encoded"])


async def generate_single_greeting_image(prompt: str) -> bytes:
    """Generates an image using OpenAI DALL-E 3 or Google Imagen 3 with automatic fallback."""
    primary = IMAGE_AI_PROVIDER
    if primary == "openai":
        try:
            return await _generate_openai_dalle3(prompt)
        except Exception as e:
            logger.warning(f"OpenAI DALL-E 3 failed: {e}. Attempting fallback to Google Imagen 3...")
            if GEMINI_API_KEY:
                return await _generate_gemini_imagen3(prompt)
            raise
    else:
        try:
            return await _generate_gemini_imagen3(prompt)
        except Exception as e:
            logger.warning(f"Google Imagen 3 failed: {e}. Attempting fallback to OpenAI DALL-E 3...")
            if OPENAI_API_KEY:
                return await _generate_openai_dalle3(prompt)
            raise


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
    images_per_lang: int = 5,
    is_manual_trigger: bool = False,
) -> Dict[str, Any]:
    """Generates Good Morning greeting cards for each language and stores them on the server.
    Ensures zero duplicate themes in the batch.
    Paced to respect provider rate limits.
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
            f"🌅 Starting Automated Morning Greetings Pipeline: {images_per_lang} images each for {languages} (Total: {total_target})"
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
                theme = themes[i % len(themes)]
                theme_name = theme.get("theme", f"Theme #{i+1}")
                deity = theme.get("deity", "General")

                progress_msg = f"[{idx}/{total_target}] Generating {lang.upper()} ({deity}: {theme_name})..."
                _last_job_status["current_progress"] = progress_msg
                logger.info(progress_msg)
                await update_job_run_detail(run_id, progress_msg)

                prompt = build_image_prompt(theme, lang)

                try:
                    # Generate with primary or fallback AI engine
                    raw_bytes = await generate_single_greeting_image(prompt)

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
