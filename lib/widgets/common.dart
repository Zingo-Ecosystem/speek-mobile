import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Scaffold whose background and default text color follow light/dark mode.
/// Used by "chrome" screens (profile, settings) so they adapt to the theme,
/// while immersive screens keep the fixed dark palette.
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final bool resizeToAvoidBottomInset;
  const AdaptiveScaffold(
      {super.key, required this.body, this.resizeToAvoidBottomInset = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sBg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: DefaultTextStyle.merge(
        style: TextStyle(color: AppColors.sText),
        child: body,
      ),
    );
  }
}

/// Shows a bottom sheet to pick one option from a list. Returns the choice.
Future<String?> pickOption(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7),
      decoration: const BoxDecoration(
        color: AppColors.n800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: AppText.h3)),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in options)
                    ListTile(
                      title: Text(o, style: AppText.body),
                      trailing: o == selected
                          ? const Icon(Icons.check, color: AppColors.brand400)
                          : null,
                      onTap: () => Navigator.of(sheetCtx).pop(o),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

/// Primary gradient button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool small;
  final Gradient gradient;
  final Color textColor;
  final List<BoxShadow>? shadow;

  const PrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.leading,
    this.small = false,
    this.gradient = AppColors.grad,
    this.textColor = Colors.white,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return _ButtonShell(
      onTap: onTap,
      small: small,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(small ? Radii.md : Radii.lg),
        boxShadow: shadow ??
            [
              BoxShadow(
                color: AppColors.brand500.withValues(alpha: 0.40),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: _content(textColor),
    );
  }

  Widget _content(Color color) {
    final style = (small ? AppText.label : AppText.body).copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: small ? 14 : 16,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Flexible(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// Secondary glassy button.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool small;
  final bool light; // white bg / dark bg variant
  final bool dark;

  const GhostButton(
    this.label, {
    super.key,
    this.onTap,
    this.leading,
    this.small = false,
    this.light = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = light
        ? Colors.white
        : dark
            ? Colors.black
            : Colors.white.withValues(alpha: 0.06);
    final fg = light ? const Color(0xFF111111) : Colors.white;
    final border = light
        ? null
        : Border.all(color: Colors.white.withValues(alpha: dark ? 0.15 : 0.12));
    return _ButtonShell(
      onTap: onTap,
      small: small,
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(small ? Radii.md : Radii.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: (small ? AppText.label : AppText.body).copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: small ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonShell extends StatelessWidget {
  final VoidCallback? onTap;
  final bool small;
  final BoxDecoration decoration;
  final Widget child;
  const _ButtonShell({
    required this.onTap,
    required this.small,
    required this.decoration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: decoration.borderRadius as BorderRadius?,
        child: Ink(
          height: small ? 46 : 54,
          width: double.infinity,
          decoration: decoration,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Soft brand pill (status / category).
class Pill extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;
  final Color? border;
  const Pill(this.text, {super.key, this.bg, this.fg, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: bg ?? AppColors.brand500.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(
            color: border ?? AppColors.brand500.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          color: fg ?? AppColors.brand200,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Gold "Premium" badge chip. Use to distinguish premium members.
class PremiumChip extends StatelessWidget {
  final bool small;
  const PremiumChip({super.key, this.small = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 11, vertical: small ? 4 : 6),
      decoration: BoxDecoration(
        gradient: AppColors.gradGold,
        borderRadius: BorderRadius.circular(Radii.pill),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF0A93B).withValues(alpha: 0.35),
              blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('👑', style: TextStyle(fontSize: small ? 11 : 13)),
          const SizedBox(width: 4),
          Text('Premium',
              style: AppText.caption.copyWith(
                  color: const Color(0xFF3A2600),
                  fontWeight: FontWeight.w800,
                  fontSize: small ? 10 : 12)),
        ],
      ),
    );
  }
}

/// Smaller chip used for interests / tags.
class Chip2 extends StatelessWidget {
  final String text;
  final bool active;
  final bool solid;
  const Chip2(this.text, {super.key, this.active = false, this.solid = false});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Border? border;
    if (solid) {
      bg = AppColors.brand500;
      fg = Colors.white;
      border = null;
    } else if (active) {
      bg = AppColors.brand500.withValues(alpha: 0.16);
      fg = AppColors.brand200;
      border = Border.all(color: AppColors.brand500.withValues(alpha: 0.4));
    } else {
      bg = Colors.white.withValues(alpha: 0.06);
      fg = AppColors.n100;
      border = Border.all(color: Colors.white.withValues(alpha: 0.1));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: solid ? null : bg,
        gradient: solid ? AppColors.grad : null,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: border,
      ),
      child: Text(text,
          style: AppText.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

/// Circular avatar. When [url] is empty (or fails to load), it falls back to a
/// branded gradient circle with the person's initials — so a user without a
/// photo still looks intentional, never broken.
class Avatar extends StatelessWidget {
  final String url;
  final double size;
  final bool online;
  final Color? ringColor;
  final double borderWidth;
  final Color? borderColor;
  final String? name; // used for initials fallback

  const Avatar(
    this.url, {
    super.key,
    this.size = 48,
    this.online = false,
    this.ringColor,
    this.borderWidth = 0,
    this.borderColor,
    this.name,
  });

  /// Deterministic gradient + initials from a name/seed.
  Widget _initials() {
    final seed = (name ?? '').trim();
    final letters = seed.isEmpty
        ? '🙂'
        : seed
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w.characters.first.toUpperCase())
            .join();
    // Pick a stable gradient from the seed.
    const palettes = [
      [Color(0xFF6C63FF), Color(0xFF9D7BFF)],
      [Color(0xFF3DD6E0), Color(0xFF6C63FF)],
      [Color(0xFFFF6FB5), Color(0xFFF0A93B)],
      [Color(0xFF45E07A), Color(0xFF3DD6E0)],
      [Color(0xFFFFB547), Color(0xFFFF6FB5)],
    ];
    final idx = seed.isEmpty ? 0 : seed.codeUnits.fold<int>(0, (a, b) => a + b) % palettes.length;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palettes[idx],
        ),
      ),
      child: Text(
        letters,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: borderWidth > 0
                  ? Border.all(
                      color: borderColor ?? Colors.white.withValues(alpha: 0.4),
                      width: borderWidth)
                  : null,
              boxShadow: ringColor != null
                  ? [BoxShadow(color: ringColor!.withValues(alpha: 0.35), blurRadius: 0, spreadRadius: 4)]
                  : null,
            ),
            child: ClipOval(
              child: hasUrl
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                      placeholder: (_, __) => _initials(),
                      errorWidget: (_, __, ___) => _initials(),
                    )
                  : _initials(),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.n900, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Square icon button (42x42) used in top bars.
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? bg;
  final double size;
  const SquareIconButton(this.icon,
      {super.key, this.onTap, this.bg, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg ?? Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// Radial brand glow used behind hero sections.
class BrandGlow extends StatelessWidget {
  final double opacity;
  const BrandGlow({super.key, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.7),
            radius: 0.9,
            colors: [
              AppColors.brand500.withValues(alpha: 0.35 * opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// Page dots indicator.
class Dots extends StatelessWidget {
  final int count;
  final int index;
  const Dots({super.key, required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: on ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: on ? AppColors.brand500 : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Card-style stat tile.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  const StatTile(this.value, this.label, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppText.h3.copyWith(
                  color: valueColor ?? AppColors.textPrimary, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.caption.copyWith(fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
