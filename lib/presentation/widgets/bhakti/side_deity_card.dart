import 'package:flutter/material.dart';

import '../../../domain/entities/bhakti_deity.dart';

/// Previous / next deity preview, tilted in perspective so it recedes behind the shrine.
class SideDeityCard extends StatelessWidget {
  final BhaktiDeity deity;
  final bool isLeft;
  final double width;
  final VoidCallback onTap;

  const SideDeityCard({
    super.key,
    required this.deity,
    required this.isLeft,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;
    final radius = BorderRadius.circular(width * 0.12);

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..rotateY(isLeft ? 0.9 : -0.9);

    return GestureDetector(
      onTap: onTap,
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFE2B04F), width: 2),
            gradient: const RadialGradient(
              center: Alignment(0, -0.3),
              radius: 0.9,
              colors: [Color(0xFF8A4414), Color(0xFF3A1408), Color(0xFF1C0703)],
              stops: [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: const Color(0xFFFFAA3C).withValues(alpha: 0.35),
                blurRadius: 18,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: height * 0.08, bottom: height * 0.03),
                  child: Image.asset(
                    deity.imageAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    cacheWidth: 360,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                      end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                        const Color(0xFFFFDC96).withValues(alpha: 0.18),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
