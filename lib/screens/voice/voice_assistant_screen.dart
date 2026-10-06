import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../core/voice/intent_parser.dart';
import '../../core/voice/voice_service.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../help/help_screen.dart';
import '../help/report_screen.dart';
import '../help/unsafe_work_screen.dart';
import '../jobs/job_accepted_screen.dart';
import '../jobs/job_details_screen.dart';
import '../jobs/rating_screen.dart';
import '../main_shell.dart';
import '../work/absence_screen.dart';
import '../work/leave_job_screen.dart';

/// Voice Assistant (screens 17–20): Speech → intent → backend → speech.
///
/// The parser only produces an allowed [VoiceIntent]; every change goes
/// through [AppState] which validates business rules. Sensitive actions are
/// always confirmed first, and every command is written to the voice log.
class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key, this.contextJob, this.autoListen = true});
  final Job? contextJob;
  final bool autoListen;

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  String? _heard;
  String? _reply;
  List<Job> _jobs = const [];
  bool _busy = false;

  static const _suggestions = [
    'Kaam batao',
    'Meri kamai kitni hai?',
    'Aaj meri attendance lagi hai?',
    'Main kaam par pahunch gaya',
    'Kal kaam hai?',
    'Kaam kahan hai?',
    'Main aaj bimaar hoon',
    'Contractor ko phone karo',
    'Mere profile mein kya hai?',
    'Madad chahiye',
  ];

  @override
  void initState() {
    super.initState();
    voice.reset();
    if (widget.autoListen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
    }
  }

  @override
  void dispose() {
    voice.stopListening();
    voice.stopSpeaking();
    voice.reset();
    super.dispose();
  }

  Future<void> _listen() async {
    if (_busy) return;
    final s = AppScope.read(context);
    if (!s.online) {
      voice.setStatus(VoiceStatus.offline);
      await voice.speak('Internet connection nahi hai. Neeche diye sawaal dabaiye.');
      voice.setStatus(VoiceStatus.offline);
      return;
    }
    setState(() {
      _heard = null;
      _reply = null;
      _jobs = const [];
    });
    final text = await voice.listen();
    if (!mounted) return;
    if (text == null) {
      final st = voice.status;
      if (st == VoiceStatus.permissionDenied) {
        _say('Voice feature use karne ke liye microphone permission chahiye.', keep: VoiceStatus.permissionDenied);
      } else if (st == VoiceStatus.unavailable) {
        _say('Is phone par voice pehchaan nahi chal raha. Neeche diye sawaal dabaiye.', keep: VoiceStatus.unavailable);
      } else {
        _say('Main samajh nahi paaya. Thoda dheere boliye.', keep: VoiceStatus.error);
      }
      return;
    }
    await _handle(text);
  }

  Future<void> _say(String text, {VoiceStatus? keep}) async {
    setState(() => _reply = text);
    await voice.speak(text);
    if (!mounted) return;
    voice.setStatus(keep ?? VoiceStatus.idle);
  }

  Future<void> _handle(String text) async {
    _busy = true;
    voice.setTranscript(text);
    voice.setStatus(VoiceStatus.processing);
    setState(() {
      _heard = text;
      _reply = null;
      _jobs = const [];
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final parsed = IntentParser.parse(text);
    final s = AppScope.read(context);
    final log = s.logVoice(text, parsed.intent.code, slots: parsed.slots);
    try {
      await _route(parsed, s, log);
    } finally {
      _busy = false;
      s.touch();
    }
  }

  Job? _targetJob(AppState s) =>
      widget.contextJob ??
      (s.focusedJobId == null ? null : s.jobById(s.focusedJobId!)) ??
      s.todayAssignment?.job ??
      s.currentAssignment?.job;

  Future<void> _route(ParsedIntent p, AppState s, VoiceLogEntry log) async {
    final name = s.profile.firstName;
    switch (p.intent) {
      case VoiceIntent.readJobs:
        final jobs = s.matchedJobs;
        if (jobs.isEmpty) {
          log.result = 'NO_JOBS';
          return _say('Abhi koi naya kaam nahi hai. Naya kaam aate hi main aapko bataunga.');
        }
        final b = StringBuffer('Aapke liye ${jobs.length} kaam hain. ');
        const ord = ['Pehla', 'Doosra', 'Teesra'];
        for (var i = 0; i < jobs.length && i < 3; i++) {
          final j = jobs[i];
          b.write('${ord[i]}: ${j.area} mein ${j.skill.name}, ${Fmt.rupeesSpoken(j.wage)} roz, ${Fmt.days(j.days)}. ');
        }
        b.write('Kholne ke liye boliye, pehla kaam kholo.');
        setState(() => _jobs = jobs.take(3).toList());
        log.result = 'READ ${jobs.length} JOBS';
        return _say(b.toString());

      case VoiceIntent.openJob:
        final jobs = s.matchedJobs;
        final i = p.index ?? 0;
        if (i >= jobs.length) {
          log.result = 'INDEX_OUT_OF_RANGE';
          return _say('Itne kaam nahi hain. Abhi ${jobs.length} kaam hain.');
        }
        log.action = 'OPEN_JOB ${jobs[i].id}';
        await _say('${jobs[i].skill.name} ka kaam khol raha hoon.');
        if (mounted) pushReplacement(context, JobDetailsScreen(jobId: jobs[i].id));
        return;

      case VoiceIntent.acceptJob:
        final j = widget.contextJob ??
            (s.focusedJobId == null ? null : s.jobById(s.focusedJobId!)) ??
            (s.matchedJobs.length == 1 ? s.matchedJobs.first : null);
        if (j == null || !j.isAvailable || s.assignmentFor(j.id) != null) {
          log.result = 'NO_JOB_CONTEXT';
          return _say('Kaun sa kaam? Pehle kaam kholiye, phir boliye, ye kaam karunga.');
        }
        final ok = await confirmAction(
          context,
          emoji: '🤝',
          title: 'Kaam pakka karein?',
          speech: '$name ji, aap ${j.area} mein ${j.wage} rupaye roz ke ${Fmt.days(j.days)} ke kaam ko accept kar rahe hain. Kya main pakka karun?',
          yesLabel: 'Haan, pakka karo',
        );
        log.confirmation = ok ? 'YES' : 'NO';
        if (!ok) return _say('Theek hai, kaam pakka nahi kiya.');
        final r = s.acceptJob(j);
        log
          ..action = 'ACCEPT_JOB ${j.id}'
          ..result = r.success ? 'ACCEPTED' : 'REJECTED_BY_RULES: ${r.message}';
        if (!r.success) return _say(r.speech, keep: VoiceStatus.error);
        if (mounted) pushReplacement(context, JobAcceptedScreen(jobId: j.id));
        return;

      case VoiceIntent.rejectJob:
        final j = widget.contextJob ?? (s.focusedJobId == null ? null : s.jobById(s.focusedJobId!));
        if (j == null || !j.isAvailable) {
          return _say('Kaun sa kaam? Pehle kaam kholiye.');
        }
        final ok = await confirmAction(
          context,
          emoji: '❌',
          title: 'Kaam mana karein?',
          speech: 'Kya aap ${j.area} wala ${j.skill.name} ka kaam mana karna chahte hain?',
          yesLabel: 'Haan, mana karo',
        );
        log.confirmation = ok ? 'YES' : 'NO';
        if (!ok) return _say('Theek hai.');
        final r = s.rejectJob(j);
        log
          ..action = 'REJECT_JOB ${j.id}'
          ..result = 'REJECTED';
        return _say(r.speech);

      case VoiceIntent.readWage:
        final j = _targetJob(s) ?? s.matchedJobs.firstOrNull;
        if (j == null) return _say('Abhi koi kaam nahi hai.');
        log.result = 'WAGE ${j.wage}';
        return _say('${j.area} wale kaam mein ${Fmt.rupeesSpoken(j.wage)} roz milenge. ${Fmt.days(j.days)} ke kul ${Fmt.rupeesSpoken(j.totalEarning)} banenge. Payment ${j.paymentFrequency.label} milega.');

      case VoiceIntent.readLocation:
        final j = _targetJob(s) ?? s.matchedJobs.firstOrNull;
        if (j == null) return _say('Abhi koi kaam nahi hai.');
        log.result = 'LOCATION ${j.area}';
        return _say('Kaam ${j.area}, ${j.city} mein hai. ${j.landmark == null ? '' : '${j.landmark}. '}Aapke ghar se lagbhag ${j.distanceKm.round()} kilometer.');

      case VoiceIntent.readEarnings:
        log.result = 'MONTH ${s.earnedThisMonth}';
        final pending = s.pendingAmount;
        return _say('Aaj aapne ${Fmt.rupeesSpoken(s.earnedToday)} kamaye. Is hafte ${Fmt.rupeesSpoken(s.earnedThisWeek)}. '
            'Is mahine aapne ${Fmt.rupeesSpoken(s.earnedThisMonth)} kamaye hain.'
            '${pending > 0 ? ' ${Fmt.rupeesSpoken(pending)} abhi pending hain.' : ''}');

      case VoiceIntent.readAttendance:
        final a = s.todayAssignment;
        if (a == null) return _say('Aaj aapka koi kaam nahi hai, isliye attendance ki zarurat nahi.');
        final r = s.todayRecord;
        log.result = s.todayStatus.name;
        return switch (s.todayStatus) {
          AttendanceStatus.present || AttendanceStatus.completed =>
            _say('Haan, aapki aaj ki attendance ${r?.checkIn == null ? '' : Fmt.timeSpoken(TimeOfDay.fromDateTime(r!.checkIn!))} lag gayi hai.'),
          AttendanceStatus.notMarked => _say('Abhi aapki attendance nahi lagi hai. Kaam par pahunch kar boliye, main pahunch gaya.'),
          final st => _say('Aaj aapki chhutti darj hai: ${st.label}.'),
        };

      case VoiceIntent.markAttendance:
        final r = s.markAttendance(AttendanceMethod.voice);
        log
          ..action = 'MARK_ATTENDANCE'
          ..result = r.success ? (r.queued ? 'QUEUED_OFFLINE' : 'MARKED') : 'FAILED: ${r.message}';
        return _say(r.speech, keep: r.success ? null : VoiceStatus.error);

      case VoiceIntent.endDay:
        if (s.todayAssignment == null) return _say('Aaj aapka koi kaam nahi hai.');
        final ok = await confirmAction(context, emoji: '🏁', title: 'Aaj ka kaam khatam?', speech: 'Kya aaj ka kaam khatam ho gaya?');
        log.confirmation = ok ? 'YES' : 'NO';
        if (!ok) return _say('Theek hai.');
        final a = s.todayAssignment;
        final r = s.endDay();
        log
          ..action = 'END_DAY'
          ..result = r.message;
        await _say(r.speech);
        if (a != null && a.status == WorkerJobStatus.completed && mounted) {
          pushReplacement(context, RatingScreen(jobId: a.job.id));
        }
        return;

      case VoiceIntent.readNextWork:
        final n = s.nextWorkDay;
        if (n == null) return _say('Abhi aage ka koi kaam pakka nahi hai. Kaam dhoondhne ke liye boliye, kaam batao.');
        final j = n.assignment.job;
        final when = Fmt.relativeDay(n.day, s.now) == 'Kal' ? 'Haan, kal' : '${Fmt.date(n.day)} ko';
        return _say('$when ${Fmt.timeSpoken(j.schedule.start)} aapka kaam hai. ${j.area} pahunchna hai. ${j.contractor.company} ka kaam hai.');

      case VoiceIntent.readSchedule:
        final j = _targetJob(s);
        if (j == null) return _say('Abhi koi kaam pakka nahi hai.');
        return _say(j.schedule.spoken);

      case VoiceIntent.readBreak:
        final j = _targetJob(s);
        if (j == null) return _say('Abhi koi kaam pakka nahi hai.');
        final ph = s.todayAssignment?.job.id == j.id ? s.todayPhase : null;
        if (ph?.kind == DayPhaseKind.onBreak) {
          final b = ph!.slot!;
          return _say('Abhi break hai. Aapka ${b.label} ${Fmt.timeSpoken(b.start)} se ${Fmt.timeSpoken(b.end)} tak hai.');
        }
        if (j.schedule.breaks.isEmpty) return _say('Is kaam mein koi break nahi bataya gaya hai.');
        return _say(j.schedule.breaks.map((b) => '${b.label} ${Fmt.timeSpoken(b.start)} se ${Fmt.timeSpoken(b.end)} tak.').join(' '));

      case VoiceIntent.reportAbsence:
        final a = s.todayAssignment;
        if (a == null) {
          log.result = 'NO_ACTIVE_JOB';
          return _say('Aaj aapka koi kaam assigned nahi hai, isliye chhutti batane ki zarurat nahi hai.');
        }
        final reason = p.reason ?? AbsenceReason.other;
        if (reason == AbsenceReason.other || p.dayOffset != 0) {
          // Unclear reason / not today → guided flow asks "sirf aaj ya kaam chhodna hai?"
          log.action = 'OPEN_ABSENCE_FLOW';
          await _say('Theek hai. Kuch sawaal poochhta hoon.');
          if (mounted) pushReplacement(context, AbsenceScreen(initialReason: p.reason));
          return;
        }
        final phrase = switch (reason) {
          AbsenceReason.sick => 'Aap aaj bimaar hain',
          AbsenceReason.injury => 'Aapko chot lagi hai',
          AbsenceReason.emergency => 'Aapke ghar mein emergency hai',
          AbsenceReason.family => 'Aapke ghar mein zaroori kaam hai',
          AbsenceReason.transport => 'Aaj aane ka saadhan nahi hai',
          AbsenceReason.other => 'Aap aaj nahi aa sakte',
        };
        final ok = await confirmAction(
          context,
          emoji: reason.emoji,
          title: 'Contractor ko bata dein?',
          speech: '$phrase aur kaam par nahi ja paayenge. Kya main contractor ko bata doon?',
          yesLabel: 'Haan, bata do',
        );
        log.confirmation = ok ? 'YES' : 'NO';
        if (!ok) return _say('Theek hai, contractor ko kuch nahi bheja.');
        final r = s.reportAbsence(reason, AbsenceScope.todayOnly);
        log
          ..action = 'ABSENCE_REPORTED'
          ..result = r.success ? (r.queued ? 'CONTRACTOR: QUEUED_OFFLINE' : 'CONTRACTOR: NOTIFIED') : 'FAILED';
        return _say(r.speech);

      case VoiceIntent.leaveJob:
        if (s.currentAssignment == null) return _say('Abhi aapka koi kaam chal nahi raha hai.');
        log.action = 'OPEN_LEAVE_FLOW';
        if (mounted) pushReplacement(context, LeaveJobScreen(jobId: s.currentAssignment!.job.id));
        return;

      case VoiceIntent.callContractor:
        final c = (s.todayAssignment ?? s.currentAssignment)?.job.contractor ?? widget.contextJob?.contractor;
        if (c == null) return _say('Abhi aapka koi contractor nahi hai.');
        log
          ..action = 'CALL_CONTRACTOR ${c.id}'
          ..result = 'DIALER_OPENED';
        await _say('${c.company} ko phone laga raha hoon.');
        if (mounted) await callPhone(context, c.phone);
        return;

      case VoiceIntent.openProfile:
        log.action = 'OPEN_PROFILE';
        await _say('Aapka profile khol raha hoon.');
        if (mounted) MainShell.goTo(context, MainShell.profile);
        return;

      case VoiceIntent.readProfile:
        return _say(s.profile.spoken);

      case VoiceIntent.help:
        log.action = 'OPEN_HELP';
        await _say('Madad ke options khol raha hoon.');
        if (mounted) pushReplacement(context, const HelpScreen());
        return;

      case VoiceIntent.unsafeWork:
        log.action = 'OPEN_UNSAFE_REPORT';
        if (mounted) pushReplacement(context, const UnsafeWorkScreen());
        return;

      case VoiceIntent.paymentIssue:
        log.action = 'OPEN_PAYMENT_REPORT';
        final pending = s.payments.where((x) => x.status != PaymentStatus.paid).firstOrNull;
        if (mounted) pushReplacement(context, ReportScreen(type: ReportType.payment, jobId: pending?.jobId));
        return;

      case VoiceIntent.yes || VoiceIntent.no:
        return _say('Kis baat ke liye? Boliye jaise, kaam batao, ya meri kamai kitni hai.');

      case VoiceIntent.unknown:
        log.result = 'NOT_UNDERSTOOD';
        return _say('Main samajh nahi paaya. Thoda dheere boliye.', keep: VoiceStatus.error);
    }
  }

  Future<void> _type() async {
    final t = await showTypeInputDialog(context, hint: 'Jaise: Kaam batao');
    if (t != null && t.trim().isNotEmpty) await _handle(t);
  }

  @override
  Widget build(BuildContext context) {
    final online = AppScope.of(context).online;
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: voice,
          builder: (context, _) {
            final st = !online && voice.status == VoiceStatus.idle ? VoiceStatus.offline : voice.status;
            final (title, sub) = _copy(st);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Band karein',
                        iconSize: 32,
                        icon: const Icon(Icons.close_rounded, color: AppColors.white),
                      ),
                      const Expanded(
                        child: Text('Kaam Saathi', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                      const MadadButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 12),
                      Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.yellowSoft, fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Center(
                        child: MicButton(
                          size: 150,
                          label: st == VoiceStatus.listening ? 'ROKO' : 'BOLO',
                          icon: switch (st) {
                            VoiceStatus.listening => Icons.graphic_eq_rounded,
                            VoiceStatus.speaking => Icons.volume_up_rounded,
                            VoiceStatus.processing => Icons.hourglass_top_rounded,
                            VoiceStatus.offline => Icons.wifi_off_rounded,
                            VoiceStatus.permissionDenied => Icons.mic_off_rounded,
                            _ => Icons.mic_rounded,
                          },
                          active: st == VoiceStatus.listening || st == VoiceStatus.speaking,
                          onTap: () {
                            if (st == VoiceStatus.listening) {
                              voice.stopListening();
                            } else if (st == VoiceStatus.speaking) {
                              voice.stopSpeaking();
                            } else {
                              _listen();
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: st == VoiceStatus.listening || st == VoiceStatus.speaking
                            ? const VoiceWaveform(color: AppColors.yellow)
                            : st == VoiceStatus.processing
                                ? const Center(child: SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 4)))
                                : null,
                      ),
                      if (st == VoiceStatus.listening && voice.transcript.isNotEmpty)
                        _Bubble(text: voice.transcript, mine: true)
                      else if (_heard != null)
                        _Bubble(text: _heard!, mine: true),
                      if (_reply != null) _Bubble(text: _reply!, mine: false),
                      for (final j in _jobs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: JobCard(job: j, onTap: () => pushReplacement(context, JobDetailsScreen(jobId: j.id))),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _Suggestions(
                  items: _suggestions,
                  onPick: (t) => _busy ? null : _handle(t),
                  onType: _type,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  (String, String) _copy(VoiceStatus st) => switch (st) {
        VoiceStatus.idle => ('Bolkar poochhein', 'Mic dabaiye aur boliye'),
        VoiceStatus.listening => ('Main sun raha hoon…', 'Boliye — jaise “Kaam batao”'),
        VoiceStatus.processing => ('Samajh raha hoon…', 'Ek second'),
        VoiceStatus.speaking => ('Suniye…', 'Rokne ke liye mic dabaiye'),
        VoiceStatus.error => ('Samajh nahi aaya', 'Dobara boliye — thoda dheere'),
        VoiceStatus.offline => ('Internet connection nahi hai', 'Neeche ke sawaal dabakar poochhein'),
        VoiceStatus.permissionDenied => ('Mic permission chahiye', 'Phone Settings → Apps → KaamSaathi → Microphone'),
        VoiceStatus.unavailable => ('Voice uplabdh nahi', 'Neeche ke sawaal dabakar poochhein'),
      };
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine});
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: mine ? AppColors.charcoalSoft : AppColors.yellow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Radii.m),
            topRight: const Radius.circular(Radii.m),
            bottomLeft: Radius.circular(mine ? Radii.m : 4),
            bottomRight: Radius.circular(mine ? 4 : Radii.m),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mine ? '🗣️' : '🤖', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                mine ? '“$text”' : text,
                style: TextStyle(
                  color: mine ? AppColors.white : AppColors.charcoal,
                  fontSize: 18,
                  fontWeight: mine ? FontWeight.w600 : FontWeight.w700,
                ),
              ),
            ),
            if (!mine) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () => voice.speak(text),
                child: const Icon(Icons.replay_rounded, color: AppColors.charcoal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.items, required this.onPick, required this.onType});
  final List<String> items;
  final void Function(String) onPick;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Ya dabakar poochhein', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              TextButton.icon(onPressed: onType, icon: const Icon(Icons.keyboard_rounded), label: const Text('Likhein')),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ActionChip(
                onPressed: () => onPick(items[i]),
                avatar: const Icon(Icons.mic_none_rounded, size: 20),
                label: Text(items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
