import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import 'my_work_screen.dart';

/// Screen 27 — "Kaam Pakka ✓".
class JobAcceptedScreen extends StatefulWidget {
  const JobAcceptedScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<JobAcceptedScreen> createState() => _JobAcceptedScreenState();
}

class _JobAcceptedScreenState extends State<JobAcceptedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = AppScope.read(context);
      final j = s.jobById(widget.jobId);
      if (j == null) return;
      voice.speak('Aapka kaam pakka ho gaya hai. ${Fmt.date(j.startDate)} ko ${Fmt.timeSpoken(j.schedule.start)} ${j.area} pahunchna hai.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final j = s.jobById(widget.jobId);
    final a = s.assignmentFor(widget.jobId);
    if (j == null || a == null) {
      return Scaffold(
        appBar: ksAppBar(context, title: 'Kaam'),
        body: const Center(child: EmptyState(emoji: '⌛', title: 'Ye kaam ab available nahi hai.')),
      );
    }
    final ot = j.schedule.overtimePerHour;
    final speech = 'Aapka kaam pakka ho gaya hai. ${Fmt.date(j.startDate)} ko ${Fmt.timeSpoken(j.schedule.start)} ${j.area} pahunchna hai. '
        '${j.days} din mein ${Fmt.rupeesSpoken(j.totalEarning)} banenge.';
    return Scaffold(
      appBar: ksAppBar(context, title: 'Kaam Pakka', showBack: false, speak: speech),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Center(child: SuccessCheck()),
            const SizedBox(height: 16),
            const Text('Kaam Pakka ✓', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.greenDark)),
            const SizedBox(height: 4),
            Text('${j.title} · ${j.area}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            KsCard(
              child: Column(
                children: [
                  _Row('🆔', 'Job ID', a.jobCode),
                  _Row('🏗️', 'Contractor', j.contractor.company),
                  _Row('📅', 'Kab', '${Fmt.date(j.startDate)} – ${Fmt.date(j.endDate)}'),
                  _Row('⏰', 'Samay', j.schedule.rangeLabel),
                  _Row('💵', 'Payment', j.paymentFrequency.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MoneyTile(
              label: 'Expected kamai',
              amount: j.totalEarning,
              color: AppColors.greenTint,
              big: true,
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${Fmt.days(j.days)} × ${Fmt.rupees(j.wage)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
                  if (ot != null)
                    Text('+ Overtime alag se: ${Fmt.rupees(ot)}/ghanta', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.charcoalSoft)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            KsCard(
              color: AppColors.yellowTint,
              borderColor: AppColors.yellow,
              child: Row(
                children: [
                  const Text('⏰', style: TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${Fmt.relativeDay(j.startDate, s.now)} ${Fmt.time(j.schedule.start)} baje ${j.area} pahunchna hai. Hum aapko yaad dilayenge.',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            KsButton(
              label: 'Mera kaam dekhein',
              icon: Icons.assignment_turned_in_rounded,
              onPressed: () => pushReplacement(context, MyWorkScreen(jobId: j.id)),
            ),
            const SizedBox(height: 12),
            KsButton(
              label: 'Home par jaayein',
              icon: Icons.home_rounded,
              kind: KsButtonKind.secondary,
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.emoji, this.label, this.value);
  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 16, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
