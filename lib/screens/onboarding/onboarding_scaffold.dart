import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/widgets.dart';

/// Total numbered onboarding steps (Phone → Permissions).
const kOnboardingSteps = 11;

/// Shared layout for every onboarding question:
/// progress → big question → 🔊 → body → voice bar → sticky primary button.
class OnboardingScaffold extends StatefulWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.body,
    this.step,
    this.speech,
    this.subtitle,
    this.voiceBar,
    this.primaryLabel = 'Aage badhein',
    this.onPrimary,
    this.secondary,
    this.editMode = false,
    this.autoSpeak = true,
    this.scrollable = true,
  });

  final int? step;
  final String title;
  final String? speech;
  final String? subtitle;
  final Widget body;
  final Widget? voiceBar;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final Widget? secondary;
  final bool editMode;
  final bool autoSpeak;
  final bool scrollable;

  @override
  State<OnboardingScaffold> createState() => _OnboardingScaffoldState();
}

class _OnboardingScaffoldState extends State<OnboardingScaffold> {
  String get _speech => widget.speech ?? widget.title;

  @override
  void initState() {
    super.initState();
    if (widget.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) voice.speak(_speech);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.editMode ? null : widget.step;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
              ),
            ),
            const SizedBox(width: 10),
            SpeakButton(text: _speech, label: '', compact: true),
          ],
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(widget.subtitle!, style: const TextStyle(fontSize: 17, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: Space.xl),
        widget.body,
        if (widget.voiceBar != null) ...[
          const SizedBox(height: Space.xl),
          widget.voiceBar!,
        ],
        const SizedBox(height: Space.l),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 0,
        title: step == null
            ? (widget.editMode ? const Text('Profile badlein') : null)
            : Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: step / kOnboardingSteps,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$step / $kOnboardingSteps', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 16),
                ],
              ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: widget.scrollable
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: content,
                    )
                  : Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), child: content),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KsButton(
                    label: widget.editMode ? 'Save karein' : '${widget.primaryLabel}  →',
                    icon: widget.editMode ? Icons.check_rounded : null,
                    height: 68,
                    onPressed: widget.onPrimary,
                  ),
                  if (widget.secondary != null) ...[const SizedBox(height: 8), widget.secondary!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Persist profile then either pop (edit mode) or go to [next].
void finishStep(BuildContext context, {required bool editMode, required Widget Function() next}) {
  voice.stopSpeaking();
  if (editMode) {
    showSnack(context, 'Save ho gaya', icon: Icons.check_circle_rounded);
    Navigator.pop(context);
  } else {
    push(context, next());
  }
}

/// Large on-screen numeric keypad (no system keyboard needed).
class BigKeypad extends StatelessWidget {
  const BigKeypad({super.key, required this.onDigit, required this.onBackspace});
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Semantics(
              button: true,
              label: icon != null ? 'Mitayein' : label,
              excludeSemantics: true,
              child: Material(
                color: icon != null ? AppColors.yellowTint : AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.m),
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.m),
                  onTap: onTap,
                  child: SizedBox(
                    height: 64,
                    child: Center(
                      child: icon != null
                          ? Icon(icon, size: 30)
                          : Text(label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    Widget row(List<String> ds) => Row(children: [for (final d in ds) key(d, onTap: () => onDigit(d))]);

    return Column(
      children: [
        row(['1', '2', '3']),
        row(['4', '5', '6']),
        row(['7', '8', '9']),
        Row(children: [
          const Expanded(child: SizedBox()),
          key('0', onTap: () => onDigit('0')),
          key('', icon: Icons.backspace_rounded, onTap: onBackspace),
        ]),
      ],
    );
  }
}

/// Wrap of choice chips with big touch targets.
class BigChoiceChip extends StatelessWidget {
  const BigChoiceChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.yellow : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.m),
          side: BorderSide(color: selected ? AppColors.charcoal : AppColors.border, width: selected ? 2.5 : 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.m),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60, minWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[const Icon(Icons.check_circle_rounded, size: 22), const SizedBox(width: 6)],
                Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
