import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/voice/intent_parser.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'experience_screen.dart';
import 'onboarding_scaffold.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  /// Selection order matters: first = primary (MUKHYA).
  late final List<String> _selected = [...AppScope.read(context).profile.skills];

  void _toggle(Skill s) {
    setState(() {
      if (!_selected.remove(s.id)) _selected.add(s.id);
    });
    if (_selected.contains(s.id)) {
      voice.speak(_selected.first == s.id ? '${s.name}. Ye aapka mukhya kaam hai.' : s.name);
    }
  }

  void _makePrimary(String id) {
    setState(() {
      _selected
        ..remove(id)
        ..insert(0, id);
    });
    voice.speak('${SkillCatalog.byId(id).name} ab aapka mukhya kaam hai.');
  }

  String _names(List<String> ids) {
    final n = ids.map((e) => SkillCatalog.byId(e).name).toList();
    if (n.length == 1) return n.first;
    return '${n.sublist(0, n.length - 1).join(', ')} aur ${n.last}';
  }

  Future<void> _onVoice(String text) async {
    final ids = IntentParser.parseSkills(text);
    if (ids.isEmpty) {
      voice.speak('Kaam samajh nahi aaya. Jaise boliye: main raj mistri ka kaam karta hoon.');
      showSnack(context, 'Samajh nahi aaya. Dobara boliye.', icon: Icons.hearing_disabled_rounded);
      return;
    }
    final ok = await confirmAction(
      context,
      emoji: SkillCatalog.byId(ids.first).emoji,
      title: _names(ids),
      speech: 'Aap ${_names(ids)} ka kaam karte hain. Sahi hai?',
      yesLabel: 'Haan',
      noLabel: 'Dobara Bolo',
    );
    if (ok) {
      setState(() {
        _selected
          ..clear()
          ..addAll(ids);
      });
    }
  }

  void _next() {
    final s = AppScope.read(context);
    s.profile.skills = [..._selected];
    s.profile.workPrefs.addAll(_selected.map((e) => SkillCatalog.byId(e).category));
    s.saveProfile();
    finishStep(context, editMode: widget.editMode, next: () => const ExperienceScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 5,
      editMode: widget.editMode,
      title: 'Aap kaun sa kaam karte hain?',
      subtitle: 'Ek se zyada chun sakte hain',
      speech: 'Aap kaun sa kaam karte hain? Tasveer wale button dabaiye, ya bolkar batayiye. Ek se zyada kaam chun sakte hain.',
      onPrimary: _selected.isEmpty ? null : _next,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VoiceInputBar(prompt: 'Bolkar batayein', example: 'Main raj mistri aur helper ka kaam karta hoon', onResult: _onVoice),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            KsCard(
              color: AppColors.yellowTint,
              borderColor: AppColors.yellow,
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Chune gaye:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.charcoalSoft)),
                  for (final id in _selected)
                    InputChip(
                      label: Text('${SkillCatalog.byId(id).emoji} ${SkillCatalog.byId(id).name}${id == _selected.first ? ' ★' : ''}'),
                      selected: id == _selected.first,
                      showCheckmark: false,
                      onPressed: id == _selected.first ? null : () => _makePrimary(id),
                      onDeleted: () => setState(() => _selected.remove(id)),
                      tooltip: id == _selected.first ? 'Mukhya kaam' : 'Mukhya banayein',
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text('★ = Mukhya kaam. Kisi aur ko mukhya banane ke liye us par dabayein.', style: TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 190,
              mainAxisExtent: 140,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: SkillCatalog.all.length,
            itemBuilder: (context, i) {
              final s = SkillCatalog.all[i];
              final sel = _selected.contains(s.id);
              return SelectTile(
                vertical: true,
                emoji: s.emoji,
                title: s.name,
                selected: sel,
                badge: sel && _selected.first == s.id ? 'MUKHYA' : null,
                onTap: () => _toggle(s),
              );
            },
          ),
        ],
      ),
    );
  }
}
