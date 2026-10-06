import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/voice/intent_parser.dart';
import '../core/voice/voice_service.dart';
import 'common.dart';

VoiceService get voice => VoiceService.instance;

/// "🔊 Suno" — reads [text] aloud. Every screen with important info has one.
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.text, this.label = 'Suno', this.compact = false, this.dark = false});

  final String text;
  final String label;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) {
        final speakingThis = voice.isSpeaking && voice.caption == text;
        final bg = dark ? AppColors.charcoal : AppColors.yellow;
        final fg = dark ? AppColors.yellow : AppColors.charcoal;
        return Semantics(
          button: true,
          label: speakingThis ? 'Rokein' : '$label — sunne ke liye dabayein',
          excludeSemantics: true,
          child: Material(
            color: bg,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => speakingThis ? voice.stopSpeaking() : voice.speak(text),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 8 : 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(speakingThis ? Icons.stop_rounded : Icons.volume_up_rounded, color: fg, size: compact ? 22 : 26),
                    if (!compact || label.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(speakingThis ? 'Roko' : label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: compact ? 15 : 17)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Big round microphone with pulse rings when listening/speaking.
class MicButton extends StatefulWidget {
  const MicButton({super.key, required this.onTap, this.size = 150, this.label, this.active = false, this.icon});

  final VoidCallback onTap;
  final double size;
  final String? label;
  final bool active;
  final IconData? icon;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(MicButton old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      button: true,
      label: widget.label ?? 'Bolne ke liye dabayein',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: s * 1.45,
          height: s * 1.45,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 2; i++)
                    if (widget.active)
                      Builder(builder: (_) {
                        final t = (_c.value + i * 0.5) % 1.0;
                        return Container(
                          width: s * (1 + 0.45 * t),
                          height: s * (1 + 0.45 * t),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.yellow.withValues(alpha: 0.35 * (1 - t)),
                          ),
                        );
                      }),
                  if (!widget.active)
                    Container(
                      width: s * 1.18,
                      height: s * 1.18,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.yellow.withValues(alpha: 0.22)),
                    ),
                  child!,
                ],
              );
            },
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow,
                border: Border.all(color: AppColors.charcoal, width: 4),
                boxShadow: [BoxShadow(color: AppColors.orange.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon ?? Icons.mic_rounded, size: s * 0.38, color: AppColors.charcoal),
                  if (widget.label != null)
                    Text(widget.label!, style: TextStyle(fontSize: s * 0.13, fontWeight: FontWeight.w900, color: AppColors.charcoal, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated bars driven by mic level (listening) or a gentle loop (speaking).
class VoiceWaveform extends StatefulWidget {
  const VoiceWaveform({super.key, this.color = AppColors.charcoal, this.height = 48, this.bars = 21});
  final Color color;
  final double height;
  final int bars;

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, voice]),
      builder: (context, _) {
        final lvl = voice.isListening ? math.max(0.25, voice.level) : 0.55;
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.bars, (i) {
              final phase = _c.value * 2 * math.pi + i * 0.55;
              final center = 1 - (i - widget.bars / 2).abs() / (widget.bars / 2);
              final h = (0.18 + 0.82 * lvl * (0.5 + 0.5 * math.sin(phase)) * (0.45 + 0.55 * center)).clamp(0.12, 1.0);
              return Container(
                width: 5,
                height: widget.height * h,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(4)),
              );
            }),
          ),
        );
      },
    );
  }
}

/// "🔊 Bolkar batayein" — inline voice input used in onboarding/forms.
/// Calls [onResult] with the recognised text. Shows every voice state.
class VoiceInputBar extends StatefulWidget {
  const VoiceInputBar({super.key, required this.onResult, this.prompt = 'Bolkar batayein', this.example});

  final ValueChanged<String> onResult;
  final String prompt;
  final String? example;

  @override
  State<VoiceInputBar> createState() => _VoiceInputBarState();
}

class _VoiceInputBarState extends State<VoiceInputBar> {
  bool _mine = false;

  Future<void> _start() async {
    setState(() => _mine = true);
    final text = await voice.listen();
    if (!mounted) return;
    if (text != null) {
      voice.setStatus(VoiceStatus.idle);
      widget.onResult(text);
    } else if (voice.status == VoiceStatus.error) {
      voice.speak('Samajh nahi aaya. Dobara boliye.');
    }
  }

  Future<void> _type() async {
    final text = await showTypeInputDialog(context, hint: widget.example ?? widget.prompt);
    if (text != null && text.trim().isNotEmpty) widget.onResult(text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) {
        final st = _mine ? voice.status : VoiceStatus.idle;
        final listening = st == VoiceStatus.listening;
        final (String title, String? sub, Color bg) = switch (st) {
          VoiceStatus.listening => ('Main sun raha hoon…', voice.transcript.isEmpty ? widget.example : '“${voice.transcript}”', AppColors.yellow),
          VoiceStatus.processing => ('Samajh raha hoon…', voice.transcript, AppColors.yellowTint),
          VoiceStatus.error => ('Samajh nahi aaya', 'Dobara boliye — thoda dheere', AppColors.redTint),
          VoiceStatus.permissionDenied => ('Mic ki permission chahiye', 'Settings mein microphone allow karein', AppColors.redTint),
          VoiceStatus.unavailable => ('Is phone par voice nahi chal raha', 'Button dabakar chunein', AppColors.orangeTint),
          _ => ('🔊 ${widget.prompt}', widget.example == null ? null : 'Jaise: “${widget.example}”', AppColors.charcoal),
        };
        final dark = bg == AppColors.charcoal;
        return Row(
          children: [
            Expanded(
              child: Material(
                color: bg,
                borderRadius: BorderRadius.circular(Radii.l),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.l),
                  onTap: listening ? voice.stopListening : _start,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: dark ? AppColors.yellow : AppColors.charcoal, shape: BoxShape.circle),
                          child: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded, color: dark ? AppColors.charcoal : AppColors.yellow, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: dark ? AppColors.white : AppColors.charcoal)),
                              if (listening) const Padding(padding: EdgeInsets.only(top: 4), child: VoiceWaveform(height: 22, bars: 15))
                              else if (sub != null && sub.isNotEmpty)
                                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: dark ? AppColors.yellowSoft : AppColors.charcoalSoft)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Likh kar batayein',
              child: IconButton.outlined(
                onPressed: _type,
                iconSize: 26,
                style: IconButton.styleFrom(minimumSize: const Size(56, 56), side: const BorderSide(color: AppColors.border, width: 2)),
                icon: const Icon(Icons.keyboard_rounded),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fallback text entry for voice (also helps on emulators without STT).
Future<String?> showTypeInputDialog(BuildContext context, {String hint = 'Yahan likhein'}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Likh kar batayein', style: TextStyle(fontWeight: FontWeight.w800)),
      content: TextField(
        controller: c,
        autofocus: true,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Wapas')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('Theek hai'),
        ),
      ],
    ),
  );
}

/// Sensitive-action confirmation (job accept, leave, absence, payment).
/// Speaks [speech], offers big Haan / Nahi, and also accepts a spoken
/// "haan" / "nahi". Returns true only on explicit yes.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String speech,
  String emoji = '❓',
  String yesLabel = 'Haan',
  String noLabel = 'Nahi',
  bool danger = false,
  Widget? details,
}) async {
  voice.speak(speech);
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ConfirmSheet(
      title: title,
      speech: speech,
      emoji: emoji,
      yesLabel: yesLabel,
      noLabel: noLabel,
      danger: danger,
      details: details,
    ),
  );
  await voice.stopSpeaking();
  return r ?? false;
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({
    required this.title,
    required this.speech,
    required this.emoji,
    required this.yesLabel,
    required this.noLabel,
    required this.danger,
    this.details,
  });

  final String title;
  final String speech;
  final String emoji;
  final String yesLabel;
  final String noLabel;
  final bool danger;
  final Widget? details;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  String? _hint;

  Future<void> _listen() async {
    setState(() => _hint = null);
    final text = await voice.listen(listenFor: const Duration(seconds: 6));
    if (!mounted) return;
    voice.setStatus(VoiceStatus.idle);
    final yn = text == null ? null : IntentParser.parseYesNo(text);
    if (yn == null) {
      setState(() => _hint = 'Samajh nahi aaya. “Haan” ya “Nahi” boliye.');
      voice.speak('Samajh nahi aaya. Haan ya nahi boliye.');
      return;
    }
    Navigator.pop(context, yn);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: widget.danger ? AppColors.redTint : AppColors.yellowTint, shape: BoxShape.circle),
            child: Text(widget.emoji, style: const TextStyle(fontSize: 42)),
          ),
          const SizedBox(height: 14),
          Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
          const SizedBox(height: 8),
          Text(widget.speech, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, color: AppColors.charcoalSoft, fontWeight: FontWeight.w500)),
          if (widget.details != null) ...[const SizedBox(height: 14), widget.details!],
          const SizedBox(height: 10),
          SpeakButton(text: widget.speech, label: 'Dobara suno', compact: true, dark: true),
          const SizedBox(height: 18),
          KsButton(
            label: widget.yesLabel,
            icon: Icons.check_circle_rounded,
            kind: widget.danger ? KsButtonKind.danger : KsButtonKind.success,
            height: 68,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 12),
          KsButton(
            label: widget.noLabel,
            icon: Icons.close_rounded,
            kind: KsButtonKind.secondary,
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: 14),
          ListenableBuilder(
            listenable: voice,
            builder: (context, _) {
              final listening = voice.isListening;
              return TextButton.icon(
                onPressed: listening ? voice.stopListening : _listen,
                icon: Icon(listening ? Icons.graphic_eq_rounded : Icons.mic_rounded, size: 26),
                label: Text(listening ? 'Sun raha hoon… (Haan / Nahi)' : 'Ya bolkar jawab dein', style: const TextStyle(fontSize: 17)),
              );
            },
          ),
          if (_hint != null) Text(_hint!, style: const TextStyle(color: AppColors.redDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Live caption strip of what the app is saying (for noisy sites / low hearing).
class VoiceCaption extends StatelessWidget {
  const VoiceCaption({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) {
        if (!voice.isSpeaking || voice.caption == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.charcoal, borderRadius: BorderRadius.circular(Radii.m)),
          child: Row(
            children: [
              const SizedBox(width: 40, child: VoiceWaveform(color: AppColors.yellow, height: 22, bars: 5)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(voice.caption!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                onPressed: voice.stopSpeaking,
                tooltip: 'Roko',
                icon: const Icon(Icons.stop_circle_rounded, color: AppColors.yellow, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }
}
