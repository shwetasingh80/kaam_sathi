import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../core/voice/intent_parser.dart';
import '../../core/voice/voice_service.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../work/absence_screen.dart';
import 'emergency_screen.dart';
import 'report_screen.dart';
import 'unsafe_work_screen.dart';

const supportPhone = '+911800000000';

/// Screen 43 — Madad.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  static const _intro = 'Madad chahiye? Neeche se chunein, ya mic dabakar boliye kya hua.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => voice.speak(_intro));
  }

  Future<void> _listen() async {
    if (voice.isListening) {
      await voice.stopListening();
      return;
    }
    final text = await voice.listen();
    if (!mounted) return;
    voice.setStatus(VoiceStatus.idle);
    if (text == null) {
      voice.speak('Main samajh nahi paaya. Thoda dheere boliye.');
      return;
    }
    final p = IntentParser.parse(text);
    final state = AppScope.read(context);
    state.logVoice(text, p.intent.code, slots: p.slots).action = 'OPEN_HELP_OPTION';
    switch (p.intent) {
      case VoiceIntent.unsafeWork:
        push(context, const UnsafeWorkScreen());
      case VoiceIntent.paymentIssue:
        push(context, const ReportScreen(type: ReportType.payment));
      case VoiceIntent.reportAbsence:
        if (p.reason == AbsenceReason.injury) {
          push(context, const ReportScreen(type: ReportType.injury));
        } else {
          push(context, AbsenceScreen(initialReason: p.reason));
        }
      case VoiceIntent.callContractor:
        _callContractor();
      default:
        voice.speak('Theek hai. Neeche se apni madad chunein.');
    }
  }

  void _callContractor() {
    final a = AppScope.read(context).currentAssignment;
    if (a == null) {
      voice.speak('Abhi aapka koi kaam chal nahi raha hai.');
      return;
    }
    callPhone(context, a.job.contractor.phone, who: a.job.contractor.company);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final a = state.currentAssignment;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Madad', madad: false),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.redTint,
                    borderRadius: BorderRadius.circular(Radii.l),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🆘', style: TextStyle(fontSize: 40)),
                            const Text('Madad chahiye?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.redDark)),
                            const SizedBox(height: 4),
                            const Text('Hum aapke saath hain.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            const SpeakButton(text: _intro, dark: true),
                          ],
                        ),
                      ),
                      ListenableBuilder(
                        listenable: voice,
                        builder: (context, _) => Column(
                          children: [
                            MicButton(size: 84, active: voice.isListening, onTap: _listen),
                            Text(voice.isListening ? 'Sun raha hoon…' : 'Bolkar batayein',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _HelpTile(
                  emoji: '🚨',
                  title: 'Emergency',
                  subtitle: '112 · Ambulance · Ghar wale',
                  danger: true,
                  onTap: () => push(context, const EmergencyScreen()),
                ),
                _HelpTile(
                  emoji: '📞',
                  title: 'Contractor ko call karein',
                  subtitle: a == null ? 'Abhi koi kaam nahi chal raha' : a.job.contractor.company,
                  onTap: a == null ? null : _callContractor,
                ),
                _HelpTile(
                  emoji: '🎧',
                  title: 'KaamSaathi support',
                  subtitle: 'Muft call · subah 7 se raat 9',
                  onTap: () => callPhone(context, supportPhone, who: 'KaamSaathi support'),
                ),
                const SectionTitle('Shikayat karein'),
                _HelpTile(emoji: '⚠️', title: 'Kaam safe nahi hai', onTap: () => push(context, const UnsafeWorkScreen())),
                _HelpTile(emoji: '💰', title: 'Paisa nahi mila', onTap: () => push(context, const ReportScreen(type: ReportType.payment))),
                _HelpTile(emoji: '🛑', title: 'Bura vyavhar / pareshaan', onTap: () => push(context, const ReportScreen(type: ReportType.harassment))),
                _HelpTile(emoji: '🚫', title: 'Dhokha / nakli kaam', onTap: () => push(context, const ReportScreen(type: ReportType.fraud))),
                _HelpTile(emoji: '🩹', title: 'Chot lagi', onTap: () => push(context, const ReportScreen(type: ReportType.injury))),
                _HelpTile(emoji: '🪙', title: 'Galat mazdoori', onTap: () => push(context, const ReportScreen(type: ReportType.wrongWage))),
                _HelpTile(emoji: '📍', title: 'Galat jagah batayi', onTap: () => push(context, const ReportScreen(type: ReportType.location))),
                if (state.reports.isNotEmpty) ...[
                  const SectionTitle('Meri shikayatein'),
                  for (final r in state.reports)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: KsCard(
                        child: Row(
                          children: [
                            Text(r.type.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.type.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                  Text('${r.id} · ${Fmt.ago(r.time, state.now)}',
                                      style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const StatusPill(label: 'Darj', bg: AppColors.blueTint, fg: AppColors.blueDark, icon: Icons.assignment_turned_in_rounded),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({required this.emoji, required this.title, this.subtitle, this.onTap, this.danger = false});
  final String emoji;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: KsCard(
          onTap: onTap,
          color: danger ? AppColors.red : AppColors.white,
          borderColor: danger ? AppColors.red : AppColors.border,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: danger ? AppColors.white : AppColors.yellowTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: danger ? AppColors.white : AppColors.charcoal)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: danger ? AppColors.white : AppColors.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 30, color: danger ? AppColors.white : AppColors.charcoal),
            ],
          ),
        ),
      ),
    );
  }
}
