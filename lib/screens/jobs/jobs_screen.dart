import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'job_details_screen.dart';
import 'my_work_screen.dart';

/// Kaam tab — new matching jobs + the worker's own jobs.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _tab = 0;

  String _spoken(AppState s) {
    final jobs = s.matchedJobs;
    if (jobs.isEmpty) return 'Abhi koi naya kaam nahi hai. Naya kaam aate hi hum aapko batayenge.';
    final b = StringBuffer('Aapke liye ${jobs.length} kaam hain. ');
    final ords = ['Pehla', 'Doosra', 'Teesra'];
    for (var i = 0; i < jobs.length && i < 3; i++) {
      final j = jobs[i];
      b.write('${ords[i]}: ${j.area} mein ${j.skill.name}, ${Fmt.rupeesSpoken(j.wage)} roz, ${Fmt.days(j.days)}. ');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final jobs = s.matchedJobs;
    final mine = [...s.liveAssignments, ...s.pastAssignments];
    return Scaffold(
      appBar: ksAppBar(context, title: 'Kaam', showBack: false, speak: _spoken(s)),
      floatingActionButton: const VoiceFab(),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _Segment(
              labels: ['Naye kaam (${jobs.length})', 'Mera kaam (${mine.length})'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: _tab == 0 ? _newJobs(context, s, jobs) : _myJobs(context, s, mine),
          ),
        ],
      ),
    );
  }

  Widget _newJobs(BuildContext context, AppState s, List<Job> jobs) {
    final closed = s.closedJobs;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
      children: [
        if (jobs.isEmpty)
          const EmptyState(
            emoji: '🔍',
            title: 'Abhi koi naya kaam nahi hai.',
            subtitle: 'Naya kaam aate hi hum aapko bolkar batayenge.',
          )
        else ...[
          SpeakButtonRow(text: _spoken(s)),
          const SizedBox(height: 12),
          for (final j in jobs) ...[
            JobCard(
              job: j,
              isNew: !s.seenJobIds.contains(j.id),
              onTap: () => push(context, JobDetailsScreen(jobId: j.id)),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (closed.isNotEmpty) ...[
          const SectionTitle('Band ho chuke kaam'),
          for (final j in closed) ...[
            Opacity(
              opacity: 0.75,
              child: JobCard(job: j, onTap: () => push(context, JobDetailsScreen(jobId: j.id))),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _myJobs(BuildContext context, AppState s, List<Assignment> mine) {
    if (mine.isEmpty) {
      return ListView(
        children: [
          EmptyState(
            emoji: '🧱',
            title: 'Abhi aapka koi kaam nahi hai.',
            subtitle: 'Naye kaam mein se kaam chunein.',
            action: KsButton(label: 'Naye kaam dekhein', icon: Icons.search_rounded, onPressed: () => setState(() => _tab = 0)),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
      children: [
        for (final a in mine) ...[
          JobCard(
            job: a.job,
            status: StatusPill.workerJob(a.status),
            onTap: () => push(context, MyWorkScreen(jobId: a.job.id)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Full-width "🔊 Kaam suno" row.
class SpeakButtonRow extends StatelessWidget {
  const SpeakButtonRow({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text('Aapke liye kaam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        SpeakButton(text: text, label: 'Kaam suno', dark: true),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Radii.m),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.yellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.s),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(fontSize: 17, fontWeight: i == index ? FontWeight.w900 : FontWeight.w700, color: AppColors.charcoal),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
