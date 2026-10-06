import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Skills & categories
// ─────────────────────────────────────────────────────────────────────────────

enum WorkCategory {
  construction('Construction', 'Bilding ka kaam', '🏗️'),
  road('Road ka kaam', 'Sadak ka kaam', '🛣️'),
  agriculture('Khet ka kaam', 'Kheti', '🌾'),
  material('Material uthana', 'Maal dhona', '🧱'),
  loading('Loading / Unloading', 'Chadhana-utaarna', '📦'),
  factory('Factory', 'Factory helper', '🏭'),
  gardening('Bagicha', 'Mali ka kaam', '🌳'),
  household('Ghar ka kaam', 'Saaf-safai', '🏠'),
  other('Aur kaam', 'General labour', '🛠️');

  const WorkCategory(this.label, this.hint, this.emoji);
  final String label;
  final String hint;
  final String emoji;
}

class Skill {
  const Skill({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.keywords = const [],
  });

  final String id;
  final String name;
  final String emoji;
  final WorkCategory category;

  /// Words (Roman + Devanagari) used by the voice parser to detect this skill.
  final List<String> keywords;
}

class SkillCatalog {
  SkillCatalog._();

  static const all = <Skill>[
    Skill(id: 'MASON', name: 'Raj Mistri', emoji: '👷', category: WorkCategory.construction,
        keywords: ['raj mistri', 'rajmistri', 'mistri', 'mason', 'raaj mistri', 'राज मिस्त्री', 'मिस्त्री', 'राजमिस्त्री']),
    Skill(id: 'HELPER', name: 'Construction Helper', emoji: '🧱', category: WorkCategory.construction,
        keywords: ['helper', 'hailper', 'beldar', 'हेल्पर', 'बेलदार', 'मजदूर', 'mazdoor', 'majdoor']),
    Skill(id: 'CARPENTER', name: 'Carpenter', emoji: '🔨', category: WorkCategory.construction,
        keywords: ['carpenter', 'badhai', 'barhai', 'kaarpenter', 'बढ़ई', 'कारपेंटर', 'लकड़ी']),
    Skill(id: 'ELECTRICIAN', name: 'Electrician', emoji: '⚡', category: WorkCategory.construction,
        keywords: ['electrician', 'bijli', 'wiring', 'इलेक्ट्रीशियन', 'बिजली']),
    Skill(id: 'PLUMBER', name: 'Plumber', emoji: '🚰', category: WorkCategory.construction,
        keywords: ['plumber', 'nal', 'pipe', 'प्लंबर', 'नल', 'पाइप']),
    Skill(id: 'PAINTER', name: 'Painter', emoji: '🎨', category: WorkCategory.construction,
        keywords: ['painter', 'paint', 'putai', 'rang', 'पेंटर', 'पुताई', 'रंग', 'पेंट']),
    Skill(id: 'TILE', name: 'Tile ka kaam', emoji: '🔲', category: WorkCategory.construction,
        keywords: ['tile', 'tiles', 'marble', 'टाइल', 'मार्बल']),
    Skill(id: 'WELDER', name: 'Welder', emoji: '🔥', category: WorkCategory.construction,
        keywords: ['welder', 'welding', 'वेल्डर', 'वेल्डिंग']),
    Skill(id: 'SHUTTERING', name: 'Shuttering', emoji: '🪵', category: WorkCategory.construction,
        keywords: ['shuttering', 'centring', 'centering', 'शटरिंग', 'सेंटरिंग']),
    Skill(id: 'BAR_BENDER', name: 'Sariya / Bar-bender', emoji: '➰', category: WorkCategory.construction,
        keywords: ['bar bender', 'sariya', 'saria', 'सरिया', 'बार बेंडर']),
    Skill(id: 'POP', name: 'POP ka kaam', emoji: '⬜', category: WorkCategory.construction,
        keywords: ['pop', 'p o p', 'false ceiling', 'पीओपी']),
    Skill(id: 'FLOORING', name: 'Flooring', emoji: '🟫', category: WorkCategory.construction,
        keywords: ['flooring', 'farsh', 'फर्श', 'फ्लोरिंग']),
    Skill(id: 'ROAD', name: 'Road ka kaam', emoji: '🛣️', category: WorkCategory.road,
        keywords: ['road', 'sadak', 'सड़क', 'रोड', 'khudai', 'खुदाई', 'bitumen', 'damar', 'डामर', 'paver', 'drain', 'naali', 'नाली']),
    Skill(id: 'CONCRETE', name: 'Concrete / Masala', emoji: '🪣', category: WorkCategory.road,
        keywords: ['concrete', 'masala', 'मसाला', 'कंक्रीट', 'dhalai', 'ढलाई']),
    Skill(id: 'FARM', name: 'Khet ka kaam', emoji: '🌾', category: WorkCategory.agriculture,
        keywords: ['khet', 'kheti', 'farm', 'खेत', 'खेती', 'katai', 'कटाई', 'fasal', 'फसल', 'nirai', 'निराई']),
    Skill(id: 'PLANTING', name: 'Paudhe lagana', emoji: '🌱', category: WorkCategory.agriculture,
        keywords: ['paudhe', 'paudha', 'planting', 'ropai', 'पौधे', 'पौधा', 'रोपाई', 'nursery', 'नर्सरी']),
    Skill(id: 'MATERIAL', name: 'Maurang / Balu uthana', emoji: '🏗️', category: WorkCategory.material,
        keywords: ['maurang', 'balu', 'mitti', 'material', 'मौरंग', 'बालू', 'मिट्टी', 'cement', 'सीमेंट', 'uthana', 'उठाना']),
    Skill(id: 'LOADING', name: 'Loading / Unloading', emoji: '📦', category: WorkCategory.loading,
        keywords: ['loading', 'unloading', 'load', 'लोडिंग', 'अनलोडिंग', 'palledari', 'पल्लेदारी', 'hamal', 'हमाल']),
    Skill(id: 'GARDENER', name: 'Mali / Gardener', emoji: '🌳', category: WorkCategory.gardening,
        keywords: ['mali', 'maali', 'garden', 'gardener', 'bagicha', 'माली', 'बगीचा']),
    Skill(id: 'CLEANING', name: 'Saaf-safai', emoji: '🧹', category: WorkCategory.household,
        keywords: ['safai', 'cleaning', 'jhadu', 'सफाई', 'झाड़ू']),
    Skill(id: 'WAREHOUSE', name: 'Godown / Warehouse', emoji: '🏬', category: WorkCategory.factory,
        keywords: ['warehouse', 'godown', 'गोदाम', 'गोडाउन']),
    Skill(id: 'FACTORY', name: 'Factory Helper', emoji: '🏭', category: WorkCategory.factory,
        keywords: ['factory', 'फैक्ट्री', 'karkhana', 'कारखाना']),
    Skill(id: 'DEMOLITION', name: 'Todne ka kaam', emoji: '⛏️', category: WorkCategory.construction,
        keywords: ['todna', 'todne', 'demolition', 'तोड़ना', 'तोड़']),
    Skill(id: 'GENERAL', name: 'General Labour', emoji: '💪', category: WorkCategory.other,
        keywords: ['general', 'koi bhi', 'कोई भी', 'labour', 'लेबर']),
  ];

  static Skill byId(String id) => all.firstWhere((s) => s.id == id, orElse: () => all.last);
}

// ─────────────────────────────────────────────────────────────────────────────
// Job conditions
// ─────────────────────────────────────────────────────────────────────────────

enum PhysicalLevel {
  light('Halka', '🪶'),
  medium('Madhyam', '💪'),
  heavy('Bhaari', '🏋️');

  const PhysicalLevel(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum WorkEnvironment {
  indoor('Andar', '🏠'),
  outdoor('Bahar', '☀️'),
  both('Andar + Bahar', '🔁');

  const WorkEnvironment(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum WorkCondition {
  height('Oonchai par kaam', '🪜', 'Is kaam mein height par kaam karna hai.'),
  dust('Dhool', '🌫️', 'Is kaam mein dhool hogi.'),
  heat('Garmi / Dhoop', '🌡️', 'Is kaam mein dhoop aur garmi mein kaam hai.'),
  water('Paani mein kaam', '💧', 'Is kaam mein paani mein kaam karna padega.'),
  heavyLifting('Bhaari saman', '🏋️', 'Is kaam mein bhaari saman uthana padega.'),
  roadTraffic('Road traffic', '🚗', 'Is kaam mein sadak par traffic ke paas kaam hai.'),
  machinery('Machine', '⚙️', 'Is kaam mein machine chalani ya machine ke paas kaam karna hai.'),
  chemical('Dawai / Chemical', '🧪', 'Is kaam mein dawai ya chemical ka istemal hoga.');

  const WorkCondition(this.label, this.emoji, this.spoken);
  final String label;
  final String emoji;
  final String spoken;
}

enum PaymentFrequency {
  daily('Roz shaam ko'),
  weekly('Har hafte'),
  endOfJob('Kaam khatam hone par');

  const PaymentFrequency(this.label);
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule
// ─────────────────────────────────────────────────────────────────────────────

class BreakSlot {
  const BreakSlot({required this.label, required this.start, required this.end, this.isLunch = false});
  final String label;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool isLunch;

  int get minutes => Fmt.minutesOf(end) - Fmt.minutesOf(start);
}

class WorkSchedule {
  const WorkSchedule({
    required this.start,
    required this.end,
    this.breaks = const [],
    this.weeklyOff = 'Ravivar',
    this.overtimePerHour,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final List<BreakSlot> breaks;
  final String weeklyOff;
  final int? overtimePerHour;

  BreakSlot? get lunch => breaks.where((b) => b.isLunch).firstOrNull;

  String get rangeLabel => '${Fmt.time(start)} – ${Fmt.time(end)}';

  String get breakSummary {
    if (breaks.isEmpty) return 'Koi break nahi';
    final total = breaks.fold<int>(0, (s, b) => s + b.minutes);
    return '${breaks.length} break · kul ${Fmt.durationMinutes(total)}';
  }

  String get spoken {
    final b = StringBuffer(
      'Kaam ${Fmt.timeSpoken(start)} shuru hoga aur ${Fmt.timeSpoken(end)} khatam hoga.',
    );
    for (final br in breaks) {
      b.write(' ${br.label} ${Fmt.timeSpoken(br.start)} se ${Fmt.timeSpoken(br.end)} tak hoga.');
    }
    return b.toString();
  }

  /// What is happening at [now] according to this schedule.
  DayPhase phaseAt(TimeOfDay now) {
    final n = Fmt.minutesOf(now);
    if (n < Fmt.minutesOf(start)) return const DayPhase(DayPhaseKind.beforeStart);
    if (n >= Fmt.minutesOf(end)) return const DayPhase(DayPhaseKind.ended);
    for (final b in breaks) {
      if (n >= Fmt.minutesOf(b.start) && n < Fmt.minutesOf(b.end)) {
        return DayPhase(DayPhaseKind.onBreak, slot: b);
      }
    }
    return const DayPhase(DayPhaseKind.working);
  }
}

enum DayPhaseKind { beforeStart, working, onBreak, ended }

class DayPhase {
  const DayPhase(this.kind, {this.slot});
  final DayPhaseKind kind;
  final BreakSlot? slot;
}

// ─────────────────────────────────────────────────────────────────────────────
// Contractor
// ─────────────────────────────────────────────────────────────────────────────

class Contractor {
  const Contractor({
    required this.id,
    required this.company,
    required this.ownerName,
    required this.phone,
    required this.area,
    this.mobileVerified = true,
    this.identityVerified = false,
    this.rating = 0,
    this.ratingCount = 0,
    this.workersHired = 0,
    this.jobsCompleted = 0,
    this.paymentOnTimePercent = 0,
    this.since = 2024,
  });

  final String id;
  final String company;
  final String ownerName;
  final String phone;
  final String area;
  final bool mobileVerified;
  final bool identityVerified;
  final double rating;
  final int ratingCount;
  final int workersHired;
  final int jobsCompleted;
  final int paymentOnTimePercent;
  final int since;

  String get spokenTrust {
    final parts = <String>[company];
    if (identityVerified) parts.add('pehchaan verified hai');
    if (rating > 0) parts.add('rating ${rating.toStringAsFixed(1)} hai');
    if (workersHired > 0) parts.add('inhone $workersHired mazdooron ko kaam diya hai');
    if (paymentOnTimePercent > 0) parts.add('$paymentOnTimePercent pratishat payment samay par diya hai');
    return '${parts.join(', ')}.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job
// ─────────────────────────────────────────────────────────────────────────────

enum JobStatus { draft, open, partiallyFilled, filled, inProgress, completed, cancelled, expired }

class Job {
  Job({
    required this.id,
    required this.skillId,
    required this.contractor,
    required this.area,
    required this.city,
    required this.distanceKm,
    required this.days,
    required this.wage,
    required this.startDate,
    required this.schedule,
    required this.category,
    this.physical = PhysicalLevel.medium,
    this.environment = WorkEnvironment.outdoor,
    this.conditions = const [],
    this.workersNeeded = 1,
    this.workersFilled = 0,
    this.status = JobStatus.open,
    this.paymentFrequency = PaymentFrequency.daily,
    this.landmark,
    this.note,
    this.medicalProofRequired = false,
    DateTime? postedAt,
  }) : postedAt = postedAt ?? DateTime.now();

  final String id;
  final String skillId;
  final Contractor contractor;
  final String area;
  final String city;
  final double distanceKm;
  final int days;
  final int wage;
  final DateTime startDate;
  final WorkSchedule schedule;
  final WorkCategory category;
  final PhysicalLevel physical;
  final WorkEnvironment environment;
  final List<WorkCondition> conditions;
  final int workersNeeded;
  int workersFilled;
  JobStatus status;
  final PaymentFrequency paymentFrequency;
  final String? landmark;
  final String? note;
  final bool medicalProofRequired;
  final DateTime postedAt;

  Skill get skill => SkillCatalog.byId(skillId);
  String get title => '${skill.name} ka kaam';
  String get place => '$area, $city';
  DateTime get endDate => startDate.add(Duration(days: days - 1));
  int get totalEarning => wage * days;

  bool get isAvailable => status == JobStatus.open || status == JobStatus.partiallyFilled;

  bool coversDay(DateTime day) {
    final d = Fmt.dayOnly(day);
    return !d.isBefore(Fmt.dayOnly(startDate)) && !d.isAfter(Fmt.dayOnly(endDate));
  }

  bool overlaps(Job other) =>
      !Fmt.dayOnly(endDate).isBefore(Fmt.dayOnly(other.startDate)) &&
      !Fmt.dayOnly(other.endDate).isBefore(Fmt.dayOnly(startDate));

  /// Full TTS announcement (screen 22).
  String announcement(String workerName) {
    final b = StringBuffer('$workerName ji, aapke liye naya kaam aaya hai. ');
    b.write('$area mein ${skill.name} ki zarurat hai. ');
    b.write('${Fmt.rupeesSpoken(wage)} roz milenge. ');
    b.write('${Fmt.days(days)} ka kaam hai. ');
    b.write('Kaam ${Fmt.timeSpoken(schedule.start)} se ${Fmt.timeSpoken(schedule.end)} tak hai. ');
    b.write('Kya aap kaam dekhna chahte hain?');
    return b.toString();
  }

  /// Detailed TTS description (job details screen).
  String spokenDetails() {
    final b = StringBuffer('$title. ');
    b.write('Jagah: $place. ');
    b.write('${Fmt.days(days)} ka kaam, ${Fmt.date(startDate)} se. ');
    b.write('${Fmt.rupeesSpoken(wage)} roz. Kul ${Fmt.rupeesSpoken(totalEarning)} banenge. ');
    b.write(schedule.spoken);
    b.write(' Payment ${paymentFrequency.label} milega. ');
    for (final c in conditions) {
      b.write('${c.spoken} ');
    }
    b.write('Kaam dene wale: ${contractor.company}.');
    return b.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Worker ↔ Job (Project Worker)
// ─────────────────────────────────────────────────────────────────────────────

enum WorkerJobStatus {
  invited('Bulaya gaya', AppColors.blueTint, AppColors.blueDark, Icons.mail_outline),
  pending('Intezaar', AppColors.orangeTint, AppColors.orangeDark, Icons.hourglass_top_rounded),
  accepted('Pakka ✓', AppColors.greenTint, AppColors.greenDark, Icons.verified_rounded),
  rejected('Mana kiya', AppColors.redTint, AppColors.redDark, Icons.close_rounded),
  active('Chal raha hai', AppColors.yellowTint, AppColors.charcoal, Icons.construction_rounded),
  absentSick('Bimaar', AppColors.orangeTint, AppColors.orangeDark, Icons.sick_outlined),
  absentEmergency('Emergency', AppColors.orangeTint, AppColors.orangeDark, Icons.warning_amber_rounded),
  completed('Poora hua', AppColors.greenTint, AppColors.greenDark, Icons.check_circle_rounded),
  leftJob('Kaam chhoda', AppColors.redTint, AppColors.redDark, Icons.logout_rounded),
  cancelled('Cancel', AppColors.redTint, AppColors.redDark, Icons.cancel_outlined),
  noShow('Nahi aaye', AppColors.redTint, AppColors.redDark, Icons.person_off_outlined);

  const WorkerJobStatus(this.label, this.bg, this.fg, this.icon);
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
}

enum AttendanceStatus {
  notMarked('Attendance baaki', AppColors.yellowTint, AppColors.charcoal, Icons.radio_button_unchecked),
  present('Haazir ✓', AppColors.greenTint, AppColors.greenDark, Icons.check_circle_rounded),
  absentSick('Bimaar – chhutti', AppColors.orangeTint, AppColors.orangeDark, Icons.sick_outlined),
  absentEmergency('Emergency chhutti', AppColors.orangeTint, AppColors.orangeDark, Icons.warning_amber_rounded),
  absentApproved('Chhutti manzoor', AppColors.blueTint, AppColors.blueDark, Icons.event_available_rounded),
  noShow('Nahi aaye', AppColors.redTint, AppColors.redDark, Icons.person_off_outlined),
  leftJob('Kaam chhoda', AppColors.redTint, AppColors.redDark, Icons.logout_rounded),
  completed('Din poora ✓', AppColors.greenTint, AppColors.greenDark, Icons.task_alt_rounded);

  const AttendanceStatus(this.label, this.bg, this.fg, this.icon);
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
}

enum AttendanceMethod { tap, voice, gps, qr, contractor }

enum AbsenceReason {
  sick('Bimaar hoon', '🤒', 'tabiyat kharab hone ke karan'),
  injury('Chot lagi hai', '🩹', 'chot lagne ke karan'),
  emergency('Ghar mein emergency', '🚨', 'ghar mein emergency ke karan'),
  family('Ghar ka zaroori kaam', '👨‍👩‍👧', 'ghar ke zaroori kaam ke karan'),
  transport('Aane ka saadhan nahi', '🚌', 'aane ka saadhan na hone ke karan'),
  other('Koi aur karan', '💬', 'kisi zaroori karan se');

  const AbsenceReason(this.label, this.emoji, this.because);
  final String label;
  final String emoji;
  final String because;

  AttendanceStatus get attendanceStatus => switch (this) {
        AbsenceReason.sick || AbsenceReason.injury => AttendanceStatus.absentSick,
        _ => AttendanceStatus.absentEmergency,
      };
}

enum AbsenceScope {
  todayOnly('Sirf Aaj', 'Kal se kaam par aaunga'),
  fewDays('Kal Se Aaunga', 'Aaj nahi, kal pakka aaunga'),
  leaveJob('Kaam Chhodna Hai', 'Baaki kaam nahi kar paunga');

  const AbsenceScope(this.label, this.hint);
  final String label;
  final String hint;
}

class AttendanceRecord {
  AttendanceRecord({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.method,
    this.reason,
    this.note,
  });

  final DateTime date;
  AttendanceStatus status;
  DateTime? checkIn;
  DateTime? checkOut;
  AttendanceMethod? method;
  AbsenceReason? reason;
  String? note;
}

class Assignment {
  Assignment({
    required this.job,
    required this.status,
    required this.acceptedAt,
    Map<DateTime, AttendanceRecord>? attendance,
  }) : attendance = attendance ?? {};

  final Job job;
  WorkerJobStatus status;
  final DateTime acceptedAt;
  final Map<DateTime, AttendanceRecord> attendance;
  String? leaveReason;
  int? ratingGiven;

  String get jobCode => 'KS-${job.id.toUpperCase()}';

  bool get isLive =>
      status == WorkerJobStatus.accepted ||
      status == WorkerJobStatus.active ||
      status == WorkerJobStatus.absentSick ||
      status == WorkerJobStatus.absentEmergency;

  AttendanceRecord? recordFor(DateTime day) => attendance[Fmt.dayOnly(day)];

  int get daysWorked => attendance.values
      .where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.completed)
      .length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Money
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentStatus {
  paid('Paid ✓', AppColors.greenTint, AppColors.greenDark, Icons.check_circle_rounded),
  pending('Pending', AppColors.orangeTint, AppColors.orangeDark, Icons.schedule_rounded),
  requested('Maanga gaya', AppColors.blueTint, AppColors.blueDark, Icons.send_rounded),
  disputed('Shikayat', AppColors.redTint, AppColors.redDark, Icons.report_gmailerrorred_rounded);

  const PaymentStatus(this.label, this.bg, this.fg, this.icon);
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
}

class PaymentEntry {
  PaymentEntry({
    required this.id,
    required this.contractor,
    required this.workTitle,
    required this.days,
    required this.amount,
    required this.date,
    required this.status,
    this.jobId,
  });

  final String id;
  final String contractor;
  final String workTitle;
  final int days;
  final int amount;
  final DateTime date;
  PaymentStatus status;
  final String? jobId;

  String get spoken => status == PaymentStatus.paid
      ? '$contractor se ${Fmt.days(days)} ke kaam ke ${Fmt.rupeesSpoken(amount)} mile.'
      : '$contractor ke ${Fmt.rupeesSpoken(amount)} abhi pending hain.';
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────

enum NotifType {
  newJob('Naya kaam', '🔔', AppColors.yellowTint),
  jobAccepted('Kaam pakka', '✅', AppColors.greenTint),
  contractorMessage('Contractor ka sandesh', '💬', AppColors.blueTint),
  workReminder('Yaad dilana', '⏰', AppColors.yellowTint),
  breakReminder('Break', '☕', AppColors.orangeTint),
  attendance('Attendance', '🟢', AppColors.greenTint),
  paymentReceived('Paisa mila', '💰', AppColors.greenTint),
  paymentPending('Paisa baaki', '⏳', AppColors.orangeTint),
  emergency('Emergency', '🆘', AppColors.redTint),
  jobCancelled('Kaam cancel', '❌', AppColors.redTint),
  replacement('Badli', '🔁', AppColors.blueTint),
  system('Suchna', 'ℹ️', AppColors.blueTint);

  const NotifType(this.label, this.emoji, this.bg);
  final String label;
  final String emoji;
  final Color bg;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    String? spoken,
    this.jobId,
    this.read = false,
  }) : spoken = spoken ?? '$title. $body';

  final String id;
  final NotifType type;
  final String title;
  final String body;
  final String spoken;
  final DateTime time;
  final String? jobId;
  bool read;
}

/// Message the backend sends to the contractor (screen 36 preview).
class ContractorMessage {
  ContractorMessage({required this.text, required this.time, required this.kind, this.options = const []});
  final String text;
  final DateTime time;
  final String kind;
  final List<String> options;
}

// ─────────────────────────────────────────────────────────────────────────────
// Worker profile
// ─────────────────────────────────────────────────────────────────────────────

enum Availability {
  available('Kaam ke liye taiyaar', AppColors.greenTint, AppColors.greenDark, '🟢'),
  working('Kaam par hoon', AppColors.yellowTint, AppColors.charcoal, '🟡'),
  notAvailable('Abhi kaam nahi chahiye', AppColors.redTint, AppColors.redDark, '🔴');

  const Availability(this.label, this.bg, this.fg, this.emoji);
  final String label;
  final Color bg;
  final Color fg;
  final String emoji;
}

enum ShiftPreference {
  fullDay('Poora din', '☀️', '8 AM – 5 PM'),
  morning('Subah', '🌅', '6 AM – 12 PM'),
  evening('Dopahar–Shaam', '🌇', '12 PM – 7 PM'),
  any('Koi bhi samay', '🕒', 'Jab kaam ho');

  const ShiftPreference(this.label, this.emoji, this.hint);
  final String label;
  final String emoji;
  final String hint;
}

class AppLanguage {
  const AppLanguage(this.code, this.name, this.native, {this.enabled = false});
  final String code;
  final String name;
  final String native;
  final bool enabled;

  static const all = [
    AppLanguage('hi', 'Hindi', 'हिंदी', enabled: true),
    AppLanguage('hinglish', 'Hinglish', 'Hindi + English', enabled: true),
    AppLanguage('ur', 'Urdu', 'اردو'),
    AppLanguage('bho', 'Bhojpuri', 'भोजपुरी'),
    AppLanguage('awa', 'Awadhi', 'अवधी'),
    AppLanguage('bn', 'Bengali', 'বাংলা'),
    AppLanguage('mr', 'Marathi', 'मराठी'),
    AppLanguage('gu', 'Gujarati', 'ગુજરાતી'),
    AppLanguage('pa', 'Punjabi', 'ਪੰਜਾਬੀ'),
    AppLanguage('ta', 'Tamil', 'தமிழ்'),
    AppLanguage('te', 'Telugu', 'తెలుగు'),
    AppLanguage('kn', 'Kannada', 'ಕನ್ನಡ'),
  ];
}

class ExperienceBucket {
  const ExperienceBucket(this.label, this.min, this.max);
  final String label;
  final int min;
  final int max;

  static const all = [
    ExperienceBucket('0–1 saal', 0, 1),
    ExperienceBucket('1–3 saal', 1, 3),
    ExperienceBucket('3–5 saal', 3, 5),
    ExperienceBucket('5–10 saal', 5, 10),
    ExperienceBucket('10+ saal', 10, 99),
  ];

  static ExperienceBucket forYears(int y) =>
      all.lastWhere((b) => y >= b.min, orElse: () => all.first);
}

class WorkerProfile {
  WorkerProfile({
    this.name = '',
    this.phone = '',
    this.photoPath,
    this.language = 'hi',
    this.city = 'Lucknow',
    this.area = '',
    List<String>? skills,
    this.experienceYears = 0,
    this.dailyWage = 700,
    Set<WorkCategory>? workPrefs,
    this.environment = WorkEnvironment.both,
    this.maxDistanceKm = 10,
    this.availability = Availability.available,
    this.shift = ShiftPreference.fullDay,
    this.mobileVerified = false,
    this.identityVerified = false,
    Set<String>? verifiedSkills,
    this.rating = 0,
    this.jobsCompleted = 0,
    this.emergencyContact,
    this.autoAnnounce = true,
  })  : skills = skills ?? [],
        workPrefs = workPrefs ?? {},
        verifiedSkills = verifiedSkills ?? {};

  String name;
  String phone;
  String? photoPath;
  String language;
  String city;
  String area;

  /// First entry is the primary skill.
  List<String> skills;
  int experienceYears;
  int dailyWage;
  Set<WorkCategory> workPrefs;
  WorkEnvironment environment;
  int maxDistanceKm;
  Availability availability;
  ShiftPreference shift;
  bool mobileVerified;
  bool identityVerified;
  Set<String> verifiedSkills;
  double rating;
  int jobsCompleted;
  String? emergencyContact;
  bool autoAnnounce;

  String get firstName => name.trim().isEmpty ? 'Saathi' : name.trim().split(' ').first;
  Skill? get primarySkill => skills.isEmpty ? null : SkillCatalog.byId(skills.first);

  String get spoken {
    final b = StringBuffer('Aapka naam $name hai. ');
    if (skills.isNotEmpty) {
      b.write('Aap ${skills.map((s) => SkillCatalog.byId(s).name).join(', ')} ka kaam karte hain. ');
    }
    b.write('Aapko $experienceYears saal ka experience hai. ');
    b.write('Aap ek din ke ${Fmt.rupeesSpoken(dailyWage)} chahte hain. ');
    b.write('Aap ${area.isEmpty ? city : '$area, $city'} mein $maxDistanceKm kilometer tak kaam dekhte hain. ');
    if (jobsCompleted > 0) b.write('Aapne $jobsCompleted kaam poore kiye hain. ');
    if (rating > 0) b.write('Aapki rating ${rating.toStringAsFixed(1)} hai. ');
    b.write('Abhi aap: ${availability.label}.');
    return b.toString();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'photoPath': photoPath,
        'language': language,
        'city': city,
        'area': area,
        'skills': skills,
        'experienceYears': experienceYears,
        'dailyWage': dailyWage,
        'workPrefs': workPrefs.map((e) => e.name).toList(),
        'environment': environment.name,
        'maxDistanceKm': maxDistanceKm,
        'availability': availability.name,
        'shift': shift.name,
        'mobileVerified': mobileVerified,
        'identityVerified': identityVerified,
        'verifiedSkills': verifiedSkills.toList(),
        'rating': rating,
        'jobsCompleted': jobsCompleted,
        'emergencyContact': emergencyContact,
        'autoAnnounce': autoAnnounce,
      };

  static WorkerProfile fromJson(Map<String, dynamic> j) {
    T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return WorkerProfile(
      name: j['name'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      photoPath: j['photoPath'] as String?,
      language: j['language'] as String? ?? 'hi',
      city: j['city'] as String? ?? 'Lucknow',
      area: j['area'] as String? ?? '',
      skills: (j['skills'] as List?)?.cast<String>() ?? [],
      experienceYears: j['experienceYears'] as int? ?? 0,
      dailyWage: j['dailyWage'] as int? ?? 700,
      workPrefs: ((j['workPrefs'] as List?) ?? [])
          .map((e) => byName(WorkCategory.values, e, WorkCategory.other))
          .toSet(),
      environment: byName(WorkEnvironment.values, j['environment'], WorkEnvironment.both),
      maxDistanceKm: j['maxDistanceKm'] as int? ?? 10,
      availability: byName(Availability.values, j['availability'], Availability.available),
      shift: byName(ShiftPreference.values, j['shift'], ShiftPreference.fullDay),
      mobileVerified: j['mobileVerified'] as bool? ?? false,
      identityVerified: j['identityVerified'] as bool? ?? false,
      verifiedSkills: ((j['verifiedSkills'] as List?) ?? []).cast<String>().toSet(),
      rating: (j['rating'] as num?)?.toDouble() ?? 0,
      jobsCompleted: j['jobsCompleted'] as int? ?? 0,
      emergencyContact: j['emergencyContact'] as String?,
      autoAnnounce: j['autoAnnounce'] as bool? ?? true,
    );
  }
}

/// Neutral reliability record (screen 15) — emergency sick absence ≠ no-show.
class Reliability {
  const Reliability({
    required this.accepted,
    required this.completed,
    required this.presentDays,
    required this.sickDays,
    required this.emergencyDays,
    required this.noShows,
    required this.leftJobs,
    required this.cancellations,
  });

  final int accepted;
  final int completed;
  final int presentDays;
  final int sickDays;
  final int emergencyDays;
  final int noShows;
  final int leftJobs;
  final int cancellations;

  /// Attendance % — informed absences are *excluded* from the denominator,
  /// so a sick day never lowers it. Only no-shows do.
  int get attendancePercent {
    final base = presentDays + noShows;
    if (base == 0) return 100;
    return (presentDays * 100 / base).round();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reports / help
// ─────────────────────────────────────────────────────────────────────────────

enum ReportType {
  unsafe('Kaam safe nahi hai', '⚠️', 'Unsafe work'),
  payment('Paisa nahi mila', '💰', 'Payment issue'),
  wrongWage('Galat mazdoori', '🪙', 'Wrong wage'),
  harassment('Bura vyavhar / pareshaan', '🛑', 'Harassment'),
  fraud('Dhokha / fraud', '🚫', 'Fraud'),
  fakeJob('Nakli kaam', '❓', 'Fake job'),
  location('Galat jagah batayi', '📍', 'Misleading location'),
  injury('Chot lagi', '🩹', 'Injury');

  const ReportType(this.label, this.emoji, this.english);
  final String label;
  final String emoji;
  final String english;
}

class ReportTicket {
  ReportTicket({required this.id, required this.type, required this.time, this.jobId, this.details, this.stoppedWork = false});
  final String id;
  final ReportType type;
  final DateTime time;
  final String? jobId;
  final String? details;
  final bool stoppedWork;
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice audit log (screen 45)
// ─────────────────────────────────────────────────────────────────────────────

class VoiceLogEntry {
  VoiceLogEntry({
    required this.time,
    required this.transcript,
    required this.intent,
    this.slots = const {},
    this.confirmation,
    this.action,
    this.result,
  });

  final DateTime time;
  final String transcript;
  final String intent;
  final Map<String, String> slots;
  String? confirmation;
  String? action;
  String? result;
}

/// Result of any backend action — [spoken] is read aloud and shown.
class ActionResult {
  const ActionResult.ok(this.message, {this.spoken}) : success = true, queued = false;
  const ActionResult.fail(this.message, {this.spoken}) : success = false, queued = false;
  const ActionResult.queued(this.message, {this.spoken}) : success = true, queued = true;

  final bool success;
  final bool queued;
  final String message;
  final String? spoken;

  String get speech => spoken ?? message;
}
