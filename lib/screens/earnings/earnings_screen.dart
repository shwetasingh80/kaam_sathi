import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../help/report_screen.dart';
import 'payment_history_screen.dart';

/// "Meri Kamai" tab — simple money cards, no complex dashboards.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  static String spokenSummary(AppState s) {
    final b = StringBuffer('Is mahine aapne ${Fmt.rupeesSpoken(s.earnedThisMonth)} kamaye hain. ');
    b.write('Is hafte ${Fmt.rupeesSpoken(s.earnedThisWeek)}. ');
    if (s.earnedToday > 0) b.write('Aaj ${Fmt.rupeesSpoken(s.earnedToday)}. ');
    if (s.pendingAmount > 0) b.write('${Fmt.rupeesSpoken(s.pendingAmount)} abhi pending hain.');
    return b.toString();
  }

  Future<void> _requestAll(BuildContext context, AppState s) async {
    final pending = s.payments.where((p) => p.status == PaymentStatus.pending).toList();
    if (pending.isEmpty) {
      showSnack(context, 'Request pehle hi bhej di gayi hai.');
      return;
    }
    final ok = await confirmAction(
      context,
      emoji: '💰',
      title: 'Payment request bhejein?',
      speech: 'Kya aap ${Fmt.rupeesSpoken(pending.fold<int>(0, (t, p) => t + p.amount))} ki payment request bhejna chahte hain?',
      yesLabel: 'Haan, request bhejo',
    );
    if (!ok || !context.mounted) return;
    ActionResult? last;
    for (final p in pending) {
      last = s.requestPayment(p);
    }
    if (last != null) {
      voice.speak(last.speech);
      showSnack(context, last.message, icon: Icons.send_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final recent = s.payments.take(3).toList();
    final rel = s.reliability;
    final pendingJob = s.payments.where((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.requested).firstOrNull;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Meri Kamai', showBack: false, speak: spokenSummary(s)),
      floatingActionButton: const VoiceFab(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 140),
              children: [
                MoneyTile(
                  label: 'Is Mahine',
                  amount: s.earnedThisMonth,
                  big: true,
                  color: AppColors.yellow,
                  footer: SpeakButton(text: spokenSummary(s), label: 'Kamai suno', dark: true, compact: true),
                ),
                const SizedBox(height: Space.m),
                Row(
                  children: [
                    Expanded(child: MoneyTile(label: 'Aaj', amount: s.earnedToday)),
                    const SizedBox(width: Space.m),
                    Expanded(child: MoneyTile(label: 'Is Hafte', amount: s.earnedThisWeek)),
                  ],
                ),
                if (s.pendingAmount > 0) ...[
                  const SizedBox(height: Space.m),
                  KsCard(
                    color: AppColors.orangeTint,
                    borderColor: AppColors.orange,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('⏳', style: TextStyle(fontSize: 30)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('${Fmt.rupees(s.pendingAmount)} abhi pending hain',
                                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.orangeDark)),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.m),
                        KsButton(label: 'Payment request bhejein', icon: Icons.send_rounded, kind: KsButtonKind.dark, onPressed: () => _requestAll(context, s)),
                        const SizedBox(height: Space.s),
                        KsButton(
                          label: 'Shikayat karein',
                          icon: Icons.report_gmailerrorred_rounded,
                          kind: KsButtonKind.secondary,
                          onPressed: () => push(context, ReportScreen(type: ReportType.payment, jobId: pendingJob?.jobId)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SectionTitle('Pichhle 7 din'),
                KsCard(child: _WeekBars(state: s)),
                SectionTitle(
                  'Haal ke payment',
                  trailing: TextButton(onPressed: () => push(context, const PaymentHistoryScreen()), child: const Text('Poori history')),
                ),
                if (recent.isEmpty)
                  const EmptyState(emoji: '💰', title: 'Abhi koi payment nahi', compact: true)
                else
                  for (final p in recent) ...[
                    PaymentCard(payment: p, compact: true),
                    const SizedBox(height: Space.s),
                  ],
                const SizedBox(height: Space.s),
                KsButton(
                  label: 'Poori payment history',
                  icon: Icons.receipt_long_rounded,
                  kind: KsButtonKind.secondary,
                  onPressed: () => push(context, const PaymentHistoryScreen()),
                ),
                const SectionTitle('Mera record'),
                KsCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _RelStat(emoji: '✅', value: '${rel.attendancePercent}%', label: 'Haaziri'),
                          _RelStat(emoji: '🏗️', value: '${rel.completed}', label: 'Kaam poore'),
                          _RelStat(emoji: '🤒', value: '${rel.sickDays + rel.emergencyDays}', label: 'Bimaari / emergency'),
                          _RelStat(emoji: '🚫', value: '${rel.noShows}', label: 'Bina bataye'),
                        ],
                      ),
                      const SizedBox(height: Space.m),
                      Container(
                        padding: const EdgeInsets.all(Space.m),
                        decoration: BoxDecoration(color: AppColors.greenTint, borderRadius: BorderRadius.circular(Radii.s)),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_rounded, color: AppColors.greenDark),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Bimaari ki chhutti se score kam nahi hota. Bas bata dena zaruri hai.',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.greenDark)),
                            ),
                          ],
                        ),
                      ),
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

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => state.today.subtract(Duration(days: 6 - i)));
    final totals = [
      for (final d in days) state.payments.where((p) => Fmt.dayOnly(p.date) == d).fold<int>(0, (t, p) => t + p.amount),
    ];
    final maxV = totals.fold<int>(0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Semantics(
                label: '${Fmt.weekday(days[i])}: ${Fmt.rupees(totals[i])}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (totals[i] > 0)
                      FittedBox(child: Text(Fmt.rupees(totals[i]), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                    const SizedBox(height: 4),
                    Container(
                      height: maxV == 0 ? 6 : 6 + 100 * totals[i] / maxV,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i == 6 ? AppColors.yellow : (totals[i] > 0 ? AppColors.charcoal : AppColors.divider),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(i == 6 ? 'Aaj' : Fmt.weekday(days[i]).substring(0, 3),
                        style: TextStyle(fontSize: 13, fontWeight: i == 6 ? FontWeight.w900 : FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelStat extends StatelessWidget {
  const _RelStat({required this.emoji, required this.value, required this.label});
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
