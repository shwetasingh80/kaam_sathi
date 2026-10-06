import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../jobs/job_announcement_screen.dart';
import '../onboarding/language_screen.dart';
import '../onboarding/splash_screen.dart';
import '../states/states_gallery_screen.dart';
import 'voice_log_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _times = <(String, TimeOfDay?)>[
    ('Asli samay', null),
    ('7:30 AM', TimeOfDay(hour: 7, minute: 30)),
    ('9:00 AM', TimeOfDay(hour: 9, minute: 0)),
    ('11:10 AM', TimeOfDay(hour: 11, minute: 10)),
    ('1:15 PM', TimeOfDay(hour: 13, minute: 15)),
    ('3:00 PM', TimeOfDay(hour: 15, minute: 0)),
    ('5:30 PM', TimeOfDay(hour: 17, minute: 30)),
  ];

  Future<void> _reset(BuildContext context) async {
    final ok = await confirmAction(
      context,
      emoji: '🗑️',
      title: 'App reset karein?',
      speech: 'Saari jaankari mit jayegi aur app shuru se khulega. Kya reset karein?',
      yesLabel: 'Haan, reset karo',
      noLabel: 'Nahi',
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await AppScope.read(context).resetApp();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lang = AppLanguage.all.where((l) => l.code == state.profile.language).firstOrNull ?? AppLanguage.all.first;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _Row(
            emoji: '🗣️',
            title: 'Bhasha',
            subtitle: '${lang.name} · ${lang.native}',
            onTap: () => push(context, const LanguageScreen(editMode: true)),
          ),
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: voice,
            builder: (context, _) => Column(
              children: [
                _SwitchRow(
                  emoji: '🔔',
                  title: 'Naye kaam ki awaaz announcement',
                  value: state.profile.autoAnnounce,
                  onChanged: (v) {
                    state.profile.autoAnnounce = v;
                    state.saveProfile();
                  },
                ),
                const SizedBox(height: 10),
                _SwitchRow(
                  emoji: '🔇',
                  title: 'Awaaz band karein',
                  subtitle: 'Sirf likha hua dikhega',
                  value: voice.muted,
                  onChanged: voice.setMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Row(
            emoji: '🧾',
            title: 'Voice history (audit log)',
            subtitle: '${state.voiceLogs.length} entries',
            onTap: () => push(context, const VoiceLogScreen()),
          ),
          const SizedBox(height: 10),
          _Row(
            emoji: '🎨',
            title: 'App ke sabhi states (design)',
            subtitle: 'Offline, error, empty…',
            onTap: () => push(context, const StatesGalleryScreen()),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(Radii.l),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.science_rounded, color: AppColors.yellow),
                    SizedBox(width: 8),
                    Text('DEMO CONTROLS', style: TextStyle(color: AppColors.yellow, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Sirf testing ke liye — asli app mein nahi dikhega.',
                    style: TextStyle(color: AppColors.yellowSoft, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                KsButton(
                  label: 'Naya kaam bhejo',
                  emoji: '🔔',
                  onPressed: () {
                    final j = state.simulateNewJob();
                    state.takePendingAnnouncement();
                    push(context, JobAnnouncementScreen(jobId: j.id));
                  },
                ),
                const SizedBox(height: 10),
                Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(Radii.m),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: const Text('📵  Internet band karein', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    value: state.demoOffline,
                    onChanged: state.setDemoOffline,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Samay: ${Fmt.time(state.timeOfDay)}${state.demoTime == null ? ' (asli)' : ' (demo)'}',
                  style: const TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (label, t) in _times)
                      ChoiceChip(
                        label: Text(label),
                        selected: state.demoTime == t ||
                            (t != null && state.demoTime != null && state.demoTime!.hour == t.hour && state.demoTime!.minute == t.minute),
                        onSelected: (_) => state.setDemoTime(t),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                KsButton(
                  label: 'Contractor ne payment kiya',
                  emoji: '💰',
                  kind: KsButtonKind.success,
                  onPressed: () {
                    state.simulatePaymentReceived();
                    showSnack(context, 'Sab pending payment “Paid” ho gaye', icon: Icons.check_circle_rounded);
                  },
                ),
                const SizedBox(height: 10),
                KsButton(
                  label: 'Contractor ne chhutti manzoor ki',
                  emoji: '✅',
                  kind: KsButtonKind.secondary,
                  onPressed: () {
                    state.contractorApprovesAbsence();
                    showSnack(context, 'Aaj ki chhutti (agar thi) manzoor ho gayi', icon: Icons.event_available_rounded);
                  },
                ),
                const SizedBox(height: 10),
                KsButton(label: 'App reset karein', icon: Icons.restart_alt_rounded, kind: KsButtonKind.danger, onPressed: () => _reset(context)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: KsLogo(size: 72)),
          const SizedBox(height: 6),
          const Center(
            child: Text('KaamSaathi v1.0.0 · Suno. Bolo. Kaam Pao.',
                style: TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.emoji, required this.title, required this.onTap, this.subtitle});
  final String emoji;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KsCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 30),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.emoji, required this.title, required this.value, required this.onChanged, this.subtitle});
  final String emoji;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return KsCard(
      onTap: () => onChanged(!value),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
