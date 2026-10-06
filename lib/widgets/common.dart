import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../data/app_state.dart';
import '../data/models.dart';

enum KsButtonKind { primary, secondary, dark, success, danger, ghost }

/// Large, full-width button. Always icon + text (never colour-only meaning).
class KsButton extends StatelessWidget {
  const KsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.emoji,
    this.kind = KsButtonKind.primary,
    this.subtitle,
    this.height = Space.tapTarget,
    this.expand = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? emoji;
  final KsButtonKind kind;
  final String? subtitle;
  final double height;
  final bool expand;
  final String? semanticLabel;

  ({Color bg, Color fg, Color? border}) get _colors => switch (kind) {
        KsButtonKind.primary => (bg: AppColors.yellow, fg: AppColors.charcoal, border: null),
        KsButtonKind.secondary => (bg: AppColors.white, fg: AppColors.charcoal, border: AppColors.charcoal),
        KsButtonKind.dark => (bg: AppColors.charcoal, fg: AppColors.white, border: null),
        KsButtonKind.success => (bg: AppColors.green, fg: AppColors.white, border: null),
        KsButtonKind.danger => (bg: AppColors.red, fg: AppColors.white, border: null),
        KsButtonKind.ghost => (bg: Colors.transparent, fg: AppColors.charcoal, border: null),
      };

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final disabled = onPressed == null;
    final bg = disabled ? AppColors.disabled : c.bg;
    final fg = disabled ? AppColors.muted : c.fg;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, color: fg, size: 26),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: fg, height: 1.15),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.85)),
                ),
            ],
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: semanticLabel != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.m),
            side: c.border == null || disabled ? BorderSide.none : BorderSide(color: c.border!, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Center(widthFactor: expand ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded card with a soft border.
class KsCard extends StatelessWidget {
  const KsCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.white,
    this.borderColor = AppColors.border,
    this.padding = const EdgeInsets.all(Space.l),
    this.radius = Radii.l,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Icon + text status pill (never colour alone).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.bg, required this.fg, this.icon, this.large = false});

  StatusPill.attendance(AttendanceStatus s, {super.key, this.large = false})
      : label = s.label,
        bg = s.bg,
        fg = s.fg,
        icon = s.icon;

  StatusPill.workerJob(WorkerJobStatus s, {super.key, this.large = false})
      : label = s.label,
        bg = s.bg,
        fg = s.fg,
        icon = s.icon;

  StatusPill.payment(PaymentStatus s, {super.key, this.large = false})
      : label = s.label,
        bg = s.bg,
        fg = s.fg,
        icon = s.icon;

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 8 : 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: large ? 20 : 16, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: large ? 16 : 14)),
          ),
        ],
      ),
    );
  }
}

/// "✓ Mobile Verified" style badge.
class TrustBadge extends StatelessWidget {
  const TrustBadge(this.label, {super.key, this.ok = true});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ok ? Icons.verified_rounded : Icons.help_outline_rounded, size: 20, color: ok ? AppColors.green : AppColors.muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ok ? AppColors.greenDark : AppColors.muted),
          ),
        ),
      ],
    );
  }
}

/// Q&A style row for job details: "Kitna paisa?" → "₹800 roz".
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.emoji, required this.question, required this.answer, this.sub, this.trailing});

  final String emoji;
  final String question;
  final String answer;
  final String? sub;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.yellowTint, borderRadius: BorderRadius.circular(16)),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question, style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
                Text(answer, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
                if (sub != null) Text(sub!, style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Large selectable card (skills, options, languages). Shows a check when selected.
class SelectTile extends StatelessWidget {
  const SelectTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.subtitle,
    this.badge,
    this.vertical = false,
    this.enabled = true,
  });

  final String title;
  final String? emoji;
  final String? subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;
  final bool vertical;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? AppColors.charcoal : AppColors.muted;
    final check = AnimatedScale(
      scale: selected ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.charcoal, shape: BoxShape.circle),
        padding: const EdgeInsets.all(3),
        child: const Icon(Icons.check_rounded, color: AppColors.yellow, size: 20),
      ),
    );
    final text = Column(
      crossAxisAlignment: vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: vertical ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: vertical ? 17 : 20, fontWeight: FontWeight.w800, color: fg, height: 1.15),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: vertical ? TextAlign.center : TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
      ],
    );
    return Semantics(
      selected: selected,
      button: true,
      label: title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.yellowTint : AppColors.white,
          borderRadius: BorderRadius.circular(Radii.l),
          border: Border.all(color: selected ? AppColors.yellow : AppColors.border, width: selected ? 3 : 1.5),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.l),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: EdgeInsets.all(vertical ? 12 : 16),
              child: vertical
                  ? Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (emoji != null)
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(emoji!, style: const TextStyle(fontSize: 40)),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Flexible(child: text),
                            ],
                          ),
                        ),
                        Positioned(top: 0, right: 0, child: check),
                        if (badge != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: StatusPill(label: badge!, bg: AppColors.charcoal, fg: AppColors.yellow),
                          ),
                      ],
                    )
                  : Row(
                      children: [
                        if (emoji != null) ...[
                          Text(emoji!, style: const TextStyle(fontSize: 34)),
                          const SizedBox(width: 14),
                        ],
                        Expanded(child: text),
                        if (badge != null) ...[
                          StatusPill(label: badge!, bg: AppColors.charcoal, fg: AppColors.yellow),
                          const SizedBox(width: 8),
                        ],
                        check,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two equal columns whose rows size to their tallest tile — unlike a
/// fixed-aspect GridView this never clips large text on small phones.
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({super.key, required this.children, this.spacing = 10});
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: spacing));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            SizedBox(width: spacing),
            Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(4, 20, 4, 10)});
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Friendly empty / error state (big emoji, short line, one action).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle, this.action, this.compact = false});
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? Space.l : Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 88 : 120,
            height: compact ? 88 : 120,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.yellowTint, shape: BoxShape.circle),
            child: Text(emoji, style: TextStyle(fontSize: compact ? 44 : 60)),
          ),
          const SizedBox(height: Space.l),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, color: AppColors.muted)),
          ],
          if (action != null) ...[const SizedBox(height: Space.xl), action!],
        ],
      ),
    );
  }
}

/// Shows only when offline. Calm wording, no technical errors.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: s.online
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              color: AppColors.charcoal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.yellow, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.pendingQueue.isEmpty
                          ? 'Internet nahi hai. Purani jaankari dikh rahi hai.'
                          : 'Internet nahi hai. ${s.pendingQueue.length} request baad mein jayenge.',
                      style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Worker photo or initials.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.photoPath, this.size = 56});
  final String name;
  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '🙂'
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.characters.first.toUpperCase()).join();
    ImageProvider? img;
    if (photoPath != null) {
      try {
        final f = File(photoPath!);
        if (f.existsSync()) img = FileImage(f);
      } catch (_) {}
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
        image: img == null ? null : DecorationImage(image: img, fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: img == null
          ? Text(initials, style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w900, color: AppColors.charcoal))
          : null,
    );
  }
}

class KsLogo extends StatelessWidget {
  const KsLogo({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'KaamSaathi logo',
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
        child: Text('👷', style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}

/// Animated success tick (job accepted / attendance / payment).
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, this.size = 140, this.color = AppColors.green});
  final double size;
  final Color color;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    return ScaleTransition(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 6)],
        ),
        child: Icon(Icons.check_rounded, color: AppColors.white, size: widget.size * 0.6),
      ),
    );
  }
}

/// Small helper for pushing screens.
Future<T?> push<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

Future<T?> pushReplacement<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).pushReplacement<T, void>(MaterialPageRoute(builder: (_) => screen));

void showSnack(BuildContext context, String text, {IconData icon = Icons.info_outline_rounded}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: AppColors.yellow),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ]),
    ));
}
