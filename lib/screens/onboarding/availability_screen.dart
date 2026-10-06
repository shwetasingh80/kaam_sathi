import 'package:flutter/material.dart';

import '../../core/voice/intent_parser.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'onboarding_scaffold.dart';
import 'permissions_screen.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late Availability _avail = AppScope.read(context).profile.availability;
  late ShiftPreference _shift = AppScope.read(context).profile.shift;

  void _onVoice(String text) {
    final s = IntentParser.normalize(text);
    final yn = IntentParser.parseYesNo(text);
    setState(() {
      if (s.contains('subah') || s.contains('सुबह')) _shift = ShiftPreference.morning;
      if (s.contains('shaam') || s.contains('शाम') || s.contains('dopahar') || s.contains('दोपहर')) _shift = ShiftPreference.evening;
      if (s.contains('poora') || s.contains('pura') || s.contains('पूरा')) _shift = ShiftPreference.fullDay;
      if (s.contains('koi bhi') || s.contains('कोई भी')) _shift = ShiftPreference.any;
      if (yn == false) {
        _avail = Availability.notAvailable;
      } else if (s.contains('taiyaar') || s.contains('तैयार') || s.contains('abhi') || yn == true) {
        _avail = Availability.available;
      }
    });
    voice.speak('${_avail.label}. ${_shift.label}.');
  }

  void _next() {
    final s = AppScope.read(context);
    s.profile
      ..availability = _avail
      ..shift = _shift;
    s.saveProfile();
    finishStep(context, editMode: widget.editMode, next: () => const PermissionsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 10,
      editMode: widget.editMode,
      title: 'Kya aap abhi kaam ke liye taiyaar hain?',
      speech: 'Kya aap abhi kaam ke liye taiyaar hain? Aur kis samay kaam karna pasand hai?',
      onPrimary: _next,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in Availability.values.where((a) => a != Availability.working || _avail == Availability.working))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SelectTile(
                emoji: a.emoji,
                title: a.label,
                selected: _avail == a,
                onTap: () {
                  setState(() => _avail = a);
                  voice.speak(a.label);
                },
              ),
            ),
          const SizedBox(height: 14),
          const Text('⏰ Kis samay kaam karenge?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TwoColumnGrid(
            children: [
              for (final sp in ShiftPreference.values)
                SelectTile(
                  vertical: true,
                  emoji: sp.emoji,
                  title: sp.label,
                  subtitle: sp.hint,
                  selected: _shift == sp,
                  onTap: () {
                    setState(() => _shift = sp);
                    voice.speak(sp.label);
                  },
                ),
            ],
          ),
        ],
      ),
      voiceBar: VoiceInputBar(prompt: 'Bolkar batayein', example: 'Haan, poora din kaam karunga', onResult: _onVoice),
    );
  }
}
