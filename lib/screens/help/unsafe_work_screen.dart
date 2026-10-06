import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'emergency_screen.dart';
import 'help_screen.dart' show supportPhone;

/// Screen 45 / §31 — "Yahan kaam safe nahi hai".
class UnsafeWorkScreen extends StatefulWidget {
  const UnsafeWorkScreen({super.key});

  @override
  State<UnsafeWorkScreen> createState() => _UnsafeWorkScreenState();
}

class _UnsafeWorkScreenState extends State<UnsafeWorkScreen> {
  static const _intro = 'Yahan kaam safe nahi hai? Aapki jaan sabse zaroori hai. Kya aap kaam rokna chahte hain?';
  ActionResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => voice.speak(_intro));
  }

  Future<void> _report() async {
    final state = AppScope.read(context);
    final stopped = await confirmAction(
      context,
      emoji: '✋',
      title: 'Kaam rok diya?',
      speech: 'Kya aapne khatre ki wajah se kaam rok diya hai?',
      yesLabel: 'Haan, kaam rok diya',
      noLabel: 'Nahi, sirf batana hai',
    );
    if (!mounted) return;
    final r = state.submitReport(
      ReportType.unsafe,
      jobId: state.currentAssignment?.job.id,
      stoppedWork: stopped,
      details: stopped ? 'Worker ne kaam rok diya' : null,
    );
    setState(() => _result = r);
    voice.speak(stopped
        ? '${r.speech} Aapne kaam roka, isse aapke record par koi asar nahi padega.'
        : r.speech);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final a = state.currentAssignment;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Kaam safe nahi', speak: _intro),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.orangeTint, borderRadius: BorderRadius.circular(Radii.l)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️', style: TextStyle(fontSize: 44)),
                      Text('Yahan kaam safe nahi hai?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.orangeDark)),
                      SizedBox(height: 4),
                      Text('Aapki jaan sabse zaroori hai. Khatra ho to kaam rok sakte hain.',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_result != null)
                  KsCard(
                    color: _result!.queued ? AppColors.orangeTint : AppColors.greenTint,
                    borderColor: _result!.queued ? AppColors.orange : AppColors.green,
                    child: Row(
                      children: [
                        Icon(_result!.queued ? Icons.schedule_send_rounded : Icons.check_circle_rounded,
                            color: _result!.queued ? AppColors.orangeDark : AppColors.greenDark, size: 34),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_result!.message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                      ],
                    ),
                  )
                else
                  KsButton(label: 'Unsafe kaam ki shikayat', emoji: '📢', kind: KsButtonKind.danger, height: 72, onPressed: _report),
                const SizedBox(height: 12),
                KsButton(
                  label: 'Contractor ko call',
                  subtitle: a?.job.contractor.company ?? 'Abhi koi kaam nahi',
                  icon: Icons.call_rounded,
                  kind: KsButtonKind.dark,
                  onPressed: a == null ? null : () => callPhone(context, a.job.contractor.phone, who: a.job.contractor.company),
                ),
                const SizedBox(height: 12),
                KsButton(
                  label: 'Support se baat',
                  emoji: '🎧',
                  kind: KsButtonKind.secondary,
                  onPressed: () => callPhone(context, supportPhone, who: 'KaamSaathi support'),
                ),
                const SizedBox(height: 12),
                KsButton(
                  label: 'Emergency madad',
                  emoji: '🚨',
                  kind: KsButtonKind.secondary,
                  onPressed: () => push(context, const EmergencyScreen()),
                ),
                const SectionTitle('Yaad rakhein'),
                for (final (e, t) in const [
                  ('⛑️', 'Helmet aur joote pehnein'),
                  ('🪢', 'Oonchai par belt / rassi zaroori'),
                  ('⚡', 'Khuli bijli ki taar ko na chhuein'),
                  ('💧', 'Garmi mein paani peete rahein'),
                  ('✋', 'Khatra lage to kaam rokna aapka haq hai'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(e, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
