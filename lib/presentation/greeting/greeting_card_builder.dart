import '../../data/datasources/greeting_content.dart';
import '../../domain/entities/greeting_card.dart';
import '../../domain/logic/greeting_card_logic.dart';

/// Builds today's card: the weekday's deity (or the user's choice) with a
/// greeting. Works offline and needs no input from the user.
class GreetingCardBuilder {
  static GreetingCardData build({
    required DateTime now,
    required String lang,
    String? deityOverride,
    GreetingChoice greeting = GreetingChoice.morning,
    String? senderName,
    int? photoStamp,
    String? emojis,
    CardStyle style = CardStyle.templeArch,
    bool isPremium = false,
  }) {
    final day = GreetingCardLogic.cardDay(now);
    final deity = GreetingContent.deity(deityOverride ?? GreetingCardLogic.weekdayDeity(day, lang));
    final morningTitle = GreetingContent.morningGreeting[lang] ?? GreetingContent.morningGreeting['mr']!;
    final defaultBrand = GreetingContent.brand[lang] ?? GreetingContent.brand['mr']!;

    return GreetingCardData(
      style: style,
      template: GreetingCardLogic.templateForDeity(deity.id),
      lang: lang,
      deityId: deity.id,
      title: switch (greeting) {
        GreetingChoice.morning => morningTitle,
        GreetingChoice.jaykar => deity.localizedJaykar(lang),
        GreetingChoice.alt => GreetingContent.altGreeting[lang] ?? GreetingContent.altGreeting['mr']!,
      },
      jaykar: greeting == GreetingChoice.jaykar ? morningTitle : deity.localizedJaykar(lang),
      senderName: senderName == null ? null : GreetingCardLogic.sanitizeName(senderName),
      photoStamp: photoStamp,
      emojis: emojis == null ? null : GreetingCardLogic.sanitizeEmojis(emojis),
      brand: isPremium ? '' : defaultBrand,
      isPremium: isPremium,
    );
  }
}
