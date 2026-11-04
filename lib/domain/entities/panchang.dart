/// Domain entities representing Vedic Panchang (पंचांग - पञ्च अङ्गानि).
class PanchangData {
  final DateTime date;
  final String cityName;
  final String formattedDate;
  final String dayName;
  final String vikramSamvat;
  final String shakaSamvat;
  final String samvatsara;
  final String ayana;
  final String ritu;
  final String maas;
  final String paksha;

  // 5 Sacred Limbs (पञ्च-अङ्ग)
  final String tithi;
  final String tithiEndTime;
  final String vaar;
  final String vaarGraha;
  final String nakshatra;
  final String nakshatraEndTime;
  final String yoga;
  final String yogaEndTime;
  final String karana;
  final String karanaEndTime;

  // Surya & Chandra Timings
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String suryaRashi;
  final String chandraRashi;

  // Shubh Muhurat (शुभ मुहूर्त)
  final String abhijitMuhurat;
  final String amritKaal;
  final String brahmaMuhurat;
  final String vijayaMuhurat;
  final String godhuliMuhurat;

  // Ashubh Kaal (अशुभ काळ - Avoid)
  final String rahuKaal;
  final String yamaganda;
  final String gulikaKaal;
  final String durmuhurat;
  final String bhadra;

  // Today's Festival, Vrat & Guidance
  final String festivalName;
  final String vrat;
  final String festivalDescription;
  final String dailyMantra;
  final String specialGuidance;

  final bool isAiGenerated;

  const PanchangData({
    required this.date,
    this.cityName = 'पुणे',
    required this.formattedDate,
    required this.dayName,
    required this.vikramSamvat,
    required this.shakaSamvat,
    required this.samvatsara,
    required this.ayana,
    required this.ritu,
    required this.maas,
    required this.paksha,
    required this.tithi,
    required this.tithiEndTime,
    required this.vaar,
    required this.vaarGraha,
    required this.nakshatra,
    required this.nakshatraEndTime,
    required this.yoga,
    required this.yogaEndTime,
    required this.karana,
    required this.karanaEndTime,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.suryaRashi,
    required this.chandraRashi,
    required this.abhijitMuhurat,
    required this.amritKaal,
    required this.brahmaMuhurat,
    required this.vijayaMuhurat,
    required this.godhuliMuhurat,
    required this.rahuKaal,
    required this.yamaganda,
    required this.gulikaKaal,
    required this.durmuhurat,
    required this.bhadra,
    required this.festivalName,
    required this.vrat,
    required this.festivalDescription,
    required this.dailyMantra,
    required this.specialGuidance,
    this.isAiGenerated = false,
  });

  PanchangData copyWith({
    String? vikramSamvat,
    String? shakaSamvat,
    String? maas,
    String? paksha,
    String? tithi,
    String? tithiEndTime,
    String? karana,
    String? karanaEndTime,
    String? sunrise,
    String? sunset,
    String? abhijitMuhurat,
    String? brahmaMuhurat,
    String? vijayaMuhurat,
    String? godhuliMuhurat,
    String? rahuKaal,
    String? yamaganda,
    String? gulikaKaal,
    String? durmuhurat,
    String? bhadra,
    String? festivalName,
  }) {
    return PanchangData(
      date: date,
      cityName: cityName,
      formattedDate: formattedDate,
      dayName: dayName,
      vikramSamvat: vikramSamvat ?? this.vikramSamvat,
      shakaSamvat: shakaSamvat ?? this.shakaSamvat,
      samvatsara: samvatsara,
      ayana: ayana,
      ritu: ritu,
      maas: maas ?? this.maas,
      paksha: paksha ?? this.paksha,
      tithi: tithi ?? this.tithi,
      tithiEndTime: tithiEndTime ?? this.tithiEndTime,
      vaar: vaar,
      vaarGraha: vaarGraha,
      nakshatra: nakshatra,
      nakshatraEndTime: nakshatraEndTime,
      yoga: yoga,
      yogaEndTime: yogaEndTime,
      karana: karana ?? this.karana,
      karanaEndTime: karanaEndTime ?? this.karanaEndTime,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      moonrise: moonrise,
      moonset: moonset,
      suryaRashi: suryaRashi,
      chandraRashi: chandraRashi,
      abhijitMuhurat: abhijitMuhurat ?? this.abhijitMuhurat,
      amritKaal: amritKaal,
      brahmaMuhurat: brahmaMuhurat ?? this.brahmaMuhurat,
      vijayaMuhurat: vijayaMuhurat ?? this.vijayaMuhurat,
      godhuliMuhurat: godhuliMuhurat ?? this.godhuliMuhurat,
      rahuKaal: rahuKaal ?? this.rahuKaal,
      yamaganda: yamaganda ?? this.yamaganda,
      gulikaKaal: gulikaKaal ?? this.gulikaKaal,
      durmuhurat: durmuhurat ?? this.durmuhurat,
      bhadra: bhadra ?? this.bhadra,
      festivalName: festivalName ?? this.festivalName,
      vrat: vrat,
      festivalDescription: festivalDescription,
      dailyMantra: dailyMantra,
      specialGuidance: specialGuidance,
      isAiGenerated: isAiGenerated,
    );
  }

  factory PanchangData.fromJson(
    Map<String, dynamic> json, {
    required DateTime date,
    String cityName = 'पुणे',
    bool isAiGenerated = true,
  }) {
    return PanchangData(
      date: date,
      cityName: json['cityName']?.toString() ?? cityName,
      formattedDate: json['formattedDate']?.toString() ?? '',
      dayName: json['dayName']?.toString() ?? '',
      vikramSamvat: json['vikramSamvat']?.toString() ?? '२०८३',
      shakaSamvat: json['shakaSamvat']?.toString() ?? '१९४८',
      samvatsara: json['samvatsara']?.toString() ?? 'कालयुक्त',
      ayana: json['ayana']?.toString() ?? 'दक्षिणायन',
      ritu: json['ritu']?.toString() ?? 'शरद',
      maas: json['maas']?.toString() ?? '',
      paksha: json['paksha']?.toString() ?? '',
      tithi: json['tithi']?.toString() ?? '',
      tithiEndTime: json['tithiEndTime']?.toString() ?? '',
      vaar: json['vaar']?.toString() ?? '',
      vaarGraha: json['vaarGraha']?.toString() ?? '',
      nakshatra: json['nakshatra']?.toString() ?? '',
      nakshatraEndTime: json['nakshatraEndTime']?.toString() ?? '',
      yoga: json['yoga']?.toString() ?? '',
      yogaEndTime: json['yogaEndTime']?.toString() ?? '',
      karana: json['karana']?.toString() ?? '',
      karanaEndTime: json['karanaEndTime']?.toString() ?? '',
      sunrise: json['sunrise']?.toString() ?? '०६:१२ AM',
      sunset: json['sunset']?.toString() ?? '०६:२२ PM',
      moonrise: json['moonrise']?.toString() ?? '०५:३० PM',
      moonset: json['moonset']?.toString() ?? '०५:०८ AM',
      suryaRashi: json['suryaRashi']?.toString() ?? '',
      chandraRashi: json['chandraRashi']?.toString() ?? '',
      abhijitMuhurat: json['abhijitMuhurat']?.toString() ?? '११:४८ AM - १२:३६ PM',
      amritKaal: json['amritKaal']?.toString() ?? '०६:१५ AM - ०७:४५ AM',
      brahmaMuhurat: json['brahmaMuhurat']?.toString() ?? '०४:३५ AM - ०५:२३ AM',
      vijayaMuhurat: json['vijayaMuhurat']?.toString() ?? '०२:१२ PM - ०३:०० PM',
      godhuliMuhurat: json['godhuliMuhurat']?.toString() ?? '०६:१० PM - ०६:३५ PM',
      rahuKaal: json['rahuKaal']?.toString() ?? '१०:३० AM - १२:०० PM',
      yamaganda: json['yamaganda']?.toString() ?? '०३:०० PM - ०४:३० PM',
      gulikaKaal: json['gulikaKaal']?.toString() ?? '०७:३० AM - ०९:०० AM',
      durmuhurat: json['durmuhurat']?.toString() ?? '०८:३५ AM - ०९:२४ AM',
      bhadra: json['bhadra']?.toString() ?? 'नाही',
      festivalName: json['festivalName']?.toString() ?? '',
      vrat: json['vrat']?.toString() ?? '',
      festivalDescription: json['festivalDescription']?.toString() ?? '',
      dailyMantra: json['dailyMantra']?.toString() ?? 'ॐ नमो नारायणाय',
      specialGuidance: json['specialGuidance']?.toString() ?? '',
      isAiGenerated: isAiGenerated,
    );
  }
}
