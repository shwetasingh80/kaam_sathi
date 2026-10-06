import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import 'models.dart';
import 'seed_data.dart';

/// Single source of truth for the app — acts as the *backend* for this build.
///
/// Every state change goes through a method here that validates business rules
/// (is the worker assigned? is today inside the job period? is the job still
/// open?) and returns an [ActionResult]. The voice layer only ever produces an
/// intent and calls these methods — it never mutates data directly.
class AppState extends ChangeNotifier {
  AppState();

  static const _kProfile = 'ks.profile';
  static const _kOnboarded = 'ks.onboarded';

  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  bool ready = false;
  bool onboarded = false;
  WorkerProfile profile = WorkerProfile();

  late SeedData _seed;
  final List<Job> jobs = [];
  final List<Assignment> assignments = [];
  final List<PaymentEntry> payments = [];
  final List<AppNotification> notifications = [];
  final List<ContractorMessage> contractorMessages = [];
  final List<VoiceLogEntry> voiceLogs = [];
  final List<ReportTicket> reports = [];
  final Set<String> rejectedJobIds = {};
  final Set<String> seenJobIds = {};

  /// Requests made while offline; sent when the connection returns.
  final List<String> pendingQueue = [];

  bool _deviceOnline = true;
  bool demoOffline = false;
  bool get online => _deviceOnline && !demoOffline;

  /// Demo-only clock override so every phase of the work day can be shown.
  TimeOfDay? demoTime;

  /// Job id that should be announced (full-screen) next. Set when a new job
  /// arrives; consumed by the home shell.
  String? pendingAnnouncementJobId;

  /// Job the worker is currently looking at — gives voice commands like
  /// "ye kaam karunga" / "kitna paisa milega" their context.
  String? focusedJobId;

  int _idCounter = 0;
  int _demoJobCounter = 0;

  DateTime get now {
    final real = DateTime.now();
    final t = demoTime;
    if (t == null) return real;
    return DateTime(real.year, real.month, real.day, t.hour, t.minute);
  }

  DateTime get today => Fmt.dayOnly(now);
  TimeOfDay get timeOfDay => TimeOfDay.fromDateTime(now);

  // ───────────────────────────────────────────────────────────── lifecycle

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      onboarded = _prefs!.getBool(_kOnboarded) ?? false;
      final raw = _prefs!.getString(_kProfile);
      if (raw != null) profile = WorkerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Storage unavailable — continue with in-memory state.
    }
    _seedData();
    _listenConnectivity();
    ready = true;
    notifyListeners();
  }

  void _seedData() {
    _seed = SeedData(DateTime.now());
    jobs
      ..clear()
      ..add(_seed.activeJob)
      ..addAll(_seed.openJobs());
    assignments
      ..clear()
      ..add(Assignment(
        job: _seed.activeJob,
        status: WorkerJobStatus.active,
        acceptedAt: _seed.d(-3),
        attendance: {
          _seed.d(-1): AttendanceRecord(
            date: _seed.d(-1),
            status: AttendanceStatus.completed,
            checkIn: _seed.d(-1).add(const Duration(hours: 7, minutes: 52)),
            checkOut: _seed.d(-1).add(const Duration(hours: 17)),
            method: AttendanceMethod.tap,
          ),
        },
      ));
    payments
      ..clear()
      ..addAll(_seed.payments());
    final n = DateTime.now();
    notifications
      ..clear()
      ..addAll([
        AppNotification(
          id: 'n1',
          type: NotifType.newJob,
          title: 'Naya kaam: Raj Mistri',
          body: 'Aliganj · ₹800 roz · 3 din',
          time: n.subtract(const Duration(minutes: 12)),
          jobId: 'j101',
        ),
        AppNotification(
          id: 'n2',
          type: NotifType.newJob,
          title: 'Naya kaam: Road ka kaam',
          body: 'Chinhat · ₹650 roz · 7 din',
          time: n.subtract(const Duration(hours: 5)),
          jobId: 'j103',
        ),
        AppNotification(
          id: 'n3',
          type: NotifType.contractorMessage,
          title: 'Sharma Builders',
          body: 'Kal sabhi log subah 8 baje site par samay se pahunchein.',
          time: n.subtract(const Duration(hours: 14)),
          jobId: 'j100',
          read: true,
        ),
        AppNotification(
          id: 'n4',
          type: NotifType.jobCancelled,
          title: 'Kaam cancel ho gaya',
          body: 'Raj Construction ne Hazratganj wala Helper ka kaam cancel kar diya hai.',
          time: n.subtract(const Duration(days: 1)),
          jobId: 'j105',
          read: true,
        ),
        AppNotification(
          id: 'n5',
          type: NotifType.paymentPending,
          title: '₹750 pending',
          body: 'Sharma Builders se kal ke kaam ka paisa abhi baaki hai.',
          time: n.subtract(const Duration(hours: 15)),
          jobId: 'j100',
          read: true,
        ),
        AppNotification(
          id: 'n6',
          type: NotifType.paymentReceived,
          title: '₹1,600 mile',
          body: 'Gupta Interiors se 2 din ke tile kaam ka paisa mil gaya.',
          time: n.subtract(const Duration(days: 4)),
          read: true,
        ),
      ]);
    contractorMessages.clear();
    voiceLogs.clear();
    reports.clear();
    rejectedJobIds.clear();
    seenJobIds
      ..clear()
      ..addAll(['j102', 'j104', 'j105', 'j106']);
  }

  void _listenConnectivity() {
    try {
      final c = Connectivity();
      c.checkConnectivity().then(_onConnectivity, onError: (_) {});
      _connSub = c.onConnectivityChanged.listen(_onConnectivity, onError: (_) {});
    } catch (_) {
      // Plugin unavailable (tests / unsupported platform) — assume online.
    }
  }

  void _onConnectivity(List<ConnectivityResult> r) {
    final was = online;
    _deviceOnline = r.isNotEmpty && !r.every((e) => e == ConnectivityResult.none);
    if (!was && online) _flushQueue();
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> saveProfile() async {
    notifyListeners();
    try {
      await _prefs?.setString(_kProfile, jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  Future<void> completeOnboarding() async {
    onboarded = true;
    profile.mobileVerified = true;
    await saveProfile();
    try {
      await _prefs?.setBool(_kOnboarded, true);
    } catch (_) {}
    notifyListeners();
  }

  /// Fills a complete sample profile (Rakesh Kumar persona) for quick demos.
  void loadDemoProfile() {
    profile = WorkerProfile(
      name: 'Rakesh Kumar',
      phone: '9876543210',
      language: 'hi',
      city: 'Lucknow',
      area: 'Kapoorthala',
      skills: ['MASON', 'HELPER', 'TILE'],
      experienceYears: 8,
      dailyWage: 800,
      workPrefs: {WorkCategory.construction, WorkCategory.road, WorkCategory.material},
      environment: WorkEnvironment.both,
      maxDistanceKm: 10,
      availability: Availability.working,
      shift: ShiftPreference.fullDay,
      mobileVerified: true,
      identityVerified: true,
      verifiedSkills: {'MASON'},
      rating: 4.7,
      jobsCompleted: 42,
      emergencyContact: '9876500099',
    );
  }

  Future<void> resetApp() async {
    try {
      await _prefs?.clear();
    } catch (_) {}
    onboarded = false;
    profile = WorkerProfile();
    demoTime = null;
    demoOffline = false;
    pendingQueue.clear();
    _seedData();
    notifyListeners();
  }

  String _nextId(String prefix) => '$prefix${++_idCounter}${DateTime.now().millisecondsSinceEpoch % 10000}';

  // ───────────────────────────────────────────────────────────── network

  /// Returns a queued result if offline (action is still applied locally and
  /// will sync later), otherwise null.
  ActionResult? _offlineGuard(String what, String successText) {
    if (online) return null;
    pendingQueue.add(what);
    return ActionResult.queued(
      'Internet nahi hai. Aapka request connection aate hi bhej diya jayega.',
      spoken: '$successText Internet nahi hai, isliye connection aate hi contractor ko bhej diya jayega.',
    );
  }

  void _flushQueue() {
    if (pendingQueue.isEmpty) return;
    final count = pendingQueue.length;
    pendingQueue.clear();
    _notify(NotifType.system, 'Connection wapas aa gaya',
        '$count request bhej diye gaye hain.');
  }

  void setDemoOffline(bool v) {
    final was = online;
    demoOffline = v;
    if (!was && online) _flushQueue();
    notifyListeners();
  }

  void setDemoTime(TimeOfDay? t) {
    demoTime = t;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────── jobs

  Job? jobById(String id) => jobs.where((j) => j.id == id).firstOrNull;

  Assignment? assignmentFor(String jobId) => assignments.where((a) => a.job.id == jobId).lastOrNull;

  /// Score used for matching (screen 33). Higher is better; < 0 means hide.
  int matchScore(Job j) {
    final p = profile;
    var score = 0;
    final skillIdx = p.skills.indexOf(j.skillId);
    final catMatch = p.workPrefs.contains(j.category);
    if (p.skills.isNotEmpty && skillIdx < 0 && !catMatch) return -1;
    if (skillIdx == 0) score += 40;
    if (skillIdx > 0) score += 25;
    if (catMatch) score += 10;
    if (j.distanceKm <= p.maxDistanceKm) {
      score += (20 * (1 - j.distanceKm / (p.maxDistanceKm + 1))).round();
    } else if (j.distanceKm > p.maxDistanceKm + 5) {
      return -1;
    }
    if (j.wage >= p.dailyWage) score += 15;
    if (j.wage < p.dailyWage * 0.75) score -= 10;
    if (p.environment != WorkEnvironment.both && j.environment != WorkEnvironment.both && p.environment != j.environment) {
      score -= 10;
    }
    score += (j.contractor.rating * 2).round();
    if (p.verifiedSkills.contains(j.skillId)) score += 5;
    return score;
  }

  /// Open jobs relevant to the worker, best first.
  List<Job> get matchedJobs {
    final list = jobs
        .where((j) => j.isAvailable && !rejectedJobIds.contains(j.id) && assignmentFor(j.id) == null)
        .where((j) => matchScore(j) >= 0)
        .toList()
      ..sort((a, b) => matchScore(b).compareTo(matchScore(a)));
    return list;
  }

  /// Jobs that are no longer available but the worker may still open
  /// (expired / cancelled) — shown so edge-case states are visible.
  List<Job> get closedJobs => jobs
      .where((j) => j.status == JobStatus.expired || j.status == JobStatus.cancelled)
      .toList();

  List<Job> get newJobs => matchedJobs.where((j) => !seenJobIds.contains(j.id)).toList();

  void markJobSeen(String id) {
    if (seenJobIds.add(id)) notifyListeners();
  }

  /// Live assignment whose period includes today.
  Assignment? get todayAssignment => assignments
      .where((a) => a.isLive && a.job.coversDay(today))
      .firstOrNull;

  /// Live assignments starting after today, soonest first.
  List<Assignment> get upcomingAssignments => assignments
      .where((a) => a.isLive && Fmt.dayOnly(a.job.startDate).isAfter(today))
      .toList()
    ..sort((a, b) => a.job.startDate.compareTo(b.job.startDate));

  /// Next working day info (for "Kal kaam hai?").
  ({Assignment assignment, DateTime day})? get nextWorkDay {
    final tomorrow = today.add(const Duration(days: 1));
    final t = todayAssignment;
    if (t != null && t.job.coversDay(tomorrow)) return (assignment: t, day: tomorrow);
    final up = upcomingAssignments.firstOrNull;
    if (up != null) return (assignment: up, day: Fmt.dayOnly(up.job.startDate));
    return null;
  }

  List<Assignment> get liveAssignments => assignments.where((a) => a.isLive).toList();

  List<Assignment> get pastAssignments => assignments.where((a) => !a.isLive).toList();

  Assignment? conflictFor(Job j) =>
      assignments.where((a) => a.isLive && a.job.id != j.id && a.job.overlaps(j)).firstOrNull;

  ActionResult acceptJob(Job j) {
    if (j.status == JobStatus.cancelled) {
      return const ActionResult.fail('Contractor ne ye kaam cancel kar diya hai.');
    }
    if (!j.isAvailable || Fmt.dayOnly(j.startDate).isBefore(today)) {
      j.status = j.status == JobStatus.open || j.status == JobStatus.partiallyFilled ? JobStatus.expired : j.status;
      notifyListeners();
      return const ActionResult.fail('Ye kaam ab available nahi hai.');
    }
    final conflict = conflictFor(j);
    if (conflict != null) {
      return ActionResult.fail(
        'Is samay aap ek aur kaam par assigned hain.',
        spoken: 'Is samay aap ek aur kaam par assigned hain. ${conflict.job.contractor.company} ka kaam ${Fmt.date(conflict.job.endDate)} tak chalega. Isliye ye kaam nahi le sakte.',
      );
    }
    assignments.add(Assignment(job: j, status: WorkerJobStatus.accepted, acceptedAt: now));
    j.workersFilled += 1;
    j.status = j.workersFilled >= j.workersNeeded ? JobStatus.filled : JobStatus.partiallyFilled;
    seenJobIds.add(j.id);
    _notify(NotifType.jobAccepted, 'Kaam pakka ho gaya',
        '${j.title} · ${j.area} · ${Fmt.date(j.startDate)} se', jobId: j.id);
    _notify(NotifType.workReminder, 'Yaad rakhein',
        '${Fmt.relativeDay(j.startDate, now)} ${Fmt.time(j.schedule.start)} baje ${j.area} pahunchna hai.',
        jobId: j.id,
        spoken: '${profile.firstName} ji, ${Fmt.date(j.startDate)} ko ${Fmt.timeSpoken(j.schedule.start)} aapka kaam hai. ${j.area} pahunchna hai.');
    final queued = _offlineGuard('Kaam accept: ${j.id}', 'Aapka kaam pakka kar diya gaya hai.');
    notifyListeners();
    return queued ?? const ActionResult.ok('Aapka kaam pakka ho gaya hai.');
  }

  ActionResult rejectJob(Job j) {
    rejectedJobIds.add(j.id);
    seenJobIds.add(j.id);
    notifyListeners();
    return const ActionResult.ok('Kaam reject kar diya gaya.',
        spoken: 'Theek hai, ye kaam aapko dobara nahi dikhaya jayega.');
  }

  // ───────────────────────────────────────────────────────────── attendance

  AttendanceRecord? get todayRecord => todayAssignment?.recordFor(today);

  AttendanceStatus get todayStatus => todayRecord?.status ?? AttendanceStatus.notMarked;

  DayPhase? get todayPhase => todayAssignment?.job.schedule.phaseAt(timeOfDay);

  ActionResult markAttendance(AttendanceMethod method) {
    final a = todayAssignment;
    if (a == null) {
      return const ActionResult.fail('Aaj aapka koi kaam assigned nahi hai.');
    }
    final existing = a.recordFor(today);
    if (existing != null && (existing.status == AttendanceStatus.present || existing.status == AttendanceStatus.completed)) {
      return ActionResult.ok('Aapki aaj ki attendance pehle se lagi hai.',
          spoken: 'Aapki aaj ki attendance ${existing.checkIn == null ? '' : '${Fmt.timeSpoken(TimeOfDay.fromDateTime(existing.checkIn!))} '}pehle se lagi hai.');
    }
    a.attendance[today] = AttendanceRecord(
      date: today,
      status: AttendanceStatus.present,
      checkIn: now,
      method: method,
    );
    a.status = WorkerJobStatus.active;
    profile.availability = Availability.working;
    _notify(NotifType.attendance, 'Attendance lag gayi',
        '${a.job.contractor.company} · ${Fmt.time(timeOfDay)}', jobId: a.job.id);
    final queued = _offlineGuard('Attendance: ${a.job.id}', 'Aapki aaj ki attendance laga di gayi hai.');
    notifyListeners();
    return queued ?? const ActionResult.ok('Aapki aaj ki attendance laga di gayi hai.');
  }

  /// Ends today's work, creates today's earning entry. If it was the last day
  /// the assignment is completed (caller should then show rating).
  ActionResult endDay() {
    final a = todayAssignment;
    if (a == null) return const ActionResult.fail('Aaj aapka koi kaam assigned nahi hai.');
    final rec = a.recordFor(today);
    if (rec == null || rec.status != AttendanceStatus.present) {
      if (rec?.status == AttendanceStatus.completed) {
        return const ActionResult.ok('Aaj ka kaam pehle hi poora ho chuka hai.');
      }
      return const ActionResult.fail('Pehle attendance lagayein.',
          spoken: 'Aaj ki attendance nahi lagi hai. Pehle attendance lagayein.');
    }
    rec
      ..status = AttendanceStatus.completed
      ..checkOut = now;
    final job = a.job;
    final paidDaily = job.paymentFrequency == PaymentFrequency.daily;
    payments.insert(
      0,
      PaymentEntry(
        id: _nextId('p'),
        contractor: job.contractor.company,
        workTitle: job.skill.name,
        days: 1,
        amount: job.wage,
        date: today,
        status: PaymentStatus.pending,
        jobId: job.id,
      ),
    );
    final lastDay = Fmt.dayOnly(job.endDate) == today;
    if (lastDay) {
      a.status = WorkerJobStatus.completed;
      job.status = JobStatus.completed;
      profile.jobsCompleted += 1;
      profile.availability = Availability.available;
      saveProfile();
    }
    _notify(
      paidDaily ? NotifType.paymentPending : NotifType.attendance,
      'Aaj ki kamai ${Fmt.rupees(job.wage)}',
      paidDaily ? 'Payment pending · ${job.contractor.company}' : 'Paisa ${job.paymentFrequency.label} milega',
      jobId: job.id,
    );
    notifyListeners();
    final spoken = 'Aaj ka kaam poora ho gaya. Aapki attendance laga di gayi hai. Aaj ki kamai ${Fmt.rupeesSpoken(job.wage)}.'
        '${lastDay ? ' Ye is kaam ka aakhri din tha. Shabash!' : ''}';
    return ActionResult.ok('Aaj ka kaam poora ho gaya.', spoken: spoken);
  }

  ActionResult reportAbsence(AbsenceReason reason, AbsenceScope scope, {String? note}) {
    if (scope == AbsenceScope.leaveJob) return leaveJob(reason.label);
    final a = todayAssignment;
    if (a == null) {
      return const ActionResult.fail('Aaj aapka koi kaam assigned nahi hai.',
          spoken: 'Aaj aapka koi kaam assigned nahi hai, isliye chhutti batane ki zarurat nahi hai.');
    }
    final status = reason.attendanceStatus;
    final existing = a.recordFor(today);
    a.attendance[today] = AttendanceRecord(
      date: today,
      status: status,
      checkIn: existing?.checkIn,
      reason: reason,
      note: note,
    );
    a.status = status == AttendanceStatus.absentSick ? WorkerJobStatus.absentSick : WorkerJobStatus.absentEmergency;
    final returning = scope == AbsenceScope.fewDays ? ' Wo kal se kaam par aayenge.' : '';
    contractorMessages.insert(
      0,
      ContractorMessage(
        text: '${profile.name} aaj ${reason.because} kaam par nahi aa paayenge.$returning',
        time: now,
        kind: 'ABSENCE_${status.name.toUpperCase()}',
        options: const [
          'Chhutti manzoor karein',
          'Worker ko call karein',
          'Replacement dhoondhein',
          'Kam workers se kaam chalayein',
          'Bina paise ki chhutti mark karein',
          'Support se baat karein',
        ],
      ),
    );
    final isHealth = status == AttendanceStatus.absentSick;
    final msg = isHealth
        ? 'Contractor ko aapki tabiyat ki jaankari bhej di gayi.'
        : 'Contractor ko aapki chhutti ki jaankari bhej di gayi.';
    _notify(NotifType.emergency, 'Chhutti ki jaankari bheji', '${a.job.contractor.company} · ${reason.label}', jobId: a.job.id);
    final queued = _offlineGuard('Chhutti: ${a.job.id}', msg);
    notifyListeners();
    return queued ??
        ActionResult.ok(msg,
            spoken: '$msg ${isHealth ? 'Aaram kijiye, jaldi theek ho jaiye.' : 'Apna dhyaan rakhiye.'}');
  }

  /// Simulates the contractor approving today's absence.
  void contractorApprovesAbsence() {
    final a = todayAssignment;
    final r = a?.recordFor(today);
    if (a == null || r == null) return;
    if (r.status == AttendanceStatus.absentSick || r.status == AttendanceStatus.absentEmergency) {
      r.status = AttendanceStatus.absentApproved;
      _notify(NotifType.contractorMessage, a.job.contractor.company,
          'Aapki aaj ki chhutti manzoor ho gayi hai. Apna dhyaan rakhein.', jobId: a.job.id);
      notifyListeners();
    }
  }

  /// The live assignment a leave/absence applies to (today's, else next).
  Assignment? get currentAssignment => todayAssignment ?? upcomingAssignments.firstOrNull;

  ActionResult leaveJob(String reason, {Assignment? assignment}) {
    final a = assignment ?? currentAssignment;
    if (a == null) return const ActionResult.fail('Abhi aapka koi kaam chal nahi raha hai.');
    a.status = WorkerJobStatus.leftJob;
    a.leaveReason = reason;
    if (a.job.coversDay(today)) {
      a.attendance[today] = AttendanceRecord(date: today, status: AttendanceStatus.leftJob, note: reason);
    }
    a.job.workersFilled = (a.job.workersFilled - 1).clamp(0, a.job.workersNeeded);
    if (a.job.status == JobStatus.filled || a.job.status == JobStatus.inProgress) {
      a.job.status = JobStatus.partiallyFilled;
    }
    profile.availability = Availability.available;
    contractorMessages.insert(
      0,
      ContractorMessage(
        text: '${profile.name} ne bataya hai ki wo ye kaam aage nahi kar paayenge. Karan: $reason.',
        time: now,
        kind: 'LEFT_JOB',
        options: const [
          'Replacement dhoondhein',
          'Worker ko call karein',
          'Kam workers se kaam chalayein',
          'Support se baat karein',
        ],
      ),
    );
    _notify(NotifType.replacement, 'Kaam chhodne ki jaankari bheji', '${a.job.contractor.company} ko bata diya gaya hai.', jobId: a.job.id);
    saveProfile();
    final queued = _offlineGuard('Kaam chhoda: ${a.job.id}', 'Contractor ko bata diya gaya hai.');
    notifyListeners();
    return queued ??
        const ActionResult.ok('Contractor ko bata diya gaya hai.',
            spoken: 'Contractor ko bata diya gaya hai ki aap ye kaam aage nahi kar paayenge. Aapke profile par koi saza nahi lagegi.');
  }

  void rateContractor(Assignment a, int stars) {
    a.ratingGiven = stars;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────── earnings

  int _sum(bool Function(PaymentEntry p) test) =>
      payments.where(test).fold(0, (s, p) => s + p.amount);

  int get earnedToday => _sum((p) => Fmt.dayOnly(p.date) == today);

  int get earnedThisWeek {
    final start = today.subtract(Duration(days: today.weekday - 1));
    return _sum((p) => !Fmt.dayOnly(p.date).isBefore(start));
  }

  int get earnedThisMonth => _sum((p) => p.date.year == today.year && p.date.month == today.month);

  int get pendingAmount => _sum((p) => p.status == PaymentStatus.pending || p.status == PaymentStatus.requested);

  /// Today's payment entry if the day was completed.
  PaymentEntry? get todayPayment => payments.where((p) => Fmt.dayOnly(p.date) == today).firstOrNull;

  ActionResult requestPayment(PaymentEntry p) {
    if (p.status == PaymentStatus.paid) return const ActionResult.ok('Ye payment pehle hi mil chuka hai.');
    p.status = PaymentStatus.requested;
    contractorMessages.insert(
      0,
      ContractorMessage(
        text: '${profile.name} ne ${p.workTitle} ke ${Fmt.days(p.days)} ke ${Fmt.rupees(p.amount)} ka payment maanga hai.',
        time: now,
        kind: 'PAYMENT_REQUEST',
        options: const ['Payment karein', 'Worker ko call karein'],
      ),
    );
    final queued = _offlineGuard('Payment request: ${p.id}', 'Payment request bhej di gayi hai.');
    notifyListeners();
    return queued ?? const ActionResult.ok('Payment request contractor ko bhej di gayi hai.');
  }

  /// Demo: contractor pays all pending amounts.
  void simulatePaymentReceived() {
    for (final p in payments.where((p) => p.status != PaymentStatus.paid && p.status != PaymentStatus.disputed)) {
      p.status = PaymentStatus.paid;
      _notify(NotifType.paymentReceived, '${Fmt.rupees(p.amount)} mile', '${p.contractor} se ${Fmt.days(p.days)} ke kaam ka paisa mil gaya.',
          spoken: p.spoken);
    }
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────── notifications

  int get unreadCount => notifications.where((n) => !n.read).length;

  void markRead(AppNotification n) {
    if (!n.read) {
      n.read = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void _notify(NotifType type, String title, String body, {String? jobId, String? spoken}) {
    notifications.insert(
      0,
      AppNotification(id: _nextId('n'), type: type, title: title, body: body, time: now, jobId: jobId, spoken: spoken),
    );
  }

  /// Demo: a new matching job arrives → notification + voice announcement.
  Job simulateNewJob() {
    final j = _seed.demoIncomingJob(_demoJobCounter++);
    jobs.add(j);
    _notify(NotifType.newJob, 'Naya kaam: ${j.skill.name}', '${j.area} · ${Fmt.rupees(j.wage)} roz · ${Fmt.days(j.days)}',
        jobId: j.id, spoken: j.announcement(profile.firstName));
    pendingAnnouncementJobId = j.id;
    notifyListeners();
    return j;
  }

  String? takePendingAnnouncement() {
    final id = pendingAnnouncementJobId;
    pendingAnnouncementJobId = null;
    return id;
  }

  // ───────────────────────────────────────────────────────────── reports

  ActionResult submitReport(ReportType type, {String? jobId, String? details, bool stoppedWork = false}) {
    final t = ReportTicket(id: 'R-${1000 + reports.length + 1}', type: type, time: now, jobId: jobId, details: details, stoppedWork: stoppedWork);
    reports.insert(0, t);
    if (type == ReportType.payment || type == ReportType.wrongWage) {
      for (final p in payments.where((p) => p.jobId == jobId && p.status != PaymentStatus.paid)) {
        p.status = PaymentStatus.disputed;
      }
    }
    _notify(NotifType.system, 'Shikayat darj: ${t.id}', '${type.label} · Support team 24 ghante mein sampark karegi.');
    final queued = _offlineGuard('Report: ${t.id}', 'Aapki shikayat darj kar li gayi hai.');
    notifyListeners();
    return queued ??
        ActionResult.ok('Aapki shikayat darj ho gayi. Number: ${t.id}',
            spoken: 'Aapki shikayat darj ho gayi hai. Hamari team jald hi aapse baat karegi.');
  }

  // ───────────────────────────────────────────────────────────── reliability

  Reliability get reliability {
    var present = 0, sick = 0, emergency = 0, noShow = 0;
    for (final a in assignments) {
      for (final r in a.attendance.values) {
        switch (r.status) {
          case AttendanceStatus.present || AttendanceStatus.completed:
            present++;
          case AttendanceStatus.absentSick:
            sick++;
          case AttendanceStatus.absentEmergency || AttendanceStatus.absentApproved:
            emergency++;
          case AttendanceStatus.noShow:
            noShow++;
          default:
            break;
        }
      }
    }
    return Reliability(
      accepted: assignments.length + profile.jobsCompleted,
      completed: profile.jobsCompleted + assignments.where((a) => a.status == WorkerJobStatus.completed).length,
      presentDays: present + profile.jobsCompleted * 3,
      sickDays: sick,
      emergencyDays: emergency,
      noShows: noShow,
      leftJobs: assignments.where((a) => a.status == WorkerJobStatus.leftJob).length,
      cancellations: 0,
    );
  }

  // ───────────────────────────────────────────────────────────── voice log

  VoiceLogEntry logVoice(String transcript, String intent, {Map<String, String> slots = const {}}) {
    final e = VoiceLogEntry(time: now, transcript: transcript, intent: intent, slots: slots);
    voiceLogs.insert(0, e);
    return e;
  }

  void touch() => notifyListeners();
}

/// Provides [AppState] to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Read + rebuild on change.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
