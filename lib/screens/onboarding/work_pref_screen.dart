import 'package:flutter/material.dart';

import '../../core/voice/intent_parser.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'availability_screen.dart';
import 'onboarding_scaffold.dart';

class WorkPrefScreen extends StatefulWidget {
  const WorkPrefScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<WorkPrefScreen> createState() => _WorkPrefScreenState();
}

class _WorkPrefScreenState extends State<WorkPrefScreen> {
  late final Set<WorkCategory> _prefs = {...AppScope.read(context).profile.workPrefs};
  late WorkEnvironment _env = AppScope.read(context).profile.environment;

  void _toggle(WorkCategory c) {
    setState(() {
      if (!_prefs.remove(c)) _prefs.add(c);
    });
    if (_prefs.contains(c)) voice.speak(c.label);
  }

  void _onVoice(String text) {
    final cats = IntentParser.parseSkills(text).map((id) => SkillCatalog.byId(id).category).toSet();
    final s = IntentParser.normalize(text);
    if (s.contains('andar') || s.contains('अंदर')) _env = WorkEnvironment.indoor;
    if (s.contains('bahar') || s.contains('बाहर')) {
      _env = s.contains('andar') || s.contains('अंदर') ? WorkEnvironment.both : WorkEnvironment.outdoor;
    }
    if (cats.isEmpty) {
      voice.speak('Samajh nahi aaya. Jaise boliye: bilding aur road ka kaam.');
      setState(() {});
      return;
    }
    setState(() => _prefs.addAll(cats));
    voice.speak('${cats.map((c) => c.label).join(', ')} chun liya.');
  }

  void _next() {
    final s = AppScope.read(context);
    s.profile
      ..workPrefs = {..._prefs}
      ..environment = _env;
    s.saveProfile();
    finishStep(context, editMode: widget.editMode, next: () => const AvailabilityScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 9,
      editMode: widget.editMode,
      title: 'Kis tarah ka kaam pasand hai?',
      subtitle: 'Ek se zyada chun sakte hain',
      speech: 'Aapko kis tarah ka kaam pasand hai? Ek se zyada chun sakte hain.',
      onPrimary: _prefs.isEmpty ? null : _next,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TwoColumnGrid(
            children: [
              for (final c in WorkCategory.values)
                SelectTile(
                  vertical: true,
                  emoji: c.emoji,
                  title: c.label,
                  subtitle: c.hint,
                  selected: _prefs.contains(c),
                  onTap: () => _toggle(c),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Kaam ki jagah', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in WorkEnvironment.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: e == WorkEnvironment.both ? 0 : 8),
                      child: SelectTile(
                        vertical: true,
                        emoji: e.emoji,
                        title: e.label,
                        selected: _env == e,
                        onTap: () {
                          setState(() => _env = e);
                          voice.speak(e.label);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      voiceBar: VoiceInputBar(prompt: 'Bolkar batayein', example: 'Bilding aur road ka kaam, bahar', onResult: _onVoice),
    );
  }
}
