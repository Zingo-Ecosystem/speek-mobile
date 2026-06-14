import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// The Speek wordmark with optional gradient.
class Wordmark extends StatelessWidget {
  final double fontSize;
  final bool gradient;
  const Wordmark({super.key, this.fontSize = 30, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      'Speek',
      style: AppText.displayLg.copyWith(fontSize: fontSize, color: Colors.white),
    );
    if (!gradient) return text;
    return ShaderMask(
      shaderCallback: (r) => AppColors.grad.createShader(r),
      child: text,
    );
  }
}

/// Speek logo mark — a rounded tile with a speaking-globe glyph.
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 74});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.grad,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand500.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Icon(Icons.graphic_eq_rounded,
          size: size * 0.5, color: Colors.white.withValues(alpha: 0.95)),
    );
  }
}

/// Gamification badge tile.
class BadgeTile extends StatelessWidget {
  final String emoji;
  final String label;
  final int color;
  final bool locked;
  const BadgeTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: locked
              ? Colors.white.withValues(alpha: 0.1)
              : Color.alphaBlend(c.withValues(alpha: 0.5), AppColors.n700),
          width: 1.5,
        ),
        boxShadow: locked
            ? null
            : [BoxShadow(color: c.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Opacity(
        opacity: locked ? 0.42 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
