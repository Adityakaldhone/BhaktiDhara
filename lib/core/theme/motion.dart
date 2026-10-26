import 'package:flutter/animation.dart';

/// Shared motion tokens. UI motion stays under 300ms; never use an ease-in
/// curve on UI because it delays the moment the user is watching.
abstract final class AppMotion {
  /// Strong ease-out for entrances, exits and press feedback.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Strong ease-in-out for elements moving or morphing on screen.
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// CSS `ease`, for color and weight changes.
  static const Curve ease = Curves.ease;

  static const Duration press = Duration(milliseconds: 160);
  static const Duration state = Duration(milliseconds: 200);
  static const Duration entrance = Duration(milliseconds: 250);
  static const Duration stagger = Duration(milliseconds: 40);
}
