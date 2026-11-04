/// Localised copy for the Panchang Calendar screens.
class CalendarStrings {
  const CalendarStrings(this.lang);
  final String lang;

  String _t(String mr, String hi, String en) =>
      lang == 'en' ? en : (lang == 'hi' ? hi : mr);

  String get title => _t('पंचांग कॅलेंडर', 'पंचांग कैलेंडर', 'Panchang Calendar');
  String get subtitle => _t('तिथी, सण व शुभ मुहूर्त', 'तिथि, त्योहार व शुभ मुहूर्त', 'Tithi, Festivals & Muhurta');
  String get today => _t('आज', 'आज', 'Today');
  String get rahuKaal => _t('राहु काळ', 'राहु काल', 'Rahu Kaal');
  String get gulikaKaal => _t('गुलिक काळ', 'गुलिक काल', 'Gulika Kaal');
  String get yamaganda => _t('यमगंड', 'यमगंड', 'Yamaganda');
  String get nakshatra => _t('नक्षत्र', 'नक्षत्र', 'Nakshatra');
  String get yoga => _t('योग', 'योग', 'Yoga');
  String get karana => _t('करण', 'करण', 'Karana');
  String get tithi => _t('तिथी', 'तिथि', 'Tithi');
  String get sunrise => _t('सूर्योदय', 'सूर्योदय', 'Sunrise');
  String get sunset => _t('सूर्यास्त', 'सूर्यास्त', 'Sunset');
  String get festivals => _t('सण व व्रत', 'त्योहार व व्रत', 'Festivals & Vrats');
  String get noFestivals => _t('आज कोणताही सण नाही', 'आज कोई त्योहार नहीं', 'No festivals today');
  String get paksha => _t('पक्ष', 'पक्ष', 'Paksha');
  String get shuklaPaksha => _t('शुक्ल पक्ष', 'शुक्ल पक्ष', 'Shukla Paksha');
  String get krishnaPaksha => _t('कृष्ण पक्ष', 'कृष्ण पक्ष', 'Krishna Paksha');
  String get loading => _t('कॅलेंडर लोड होत आहे...', 'कैलेंडर लोड हो रहा है...', 'Loading calendar...');
  String get monthFestivals => _t('या महिन्यातील सण', 'इस महीने के त्योहार', 'Festivals this month');
  String get noMonthFestivals => _t('या महिन्यात कोणताही सण नाही', 'इस महीने कोई त्योहार नहीं', 'No festivals this month');
  String get tithiEnd => _t('तिथी समाप्ती', 'तिथि समाप्ति', 'Tithi ends');
  String get details => _t('दिवसाचे पंचांग', 'दिन का पंचांग', 'Day Panchang');
  String get close => _t('बंद करा', 'बंद करें', 'Close');

  List<String> get weekdays => lang == 'en'
      ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      : lang == 'hi'
          ? ['रवि', 'सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि']
          : ['रवि', 'सोम', 'मंगळ', 'बुध', 'गुरु', 'शुक्र', 'शनि'];

  List<String> get monthNames => lang == 'en'
      ? ['January','February','March','April','May','June','July','August','September','October','November','December']
      : lang == 'hi'
          ? ['जनवरी','फ़रवरी','मार्च','अप्रैल','मई','जून','जुलाई','अगस्त','सितंबर','अक्टूबर','नवंबर','दिसंबर']
          : ['जानेवारी','फेब्रुवारी','मार्च','एप्रिल','मे','जून','जुलै','ऑगस्ट','सप्टेंबर','ऑक्टोबर','नोव्हेंबर','डिसेंबर'];

  List<String> get dayNames => lang == 'en'
      ? ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
      : lang == 'hi'
          ? ['रविवार','सोमवार','मंगलवार','बुधवार','गुरुवार','शुक्रवार','शनिवार']
          : ['रविवार','सोमवार','मंगळवार','बुधवार','गुरुवार','शुक्रवार','शनिवार'];
}

