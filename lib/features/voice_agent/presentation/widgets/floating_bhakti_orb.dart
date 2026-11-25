import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Floating AI Circle inspired by Meta AI / Siri / ChatGPT voice orb.
/// Displays an iridescent glowing ring with continuous fluid rotation.
class FloatingBhaktiOrb extends StatefulWidget {
  final VoidCallback onTap;

  const FloatingBhaktiOrb({super.key, required this.onTap});

  @override
  State<FloatingBhaktiOrb> createState() => _FloatingBhaktiOrbState();
}

class _FloatingBhaktiOrbState extends State<FloatingBhaktiOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bhakti AI Voice Assistant',
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            final angle = _rotationController.value * 2 * math.pi;
            return Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A00).withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating Iridescent Gradient Ring (Meta AI style)
                  Transform.rotate(
                    angle: angle,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFFFF9900), // Devotional Saffron
                            Color(0xFFE040FB), // Vibrant Purple
                            Color(0xFF00E5FF), // Cyan Blue
                            Color(0xFFFFD700), // Gold
                            Color(0xFFFF9900), // Saffron loop
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Inner Dark Glass Orb Center
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF3E1F12),
                          const Color(0xFF1A0B05).withValues(alpha: 0.95),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFFFD54F),
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
