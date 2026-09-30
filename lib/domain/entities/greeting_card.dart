/// Which greeting headlines the card: "शुभ सकाळ", the deity's jaykar, or the
/// alternate greeting.
enum GreetingChoice { morning, jaykar, alt }

enum CardTemplate { sandalGold, templeDusk, marigold, tulsiGreen, royalBlue }

/// Card layout. Colours still come from the deity's [CardTemplate].
enum CardStyle { templeArch, suryoday, darshan, poojaThali, rangoli, kamal, rajwada, om }

/// Everything needed to draw the daily card. Built fresh each day; never
/// persisted and never sent to the server.
class GreetingCardData {
  final CardStyle style;
  final CardTemplate template;
  final String lang;
  final String deityId;
  final String title;
  final String jaykar;
  final String? senderName;

  /// Version of the sender's saved photo; null when the card has no photo.
  final int? photoStamp;

  /// Emoji row at the very bottom of the card.
  final String? emojis;
  final String brand;

  /// Whether user has active premium or trial (watermark removed when true).
  final bool isPremium;

  const GreetingCardData({
    this.style = CardStyle.templeArch,
    required this.template,
    required this.lang,
    required this.deityId,
    required this.title,
    required this.jaykar,
    required this.brand,
    this.senderName,
    this.photoStamp,
    this.emojis,
    this.isPremium = false,
  });

  GreetingCardData withStyle(CardStyle style) => GreetingCardData(
        style: style,
        template: template,
        lang: lang,
        deityId: deityId,
        title: title,
        jaykar: jaykar,
        brand: brand,
        senderName: senderName,
        photoStamp: photoStamp,
        emojis: emojis,
        isPremium: isPremium,
      );

  /// Identifies the rendered image so the same card is never drawn twice.
  String get cacheKey => [
        style.name,
        template.name,
        lang,
        deityId,
        title,
        jaykar,
        senderName ?? '',
        photoStamp ?? '',
        emojis ?? '',
        isPremium ? 'prem' : 'free',
      ].join('§');
}
