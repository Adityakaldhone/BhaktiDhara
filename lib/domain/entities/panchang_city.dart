/// Represents a geographic city / location for authentic Vedic Panchang calculations.
class PanchangCity {
  final String id;
  final String nameMr;
  final String nameHi;
  final String nameEn;
  final String stateOrCountry;
  final double latitude;
  final double longitude;
  final double timezoneOffsetHours;

  const PanchangCity({
    required this.id,
    required this.nameMr,
    required this.nameHi,
    required this.nameEn,
    required this.stateOrCountry,
    required this.latitude,
    required this.longitude,
    this.timezoneOffsetHours = 5.5,
  });

  String localizedName(String langCode) {
    switch (langCode) {
      case 'hi':
        return nameHi;
      case 'en':
        return nameEn;
      case 'mr':
      default:
        return nameMr;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PanchangCity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Curated sacred pilgrimage destinations, Indian metropolises, and international cities.
const List<PanchangCity> kPopularPanchangCities = [
  // ── Sacred Pilgrimage & Vedic Centers ─────────────────────────────────────
  PanchangCity(
    id: 'ujjain',
    nameMr: 'उज्जैन (महाकाल)',
    nameHi: 'उज्जैन (महाकाल)',
    nameEn: 'Ujjain (Mahakal)',
    stateOrCountry: 'मध्य प्रदेश',
    latitude: 23.1765,
    longitude: 75.7885,
  ),
  PanchangCity(
    id: 'varanasi',
    nameMr: 'वाराणसी (काशी)',
    nameHi: 'वाराणसी (काशी)',
    nameEn: 'Varanasi (Kashi)',
    stateOrCountry: 'उत्तर प्रदेश',
    latitude: 25.3176,
    longitude: 82.9739,
  ),
  PanchangCity(
    id: 'ayodhya',
    nameMr: 'अयोध्या (राम जन्मभूमी)',
    nameHi: 'अयोध्या (राम जन्मभूमि)',
    nameEn: 'Ayodhya (Ram Janmabhoomi)',
    stateOrCountry: 'उत्तर प्रदेश',
    latitude: 26.7922,
    longitude: 82.1998,
  ),
  PanchangCity(
    id: 'nashik',
    nameMr: 'नाशिक (त्र्यंबकेश्वर)',
    nameHi: 'नासिक (त्र्यंबकेश्वर)',
    nameEn: 'Nashik (Trimbakeshwar)',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 19.9975,
    longitude: 73.7898,
  ),
  PanchangCity(
    id: 'kolhapur',
    nameMr: 'कोल्हापूर (महालक्ष्मी)',
    nameHi: 'कोल्हापुर (महालक्ष्मी)',
    nameEn: 'Kolhapur (Mahalakshmi)',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 16.7050,
    longitude: 74.2433,
  ),
  PanchangCity(
    id: 'pandharpur',
    nameMr: 'पंढरपूर (विठ्ठल मंदिर)',
    nameHi: 'पंढरपुर (विट्ठल मंदिर)',
    nameEn: 'Pandharpur (Vitthal Mandir)',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 17.6778,
    longitude: 75.3276,
  ),
  PanchangCity(
    id: 'shirdi',
    nameMr: 'शिर्डी (साईं धाम)',
    nameHi: 'शिर्डी (साईं धाम)',
    nameEn: 'Shirdi (Sai Dham)',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 19.7667,
    longitude: 74.4764,
  ),
  PanchangCity(
    id: 'haridwar',
    nameMr: 'हरिद्वार (गंगा द्वार)',
    nameHi: 'हरिद्वार (गंगा द्वार)',
    nameEn: 'Haridwar (Ganga Dwaar)',
    stateOrCountry: 'उत्तराखंड',
    latitude: 29.9457,
    longitude: 78.1642,
  ),
  PanchangCity(
    id: 'tirupati',
    nameMr: 'तिरुपती (बालाजी)',
    nameHi: 'तिरुपति (बालाजी)',
    nameEn: 'Tirupati (Balaji)',
    stateOrCountry: 'आंध्र प्रदेश',
    latitude: 13.6288,
    longitude: 79.4192,
  ),

  // ── Maharashtra Major Cities ─────────────────────────────────────────────
  PanchangCity(
    id: 'pune',
    nameMr: 'पुणे',
    nameHi: 'पुणे',
    nameEn: 'Pune',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 18.5204,
    longitude: 73.8567,
  ),
  PanchangCity(
    id: 'mumbai',
    nameMr: 'मुंबई',
    nameHi: 'मुंबई',
    nameEn: 'Mumbai',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 19.0760,
    longitude: 72.8777,
  ),
  PanchangCity(
    id: 'nagpur',
    nameMr: 'नागपूर',
    nameHi: 'नागपुर',
    nameEn: 'Nagpur',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 21.1458,
    longitude: 79.0882,
  ),
  PanchangCity(
    id: 'sambhajinagar',
    nameMr: 'छत्रपती संभाजीनगर',
    nameHi: 'छत्रपति संभाजीनगर',
    nameEn: 'Chh. Sambhajinagar',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 19.8762,
    longitude: 75.3433,
  ),
  PanchangCity(
    id: 'thane',
    nameMr: 'ठाणे',
    nameHi: 'ठाणे',
    nameEn: 'Thane',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 19.2183,
    longitude: 72.9781,
  ),
  PanchangCity(
    id: 'solapur',
    nameMr: 'सोलापूर',
    nameHi: 'सोलापुर',
    nameEn: 'Solapur',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 17.6599,
    longitude: 75.9064,
  ),
  PanchangCity(
    id: 'satara',
    nameMr: 'सातारा',
    nameHi: 'सतारा',
    nameEn: 'Satara',
    stateOrCountry: 'महाराष्ट्र',
    latitude: 17.6805,
    longitude: 73.9997,
  ),

  // ── National Metros & Capitals ───────────────────────────────────────────
  PanchangCity(
    id: 'delhi',
    nameMr: 'नवी दिल्ली',
    nameHi: 'नई दिल्ली',
    nameEn: 'New Delhi',
    stateOrCountry: 'दिल्ली NCR',
    latitude: 28.6139,
    longitude: 77.2090,
  ),
  PanchangCity(
    id: 'bengaluru',
    nameMr: 'बंगळूरू',
    nameHi: 'बेंगलुरु',
    nameEn: 'Bengaluru',
    stateOrCountry: 'कर्नाटक',
    latitude: 12.9716,
    longitude: 77.5946,
  ),
  PanchangCity(
    id: 'hyderabad',
    nameMr: 'हैदराबाद',
    nameHi: 'हैदराबाद',
    nameEn: 'Hyderabad',
    stateOrCountry: 'तेलंगणा',
    latitude: 17.3850,
    longitude: 78.4867,
  ),
  PanchangCity(
    id: 'ahmedabad',
    nameMr: 'अहमदाबाद',
    nameHi: 'अहमदाबाद',
    nameEn: 'Ahmedabad',
    stateOrCountry: 'गुजरात',
    latitude: 23.0225,
    longitude: 72.5714,
  ),
  PanchangCity(
    id: 'kolkata',
    nameMr: 'कोलकाता',
    nameHi: 'कोलकाता',
    nameEn: 'Kolkata',
    stateOrCountry: 'पश्चिम बंगाल',
    latitude: 22.5726,
    longitude: 88.3639,
  ),
  PanchangCity(
    id: 'chennai',
    nameMr: 'चेन्नई',
    nameHi: 'चेन्नई',
    nameEn: 'Chennai',
    stateOrCountry: 'तामिळनाडू',
    latitude: 13.0827,
    longitude: 80.2707,
  ),
  PanchangCity(
    id: 'jaipur',
    nameMr: 'जयपूर',
    nameHi: 'जयपुर',
    nameEn: 'Jaipur',
    stateOrCountry: 'राजस्थान',
    latitude: 26.9124,
    longitude: 75.7873,
  ),
  PanchangCity(
    id: 'lucknow',
    nameMr: 'लखनौ',
    nameHi: 'लखनऊ',
    nameEn: 'Lucknow',
    stateOrCountry: 'उत्तर प्रदेश',
    latitude: 26.8467,
    longitude: 80.9462,
  ),
  PanchangCity(
    id: 'indore',
    nameMr: 'इंदूर',
    nameHi: 'इंदौर',
    nameEn: 'Indore',
    stateOrCountry: 'मध्य प्रदेश',
    latitude: 22.7196,
    longitude: 75.8577,
  ),

  // ── Global International Cities ──────────────────────────────────────────
  PanchangCity(
    id: 'dubai',
    nameMr: 'दुबई (UAE)',
    nameHi: 'दुबई (UAE)',
    nameEn: 'Dubai (UAE)',
    stateOrCountry: 'संयुक्त अरब अमिराती',
    latitude: 25.2048,
    longitude: 55.2708,
    timezoneOffsetHours: 4.0,
  ),
  PanchangCity(
    id: 'london',
    nameMr: 'लंडन (UK)',
    nameHi: 'लंदन (UK)',
    nameEn: 'London (UK)',
    stateOrCountry: 'युनायटेड किंगडम',
    latitude: 51.5074,
    longitude: -0.1278,
    timezoneOffsetHours: 1.0,
  ),
  PanchangCity(
    id: 'new_york',
    nameMr: 'न्यूयॉर्क (USA)',
    nameHi: 'न्यूयॉर्क (USA)',
    nameEn: 'New York (USA)',
    stateOrCountry: 'युनायटेड स्टेट्स',
    latitude: 40.7128,
    longitude: -74.0060,
    timezoneOffsetHours: -4.0,
  ),
  PanchangCity(
    id: 'san_francisco',
    nameMr: 'सॅन फ्रान्सिस्को (USA)',
    nameHi: 'सैन फ्रांसिस्को (USA)',
    nameEn: 'San Francisco (USA)',
    stateOrCountry: 'युनायटेड स्टेट्स',
    latitude: 37.7749,
    longitude: -122.4194,
    timezoneOffsetHours: -7.0,
  ),
  PanchangCity(
    id: 'singapore',
    nameMr: 'सिंगापूर',
    nameHi: 'सिंगापुर',
    nameEn: 'Singapore',
    stateOrCountry: 'सिंगापूर',
    latitude: 1.3521,
    longitude: 103.8198,
    timezoneOffsetHours: 8.0,
  ),
  PanchangCity(
    id: 'sydney',
    nameMr: 'सिडनी (ऑस्ट्रेलिया)',
    nameHi: 'सिडनी (ऑस्ट्रेलिया)',
    nameEn: 'Sydney (Australia)',
    stateOrCountry: 'ऑस्ट्रेलिया',
    latitude: -33.8688,
    longitude: 151.2093,
    timezoneOffsetHours: 10.0,
  ),
];

const PanchangCity kDefaultCity = PanchangCity(
  id: 'pune',
  nameMr: 'पुणे',
  nameHi: 'पुणे',
  nameEn: 'Pune',
  stateOrCountry: 'महाराष्ट्र',
  latitude: 18.5204,
  longitude: 73.8567,
);
