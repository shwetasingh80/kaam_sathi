import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import '../main_shell.dart';
import 'onboarding_scaffold.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool? _mic; // null = not asked yet
  bool _notif = false;
  bool _location = false;
  bool _finishing = false;

  Future<void> _askMic() async {
    final ok = await voice.requestMicPermission();
    if (!mounted) return;
    setState(() => _mic = ok);
    voice.speak(ok ? 'Microphone chalu ho gaya. Ab aap bolkar kaam kar sakte hain.' : 'Microphone permission nahi mili. Aap button dabakar bhi kaam kar sakte hain. Baad mein phone ki settings se chalu kar sakte hain.');
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final s = AppScope.read(context);
    await s.completeOnboarding();
    if (!mounted) return;
    voice.speak('Shabash ${s.profile.firstName} ji! Aapka profile taiyaar hai.');
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 11,
      title: 'Kuch zaroori ijazat',
      subtitle: 'Isse app aapki madad kar payega',
      speech: 'Aakhri kadam. Microphone ki ijazat dijiye taaki aap bolkar kaam kar sakein.',
      primaryLabel: 'Shuru karein',
      onPrimary: _finishing ? null : _finish,
      body: Column(
        children: [
          _PermRow(
            emoji: '🎙️',
            title: 'Microphone',
            why: 'Bolkar kaam dhoondhne ke liye',
            done: _mic == true,
            denied: _mic == false,
            buttonLabel: _mic == false ? 'Dobara koshish' : 'Ijazat dein',
            onTap: _askMic,
          ),
          const SizedBox(height: 12),
          _PermRow(
            emoji: '🔔',
            title: 'Suchna (Notification)',
            why: 'Naya kaam aate hi batane ke liye',
            done: _notif,
            buttonLabel: 'Theek hai',
            onTap: () {
              setState(() => _notif = true);
              voice.speak('Naya kaam aate hi aapko bataya jayega.');
            },
          ),
          const SizedBox(height: 12),
          _PermRow(
            emoji: '📍',
            title: 'Location',
            why: 'Paas ka kaam dikhane ke liye',
            done: _location,
            buttonLabel: 'Theek hai',
            onTap: () {
              setState(() => _location = true);
              voice.speak('Aapke paas ka kaam dikhaya jayega.');
            },
          ),
          if (_mic == false) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.orangeTint, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: AppColors.orangeDark),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Voice feature use karne ke liye microphone permission chahiye. Phone Settings → Apps → KaamSaathi → Permissions.',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.orangeDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text('🔒 Aapki jaankari surakshit hai. Kisi ko aapka ID nahi dikhaya jayega.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.emoji,
    required this.title,
    required this.why,
    required this.done,
    required this.buttonLabel,
    required this.onTap,
    this.denied = false,
  });

  final String emoji;
  final String title;
  final String why;
  final bool done;
  final bool denied;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KsCard(
      borderColor: done ? AppColors.green : (denied ? AppColors.red : AppColors.border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.yellowTint, shape: BoxShape.circle),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(why, style: const TextStyle(fontSize: 15, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (done)
            const StatusPill(label: 'Chalu hai ✓', bg: AppColors.greenTint, fg: AppColors.greenDark, icon: Icons.check_circle_rounded, large: true)
          else
            KsButton(
              label: buttonLabel,
              kind: denied ? KsButtonKind.secondary : KsButtonKind.dark,
              icon: denied ? Icons.refresh_rounded : Icons.check_rounded,
              height: 56,
              onPressed: onTap,
            ),
        ],
      ),
    );
  }
}
