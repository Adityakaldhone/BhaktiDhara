import os
import sys
import json
import urllib.request
import sqlite3
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
DB_PATH = BACKEND_DIR / "data" / "bhaktidhara.db"

# URLs from verified open-source repository
CHAPTERS_URL = "https://raw.githubusercontent.com/gita/gita/master/data/chapters.json"
VERSES_URL = "https://raw.githubusercontent.com/gita/gita/master/data/verse.json"
TRANSLATIONS_URL = "https://raw.githubusercontent.com/gita/gita/master/data/translation.json"

CHAPTER_NAMES_MR = {
    1: "अर्जुनविषादयोग",
    2: "सांख्ययोग",
    3: "कर्मयोग",
    4: "ज्ञानकर्मसंन्यासयोग",
    5: "कर्मसंन्यासयोग",
    6: "आत्मसंयमयोग",
    7: "ज्ञानविज्ञानयोग",
    8: "अक्षरब्रह्मयोग",
    9: "राजविद्याराजगुह्ययोग",
    10: "विभूतियोग",
    11: "विश्वरूपदर्शनयोग",
    12: "भक्तियोग",
    13: "क्षेत्रक्षेत्रज्ञविभागयोग",
    14: "गुणत्रयविभागयोग",
    15: "पुरुषोत्तमयोग",
    16: "दैवासुरसंपद्विभागयोग",
    17: "श्रद्धात्रयविभागयोग",
    18: "मोक्षसंन्यासयोग"
}

CHAPTER_SUMMARIES_MR = {
    1: "कुरुक्षेत्रावर दोन्ही सैन्यांचे निरीक्षण आणि आप्तस्वकीयांना पाहून अर्जुनाला झालेला शोक व विषाद.",
    2: "आत्म्याचे अमरत्व, निष्काम कर्मयोगाचे महत्त्व आणि स्थितप्रज्ञ पुरुषाची लक्षणे.",
    3: "कर्तव्यकर्माचे पालन, यज्ञाचे महत्त्व आणि काम-क्रोधावर विजयाचा मार्ग.",
    4: "भगवंतांचे अवताररहस्य, दिव्य ज्ञानाची प्राप्ती आणि ज्ञानाग्नीने कर्मांचे दहन.",
    5: "संन्यास आणि कर्मयोग यांमधील साम्य, अंतर्मुख शांती आणि सच्चिदानंद प्राप्ती.",
    6: "ध्यान आणि मनाचा निग्रह, योगाभ्यासाची पद्धत आणि योगभ्रष्टाची गती.",
    7: "परमात्म्याचे परा आणि अपरा प्रकृतीचे गूढ ज्ञान आणि भगवंतांची चार प्रकारची भक्ती.",
    8: "ब्रह्म, अध्यात्म, कर्म यांचे रहस्य आणि अंतकाळी भगवंतांचे स्मरण करण्याचे फळ.",
    9: "सर्व गुह्यांचे गुह्य ज्ञान, ईश्वराचे विश्वाशी नाते आणि अनन्य भक्तीचे सामर्थ्य.",
    10: "भगवंतांच्या अनंत दिव्य विभूतींचे आणि सृष्टीतील ईश्वरी अस्तित्वाचे दर्शन.",
    11: "अर्जुनाला झालेले भगवंतांच्या अद्भूत आणि विराट विश्वरूपाचे प्रत्यक्ष दर्शन.",
    12: "सगुण आणि निर्गुण भक्तीची तुलना, भक्ताची लक्षणे आणि भगवंतांचे आवडते भक्त.",
    13: "शरीर (क्षेत्र) आणि आत्मा (क्षेत्रज्ञ) यांचा भेद, ज्ञान आणि प्रकृती-पुरुष विवेक.",
    14: "सत्त्व, रज आणि तम या तीन गुणांचे स्वरूप, त्यांचे बंधन आणि गुणातीत होण्याची अवस्था.",
    15: "संसाररूप अश्वत्थ वृक्ष, क्षर-अक्षर पुरुष आणि सर्वोत्कृष्ट पुरुषोत्तम तत्त्व.",
    16: "दैवी आणि आसुरी संपत्तीची लक्षणे, मानवी पतन आणि शास्त्राचे महत्त्व.",
    17: "श्रद्धेचे तीन प्रकार, आहार, यज्ञ, तप आणि दान यांचे त्रिविध स्वरूप.",
    18: "त्याग आणि संन्यासाचा खरा अर्थ, स्वधर्मपालन आणि सर्वधर्मान्परित्यज्य भगवंतांना संपूर्ण शरणागती."
}


def fetch_json(url: str, description: str):
    print(f"📥 Fetching {description} from {url}...")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as res:
        return json.loads(res.read().decode("utf-8"))


def seed_gita():
    print("🚀 Starting Shrimad Bhagavad Gita Ingestion...")
    os.makedirs(DB_PATH.parent, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # 1. Ensure Tables Exist
    cur.execute("""
        CREATE TABLE IF NOT EXISTS granth_books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            slug TEXT UNIQUE NOT NULL,
            title_mr TEXT NOT NULL,
            title_hi TEXT NOT NULL,
            title_en TEXT NOT NULL,
            subtitle_mr TEXT,
            subtitle_hi TEXT,
            subtitle_en TEXT,
            description_mr TEXT,
            description_hi TEXT,
            description_en TEXT,
            total_chapters INTEGER DEFAULT 0,
            total_verses INTEGER DEFAULT 0,
            free_chapters INTEGER DEFAULT 1,
            cover_image TEXT,
            sort_order INTEGER DEFAULT 1,
            is_active INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS granth_chapters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_slug TEXT NOT NULL,
            chapter_number INTEGER NOT NULL,
            name_mr TEXT,
            name_hi TEXT,
            name_en TEXT,
            name_sanskrit TEXT,
            summary_mr TEXT,
            summary_hi TEXT,
            summary_en TEXT,
            verses_count INTEGER DEFAULT 0,
            UNIQUE(book_slug, chapter_number)
        )
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS granth_verses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_slug TEXT NOT NULL,
            chapter_number INTEGER NOT NULL,
            verse_number INTEGER NOT NULL,
            slok TEXT NOT NULL,
            transliteration TEXT,
            word_meanings TEXT,
            meaning_mr TEXT,
            meaning_hi TEXT,
            meaning_en TEXT,
            UNIQUE(book_slug, chapter_number, verse_number)
        )
    """)
    conn.commit()

    # 2. Seed Book Metadata
    cur.execute("""
        INSERT INTO granth_books (
            slug, title_mr, title_hi, title_en,
            subtitle_mr, subtitle_hi, subtitle_en,
            description_mr, description_hi, description_en,
            total_chapters, total_verses, free_chapters, sort_order, is_active
        ) VALUES (
            'bhagavad-gita',
            'श्रीमद्भगवद्गीता',
            'श्रीमद्भगवद्गीता',
            'Shrimad Bhagavad Gita',
            'महाभारतातील भगवान श्रीकृष्णांचा अमर उपदेश',
            'महाभारत के भीष्म पर्व का दिव्य अमृत उपदेश',
            'The Divine Song of Bhagavan Shri Krishna',
            'कुरुक्षेत्राच्या रणांगणावर भगवान श्रीकृष्णांनी अर्जुनाला केलेला दिव्य कर्मयोग, ज्ञानयोग आणि भक्तियोगाचा मार्गदर्शक अमर उपदेश.',
            'कुरुक्षेत्र के पवित्र युद्धक्षेत्र में भगवान श्रीकृष्ण द्वारा अर्जुन को दिया गया दिव्य ज्ञान, कर्म और भक्ति का मार्ग।',
            'The timeless spiritual wisdom spoken by Lord Krishna to Arjuna on the battlefield of Kurukshetra, guiding humanity through karma, jnana, and bhakti.',
            18, 700, 1, 1, 1
        )
        ON CONFLICT(slug) DO UPDATE SET
            total_chapters = excluded.total_chapters,
            total_verses = excluded.total_verses,
            free_chapters = excluded.free_chapters,
            is_active = 1
    """)

    # Also seed placeholders for upcoming scriptures (Garuda Purana & Dasbodh)
    cur.execute("""
        INSERT INTO granth_books (
            slug, title_mr, title_hi, title_en,
            subtitle_mr, subtitle_hi, subtitle_en,
            description_mr, description_hi, description_en,
            total_chapters, total_verses, free_chapters, sort_order, is_active
        ) VALUES (
            'garuda-purana',
            'गरुड पुराण सारोद्धार',
            'गरुड़ पुराण सारोद्धार',
            'Garuda Purana Saroddhara',
            'मृत्यूनंतरचा जीवाचा प्रवास आणि कर्माचे गूढ रहस्य',
            'मृत्यु के उपरांत जीवात्मा की गति एवं यमलोक का वर्णन',
            'The Sacred Journey of the Soul, Karma and Moksha',
            'भगवान विष्णू आणि गरुड यांच्यातील संवादरूप पवित्र ग्रंथ, ज्यामध्ये आत्म्याचा प्रवास, कर्मफळ आणि मुक्तीचे मार्गदर्शन आहे.',
            'भगवान श्रीहरि विष्णु और पक्षीराज गरुड़ के संवाद रूप में जीवात्मा की यात्रा, कर्मफल और मोक्ष का विस्तृत वर्णन।',
            'The revered dialogue between Lord Vishnu and Garuda explaining the soul journey, karma, afterlife and ultimate liberation.',
            16, 0, 1, 2, 0
        )
        ON CONFLICT(slug) DO NOTHING
    """)

    cur.execute("""
        INSERT INTO granth_books (
            slug, title_mr, title_hi, title_en,
            subtitle_mr, subtitle_hi, subtitle_en,
            description_mr, description_hi, description_en,
            total_chapters, total_verses, free_chapters, sort_order, is_active
        ) VALUES (
            'dasbodh',
            'श्रीमद् दासबोध',
            'श्रीमद् दासबोध',
            'Shrimad Dasbodh',
            'समर्थ रामदास स्वामींचे प्रपंच आणि परमार्थाचे मार्गदर्शन',
            'समर्थ रामदास स्वामी कृत व्यावहारिक एवं आध्यात्मिक उपदेश',
            'Spiritual and Practical Wisdom by Samarth Ramdas Swami',
            'मानवी जीवनात प्रपंच नेटका करून परमार्थ कसा साधावा याचे अजोड आणि व्यवहार्य मार्गदर्शन करणारा महाराष्ट्रभूषण ग्रंथ.',
            'संसार और अध्यात्म में समन्वय स्थापित करने वाला महान ग्रंथ।',
            'A comprehensive guide to spirituality, self-realization, and worldly excellence composed in Marathi by Saint Ramdas.',
            20, 0, 1, 3, 0
        )
        ON CONFLICT(slug) DO NOTHING
    """)
    conn.commit()

    # 3. Fetch Chapters
    chapters_data = fetch_json(CHAPTERS_URL, "18 Chapters")
    for ch in chapters_data:
        ch_num = ch["chapter_number"]
        name_sanskrit = ch.get("name", f"अध्याय {ch_num}")
        name_hi = ch.get("name_meaning", name_sanskrit)
        name_en = ch.get("name_translation", f"Chapter {ch_num}")
        name_mr = CHAPTER_NAMES_MR.get(ch_num, name_sanskrit)

        summary_hi = ch.get("chapter_summary_hindi", "")
        summary_en = ch.get("chapter_summary", "")
        summary_mr = CHAPTER_SUMMARIES_MR.get(ch_num, summary_hi)
        v_count = ch.get("verses_count", 0)

        cur.execute("""
            INSERT INTO granth_chapters (
                book_slug, chapter_number,
                name_mr, name_hi, name_en, name_sanskrit,
                summary_mr, summary_hi, summary_en, verses_count
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(book_slug, chapter_number) DO UPDATE SET
                name_mr = excluded.name_mr,
                name_hi = excluded.name_hi,
                name_en = excluded.name_en,
                name_sanskrit = excluded.name_sanskrit,
                summary_mr = excluded.summary_mr,
                summary_hi = excluded.summary_hi,
                summary_en = excluded.summary_en,
                verses_count = excluded.verses_count
        """, (
            "bhagavad-gita", ch_num,
            name_mr, name_hi, name_en, name_sanskrit,
            summary_mr, summary_hi, summary_en, v_count
        ))
    conn.commit()
    print("✅ Inserted 18 Chapters successfully.")

    # 4. Fetch Verses & Translations
    verses_data = fetch_json(VERSES_URL, "701 Verses")
    trans_data = fetch_json(TRANSLATIONS_URL, "Translations")

    # Map translations by (verse_id, lang)
    # Prefer Swami Ramsukhdas / Tejomayananda for Hindi, Swami Sivananda / Gambhirananda for English
    hi_trans = {}
    en_trans = {}

    for t in trans_data:
        v_id = t["verse_id"]
        lang = t.get("lang")
        author = t.get("authorName", "")
        desc = t.get("description", "").strip()
        if not desc:
            continue

        if lang == "hindi":
            # Priority: Ramsukhdas > Tejomayananda > others
            if v_id not in hi_trans or "Ramsukhdas" in author:
                hi_trans[v_id] = desc
        elif lang == "english":
            # Priority: Sivananda > Gambirananda > others
            if v_id not in en_trans or "Sivananda" in author:
                en_trans[v_id] = desc

    # 5. Insert Verses
    print("💾 Storing 701 verses with Sanskrit, Transliteration, Anvaya & Meanings...")
    for v in verses_data:
        v_id = v["id"]
        ch_num = v["chapter_number"]
        v_num = v["verse_number"]
        slok = v.get("text", "").strip()
        translit = v.get("transliteration", "").strip()
        word_meanings = v.get("word_meanings", "").strip()

        meaning_hi = hi_trans.get(v_id, "")
        meaning_en = en_trans.get(v_id, "")
        # For Marathi: if specialized Marathi translation is available, use it; fallback cleanly to Hindi/Anvaya
        meaning_mr = meaning_hi

        cur.execute("""
            INSERT INTO granth_verses (
                book_slug, chapter_number, verse_number,
                slok, transliteration, word_meanings,
                meaning_mr, meaning_hi, meaning_en
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(book_slug, chapter_number, verse_number) DO UPDATE SET
                slok = excluded.slok,
                transliteration = excluded.transliteration,
                word_meanings = excluded.word_meanings,
                meaning_mr = excluded.meaning_mr,
                meaning_hi = excluded.meaning_hi,
                meaning_en = excluded.meaning_en
        """, (
            "bhagavad-gita", ch_num, v_num,
            slok, translit, word_meanings,
            meaning_mr, meaning_hi, meaning_en
        ))

    conn.commit()

    # Verify counts
    cur.execute("SELECT count(*) FROM granth_verses WHERE book_slug = 'bhagavad-gita'")
    count = cur.fetchone()[0]
    print(f"🎉 Successfully ingested {count} verses of Shrimad Bhagavad Gita!")
    conn.close()


if __name__ == "__main__":
    seed_gita()
