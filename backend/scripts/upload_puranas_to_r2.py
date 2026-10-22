#!/usr/bin/env python3
"""
Uploads all 18 Mahapuranas + Upapuranas PDFs from ~/Downloads to Cloudflare R2 bucket,
and seeds all scripture metadata into SQLite database (granth_books).
"""

import os
import sys
import time
import sqlite3
from pathlib import Path
import boto3
from botocore.config import Config
from dotenv import load_dotenv

# Load backend .env
BACKEND_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND_DIR / ".env")

R2_BUCKET_NAME = os.getenv("R2_BUCKET_NAME", "bhaktidharabucket")
R2_ACCOUNT_ID = os.getenv("R2_ACCOUNT_ID", "68cadf25803504184e3786133d647daa")
R2_ACCESS_KEY_ID = os.getenv("R2_ACCESS_KEY_ID", "7d5142e063cf1ef4f6df24ead525db24")
R2_SECRET_ACCESS_KEY = os.getenv("R2_SECRET_ACCESS_KEY", "3fc9ab7807e244fe52123d1caae41ccc6d557c8ce9ef79508a82ec7b54388891")
R2_PUBLIC_URL = os.getenv("R2_PUBLIC_URL", "https://pub-5d7718c3d5bf4d70ad7ebfbf1afb14eb.r2.dev").rstrip("/")

DOWNLOADS_DIR = Path("/Users/adityakaldhone/Downloads")

# Complete catalog of all 18 Mahapuranas, Upapuranas and Scripture Compilations
PURANAS_CATALOG = [
    {
        "slug": "vishnu-purana",
        "file": "vishnu-puran.pdf",
        "title_mr": "श्रीविष्णु महापुराण",
        "title_hi": "श्रीविष्णु महापुराण",
        "title_en": "Shri Vishnu Mahapurana",
        "subtitle_mr": "६ अंश, १२६ अध्याय • भगवान विष्णूंची उपासना, ध्रुव-प्रल्हाद चरित्र व कलियुग वर्णन",
        "subtitle_hi": "६ अंश, १२६ अध्याय • भगवान विष्णु की उपासना, ध्रुव-प्रह्लाद चरित्र एवं कलियुग वर्णन",
        "subtitle_en": "6 Amshas, 126 Chapters • Glory of Lord Vishnu, Dhruva, Prahlada & Kaliyuga",
        "description_mr": "महर्षि पराशर विरचित अत्यंत प्रामाणिक वैष्णव महापुराण. यामध्ये सृष्टीची उत्पत्ती, भगवान विष्णूंचे अवतार, ध्रुव व प्रल्हाद यांची अनन्य भक्ती, श्रीकृष्ण चरित्र आणि कलियुगाचे भविष्य सविस्तर वर्णिले आहे.",
        "description_hi": "महर्षि पराशर द्वारा उपदिष्ट सर्वाधिक प्रामाणिक वैष्णव महापुराण। इसमें सृष्टि उत्पत्ति, भगवान विष्णु के अवतार, ध्रुव एवं प्रह्लाद की भक्ति तथा श्रीकृष्ण चरित का पावन वर्णन है।",
        "description_en": "One of the most authentic Vaishnava Puranas narrated by Sage Parashara, detailing the creation of the cosmos, avatars of Lord Vishnu, Dhruva, Prahlada, and Krishna Charitra.",
        "total_chapters": 126,
        "total_verses": 535,
        "icon": "🐚",
        "sort_order": 4,
    },
    {
        "slug": "shiva-purana",
        "file": "shiv-puran.pdf",
        "title_mr": "श्रीशिव महापुराण",
        "title_hi": "श्रीशिव महापुराण",
        "title_en": "Shri Shiva Mahapurana",
        "subtitle_mr": "७ संहिता, २४००० श्लोक • द्वादश ज्योतिर्लिंग, शिव-पार्वती विवाह व कैलास महिमा",
        "subtitle_hi": "७ संहिताएँ, २४००० श्लोक • द्वादश ज्योतिर्लिंग, शिव-पार्वती विवाह एवं कैलास महिमा",
        "subtitle_en": "7 Samhitas, 24,000 Verses • 12 Jyotirlingas, Divine Wedding of Shiva-Parvati",
        "description_mr": "देवाधिदेव महादेव शंकरांचे अलौकिक महात्म्य सांगणारे पावन महापुराण. यामध्ये १२ ज्योतिर्लिंगांची उत्पत्ती, सती व पार्वती विवाह, तांडव रहस्य आणि शिवभक्तीचे कल्याणकारी मार्ग उलगडले आहेत.",
        "description_hi": "देवाधिदेव महादेव शिव की असीम महिमा का पावन आख्यान। इसमें द्वादश ज्योतिर्लिंगों की कथा, शिव-पार्वती विवाह, कालभैरव एवं महामृत्युंजय रहस्य का विस्तृत वर्णन है।",
        "description_en": "The magnificent Shaivite scripture celebrating Mahadev Shiva, the origins of the 12 sacred Jyotirlingas, the divine union of Shiva-Parvati, and cosmic liberation.",
        "total_chapters": 456,
        "total_verses": 812,
        "icon": "🔱",
        "sort_order": 5,
    },
    {
        "slug": "bhagavata-purana",
        "file": "bhagwat-puran.pdf",
        "title_mr": "श्रीमद्भागवत महापुराण",
        "title_hi": "श्रीमद्भागवत महापुराण",
        "title_en": "Shrimad Bhagavata Mahapurana",
        "subtitle_mr": "१२ स्कंध, ३३५ अध्याय • श्रीकृष्णलीला, नवविधा भक्ती व आत्मज्ञान",
        "subtitle_hi": "१२ स्कंध, ३३५ अध्याय • श्रीकृष्णलीला, नवविधा भक्ति एवं आत्मज्ञान",
        "subtitle_en": "12 Skandhas, 335 Chapters • Sacred Life & Leelas of Lord Krishna",
        "description_mr": "वेदांची परिपक्व अमृतफळे मानला जाणारा सर्वश्रेष्ठ भक्तीग्रंथ. महर्षि शुकदेवांनी राजा परीक्षितला सांगितलेली रसाळ श्रीकृष्णलीला, गोपीप्रेम आणि मोक्षप्राप्तीचे रहस्य.",
        "description_hi": "वेदों का अमृततुल्य रस माना जाने वाला सर्वोपरि भक्ति ग्रंथ। शुकदेव मुनि द्वारा राजा परीक्षित को श्रवण कराई गई पावन श्रीकृष्ण लीला एवं परम मोक्ष का मार्ग।",
        "description_en": "The crown jewel of devotional literature, detailing the life and divine pastimes of Shri Krishna, supreme devotion, and the path to ultimate liberation.",
        "total_chapters": 335,
        "total_verses": 977,
        "icon": "🪈",
        "sort_order": 6,
    },
    {
        "slug": "brahma-purana",
        "file": "bramha-puran.pdf",
        "title_mr": "श्रीब्रह्म महापुराण (आदिपुराण)",
        "title_hi": "श्रीब्रह्म महापुराण (आदिपुराण)",
        "title_en": "Brahma Mahapurana (Adi Purana)",
        "subtitle_mr": "२४५ अध्याय • सृष्टीनिर्मिती, पुरुषोत्तम क्षेत्र (पुरी) व सूर्योपासना",
        "subtitle_hi": "२४५ अध्याय • सृष्टि उत्पत्ति, पुरुषोत्तम क्षेत्र (पुरी) एवं सूर्योपासना",
        "subtitle_en": "245 Chapters • Cosmic Creation, Sacred Jagannath Puri & Sun Worship",
        "description_mr": "१८ महापुराणांमध्ये सर्वप्रथम मानले गेलेले आदिपुराण. भगवान ब्रह्मदेवांनी महर्षि दक्षांना सृष्टीचे गूढ, तीर्थक्षेत्रे आणि जगन्नाथ पुरी पुरुषोत्तम क्षेत्राचे महात्म्य सांगितले आहे.",
        "description_hi": "अठारह महापुराणों में सर्वप्रथम आदिपुराण। भगवान ब्रह्मा द्वारा महर्षि दक्ष को दिया गया सृष्टि रचना, तीर्थ महात्म्य एवं श्री जगन्नाथ धाम का पावन उपदेश।",
        "description_en": "The foremost among all 18 Puranas, expounding cosmological creation, the sacred geography of Bharat, and the eternal glory of Jagannath Puri.",
        "total_chapters": 245,
        "total_verses": 423,
        "icon": "🪷",
        "sort_order": 7,
    },
    {
        "slug": "padma-purana",
        "file": "padam-puran.pdf",
        "title_mr": "श्रीपद्म महापुराण",
        "title_hi": "श्रीपद्म महापुराण",
        "title_en": "Padma Mahapurana",
        "subtitle_mr": "५ खंड, ५५००० श्लोक • सृष्टी, भूमी, स्वर्ग, पाताल व उत्तर खंड",
        "subtitle_hi": "५ खण्ड, ५५००० श्लोक • सृष्टि, भूमि, स्वर्ग, पाताल एवं उत्तर खण्ड",
        "subtitle_en": "5 Khandas • Srishti, Bhumi, Swarga, Patala & Uttara Khanda",
        "description_mr": "हिरण्यगर्भ कमळातून प्रकट झालेले अथांग महापुराण. यामध्ये पवित्र एकादशी व्रताचे महात्म्य, श्रीमद्भगवद्गीतेचे महात्म्य, तीर्थयात्रा आणि धर्मशास्त्राचे सर्वसमावेशक मार्गदर्शन आहे.",
        "description_hi": "कमल-पुष्प के समान विशाल पावन महापुराण। इसमें पवित्र एकादशी व्रत महिमा, भगवद्गीता महात्म्य, गंगा महिमा और मर्यादा पुरुषोत्तम श्रीराम चरित का अद्भुत वर्णन है।",
        "description_en": "A monumental 55,000-verse scripture containing the esoteric glories of the Bhagavad Gita, Ekadashi observances, sacred rivers, and cosmic virtue.",
        "total_chapters": 650,
        "total_verses": 1001,
        "icon": "🌺",
        "sort_order": 8,
    },
    {
        "slug": "narada-purana",
        "file": "narad-puran.pdf",
        "title_mr": "श्रीनारद महापुराण",
        "title_hi": "श्रीनारद महापुराण",
        "title_en": "Narada Mahapurana",
        "subtitle_mr": "२ भाग, १२५ अध्याय • वेदांग, ज्योतिष, व्याकरण व एकादशी महात्म्य",
        "subtitle_hi": "२ भाग, १२५ अध्याय • वेदांग, ज्योतिष, व्याकरण एवं एकादशी महात्म्य",
        "subtitle_en": "2 Parts, 125 Chapters • Vedangas, Vedic Astrology, Grammar & Virtues",
        "description_mr": "देवर्षि नारदांनी महर्षि सनकादिकांना सांगितलेले ज्ञानमय पुराण. सर्व १८ महापुराणांची अनुक्रमणिका, वेदानुकूल ज्योतिषशास्त्र, मंत्रविद्या आणि भक्तीमार्गाचे निरूपण.",
        "description_hi": "देवर्षि नारद द्वारा सनकादि ऋषियों को उपदिष्ट दिव्य ज्ञान। इसमें संपूर्ण १८ पुराणों की अनुक्रमणिका, वैदिक ज्योतिष, व्रत विधान और भक्ति योग का समन्वय है।",
        "description_en": "Expounded by Devarshi Narada, offering a comprehensive encyclopedia of the six Vedangas, Vedic astrology, mantras, and the essence of all 18 Puranas.",
        "total_chapters": 125,
        "total_verses": 751,
        "icon": "🪕",
        "sort_order": 9,
    },
    {
        "slug": "markandeya-purana",
        "file": "markandeya-puran.pdf",
        "title_mr": "श्रीमार्कण्डेय महापुराण (दुर्गा सप्तशती)",
        "title_hi": "श्रीमार्कण्डेय महापुराण (दुर्गा सप्तशती)",
        "title_en": "Markandeya Mahapurana (Durga Saptashati)",
        "subtitle_mr": "१३७ अध्याय • श्री दुर्गा सप्तशती (देवी महात्म्य) व प्रल्हाद कथा",
        "subtitle_hi": "१३७ अध्याय • श्री दुर्गा सप्तशती (देवी महात्म्य) एवं प्रह्लाद कथा",
        "subtitle_en": "137 Chapters • Source of Sri Durga Saptashati & Devi Mahatmyam",
        "description_mr": "चिरंजीव महर्षि मार्कण्डेयांच्या संवादावर आधारित पावन ग्रंथ. यामध्येच जगप्रसिद्ध 'श्री दुर्गा सप्तशती' (देवी कवच, अर्गला, कीलक व महिषासुरमर्दिनी कथा) समाविष्ट आहे.",
        "description_hi": "अमर महर्षि मार्कण्डेय द्वारा प्रणीत पावन ग्रंथ। शक्ति साधना का मूल आधार 'श्री दुर्गा सप्तशती' (चण्डी पाठ) इसी महापुराण का गौरवशाली अंश है।",
        "description_en": "The ancient scripture containing the venerated Sri Durga Saptashati (Devi Mahatmyam), embodying the triumph of the Supreme Goddess over cosmic darkness.",
        "total_chapters": 137,
        "total_verses": 296,
        "icon": "⚔️",
        "sort_order": 10,
    },
    {
        "slug": "agni-purana",
        "file": "agni-puran.pdf",
        "title_mr": "श्रीअग्नि महापुराण",
        "title_hi": "श्रीअग्नि महापुराण",
        "title_en": "Agni Mahapurana",
        "subtitle_mr": "३८३ अध्याय • वैदिक विद्या, आयुर्वेद, धनुर्वेद, वास्तुशास्त्र व राज्यधर्म",
        "subtitle_hi": "३८३ अध्याय • वैदिक विद्या, आयुर्वेद, धनुर्वेद, वास्तुशास्त्र एवं नीतिशास्त्र",
        "subtitle_en": "383 Chapters • Comprehensive Encyclopedia of Ayurveda, Vastu & Warfare",
        "description_mr": "साक्षात अग्निदेवांनी महर्षि वशिष्ठांना सांगितलेला ज्ञानकोश. यामध्ये आयुर्वेद, खगोलशास्त्र, रत्नपरीक्षा, धनुर्वेद, राजधर्म आणि मंदिर वास्तुशास्त्राचे ज्ञान आहे.",
        "description_hi": "अग्निदेव द्वारा महर्षि वसिष्ठ को प्रदान किया गया प्राचीन वैदिक विश्वकोश। आयुर्वेद, धनुर्वेद, वास्तु, खगोल और धर्मशास्त्र का अप्रतिम समन्वय।",
        "description_en": "The great Vedic encyclopedia dictated by Agni Deva, encompassing Ayurveda, traditional medicine, warfare, architecture, astronomy, and righteous duty.",
        "total_chapters": 383,
        "total_verses": 842,
        "icon": "🔥",
        "sort_order": 11,
    },
    {
        "slug": "bhavishya-purana",
        "file": "bhavishya-puran.pdf",
        "title_mr": "श्रीभविष्य महापुराण",
        "title_hi": "श्रीभविष्य महापुराण",
        "title_en": "Bhavishya Mahapurana",
        "subtitle_mr": "४ पर्व • कलियुगाचे भविष्य, सूर्योपासना, सदाचार व ऐतिहासिक राजवंश",
        "subtitle_hi": "४ पर्व • कलियुग का भविष्य, सूर्योपासना, सदाचार एवं राजवंश वर्णन",
        "subtitle_en": "4 Parvas • Prophecies of Kali Yuga, Sun Worship & Historical Dynasties",
        "description_mr": "भविष्यातील कालचक्र, युगधर्म आणि युगांतराचे रहस्य सांगणारे अद्भुत पुराण. सूर्यदेवाची उपासना, अग्निहोत्र आणि कलियुगातील सामाजिक-राजकीय परिवर्तनाची अचूक भाकिते.",
        "description_hi": "आगामी समय, युग-परिवर्तन और कलियुग की घटनाओं का दूरदर्शी आख्यान। सूर्यदेव की आराधना, सदाचार के नियम और ऐतिहासिक गाथाएँ।",
        "description_en": "Famous for its detailed prophetic visions of human history, societal evolution in Kali Yuga, sacred solar worship, and righteous ethics.",
        "total_chapters": 195,
        "total_verses": 448,
        "icon": "☀️",
        "sort_order": 12,
    },
    {
        "slug": "brahmavaivarta-purana",
        "file": "sankshipt-brahm-vaivarta-puran.pdf",
        "title_mr": "श्रीब्रह्मवैवर्त महापुराण",
        "title_hi": "श्रीब्रह्मवैवर्त महापुराण",
        "title_en": "Brahmavaivarta Mahapurana",
        "subtitle_mr": "४ खंड • ब्रह्म, प्रकृती, गणेश व श्रीकृष्णजन्म खंड",
        "subtitle_hi": "४ खण्ड • ब्रह्म, प्रकृति, गणेश एवं श्रीकृष्णजन्म खण्ड",
        "subtitle_en": "4 Khandas • Brahma, Prakriti, Ganesha & Sri Krishna Janma Khandas",
        "description_mr": "राधा-कृष्णांच्या परम गोलोक धामाचे आणि भगवान श्रीगणेशांच्या अवताराचे अलौकिक वर्णन. प्रकृती व पुरुष यांच्या दिव्य समन्वयाचे आणि भक्तीचे रसाळ विवरण.",
        "description_hi": "राधा-कृष्ण के दिव्य गोलोक धाम, माता प्रकृति और भगवान श्रीगणेश के आविर्भाव की पावन कथा। ब्रह्म और प्रकृति का परात्पर दर्शन।",
        "description_en": "Exalts the divine manifestations of Radha-Krishna and Lord Ganesha, establishing the celestial abode of Goloka and the nature of cosmic matter (Prakriti).",
        "total_chapters": 274,
        "total_verses": 796,
        "icon": "🦚",
        "sort_order": 13,
    },
    {
        "slug": "linga-purana",
        "file": "ling-puran.pdf",
        "title_mr": "श्रीलिंग महापुराण",
        "title_hi": "श्रीलिंग महापुराण",
        "title_en": "Linga Mahapurana",
        "subtitle_mr": "२ भाग, १६३ अध्याय • शिवलिंग प्राकट्य, पंचाक्षर मंत्र व शिवपूजा विधी",
        "subtitle_hi": "२ भाग, १६३ अध्याय • शिवलिंग प्राकट्य, पंचाक्षर मन्त्र एवं शिवपूजा विधि",
        "subtitle_en": "2 Parts, 163 Chapters • The Cosmic Pillar of Light, Om Namah Shivaya",
        "description_mr": "अनादि-अनंत ज्योतिर्लिंगाच्या प्राकट्याची कथा. ब्रह्मा व विष्णूंच्या संवादातून प्रकट झालेला तेजोमय स्तंभ, 'ॐ नमः शिवाय' पंचाक्षरी मंत्राचे रहस्य व अघोर-सद्योजात रूपांचे चिंतन.",
        "description_hi": "अनादि-अनंत ज्योतिर्मय लिंग के प्राकट्य का पावन रहस्य। 'ॐ नमः शिवाय' मन्त्र की अगाध महिमा, रुद्राभिषेक विधि और मोक्षकारी शिवतत्व का विवेचन।",
        "description_en": "Reveals the manifestation of the infinite pillar of divine light (Jyotirlinga), the supreme potency of Om Namah Shivaya, and rituals of Shiva worship.",
        "total_chapters": 163,
        "total_verses": 390,
        "icon": "🪨",
        "sort_order": 14,
    },
    {
        "slug": "varaha-purana",
        "file": "varah-puran.pdf",
        "title_mr": "श्रीवराह महापुराण",
        "title_hi": "श्रीवराह महापुराण",
        "title_en": "Varaha Mahapurana",
        "subtitle_mr": "२१८ अध्याय • भूदेवी उद्धार, पावन वराह अवतार व तीर्थ महिमा",
        "subtitle_hi": "२१८ अध्याय • भूदेवी उद्धार, पावन वराह अवतार एवं तीर्थ महिमा",
        "subtitle_en": "218 Chapters • Rescue of Mother Earth by the Divine Boar Incarnation",
        "description_mr": "प्रलयकालीन समुद्रातून पृथ्वी मातेचे (भूदेवी) रक्षण करणाऱ्या भगवान वराहांची अमर गाथा. भगवंतांनी भूदेवीला सांगितलेले पवित्र व्रत, तीर्थ आणि कर्मयोगाचे मार्गदर्शन.",
        "description_hi": "रसातल से पृथ्वी का उद्धार करने वाले भगवान वराह और भूदेवी का पावन संवाद। इसमें व्रत, तीर्थ, श्राद्ध एवं निष्काम भक्ति का विस्तृत उपदेश है।",
        "description_en": "Chronicles the incarnation of Lord Varaha rescuing Mother Earth from the cosmic abyss, imparting sacred knowledge on righteous conduct and sacred shrines.",
        "total_chapters": 218,
        "total_verses": 392,
        "icon": "🐗",
        "sort_order": 15,
    },
    {
        "slug": "skanda-purana",
        "file": "skand-puran.pdf",
        "title_mr": "श्रीस्कन्द महापुराण",
        "title_hi": "श्रीस्कन्द महापुराण",
        "title_en": "Skanda Mahapurana",
        "subtitle_mr": "७ खंड, ८१००० श्लोक • काशी खंड, केदार खंड, रेवा खंड व सत्यनारायण कथा",
        "subtitle_hi": "७ खण्ड, ८१००० श्लोक • काशी खण्ड, केदार खण्ड, रेवा खण्ड एवं सत्यनारायण कथा",
        "subtitle_en": "7 Khandas, 81,000 Verses • Largest Purana: Kashi, Kedara & Satyanarayana",
        "description_mr": "सर्व १८ महापुराणांमध्ये आकाराने सर्वात भव्य महापुराण. यामध्ये काशी विश्वनाथ महात्म्य, केदारनाथ महिमा, नर्मदा परिक्रमा आणि जगप्रसिद्ध 'श्री सत्यनारायण व्रत कथा' समाविष्ट आहे.",
        "description_hi": "अठारह महापुराणों में सबसे विशालतम ग्रंथ। इसमें काशी खंड, केदार खंड, श्री सत्यनारायण व्रत कथा, रामेश्वरम एवं वैष्णोदेवी का अनुपम आख्यान है।",
        "description_en": "The largest of all Puranas (81,000 verses), enshrining the glories of Kashi, Kedarnath, Ayodhya, and the universal Sri Satyanarayana Vrata Katha.",
        "total_chapters": 500,
        "total_verses": 1108,
        "icon": "⚡",
        "sort_order": 16,
    },
    {
        "slug": "vamana-purana",
        "file": "vaman-puran.pdf",
        "title_mr": "श्रीवामन महापुराण",
        "title_hi": "श्रीवामन महापुराण",
        "title_en": "Vamana Mahapurana",
        "subtitle_mr": "९५ अध्याय • त्रिविक्रम वामन अवतार, बळीराजा समर्पण व कुरुक्षेत्र महिमा",
        "subtitle_hi": "९५ अध्याय • त्रिविक्रम वामन अवतार, राजा बलि समर्पण एवं कुरुक्षेत्र महिमा",
        "subtitle_en": "95 Chapters • The Divine Dwarf Incarnation, King Bali & Trivikrama",
        "description_mr": "अदितीच्या उदरी जन्म घेतलेल्या बटू वामनाने तीन पावलांत त्रैलोक्य व्यापल्याची पावन कथा. दानशूर राजा बळीचे संपूर्ण आत्मसमर्पण आणि कुरुक्षेत्राचे महात्म्य.",
        "description_hi": "तीन पग में त्रिलोकी नापने वाले भगवान वामन और दानवीर राजा बलि का पावन चरित्र। धर्म, दान और अहंकार-मुक्ति का अनुपम दृष्टांत।",
        "description_en": "Narrates the Trivikrama avatar where Lord Vishnu in the guise of a young ascetic measures the entire universe in three steps, humbling King Bali.",
        "total_chapters": 95,
        "total_verses": 196,
        "icon": "☂️",
        "sort_order": 17,
    },
    {
        "slug": "kurma-purana",
        "file": "kurma-puran.pdf",
        "title_mr": "श्रीकूर्म महापुराण",
        "title_hi": "श्रीकूर्म महापुराण",
        "title_en": "Kurma Mahapurana",
        "subtitle_mr": "२ भाग • समुद्रमंथन, कूर्म अवतार, ईश्वरगीता व ज्ञानयोग",
        "subtitle_hi": "२ भाग • समुद्रमंथन, कूर्म अवतार, ईश्वरगीता एवं ज्ञानयोग",
        "subtitle_en": "2 Parts • Samudra Manthana, Tortoise Avatar & The Sacred Ishwara Gita",
        "description_mr": "समुद्रमंथनाच्या वेळी मंदार पर्वताला पाठीवर धारण करणाऱ्या कूर्म (कासव) अवताराची कथा. यामध्ये समाविष्ट असलेली 'ईश्वरगीता' अद्वैत तत्त्वज्ञान आणि भक्तीचे अप्रतिम शिखर मानली जाते.",
        "description_hi": "अमृत मंथन के समय मंदराचल को धारण करने वाले भगवान कूर्म की पावन गाथा। इसमें स्थित 'ईश्वरगीता' ज्ञान और भक्ति का परम पावन संगम है।",
        "description_en": "Depicts the cosmic churning of the celestial ocean (Samudra Manthana) and contains the profound 'Ishwara Gita' where Shiva reveals supreme monistic wisdom.",
        "total_chapters": 110,
        "total_verses": 398,
        "icon": "🐢",
        "sort_order": 18,
    },
    {
        "slug": "matsya-purana",
        "file": "matsya-puran-part-1.pdf",
        "extra_files": ["matsya-puran-part-2.pdf"],
        "title_mr": "श्रीमत्स्य महापुराण",
        "title_hi": "श्रीमत्स्य महापुराण",
        "title_en": "Matsya Mahapurana",
        "subtitle_mr": "२९१ अध्याय • महाप्रलय, प्रथम मत्स्य अवतार, सत्यव्रत मनू व राजधर्म",
        "subtitle_hi": "२९१ अध्याय • महाप्रलय, प्रथम मत्स्य अवतार, राजा सत्यव्रत एवं राजधर्म",
        "subtitle_en": "291 Chapters • Great Deluge, King Manu, First Incarnation & Iconography",
        "description_mr": "महाप्रलयाच्या वेळी सत्यव्रत मनू आणि सप्तर्षींचे रक्षण करणाऱ्या सुवर्णमत्स्य रूपाची अमर कथा. यामध्ये वास्तुशास्त्र, मूर्तीकला, राजधर्म आणि तीर्थयात्रांचे विस्तृत वर्णन आहे.",
        "description_hi": "प्रलयकाल में वेदों और सप्तर्षियों की रक्षा करने वाले प्रथम मत्स्य अवतार का वर्णन। वास्तुविद्या, शिल्पशास्त्र और राजधर्म का प्राचीनतम प्रामाणिक ग्रंथ।",
        "description_en": "The legendary chronicle of the cosmic deluge, the preservation of the Vedas by the Matsya avatar, and classical treatise on sculpture and architecture.",
        "total_chapters": 291,
        "total_verses": 984,
        "icon": "🐟",
        "sort_order": 19,
    },
    {
        "slug": "brahmanda-purana",
        "file": "brahamand-puran-part-1.pdf",
        "extra_files": ["brahamand-puran-part-2.pdf"],
        "title_mr": "श्रीब्रह्माण्ड महापुराण (ललिता सहस्रनाम)",
        "title_hi": "श्रीब्रह्माण्ड महापुराण (ललिता सहस्रनाम)",
        "title_en": "Brahmanda Mahapurana (Lalita Sahasranama)",
        "subtitle_mr": "१२२ अध्याय • ब्रह्मांड रचना, परशुराम चरित्र व श्री ललिता सहस्रनाम",
        "subtitle_hi": "१२२ अध्याय • ब्रह्माण्ड रचना, परशुराम चरित्र एवं श्री ललिता सहस्रनाम",
        "subtitle_en": "122 Chapters • Cosmos Creation, Parashurama & Sri Lalita Sahasranama",
        "description_mr": "ब्रह्मांडाच्या निर्मितीचे आणि विस्ताराचे शास्त्रशुद्ध वर्णन. यामध्येच अत्यंत पवित्र 'श्री ललिता सहस्रनाम' स्तोत्र, अध्यात्म रामायण आणि भगवान परशुरामांचे चरित्र समाविष्ट आहे.",
        "description_hi": "सम्पूर्ण ब्रह्माण्ड की उत्पत्ति और विस्तार का वैज्ञानिक निरूपण। जगत्प्रसिद्ध 'श्री ललिता सहस्रनाम' तथा 'अध्यात्म रामायण' इसी महापुराण का मुकुटमणि हैं।",
        "description_en": "The cosmic treatise on cosmological origins, containing the sacred Lalita Sahasranama Stotram and the Adhyatma Ramayana.",
        "total_chapters": 122,
        "total_verses": 893,
        "icon": "🌌",
        "sort_order": 20,
    },
    # ── Upapuranas & Special Compilations ──
    {
        "slug": "vayu-purana",
        "file": "vayu-puran.pdf",
        "title_mr": "श्रीवायु महापुराण",
        "title_hi": "श्रीवायु महापुराण",
        "title_en": "Vayu Mahapurana",
        "subtitle_mr": "११२ अध्याय • पवनदेव कथित रुद्र महात्म्य, कालमान व भूगोल",
        "subtitle_hi": "११२ अध्याय • पवनदेव कथित रुद्र महिमा, काल गणना एवं भूगोल",
        "subtitle_en": "112 Chapters • Divine Discourse by Vayu Deva on Time & Geography",
        "description_mr": "साक्षात वायूदेवांनी ऋषींना सांगितलेले अतिप्राचीन पुराण. यामध्ये सौरमंडळ, भूगोल, युगांची कालगणना आणि भगवान शिवांच्या रुद्र रूपांचे विहंगम वर्णन आहे.",
        "description_hi": "पवनदेव द्वारा महर्षियों को दिया गया प्राचीनतम उपदेश। भूगोल, खगोल, कालगणना और भगवान शिव के परात्पर स्वरूप का प्रामाणिक विवेचन।",
        "description_en": "One of the most archaic Puranic texts expounded by the Wind God (Vayu), preserving ancient geography, planetary systems, and Shaiva theology.",
        "total_chapters": 112,
        "total_verses": 1160,
        "icon": "💨",
        "sort_order": 21,
    },
    {
        "slug": "kalki-purana",
        "file": "kalki-puran-hindi.pdf",
        "title_mr": "श्रीकल्कि उपपुराण",
        "title_hi": "श्रीकल्कि उपपुराण",
        "title_en": "Shri Kalki Upapurana",
        "subtitle_mr": "३५ अध्याय • कलियुगांत, भगवान विष्णूंचा १० वा कल्कि अवतार व सत्ययुग स्थापना",
        "subtitle_hi": "३५ अध्याय • कलियुग अंत, भगवान विष्णु का १०वाँ कल्कि अवतार एवं सत्ययुग स्थापना",
        "subtitle_en": "35 Chapters • The 10th Incarnation of Lord Vishnu & Dawn of Satya Yuga",
        "description_mr": "कलियुगाच्या अंती शंभल गावात जन्म घेणाऱ्या भगवान कल्कि अवताराचे भविष्यकालीन चरित्र. अधर्माचा विनाश, देवदत्त घोड्यावर स्वार होऊन दुष्टांचे निर्दालन आणि पुन्हा सत्ययुगाची स्थापना.",
        "description_hi": "कलियुग के अंत में अधर्म का विनाश कर पुनः सतयुग की स्थापना करने वाले भगवान विष्णु के दसवें 'कल्कि' अवतार का विस्तृत आख्यान।",
        "description_en": "A prophetic Vaishnava scripture detailing the future advent of Kalki, riding the white steed Devadatta to annihilate evil and usher in Satya Yuga.",
        "total_chapters": 35,
        "total_verses": 259,
        "icon": "🐎",
        "sort_order": 22,
    },
    {
        "slug": "narasimha-purana",
        "file": "upa-puran-narsihma-puran.pdf",
        "title_mr": "श्रीनृसिंह उपपुराण",
        "title_hi": "श्रीनृसिंह उपपुराण",
        "title_en": "Shri Narasimha Upapurana",
        "subtitle_mr": "६८ अध्याय • भक्त प्रल्हाद रक्षण, नृसिंह प्राकट्य व अढळ भक्ती",
        "subtitle_hi": "६८ अध्याय • भक्त प्रह्लाद रक्षा, नृसिंह प्राकट्य एवं अनन्य भक्ति",
        "subtitle_en": "68 Chapters • Manifestation of Lord Narasimha & Salvation of Prahlada",
        "description_mr": "स्तंभातून प्रकट होऊन भक्त प्रल्हादाचे रक्षण करणाऱ्या आणि हिरण्यकश्यपूचा वध करणाऱ्या भगवान नृसिंहांची ज्वलंत कथा. शरणागती आणि अनन्य भक्तीचे सामर्थ्य उलगडणारा ग्रंथ.",
        "description_hi": "खंभे से प्रकट होकर परम भक्त प्रह्लाद की रक्षा करने वाले और हिरण्यकशिपु का संहार करने वाले उग्र-शांत श्री नृसिंह भगवान का पावन चरित्र।",
        "description_en": "The glorious narrative of Lord Narasimha bursting forth from the pillar to protect devotee Prahlada, celebrating unwavering faith and supreme divine protection.",
        "total_chapters": 68,
        "total_verses": 298,
        "icon": "🦁",
        "sort_order": 23,
    },
    {
        "slug": "18-puranas-samhita",
        "file": "18 Puranas.pdf",
        "title_mr": "अष्टादश महापुराण सार संग्रह",
        "title_hi": "अष्टादश महापुराण सार संग्रह",
        "title_en": "The 18 Mahapuranas Compilation",
        "subtitle_mr": "१३४८ पृष्ठे • सर्व १८ महापुराणांचा एकत्रित पावन ज्ञानसागर",
        "subtitle_hi": "१३४८ पृष्ठ • समस्त १८ महापुराणों का समग्र पावन ज्ञानसागर",
        "subtitle_en": "1348 Pages • Complete Encyclopedic Treasury of All 18 Puranas",
        "description_mr": "हिंदू संस्कृतीतील सर्व १८ महापुराणांचा संपूर्ण सार, कथा, इतिहास व तत्त्वज्ञान एकाच ग्रंथात समाविष्ट असलेला महाग्रंथ. सर्व भाविकांसाठी अलौकिक आध्यात्मिक ठेवा.",
        "description_hi": "सनातन धर्म के समस्त अठारह महापुराणों का विस्तृत सार, मुख्य आख्यान और तत्त्वज्ञान एक ही पावन ग्रंथ में संकलित।",
        "description_en": "An encyclopedic master volume containing the essential wisdom, summaries, and stories of all eighteen classical Mahapuranas.",
        "total_chapters": 18,
        "total_verses": 1348,
        "icon": "📚",
        "sort_order": 24,
    },
]


def get_r2_client():
    return boto3.client(
        "s3",
        endpoint_url=f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com",
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY,
        config=Config(signature_version="s3v4"),
        region_name="auto",
    )


def upload_file_to_r2(s3, local_path: Path, r2_key: str):
    file_size = local_path.stat().st_size
    print(f"  Uploading {local_path.name} ({file_size / (1024*1024):.1f} MB) -> r2://{R2_BUCKET_NAME}/{r2_key} ...")
    t0 = time.time()

    # Check if object already exists and has the same size
    try:
        head = s3.head_object(Bucket=R2_BUCKET_NAME, Key=r2_key)
        if head.get("ContentLength") == file_size:
            print(f"    ✓ Already uploaded with matching size ({file_size} bytes). Skipping.")
            return f"{R2_PUBLIC_URL}/{r2_key}"
    except Exception:
        pass

    s3.upload_file(
        str(local_path),
        R2_BUCKET_NAME,
        r2_key,
        ExtraArgs={
            "ContentType": "application/pdf",
            "CacheControl": "public, max-age=31536000, immutable",
        },
    )
    elapsed = time.time() - t0
    speed_mbps = (file_size / (1024 * 1024)) / max(elapsed, 0.01)
    print(f"    ✓ Uploaded in {elapsed:.1f}s ({speed_mbps:.2f} MB/s)")
    return f"{R2_PUBLIC_URL}/{r2_key}"


def seed_db(db_path: Path, purana_records: list):
    print(f"\n💾 Updating SQLite Database at {db_path}...")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Check if pdf_url column exists
    cols = [r[1] for r in cur.execute("PRAGMA table_info(granth_books)").fetchall()]
    if "pdf_url" not in cols:
        print("  Adding 'pdf_url' column to granth_books...")
        cur.execute("ALTER TABLE granth_books ADD COLUMN pdf_url TEXT")


    for p in purana_records:
        slug = p["slug"]
        cur.execute("""
            INSERT INTO granth_books (
                slug, title_mr, title_hi, title_en,
                subtitle_mr, subtitle_hi, subtitle_en,
                description_mr, description_hi, description_en,
                total_chapters, total_verses, free_chapters,
                cover_image, sort_order, is_active, pdf_url
            ) VALUES (
                :slug, :title_mr, :title_hi, :title_en,
                :subtitle_mr, :subtitle_hi, :subtitle_en,
                :description_mr, :description_hi, :description_en,
                :total_chapters, :total_verses, 1,
                :cover_image, :sort_order, 1, :pdf_url
            )
            ON CONFLICT(slug) DO UPDATE SET
                title_mr = excluded.title_mr,
                title_hi = excluded.title_hi,
                title_en = excluded.title_en,
                subtitle_mr = excluded.subtitle_mr,
                subtitle_hi = excluded.subtitle_hi,
                subtitle_en = excluded.subtitle_en,
                description_mr = excluded.description_mr,
                description_hi = excluded.description_hi,
                description_en = excluded.description_en,
                total_chapters = excluded.total_chapters,
                total_verses = excluded.total_verses,
                sort_order = excluded.sort_order,
                is_active = 1,
                pdf_url = excluded.pdf_url
        """, {
            "slug": slug,
            "title_mr": p["title_mr"],
            "title_hi": p["title_hi"],
            "title_en": p["title_en"],
            "subtitle_mr": p["subtitle_mr"],
            "subtitle_hi": p["subtitle_hi"],
            "subtitle_en": p["subtitle_en"],
            "description_mr": p["description_mr"],
            "description_hi": p["description_hi"],
            "description_en": p["description_en"],
            "total_chapters": p["total_chapters"],
            "total_verses": p["total_verses"],
            "cover_image": p.get("icon", "📖"),
            "sort_order": p["sort_order"],
            "pdf_url": p["pdf_url"],
        })

    conn.commit()
    count = cur.execute("SELECT COUNT(*) FROM granth_books").fetchone()[0]
    print(f"  ✓ Database updated! Total granth books in DB: {count}")
    conn.close()


def main():
    print("=" * 60)
    print("🚩 Vedic Puranas Ingestion & Cloudflare R2 Uploader")
    print("=" * 60)

    s3 = get_r2_client()


    processed_records = []

    for item in PURANAS_CATALOG:
        slug = item["slug"]
        main_file = DOWNLOADS_DIR / item["file"]
        if not main_file.exists():
            print(f"⚠️ Warning: File {item['file']} not found in {DOWNLOADS_DIR}")
            continue

        r2_key = f"puranas/{item['file']}"
        pdf_url = upload_file_to_r2(s3, main_file, r2_key)

        # Upload any extra files (part 2 etc.)
        for extra in item.get("extra_files", []):
            extra_path = DOWNLOADS_DIR / extra
            if extra_path.exists():
                upload_file_to_r2(s3, extra_path, f"puranas/{extra}")

        record = dict(item)
        record["pdf_url"] = pdf_url
        processed_records.append(record)

    print(f"\n🎉 Successfully uploaded {len(processed_records)} Puranas to Cloudflare R2!")

    # Seed local database
    local_db = BACKEND_DIR / "data" / "bhaktidhara.db"
    if local_db.exists():
        seed_db(local_db, processed_records)

    # Output list for review
    print("\n📋 Seeded Puranas Summary:")
    for p in processed_records:
        print(f"  • {p['icon']} {p['title_mr']} ({p['title_en']}) -> {p['pdf_url']}")


if __name__ == "__main__":
    main()
