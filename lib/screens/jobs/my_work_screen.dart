import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../work/absence_screen.dart';
import '../work/leave_job_screen.dart';
import '../work/today_work_screen.dart';
import 'contractor_profile_screen.dart';
import 'job_details_screen.dart';
import 'rating_screen.dart';

/// Screen 10 / 28 — the work commitment ("contract") for an accepted job.
class MyWorkScreen extends StatefulWidget {
  const MyWorkScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<MyWorkScreen> createState() => _MyWorkScreenState();
}

class _MyWorkScreenState extends State<MyWorkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).focusedJobId = widget.jobId;
    });
  }

  String _speech(Assignment a) {
    final j = a.job;
    final b = StringBuffer('${j.title}, ${j.contractor.company} ke saath. ');
    b.write('Jagah ${j.place}. ${Fmt.date(j.startDate)} se ${Fmt.date(j.endDate)} tak. ');
    b.write('${Fmt.rupeesSpoken(j.wage)} roz. Kul ${Fmt.rupeesSpoken(j.totalEarning)} banenge. ');
    b.write(j.schedule.spoken);
    b.write(' Payment ${j.paymentFrequency.label} milega.');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.assignmentFor(widget.jobId);
    if (a == null) {
      return Scaffold(
        appBar: ksAppBar(context, title: 'Mera kaam'),
        body: Center(
          child: EmptyState(
            emoji: '🧱',
            title: 'Ye kaam aapke naam par nahi hai.',
            action: KsButton(label: 'Kaam dekhein', onPressed: () => pushReplacement(context, JobDetailsScreen(jobId: widget.jobId))),
          ),
        ),
      );
    }
    final j = a.job;
    final sch = j.schedule;
    final coversToday = j.coversDay(s.today);
    final days = List.generate(j.days, (i) => Fmt.dayOnly(j.startDate).add(Duration(days: i)));
    final ot = sch.overtimePerHour;

    return Scaffold(
      appBar: ksAppBar(context, title: 'Mera kaam', speak: _speech(a)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Header
                KsCard(
                  color: AppColors.charcoal,
                  borderColor: AppColors.charcoal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(j.skill.emoji, style: const TextStyle(fontSize: 40)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(j.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white)),
                                Text('Job ID: ${a.jobCode}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.yellowSoft)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StatusPill.workerJob(a.status, large: true),
                    ],
                  ),
                ),
                if (a.status == WorkerJobStatus.completed && a.ratingGiven == null) ...[
                  const SizedBox(height: 12),
                  KsButton(label: 'Contractor ko rating dein', emoji: '⭐', onPressed: () => push(context, RatingScreen(jobId: j.id))),
                ],
                if (a.status == WorkerJobStatus.leftJob) ...[
                  const SizedBox(height: 12),
                  KsCard(
                    color: AppColors.redTint,
                    borderColor: AppColors.redTint,
                    child: Text('Aapne ye kaam chhod diya. Karan: ${a.leaveReason ?? '—'}\nContractor ko bata diya gaya hai.',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.redDark)),
                  ),
                ],
                if (a.isLive && coversToday) ...[
                  const SizedBox(height: 12),
                  KsButton(
                    label: 'Aaj ka kaam',
                    emoji: '🧱',
                    height: 72,
                    subtitle: 'Attendance · Break · Schedule',
                    onPressed: () => push(context, const TodayWorkScreen()),
                  ),
                ],
                const SizedBox(height: 12),
                KsCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      InfoRow(emoji: '🏗️', question: 'Contractor', answer: j.contractor.company, sub: j.contractor.ownerName,
                          trailing: IconButton.filled(
                            tooltip: 'Call karein',
                            style: IconButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.white, minimumSize: const Size(52, 52)),
                            onPressed: () => callPhone(context, j.contractor.phone, who: j.contractor.company),
                            icon: const Icon(Icons.call_rounded),
                          )),
                      const Divider(),
                      InfoRow(emoji: '📍', question: 'Kahan?', answer: j.place, sub: j.landmark,
                          trailing: IconButton.outlined(
                            tooltip: 'Rasta dekhein',
                            style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
                            onPressed: () => openMaps(context, j.place),
                            icon: const Icon(Icons.directions_rounded),
                          )),
                      const Divider(),
                      InfoRow(emoji: '📅', question: 'Kab se kab tak?', answer: '${Fmt.date(j.startDate)} – ${Fmt.date(j.endDate)}', sub: Fmt.days(j.days)),
                      const Divider(),
                      InfoRow(emoji: '💰', question: 'Roz ka paisa', answer: '${Fmt.rupees(j.wage)} roz'),
                      const Divider(),
                      InfoRow(emoji: '⏰', question: 'Samay', answer: sch.rangeLabel, sub: 'Hafte ki chhutti: ${sch.weeklyOff}'),
                      const Divider(),
                      InfoRow(emoji: '💵', question: 'Payment kab?', answer: j.paymentFrequency.label),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MoneyTile(
                  label: 'Expected kamai',
                  amount: j.totalEarning,
                  color: AppColors.greenTint,
                  footer: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${Fmt.days(j.days)} × ${Fmt.rupees(j.wage)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
                      if (ot != null) Text('Overtime alag se: ${Fmt.rupees(ot)}/ghanta', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SectionTitle('Roz ka samay'),
                KsCard(child: ScheduleTimeline(schedule: sch, now: coversToday ? s.timeOfDay : null)),
                const SectionTitle('Haaziri'),
                KsCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      for (final d in days)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(Fmt.date(d), style: TextStyle(fontSize: 18, fontWeight: d == s.today ? FontWeight.w900 : FontWeight.w700)),
                                    Text(d == s.today ? 'Aaj' : Fmt.weekday(d), style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              _dayStatus(a, d, s.today),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SectionTitle('Contractor'),
                ContractorTrustCard(
                  contractor: j.contractor,
                  onTap: () => push(context, ContractorProfileScreen(contractor: j.contractor)),
                ),
                const SizedBox(height: 12),
                KsButton(
                  label: 'Contractor ko call karein',
                  icon: Icons.call_rounded,
                  kind: KsButtonKind.dark,
                  onPressed: () => callPhone(context, j.contractor.phone, who: j.contractor.company),
                ),
                if (a.isLive) ...[
                  const SizedBox(height: 12),
                  if (coversToday)
                    KsButton(
                      label: 'Aaj nahi aa paunga',
                      emoji: '🔴',
                      kind: KsButtonKind.secondary,
                      onPressed: () => push(context, const AbsenceScreen()),
                    ),
                  const SizedBox(height: 12),
                  KsButton(
                    label: 'Kaam chhodna hai',
                    icon: Icons.logout_rounded,
                    kind: KsButtonKind.ghost,
                    onPressed: () => push(context, LeaveJobScreen(jobId: j.id)),
                  ),
                ],
                const SizedBox(height: 12),
                const Center(child: MadadButton(large: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayStatus(Assignment a, DateTime d, DateTime today) {
    final r = a.recordFor(d);
    if (r != null) return StatusPill.attendance(r.status);
    if (d.isAfter(today)) {
      return const StatusPill(label: 'Aane wala', bg: AppColors.blueTint, fg: AppColors.blueDark, icon: Icons.event_rounded);
    }
    return StatusPill.attendance(AttendanceStatus.notMarked);
  }
}
