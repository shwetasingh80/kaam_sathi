import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import '../main_shell.dart';
import 'phone_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _speech =
      'KaamSaathi mein aapka swagat hai. Padhne ki zarurat nahi. Suno, bolo, aur kaam pao. Shuru karne ke liye neeche peela button dabaiye.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) voice.speak(_speech);
    });
  }

  Future<void> _demo() async {
    final s = AppScope.read(context);
    s.loadDemoProfile();
    await s.completeOnboarding();
    if (!mounted) return;
    voice.stopSpeaking();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    Align(alignment: Alignment.topRight, child: SpeakButton(text: _speech)),
                    const KsLogo(size: 200),
                    const SizedBox(height: 8),
                    const Text('Padhne ki zarurat nahi', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: Space.xl),
                    const _Step(emoji: '🔊', title: 'Suno', sub: 'Naya kaam phone bolkar batayega'),
                    const SizedBox(height: 10),
                    const _Step(emoji: '🎙️', title: 'Bolo', sub: 'Bolkar jawab dijiye — likhna nahi'),
                    const SizedBox(height: 10),
                    const _Step(emoji: '🧱', title: 'Kaam Pao', sub: 'Paas ka, sahi daam ka kaam'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  KsButton(
                    label: 'Shuru karein  →',
                    height: 72,
                    onPressed: () {
                      voice.stopSpeaking();
                      push(context, const PhoneScreen());
                    },
                  ),
                  const SizedBox(height: 10),
                  KsButton(
                    label: 'Demo dekhein (Rakesh ji)',
                    icon: Icons.play_circle_outline_rounded,
                    kind: KsButtonKind.secondary,
                    height: 56,
                    onPressed: _demo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.emoji, required this.title, required this.sub});
  final String emoji;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return KsCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text(sub, style: const TextStyle(fontSize: 16, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
