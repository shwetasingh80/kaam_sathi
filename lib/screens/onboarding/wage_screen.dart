import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../core/voice/intent_parser.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import 'location_screen.dart';
import 'onboarding_scaffold.dart';

class WageScreen extends StatefulWidget {
  const WageScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<WageScreen> createState() => _WageScreenState();
}

class _WageScreenState extends State<WageScreen> {
  static const _options = [500, 600, 700, 800, 900, 1000];
  late int _wage = AppScope.read(context).profile.dailyWage;

  void _set(int v, {bool speak = true}) {
    setState(() => _wage = v.clamp(200, 3000));
    if (speak) voice.speak('${Fmt.rupeesSpoken(_wage)} roz');
  }

  Future<void> _onVoice(String text) async {
    final w = IntentParser.parseWage(text);
    if (w == null) {
      voice.speak('Rakam samajh nahi aayi. Jaise boliye: aath sau rupaye.');
      showSnack(context, 'Samajh nahi aaya. Dobara boliye.', icon: Icons.hearing_disabled_rounded);
      return;
    }
    final ok = await confirmAction(
      context,
      emoji: '💰',
      title: '${Fmt.rupees(w)} roz',
      speech: 'Aapko ek din ke ${Fmt.rupeesSpoken(w)} chahiye. Sahi hai?',
      yesLabel: 'Haan',
      noLabel: 'Dobara Bolo',
    );
    if (ok) _set(w, speak: false);
  }

  void _next() {
    final s = AppScope.read(context);
    s.profile.dailyWage = _wage;
    s.saveProfile();
    finishStep(context, editMode: widget.editMode, next: () => const LocationScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 7,
      editMode: widget.editMode,
      title: 'Aapko ek din ka kitna paisa chahiye?',
      speech: 'Aapko ek din ka kitna paisa chahiye? Button dabaiye ya bolkar batayiye.',
      onPrimary: _next,
      body: Column(
        children: [
          KsCard(
            color: AppColors.yellowTint,
            borderColor: AppColors.yellow,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Row(
              children: [
                _RoundBtn(icon: Icons.remove_rounded, label: '₹50 kam', onTap: () => _set(_wage - 50)),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(child: Text(Fmt.rupees(_wage), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, height: 1.1))),
                      const Text('ek din', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.charcoalSoft)),
                    ],
                  ),
                ),
                _RoundBtn(icon: Icons.add_rounded, label: '₹50 zyada', onTap: () => _set(_wage + 50)),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final o in _options)
                BigChoiceChip(
                  label: o == 1000 ? '₹1000+' : '₹$o',
                  selected: o == 1000 ? _wage >= 1000 : _wage == o,
                  onTap: () => _set(o),
                ),
            ],
          ),
        ],
      ),
      voiceBar: VoiceInputBar(prompt: 'Bolkar batayein', example: 'Mujhe 800 rupaye roz chahiye', onResult: _onVoice),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.charcoal,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 64, height: 64, child: Icon(icon, color: AppColors.yellow, size: 36)),
        ),
      ),
    );
  }
}
