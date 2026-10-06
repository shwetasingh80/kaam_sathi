import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'contractor_profile_screen.dart';
import 'job_accepted_screen.dart';
import 'my_work_screen.dart';

/// Opens Google Maps search for a place. Never fails loudly.
Future<void> openMaps(BuildContext context, String place) async {
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) showSnack(context, 'Map nahi khul paaya. Jagah: $place', icon: Icons.map_rounded);
}

/// Screen 23 — everything about one job, in question/answer form.
class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = AppScope.read(context);
      s.focusedJobId = widget.jobId;
      s.markJobSeen(widget.jobId);
    });
  }

  Future<void> _accept(AppState s, Job j) async {
    final yes = await confirmAction(
      context,
      emoji: '🤝',
      title: 'Kaam pakka karein?',
      speech:
          '${s.profile.firstName} ji, aap ${j.area} mein ${j.wage} rupaye roz ke ${j.days} din ke kaam ko accept kar rahe hain. Kya main pakka karun?',
      yesLabel: 'Haan, pakka karo',
      noLabel: 'Nahi',
    );
    if (!yes || !mounted) return;
    setState(() => _busy = true);
    final r = s.acceptJob(j);
    setState(() => _busy = false);
    if (r.success) {
      pushReplacement(context, JobAcceptedScreen(jobId: j.id));
      if (r.queued) voice.speak(r.speech);
    } else {
      voice.speak(r.speech);
      _showError(r.message);
    }
  }

  void _showError(String message) {
    final emoji = message.contains('cancel')
        ? '❌'
        : message.contains('assigned')
            ? '📅'
            : '⌛';
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(emoji: emoji, title: message, compact: true),
            KsButton(label: 'Theek hai', icon: Icons.check_rounded, onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Future<void> _reject(AppState s, Job j) async {
    final yes = await confirmAction(
      context,
      emoji: '🙅',
      title: 'Ye kaam nahi karna?',
      speech: 'Kya aap ye kaam mana karna chahte hain?',
      yesLabel: 'Haan, mana karo',
      noLabel: 'Nahi, wapas jao',
      danger: true,
    );
    if (!yes || !mounted) return;
    s.rejectJob(j);
    voice.speak('Kaam reject kar diya gaya.');
    showSnack(context, 'Kaam reject kar diya gaya.', icon: Icons.close_rounded);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final j = s.jobById(widget.jobId);
    if (j == null) {
      return Scaffold(
        appBar: ksAppBar(context, title: 'Kaam'),
        body: const Center(child: EmptyState(emoji: '⌛', title: 'Ye kaam ab available nahi hai.')),
      );
    }
    final mine = s.assignmentFor(j.id);
    final closed = j.status == JobStatus.cancelled || j.status == JobStatus.expired;
    final s2 = j.schedule;
    final lunch = s2.lunch;
    final distance = j.distanceKm.toStringAsFixed(j.distanceKm % 1 == 0 ? 0 : 1);
    final conditionsSpeech = [
      'Mehnat ${j.physical.label} hai.',
      'Kaam ${j.environment.label} hai.',
      ...j.conditions.map((c) => c.spoken),
    ].join(' ');

    return Scaffold(
      appBar: ksAppBar(context, title: j.title, speak: j.spokenDetails()),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (closed) _ClosedBanner(job: j),
                if (mine != null && !closed) _MineBanner(assignment: mine),
                // Hero
                KsCard(
                  color: AppColors.yellowTint,
                  borderColor: AppColors.yellow,
                  child: Column(
                    children: [
                      Text(j.skill.emoji, style: const TextStyle(fontSize: 56)),
                      Text(j.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${Fmt.rupees(j.wage)} roz · ${Fmt.days(j.days)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.greenDark)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: KsButton(
                          label: 'Poora kaam suno',
                          emoji: '🔊',
                          kind: KsButtonKind.dark,
                          onPressed: () => voice.speak(j.spokenDetails()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                KsCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      InfoRow(emoji: j.skill.emoji, question: 'Kaam kya hai?', answer: j.title, sub: j.category.label),
                      const Divider(),
                      InfoRow(
                        emoji: '📍',
                        question: 'Kahan?',
                        answer: j.place,
                        sub: [if (j.landmark != null) j.landmark!, '$distance km door'].join(' · '),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 66, bottom: 6),
                          child: TextButton.icon(
                            onPressed: () => openMaps(context, j.place),
                            icon: const Icon(Icons.directions_rounded),
                            label: const Text('Rasta dekhein'),
                          ),
                        ),
                      ),
                      const Divider(),
                      InfoRow(emoji: '📅', question: 'Kitne din?', answer: Fmt.days(j.days), sub: '${Fmt.date(j.startDate)} – ${Fmt.date(j.endDate)}'),
                      const Divider(),
                      InfoRow(emoji: '💰', question: 'Kitna paisa?', answer: '${Fmt.rupees(j.wage)} roz', sub: 'Kul ${Fmt.rupees(j.totalEarning)} (${j.days} × ${Fmt.rupees(j.wage)})'),
                      const Divider(),
                      InfoRow(emoji: '⏰', question: 'Samay?', answer: s2.rangeLabel, sub: 'Chhutti: ${s2.weeklyOff}'),
                      const Divider(),
                      InfoRow(
                        emoji: '☕',
                        question: 'Break?',
                        answer: lunch == null ? s2.breakSummary : '${Fmt.durationMinutes(lunch.minutes)} lunch',
                        sub: s2.breaks.map((b) => '${b.label} ${Fmt.time(b.start)}').join(' · '),
                      ),
                      const Divider(),
                      InfoRow(emoji: '🗓️', question: 'Kab se?', answer: Fmt.dateWithDay(j.startDate), sub: Fmt.relativeDay(j.startDate, s.now)),
                      const Divider(),
                      InfoRow(
                        emoji: '💵',
                        question: 'Payment kab?',
                        answer: j.paymentFrequency.label,
                        sub: s2.overtimePerHour == null ? null : 'Overtime: ${Fmt.rupees(s2.overtimePerHour!)}/ghanta',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                KsCard(
                  color: AppColors.orangeTint,
                  borderColor: AppColors.orangeTint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Kaam se pehle jaan lein', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          ),
                          SpeakButton(text: conditionsSpeech, label: '', compact: true, dark: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConditionChips(job: j),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ContractorTrustCard(
                  contractor: j.contractor,
                  onTap: () => push(context, ContractorProfileScreen(contractor: j.contractor)),
                ),
                if (j.note != null) ...[
                  const SizedBox(height: 12),
                  KsCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(j.note!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text('${j.workersFilled}/${j.workersNeeded} workers mil chuke hain',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _BottomBar(
            child: mine != null
                ? KsButton(
                    label: 'Mera kaam dekhein',
                    icon: Icons.assignment_turned_in_rounded,
                    onPressed: () => push(context, MyWorkScreen(jobId: j.id)),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KsButton(
                        label: closed ? (j.status == JobStatus.cancelled ? 'Kaam cancel ho gaya' : 'Kaam available nahi') : 'Haan, ye kaam karunga',
                        icon: Icons.check_circle_rounded,
                        kind: KsButtonKind.success,
                        height: 68,
                        onPressed: closed || _busy ? null : () => _accept(s, j),
                      ),
                      if (!closed) ...[
                        const SizedBox(height: 10),
                        KsButton(
                          label: 'Nahi',
                          icon: Icons.close_rounded,
                          kind: KsButtonKind.secondary,
                          height: 56,
                          onPressed: () => _reject(s, j),
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final cancelled = job.status == JobStatus.cancelled;
    final text = cancelled ? 'Contractor ne ye kaam cancel kar diya hai.' : 'Ye kaam ab available nahi hai.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KsCard(
        color: AppColors.redTint,
        borderColor: AppColors.red,
        child: Row(
          children: [
            Text(cancelled ? '❌' : '⌛', style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.redDark))),
            SpeakButton(text: text, label: '', compact: true, dark: true),
          ],
        ),
      ),
    );
  }
}

class _MineBanner extends StatelessWidget {
  const _MineBanner({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KsCard(
        color: AppColors.greenTint,
        borderColor: AppColors.green,
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.green, size: 34),
            const SizedBox(width: 12),
            const Expanded(child: Text('Ye kaam aapka pakka hai', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.greenDark))),
            StatusPill.workerJob(assignment.status),
          ],
        ),
      ),
    );
  }
}
