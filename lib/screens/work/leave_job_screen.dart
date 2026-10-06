import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../help/unsafe_work_screen.dart';

/// Leaving a job permanently — never silent, always confirmed (spec 14).
class LeaveJobScreen extends StatefulWidget {
  const LeaveJobScreen({super.key, this.jobId});
  final String? jobId;

  @override
  State<LeaveJobScreen> createState() => _LeaveJobScreenState();
}

enum _Step { ask, reason, confirm, done }

class _LeaveReason {
  const _LeaveReason(this.emoji, this.label);
  final String emoji;
  final String label;
}

const _reasons = [
  _LeaveReason('🤒', 'Bimaari / Chot'),
  _LeaveReason('🚨', 'Ghar ki emergency'),
  _LeaveReason('🪙', 'Paisa kam hai'),
  _LeaveReason('⚠️', 'Kaam safe nahi'),
  _LeaveReason('📍', 'Bahut door hai'),
  _LeaveReason('🔁', 'Doosra kaam mila'),
  _LeaveReason('💬', 'Koi aur karan'),
];

class _LeaveJobScreenState extends State<LeaveJobScreen> {
  _Step _step = _Step.ask;
  String? _reason;
  ActionResult? _result;
  Assignment? _assignment;

  static const _askQ = 'Kya aap ye kaam poori tarah chhodna chahte hain?';
  static const _reasonQ = 'Kaam kyon chhod rahe hain? Karan chuniye ya bolkar batayein.';
  static const _warn = 'Kaam chhodne ki jaankari contractor ko bheji jayegi.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = AppScope.read(context);
      _assignment = widget.jobId != null ? s.assignmentFor(widget.jobId!) : s.currentAssignment;
      if (_assignment != null && !_assignment!.isLive) _assignment = null;
      setState(() {});
      if (_assignment != null) voice.speak(_askQ);
    });
  }

  void _go(_Step s, {String? speak}) {
    setState(() => _step = s);
    if (speak != null) voice.speak(speak);
  }

  void _pickReason(String r) {
    _reason = r;
    _go(_Step.confirm, speak: '$_warn Kya main bhej doon?');
  }

  void _send() {
    final s = AppScope.read(context);
    final r = s.leaveJob(_reason ?? 'Koi aur karan', assignment: _assignment);
    voice.speak(r.speech);
    setState(() {
      _result = r;
      _step = _Step.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context);
    final a = _assignment;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Kaam chhodna'),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: a == null && _step != _Step.done
                ? EmptyState(
                    emoji: '🙂',
                    title: 'Abhi aapka koi kaam chal nahi raha hai',
                    action: KsButton(label: 'Wapas', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                  )
                : switch (_step) {
                    _Step.ask => _ask(a!),
                    _Step.reason => _reasonStep(),
                    _Step.confirm => _confirm(a!),
                    _Step.done => _done(),
                  },
          ),
        ],
      ),
    );
  }

  Widget _jobSummary(Assignment a) => KsCard(
        child: Row(
          children: [
            Text(a.job.skill.emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.job.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  Text('${a.job.contractor.company} · ${a.job.area}', style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  Text('${Fmt.date(a.job.startDate)} – ${Fmt.date(a.job.endDate)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _ask(Assignment a) {
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        _jobSummary(a),
        const SizedBox(height: Space.xl),
        const Text('🚪', textAlign: TextAlign.center, style: TextStyle(fontSize: 70)),
        const SizedBox(height: Space.m),
        const Text(_askQ, textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, height: 1.25)),
        const SizedBox(height: Space.s),
        const Center(child: SpeakButton(text: _askQ, compact: true, dark: true)),
        const SizedBox(height: Space.l),
        const Text('Agar sirf aaj nahi aa sakte, to kaam mat chhodiye — “Aaj nahi aa paunga” chuniye.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
        const SizedBox(height: Space.xl),
        KsButton(
          label: 'Haan, kaam chhodna hai',
          icon: Icons.logout_rounded,
          kind: KsButtonKind.danger,
          height: 68,
          onPressed: () => _go(_Step.reason, speak: _reasonQ),
        ),
        const SizedBox(height: Space.m),
        KsButton(label: 'Nahi', icon: Icons.close_rounded, kind: KsButtonKind.secondary, onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _reasonStep() {
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        Row(
          children: [
            const Expanded(child: Text('Kaam kyon chhod rahe hain?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
            const SpeakButton(text: _reasonQ, compact: true),
          ],
        ),
        const SizedBox(height: Space.m),
        VoiceInputBar(onResult: (t) => _pickReason(t.trim().isEmpty ? 'Koi aur karan' : t.trim()), example: 'Ghar mein zaroori kaam aa gaya'),
        const SizedBox(height: Space.l),
        for (final r in _reasons) ...[
          SelectTile(title: r.label, emoji: r.emoji, selected: _reason == r.label, onTap: () => _pickReason(r.label)),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: Space.s),
        KsCard(
          color: AppColors.orangeTint,
          borderColor: AppColors.orange,
          onTap: () => push(context, const UnsafeWorkScreen()),
          child: const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Expanded(
                child: Text('Kaam safe nahi hai? Pehle shikayat karein — hum madad karenge.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.orangeDark)),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _confirm(Assignment a) {
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        _jobSummary(a),
        const SizedBox(height: Space.l),
        KsCard(
          child: InfoRow(emoji: '💬', question: 'Karan', answer: _reason ?? 'Koi aur karan', trailing: TextButton(onPressed: () => _go(_Step.reason), child: const Text('Badlein'))),
        ),
        const SizedBox(height: Space.l),
        Container(
          padding: const EdgeInsets.all(Space.l),
          decoration: BoxDecoration(
            color: AppColors.redTint,
            borderRadius: BorderRadius.circular(Radii.m),
            border: Border.all(color: AppColors.red, width: 2),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.redDark, size: 34),
              SizedBox(width: 12),
              Expanded(child: Text(_warn, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.redDark))),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        KsButton(label: 'Haan, contractor ko bata do', icon: Icons.send_rounded, kind: KsButtonKind.danger, height: 68, onPressed: _send),
        const SizedBox(height: Space.m),
        KsButton(label: 'Nahi, kaam nahi chhodna', icon: Icons.close_rounded, kind: KsButtonKind.secondary, onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _done() {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        const SizedBox(height: Space.l),
        Center(child: SuccessCheck(color: r.success ? AppColors.green : AppColors.red)),
        const SizedBox(height: Space.l),
        Text(r.success ? 'Contractor ko bata diya gaya hai.' : r.message,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        if (r.queued)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(r.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColors.orangeDark, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: Space.l),
        KsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('JOB STATUS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.muted, letterSpacing: 1)),
              const SizedBox(height: 6),
              StatusPill.workerJob(WorkerJobStatus.leftJob, large: true),
              const SizedBox(height: 8),
              Text('Karan: ${_reason ?? 'Koi aur karan'}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: Space.m),
        KsCard(
          color: AppColors.greenTint,
          borderColor: AppColors.green,
          child: const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.greenDark, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text('Aapke profile par koi saza nahi lagegi. Sirf jaankari record hoti hai.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        KsButton(label: 'Naya kaam dhoondhein', icon: Icons.search_rounded, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      ],
    );
  }
}
