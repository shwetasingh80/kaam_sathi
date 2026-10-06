import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../jobs/job_details_screen.dart';
import '../main_shell.dart';
import '../voice/voice_assistant_screen.dart';
import '../work/absence_screen.dart';
import '../work/attendance_screen.dart';
import '../work/today_work_screen.dart';

/// Labour Home (screen 16) — one voice button + four simple cards.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting(DateTime now) => switch (now.hour) {
        < 12 => 'Suprabhat',
        < 17 => 'Namaste',
        _ => 'Shubh sandhya',
      };

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile;
    final summary = _spokenSummary(s);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // ── Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => MainShell.tab.value = MainShell.profile,
                        child: Avatar(name: p.name, photoPath: p.photoPath, size: 56),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greeting(s.now)} ${p.firstName} ji 👋',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                            Text(Fmt.dateWithDay(s.now), style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const MadadButton(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Big voice button
                  _VoiceHero(summary: summary),
                  const SizedBox(height: 16),

                  // ── New jobs
                  _NewJobsCard(state: s),
                  const SizedBox(height: 14),

                  // ── Today's work
                  _TodayCard(state: s),
                  const SizedBox(height: 14),

                  // ── Earnings
                  _EarningsCard(state: s),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _spokenSummary(AppState s) {
    final b = StringBuffer('Namaste ${s.profile.firstName} ji. ');
    final n = s.newJobs.length;
    if (n > 0) b.write('Aapke liye $n naye kaam hain. ');
    final a = s.todayAssignment;
    if (a != null) {
      b.write('Aaj aapka kaam ${a.job.area} mein ${a.job.contractor.company} ke saath hai, ${Fmt.timeSpoken(a.job.schedule.start)} se. ');
      final st = s.todayStatus;
      if (st == AttendanceStatus.notMarked) b.write('Aapki attendance abhi nahi lagi hai. ');
      if (st == AttendanceStatus.present) b.write('Aapki attendance lag gayi hai. ');
    } else {
      b.write('Aaj aapka koi kaam pakka nahi hai. ');
    }
    if (s.earnedThisMonth > 0) b.write('Is mahine aapne ${Fmt.rupeesSpoken(s.earnedThisMonth)} kamaye hain.');
    return b.toString();
  }
}

class _VoiceHero extends StatelessWidget {
  const _VoiceHero({required this.summary});
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Padhne ki zarurat nahi', style: TextStyle(color: AppColors.yellowSoft, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('Suno. Bolo. Kaam Pao.', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              SpeakButton(text: summary, label: 'Aaj ka haal', compact: true),
            ],
          ),
          const SizedBox(height: 6),
          MicButton(
            size: 132,
            label: 'BOLO',
            onTap: () => push(context, const VoiceAssistantScreen()),
          ),
          const Text('Dabaiye aur boliye', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('“Kaam batao” · “Meri kamai kitni hai?”',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.yellowSoft, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.emoji, required this.title, this.trailing});
  final String emoji;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
        ?trailing,
      ],
    );
  }
}

class _NewJobsCard extends StatelessWidget {
  const _NewJobsCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final jobs = state.newJobs;
    final all = state.matchedJobs;
    if (all.isEmpty) {
      return KsCard(
        child: Row(
          children: [
            const Text('🔕', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Abhi koi naya kaam nahi hai.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            SpeakButton(text: 'Abhi koi naya kaam nahi hai. Naya kaam aate hi hum aapko bata denge.', label: '', compact: true),
          ],
        ),
      );
    }
    final top = jobs.isNotEmpty ? jobs.first : all.first;
    final title = jobs.isNotEmpty ? '${jobs.length} naye kaam' : '${all.length} kaam aapke liye';
    return KsCard(
      color: AppColors.yellow,
      borderColor: AppColors.yellow,
      onTap: () => MainShell.tab.value = MainShell.jobs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            emoji: '🔔',
            title: title,
            trailing: SpeakButton(text: top.announcement(state.profile.firstName), label: '', compact: true, dark: true),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Radii.m),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.m),
              onTap: () => push(context, JobDetailsScreen(jobId: top.id)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(top.skill.emoji, style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(top.skill.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                          Text('${top.area} · ${Fmt.days(top.days)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.charcoalSoft)),
                        ],
                      ),
                    ),
                    Text('${Fmt.rupees(top.wage)}\n/din',
                        textAlign: TextAlign.right, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.greenDark, height: 1.1)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Sab kaam dekhein', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final a = state.todayAssignment;
    if (a == null) {
      final next = state.nextWorkDay;
      return KsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(emoji: '🧱', title: 'Mera Aaj Ka Kaam'),
            const SizedBox(height: 8),
            Text(
              next == null
                  ? 'Aaj koi kaam pakka nahi hai.'
                  : 'Agla kaam: ${Fmt.relativeDay(next.day, state.now)}, ${next.assignment.job.area} · ${Fmt.time(next.assignment.job.schedule.start)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (next == null) ...[
              const SizedBox(height: 12),
              KsButton(label: 'Kaam dhoondhein', icon: Icons.search_rounded, onPressed: () => MainShell.tab.value = MainShell.jobs),
            ],
          ],
        ),
      );
    }
    final job = a.job;
    final status = state.todayStatus;
    final phase = state.todayPhase;
    final phaseText = switch (phase?.kind) {
      DayPhaseKind.beforeStart => 'Kaam ${Fmt.time(job.schedule.start)} se',
      DayPhaseKind.working => 'Kaam chal raha hai',
      DayPhaseKind.onBreak => 'Abhi ${phase!.slot!.label} hai',
      DayPhaseKind.ended => 'Aaj ka samay khatam',
      null => '',
    };
    final dayNo = Fmt.dayOnly(state.today).difference(Fmt.dayOnly(job.startDate)).inDays + 1;
    return KsCard(
      onTap: () => push(context, const TodayWorkScreen()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            emoji: '🧱',
            title: 'Mera Aaj Ka Kaam',
            trailing: SpeakButton(
              text: '${job.title}, ${job.area}. ${job.schedule.spoken} Aaj din $dayNo hai, kul ${job.days} din mein se.',
              label: '',
              compact: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(job.skill.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${job.contractor.company} · ${job.area}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('${job.schedule.rangeLabel} · Din $dayNo/${job.days}',
                        style: const TextStyle(fontSize: 16, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill.attendance(status, large: true),
              if (phaseText.isNotEmpty)
                StatusPill(
                  label: phaseText,
                  bg: phase?.kind == DayPhaseKind.onBreak ? AppColors.orangeTint : AppColors.yellowTint,
                  fg: phase?.kind == DayPhaseKind.onBreak ? AppColors.orangeDark : AppColors.charcoal,
                  icon: phase?.kind == DayPhaseKind.onBreak ? Icons.free_breakfast_rounded : Icons.schedule_rounded,
                  large: true,
                ),
            ],
          ),
          if (status == AttendanceStatus.notMarked) ...[
            const SizedBox(height: 14),
            KsButton(
              label: 'Main Kaam Par Hoon',
              emoji: '🟢',
              kind: KsButtonKind.success,
              height: 68,
              onPressed: () => push(context, const AttendanceScreen()),
            ),
            const SizedBox(height: 10),
            KsButton(
              label: 'Aaj Nahi Aa Paunga',
              emoji: '🔴',
              kind: KsButtonKind.secondary,
              onPressed: () => push(context, const AbsenceScreen()),
            ),
          ] else if (status == AttendanceStatus.present) ...[
            const SizedBox(height: 14),
            KsButton(
              label: 'Aaj ka kaam dekhein',
              icon: Icons.view_timeline_rounded,
              kind: KsButtonKind.dark,
              onPressed: () => push(context, const TodayWorkScreen()),
            ),
          ],
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingAmount;
    return KsCard(
      onTap: () => MainShell.tab.value = MainShell.earnings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            emoji: '💰',
            title: 'Meri Kamai',
            trailing: SpeakButton(
              text: 'Is mahine aapne ${Fmt.rupeesSpoken(state.earnedThisMonth)} kamaye hain.'
                  '${pending > 0 ? ' ${Fmt.rupeesSpoken(pending)} abhi pending hain.' : ''}',
              label: '',
              compact: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MiniMoney(label: 'Aaj', amount: state.earnedToday)),
              const SizedBox(width: 10),
              Expanded(child: _MiniMoney(label: 'Is Mahine', amount: state.earnedThisMonth, highlight: true)),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.orangeDark),
                const SizedBox(width: 6),
                Text('${Fmt.rupees(pending)} pending', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.orangeDark)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMoney extends StatelessWidget {
  const _MiniMoney({required this.label, required this.amount, this.highlight = false});
  final String label;
  final int amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.yellowTint : AppColors.cream,
        borderRadius: BorderRadius.circular(Radii.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.charcoalSoft)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(Fmt.rupees(amount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
