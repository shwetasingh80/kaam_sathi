import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../jobs/rating_screen.dart';

/// End of the work day → today's earning.
class DayEndScreen extends StatefulWidget {
  const DayEndScreen({super.key});

  @override
  State<DayEndScreen> createState() => _DayEndScreenState();
}

class _DayEndScreenState extends State<DayEndScreen> {
  ActionResult? _result;
  Assignment? _assignment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  Future<void> _confirm() async {
    final s = AppScope.read(context);
    _assignment = s.todayAssignment;
    final ok = await confirmAction(
      context,
      emoji: '🏁',
      title: 'Aaj ka kaam khatam?',
      speech: 'Kya aaj ka kaam poora ho gaya? Main attendance poori kar doon?',
      yesLabel: 'Haan, kaam khatam',
      noLabel: 'Nahi, abhi kaam chal raha hai',
    );
    if (!mounted) return;
    if (!ok) {
      Navigator.pop(context);
      return;
    }
    final r = s.endDay();
    voice.speak(r.speech);
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = _result;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Aaj ka kaam', speak: r?.speech),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: r == null
                ? const Center(child: CircularProgressIndicator())
                : !r.success
                    ? EmptyState(
                        emoji: '⚠️',
                        title: r.message,
                        action: KsButton(label: 'Wapas', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                      )
                    : _done(context, s),
          ),
        ],
      ),
    );
  }

  Widget _done(BuildContext context, AppState s) {
    final pay = s.todayPayment;
    final a = _assignment;
    final finished = a?.status == WorkerJobStatus.completed;
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        const Center(child: SuccessCheck()),
        const SizedBox(height: Space.l),
        const Text('Aaj ka kaam poora ho gaya', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: Space.xl),
        if (pay != null)
          MoneyTile(
            label: 'Aaj ki kamai',
            amount: pay.amount,
            big: true,
            color: AppColors.yellowTint,
            footer: StatusPill.payment(pay.status, large: true),
          ),
        if (finished && a != null) ...[
          const SizedBox(height: Space.l),
          KsCard(
            color: AppColors.greenTint,
            borderColor: AppColors.green,
            child: Column(
              children: [
                const Text('🎉 Kaam poora hua!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.greenDark)),
                const SizedBox(height: 4),
                Text('${a.job.contractor.company} · ${Fmt.days(a.job.days)} · kul ${Fmt.rupees(a.job.totalEarning)}',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          KsButton(
            label: 'Contractor ko rating dein',
            emoji: '⭐',
            onPressed: () => pushReplacement(context, RatingScreen(jobId: a.job.id)),
          ),
        ],
        const SizedBox(height: Space.m),
        KsButton(
          label: 'Home',
          icon: Icons.home_rounded,
          kind: finished ? KsButtonKind.secondary : KsButtonKind.primary,
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    );
  }
}
