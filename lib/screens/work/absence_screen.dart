import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/voice/intent_parser.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'contractor_notified_screen.dart';
import 'leave_job_screen.dart';

/// "Aaj nahi aa paunga" — sick / emergency absence flow (spec 11–13).
class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key, this.initialReason});
  final AbsenceReason? initialReason;

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

enum _Step { reason, scope, done }

class _AbsenceScreenState extends State<AbsenceScreen> {
  late _Step _step = widget.initialReason == null ? _Step.reason : _Step.scope;
  late AbsenceReason? _reason = widget.initialReason;
  AbsenceScope? _scope;
  ActionResult? _result;

  static const _reasonQ = 'Kya hua? Karan chuniye ya bolkar batayein.';
  static const _scopeQ = 'Kya aap sirf aaj nahi aa sakte ya baaki kaam bhi chhodna hai?';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AppScope.read(context).todayAssignment == null) return;
      voice.speak(_step == _Step.reason ? _reasonQ : _scopeQ);
    });
  }

  void _pickReason(AbsenceReason r) {
    setState(() {
      _reason = r;
      _step = _Step.scope;
    });
    voice.speak(_scopeQ);
  }

  void _onVoiceReason(String text) {
    final p = IntentParser.parse(text);
    if (p.intent == VoiceIntent.leaveJob) {
      pushReplacement(context, const LeaveJobScreen());
      return;
    }
    _pickReason(p.reason ?? AbsenceReason.other);
  }

  String _confirmSpeech(AbsenceReason r, String name) {
    final what = switch (r) {
      AbsenceReason.sick => 'Aap aaj bimaar hain',
      AbsenceReason.injury => 'Aapko chot lagi hai',
      AbsenceReason.emergency => 'Aapke ghar mein emergency hai',
      AbsenceReason.family => 'Aapko ghar ka zaroori kaam hai',
      AbsenceReason.transport => 'Aaj aapke paas aane ka saadhan nahi hai',
      AbsenceReason.other => 'Aap aaj',
    };
    return '$name ji, $what aur kaam par nahi ja paayenge. Kya main contractor ko bata doon?';
  }

  Future<void> _pickScope(AbsenceScope scope) async {
    if (scope == AbsenceScope.leaveJob) {
      pushReplacement(context, const LeaveJobScreen());
      return;
    }
    final s = AppScope.read(context);
    final reason = _reason ?? AbsenceReason.other;
    final ok = await confirmAction(
      context,
      emoji: reason.emoji,
      title: 'Kya main contractor ko bata doon?',
      speech: _confirmSpeech(reason, s.profile.firstName),
      yesLabel: 'Haan, bata do',
      noLabel: 'Nahi',
    );
    if (!mounted || !ok) return;
    final r = s.reportAbsence(reason, scope);
    voice.speak(r.speech);
    setState(() {
      _scope = scope;
      _result = r;
      _step = _Step.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.todayAssignment;
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: ksAppBar(context, title: 'Aaj nahi aa paunga'),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: a == null && _step != _Step.done
                  ? EmptyState(
                      emoji: '🙂',
                      title: 'Aaj aapka koi kaam assigned nahi hai',
                      subtitle: 'Chhutti batane ki zarurat nahi hai.',
                      action: KsButton(label: 'Wapas', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                    )
                  : switch (_step) {
                      _Step.reason => _reasonStep(),
                      _Step.scope => _scopeStep(),
                      _Step.done => _doneStep(context, s),
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonStep() {
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        Row(
          children: [
            const Expanded(child: Text('Kya hua?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
            const SpeakButton(text: _reasonQ, compact: true),
          ],
        ),
        const SizedBox(height: Space.m),
        VoiceInputBar(onResult: _onVoiceReason, example: 'Main aaj bimaar hoon'),
        const SizedBox(height: Space.l),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            for (final r in AbsenceReason.values)
              SelectTile(title: r.label, emoji: r.emoji, vertical: true, selected: _reason == r, onTap: () => _pickReason(r)),
          ],
        ),
      ],
    );
  }

  Widget _scopeStep() {
    final r = _reason ?? AbsenceReason.other;
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        Container(
          padding: const EdgeInsets.all(Space.m),
          decoration: BoxDecoration(color: AppColors.orangeTint, borderRadius: BorderRadius.circular(Radii.m)),
          child: Row(
            children: [
              Text(r.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(child: Text(r.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              TextButton(onPressed: () => setState(() => _step = _Step.reason), child: const Text('Badlein')),
            ],
          ),
        ),
        const SizedBox(height: Space.l),
        Row(
          children: [
            const Expanded(
              child: Text('Sirf aaj nahi aa sakte ya kaam chhodna hai?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
            ),
            const SpeakButton(text: _scopeQ, compact: true),
          ],
        ),
        const SizedBox(height: Space.l),
        _ScopeOption(emoji: '📅', scope: AbsenceScope.todayOnly, onTap: () => _pickScope(AbsenceScope.todayOnly)),
        const SizedBox(height: Space.m),
        _ScopeOption(emoji: '🔁', scope: AbsenceScope.fewDays, onTap: () => _pickScope(AbsenceScope.fewDays)),
        const SizedBox(height: Space.m),
        _ScopeOption(emoji: '🚪', scope: AbsenceScope.leaveJob, danger: true, onTap: () => _pickScope(AbsenceScope.leaveJob)),
      ],
    );
  }

  Widget _doneStep(BuildContext context, AppState s) {
    final r = _result!;
    final job = s.todayAssignment?.job ?? s.currentAssignment?.job;
    final status = s.todayStatus;
    final reason = _reason ?? AbsenceReason.other;
    final statusLabel = reason.attendanceStatus == AttendanceStatus.absentSick ? 'Absent — Sick' : 'Absent — Emergency';
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        const SizedBox(height: Space.l),
        Center(child: SuccessCheck(color: r.success ? AppColors.green : AppColors.red)),
        const SizedBox(height: Space.l),
        Text(r.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, height: 1.25)),
        if (_scope == AbsenceScope.fewDays)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Contractor ko bata diya ki aap kal se aayenge.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        if (r.queued)
          Container(
            margin: const EdgeInsets.only(top: Space.m),
            padding: const EdgeInsets.all(Space.m),
            decoration: BoxDecoration(color: AppColors.orangeTint, borderRadius: BorderRadius.circular(Radii.m)),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.orangeDark),
                SizedBox(width: 8),
                Expanded(child: Text('Internet aate hi contractor ko bhej diya jayega.', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.orangeDark))),
              ],
            ),
          ),
        const SizedBox(height: Space.l),
        KsCard(
          child: Row(
            children: [
              const Text('AAJ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.muted)),
              const SizedBox(width: 12),
              Expanded(child: Text(statusLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              StatusPill.attendance(status),
            ],
          ),
        ),
        const SizedBox(height: Space.l),
        if (job != null)
          KsButton(
            label: 'Medical proof upload karein',
            subtitle: job.medicalProofRequired ? 'Contractor ne maanga hai' : 'Zaruri nahi',
            icon: Icons.upload_file_rounded,
            kind: KsButtonKind.secondary,
            onPressed: () => showSnack(context, 'Photo baad mein bhej sakte hain', icon: Icons.photo_camera_rounded),
          ),
        const SizedBox(height: Space.m),
        if (job != null)
          KsButton(
            label: 'Contractor ko call karein',
            icon: Icons.call_rounded,
            kind: KsButtonKind.dark,
            onPressed: () => callPhone(context, job.contractor.phone, who: job.contractor.company),
          ),
        const SizedBox(height: Space.m),
        KsButton(
          label: 'Contractor ko kya bheja gaya',
          icon: Icons.chat_rounded,
          kind: KsButtonKind.secondary,
          onPressed: () => push(context, const ContractorNotifiedScreen()),
        ),
        const SizedBox(height: Space.m),
        KsButton(label: 'Home', icon: Icons.home_rounded, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      ],
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({required this.emoji, required this.scope, required this.onTap, this.danger = false});
  final String emoji;
  final AbsenceScope scope;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return KsCard(
      onTap: onTap,
      color: danger ? AppColors.redTint : AppColors.white,
      borderColor: danger ? AppColors.red : AppColors.border,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scope.label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: danger ? AppColors.redDark : AppColors.charcoal)),
                Text(scope.hint, style: const TextStyle(fontSize: 16, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 32),
        ],
      ),
    );
  }
}
