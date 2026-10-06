import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'onboarding_scaffold.dart';
import 'welcome_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _code = AppScope.read(context).profile.language;

  void _pick(AppLanguage l) {
    if (!l.enabled) {
      voice.speak('${l.name} jald aa raha hai. Abhi Hindi chuniye.');
      showSnack(context, '${l.name} jald aa raha hai');
      return;
    }
    setState(() => _code = l.code);
    voice.speak(l.code == 'hi' ? 'Hindi chuni gayi' : 'Hinglish chuni gayi');
  }

  void _next() {
    final s = AppScope.read(context);
    s.profile.language = _code;
    s.saveProfile();
    finishStep(context, editMode: widget.editMode, next: () => const WelcomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      editMode: widget.editMode,
      title: 'Apni bhasha chunein',
      subtitle: 'भाषा चुनें · Choose language',
      speech: 'Namaste! Apni bhasha chuniye.',
      onPrimary: _next,
      body: Column(
        children: [
          for (final l in AppLanguage.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SelectTile(
                title: l.native,
                subtitle: l.enabled ? l.name : '${l.name} · Jald aa raha hai',
                emoji: l.enabled ? '🗣️' : '⏳',
                selected: _code == l.code,
                enabled: l.enabled,
                onTap: () => _pick(l),
              ),
            ),
          const SizedBox(height: 4),
          const Text('Bhasha baad mein Profile se badal sakte hain.', style: TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
