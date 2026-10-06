import 'package:flutter/material.dart';

import '../../core/voice/intent_parser.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'onboarding_scaffold.dart';
import 'wage_screen.dart';

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  int? _years;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = AppScope.read(context).profile;
      if (widget.editMode || p.experienceYears > 0) setState(() => _years = p.experienceYears);
    });
  }

  ExperienceBucket? get _bucket => _years == null ? null : ExperienceBucket.forYears(_years!);

  void _pickBucket(ExperienceBucket b) {
    // Store a representative value inside the bucket.
    setState(() => _years = b.min == 0 ? 0 : (b.max >= 99 ? 10 : b.min));
    voice.speak(b.label.replaceAll('–', ' se '));
  }

  Future<void> _onVoice(String text) async {
    final y = IntentParser.parseYears(text);
    if (y == null) {
      voice.speak('Saal samajh nahi aaye. Jaise boliye: aath saal.');
      showSnack(context, 'Samajh nahi aaya. Dobara boliye.', icon: Icons.hearing_disabled_rounded);
      return;
    }
    final skills = IntentParser.parseSkills(text);
    final skillPart = skills.isEmpty ? '' : '${SkillCatalog.byId(skills.first).name} ka ';
    final ok = await confirmAction(
      context,
      emoji: '🗓️',
      title: '$skillPart$y saal',
      speech: 'Aapko ${skillPart}kaam $y saal se aata hai. Sahi hai?',
      yesLabel: 'Haan',
      noLabel: 'Dobara Bolo',
    );
    if (ok) setState(() => _years = y);
  }

  void _next() {
    final s = AppScope.read(context);
    s.profile.experienceYears = _years ?? 0;
    s.saveProfile();
    finishStep(context, editMode: widget.editMode, next: () => const WageScreen());
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppScope.of(context).profile.primarySkill;
    return OnboardingScaffold(
      step: 6,
      editMode: widget.editMode,
      title: 'Kitne saal se kaam kar rahe hain?',
      subtitle: primary == null ? null : '${primary.emoji} ${primary.name}',
      speech: 'Aap kitne saal se ye kaam kar rahe hain? Button dabaiye ya bolkar batayiye.',
      onPrimary: _years == null ? null : _next,
      body: Column(
        children: [
          for (final b in ExperienceBucket.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SelectTile(
                title: b.label,
                emoji: b.min >= 10 ? '🏆' : (b.min >= 5 ? '💪' : (b.min >= 1 ? '🔨' : '🌱')),
                subtitle: _years != null && _bucket == b && !(b.min == _years) ? '$_years saal' : null,
                selected: _bucket == b,
                onTap: () => _pickBucket(b),
              ),
            ),
        ],
      ),
      voiceBar: VoiceInputBar(prompt: 'Apna experience bolkar batayein', example: 'Mujhe raj mistri ka kaam 8 saal se aata hai', onResult: _onVoice),
    );
  }
}
