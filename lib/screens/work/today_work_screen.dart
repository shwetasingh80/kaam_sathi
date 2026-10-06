import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'absence_screen.dart';
import 'attendance_screen.dart';
import 'break_screen.dart';
import 'contractor_notified_screen.dart';
import 'day_end_screen.dart';

/// "Aaj Ka Kaam" — today's job, phase, attendance and schedule.
class TodayWorkScreen extends StatefulWidget {
  const TodayWorkScreen({super.key});

  @override
  State<TodayWorkScreen> createState() => _TodayWorkScreenState();
}

class _TodayWorkScreenState extends State<TodayWorkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = AppScope.read(context);
      final a = s.todayAssignment;
      if (a == null) {
        voice.speak('Aaj aapka koi kaam nahi hai.');
      } else {
        voice.speak('Aaj ${a.job.area} mein ${a.job.skill.name} ka kaam hai. ${a.job.schedule.spoken}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.todayAssignment;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Aaj Ka Kaam', speak: a?.job.schedule.spoken),
      floatingActionButton: a == null ? null : VoiceFab(contextJob: a.job),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: a == null ? _empty(context, s) : _body(context, s, a)),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, AppState s) {
    final next = s.nextWorkDay;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        children: [
          EmptyState(
            emoji: '🌤️',
            title: 'Aaj koi kaam nahi hai',
            subtitle: 'Naye kaam Kaam tab mein dekhein.',
            action: KsButton(label: 'Naya kaam dekhein', icon: Icons.work_rounded, onPressed: () => Navigator.pop(context)),
          ),
          if (next != null)
            KsCard(
              color: AppColors.yellowTint,
              borderColor: AppColors.yellow,
              child: InfoRow(
                emoji: '📅',
                question: 'Agla kaam',
                answer: '${Fmt.relativeDay(next.day, s.now)} · ${next.assignment.job.area}',
                sub: '${next.assignment.job.skill.name} · ${Fmt.time(next.assignment.job.schedule.start)} se',
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppState s, Assignment a) {
    final job = a.job;
    final status = s.todayStatus;
    final phase = s.todayPhase;
    final rec = s.todayRecord;
    final started = phase != null && phase.kind != DayPhaseKind.beforeStart;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 120),
      children: [
        KsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(job.skill.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.skill.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(job.contractor.company, style: const TextStyle(fontSize: 16, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text('${Fmt.rupees(job.wage)}/din', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.greenDark)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Expanded(child: Text(job.landmark == null ? job.place : '${job.place}\n${job.landmark}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 10),
              StatusPill.attendance(status, large: true),
            ],
          ),
        ),
        const SizedBox(height: Space.m),
        if (phase != null) _PhaseBanner(phase: phase, schedule: job.schedule),
        const SizedBox(height: Space.m),
        // Attendance block
        if (status == AttendanceStatus.notMarked) ...[
          KsButton(
            label: 'Main kaam par pahunch gaya',
            emoji: '🟢',
            kind: KsButtonKind.success,
            height: 80,
            onPressed: () => push(context, const AttendanceScreen()),
          ),
          const SizedBox(height: Space.m),
          KsButton(
            label: 'Aaj nahi aa paunga',
            emoji: '🔴',
            kind: KsButtonKind.danger,
            height: 72,
            onPressed: () => push(context, const AbsenceScreen()),
          ),
        ] else if (status == AttendanceStatus.present) ...[
          KsCard(
            color: AppColors.greenTint,
            borderColor: AppColors.green,
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.greenDark, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Haazir ✓ ${rec?.checkIn == null ? '' : Fmt.time(TimeOfDay.fromDateTime(rec!.checkIn!))}',
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.greenDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          KsButton(
            label: 'Aaj ka kaam khatam',
            emoji: '🏁',
            kind: KsButtonKind.dark,
            subtitle: started ? null : 'Kaam shuru hone ke baad',
            onPressed: started ? () => push(context, const DayEndScreen()) : null,
          ),
        ] else if (status == AttendanceStatus.completed) ...[
          KsCard(
            color: AppColors.greenTint,
            borderColor: AppColors.green,
            child: Row(
              children: [
                const Icon(Icons.task_alt_rounded, color: AppColors.greenDark, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aaj ka kaam poora ✓  ${s.todayPayment == null ? '' : Fmt.rupees(s.todayPayment!.amount)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.greenDark),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          KsCard(
            color: status.bg,
            borderColor: status.fg.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill.attendance(status, large: true),
                if (rec?.reason != null) ...[
                  const SizedBox(height: 8),
                  Text('${rec!.reason!.emoji} ${rec.reason!.label}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                ],
                const SizedBox(height: 6),
                const Text('Contractor ko jaankari bhej di gayi hai.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          KsButton(
            label: 'Contractor ko kya bheja gaya',
            icon: Icons.chat_rounded,
            kind: KsButtonKind.secondary,
            onPressed: () => push(context, const ContractorNotifiedScreen()),
          ),
          const SizedBox(height: Space.m),
          KsButton(
            label: 'Main kaam par aa gaya',
            emoji: '🟢',
            kind: KsButtonKind.success,
            subtitle: 'Tabiyat theek hai? Attendance lagayein',
            onPressed: () => push(context, const AttendanceScreen()),
          ),
        ],
        const SizedBox(height: Space.s),
        SectionTitle(
          'Aaj ka samay',
          trailing: SpeakButton(text: job.schedule.spoken, compact: true),
        ),
        KsCard(child: ScheduleTimeline(schedule: job.schedule, now: s.timeOfDay)),
        const SizedBox(height: Space.m),
        KsButton(
          label: 'Contractor ko call karein',
          icon: Icons.call_rounded,
          kind: KsButtonKind.secondary,
          onPressed: () => callPhone(context, job.contractor.phone, who: job.contractor.company),
        ),
      ],
    );
  }
}

class _PhaseBanner extends StatelessWidget {
  const _PhaseBanner({required this.phase, required this.schedule});
  final DayPhase phase;
  final WorkSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final (String emoji, String text, Color bg, VoidCallback? onTap) = switch (phase.kind) {
      DayPhaseKind.beforeStart => ('⏰', 'Kaam ${Fmt.time(schedule.start)} se shuru hoga', AppColors.yellowTint, null),
      DayPhaseKind.working => ('🔨', 'Kaam chal raha hai', AppColors.greenTint, null),
      DayPhaseKind.onBreak => (
          phase.slot?.isLunch == true ? '🍛' : '☕',
          'Abhi Break Hai · ${phase.slot == null ? '' : Fmt.time(phase.slot!.end)} tak',
          AppColors.orangeTint,
          () => push(context, const BreakScreen()),
        ),
      DayPhaseKind.ended => ('🏁', 'Aaj ka samay khatam (${Fmt.time(schedule.end)})', AppColors.blueTint, null),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(Radii.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.m),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
