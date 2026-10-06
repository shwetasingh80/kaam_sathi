import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../help/report_screen.dart';

enum _Filter { all, paid, pending }

/// Payment history — date, contractor, work, days, amount, paid/pending.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.payments.where((p) => switch (_filter) {
          _Filter.all => true,
          _Filter.paid => p.status == PaymentStatus.paid,
          _Filter.pending => p.status != PaymentStatus.paid,
        }).toList();
    final spoken = list.isEmpty ? 'Koi payment nahi hai.' : list.take(5).map((p) => p.spoken).join(' ');
    return Scaffold(
      appBar: ksAppBar(context, title: 'Payment History', speak: spoken),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (f, label) in [(_Filter.all, 'Sab'), (_Filter.paid, 'Paid ✓'), (_Filter.pending, 'Pending')])
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == f,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    emoji: '🧾',
                    title: _filter == _Filter.pending ? 'Koi paisa pending nahi' : 'Abhi koi payment nahi',
                    subtitle: _filter == _Filter.pending ? 'Sab paisa mil chuka hai 👍' : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Space.m),
                    itemBuilder: (context, i) => PaymentCard(payment: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One payment entry card (also used on the Earnings tab).
class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key, required this.payment, this.compact = false});
  final PaymentEntry payment;
  final bool compact;

  Future<void> _request(BuildContext context) async {
    final ok = await confirmAction(
      context,
      emoji: '💰',
      title: 'Payment request bhejein?',
      speech: 'Kya aap ${payment.contractor} ko ${Fmt.rupeesSpoken(payment.amount)} ki payment request bhejna chahte hain?',
      yesLabel: 'Haan, request bhejo',
    );
    if (!ok || !context.mounted) return;
    final r = AppScope.read(context).requestPayment(payment);
    voice.speak(r.speech);
    showSnack(context, r.message, icon: Icons.send_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final pending = p.status == PaymentStatus.pending;
    return KsCard(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.contractor, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                    Text('${p.workTitle} · ${Fmt.days(p.days)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.charcoalSoft)),
                    Text(Fmt.dateWithDay(p.date), style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.rupees(p.amount), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  StatusPill.payment(p.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SpeakButton(text: p.spoken, compact: true),
              if (!compact && pending) ...[
                TextButton.icon(
                  onPressed: () => push(context, ReportScreen(type: ReportType.payment, jobId: p.jobId)),
                  icon: const Icon(Icons.report_gmailerrorred_rounded, color: AppColors.redDark),
                  label: const Text('Shikayat', style: TextStyle(color: AppColors.redDark)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.s))),
                  onPressed: () => _request(context),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text('Request', style: TextStyle(fontSize: 16)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
