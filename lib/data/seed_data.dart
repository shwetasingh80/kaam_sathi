import 'package:flutter/material.dart';

import '../core/format.dart';
import 'models.dart';

/// Demo data, relative to "today" so the app always has a live job,
/// upcoming jobs, history and edge cases (expired / cancelled / overlapping).
class SeedData {
  SeedData(DateTime now) : today = Fmt.dayOnly(now);

  final DateTime today;

  static const standardSchedule = WorkSchedule(
    start: TimeOfDay(hour: 8, minute: 0),
    end: TimeOfDay(hour: 17, minute: 0),
    breaks: [
      BreakSlot(label: 'Chai break', start: TimeOfDay(hour: 11, minute: 0), end: TimeOfDay(hour: 11, minute: 30)),
      BreakSlot(label: 'Lunch break', start: TimeOfDay(hour: 13, minute: 0), end: TimeOfDay(hour: 14, minute: 0), isLunch: true),
    ],
    weeklyOff: 'Ravivar',
    overtimePerHour: 100,
  );

  static const farmSchedule = WorkSchedule(
    start: TimeOfDay(hour: 6, minute: 30),
    end: TimeOfDay(hour: 14, minute: 30),
    breaks: [
      BreakSlot(label: 'Nashta break', start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 9, minute: 30)),
      BreakSlot(label: 'Lunch break', start: TimeOfDay(hour: 12, minute: 0), end: TimeOfDay(hour: 12, minute: 45), isLunch: true),
    ],
    weeklyOff: 'Koi nahi',
  );

  static const roadSchedule = WorkSchedule(
    start: TimeOfDay(hour: 7, minute: 0),
    end: TimeOfDay(hour: 16, minute: 0),
    breaks: [
      BreakSlot(label: 'Chai break', start: TimeOfDay(hour: 10, minute: 0), end: TimeOfDay(hour: 10, minute: 15)),
      BreakSlot(label: 'Lunch break', start: TimeOfDay(hour: 12, minute: 30), end: TimeOfDay(hour: 13, minute: 30), isLunch: true),
      BreakSlot(label: 'Chai break', start: TimeOfDay(hour: 15, minute: 0), end: TimeOfDay(hour: 15, minute: 15)),
    ],
    weeklyOff: 'Ravivar',
    overtimePerHour: 90,
  );

  static const rajConstruction = Contractor(
    id: 'c1',
    company: 'Raj Construction',
    ownerName: 'Ramesh Verma',
    phone: '+919876500001',
    area: 'Aliganj, Lucknow',
    mobileVerified: true,
    identityVerified: true,
    rating: 4.7,
    ratingCount: 96,
    workersHired: 125,
    jobsCompleted: 58,
    paymentOnTimePercent: 96,
    since: 2023,
  );

  static const sharmaBuilders = Contractor(
    id: 'c2',
    company: 'Sharma Builders',
    ownerName: 'Vinod Sharma',
    phone: '+919876500002',
    area: 'Gomti Nagar, Lucknow',
    mobileVerified: true,
    identityVerified: true,
    rating: 4.5,
    ratingCount: 61,
    workersHired: 80,
    jobsCompleted: 34,
    paymentOnTimePercent: 92,
    since: 2024,
  );

  static const kisanAgro = Contractor(
    id: 'c3',
    company: 'Kisan Agro Farm',
    ownerName: 'Harpal Singh',
    phone: '+919876500003',
    area: 'Bakshi Ka Talab, Lucknow',
    mobileVerified: true,
    identityVerified: false,
    rating: 4.2,
    ratingCount: 22,
    workersHired: 40,
    jobsCompleted: 12,
    paymentOnTimePercent: 88,
    since: 2025,
  );

  static const metroRoad = Contractor(
    id: 'c4',
    company: 'Metro Road Infra',
    ownerName: 'Anil Yadav',
    phone: '+919876500004',
    area: 'Chinhat, Lucknow',
    mobileVerified: true,
    identityVerified: true,
    rating: 4.0,
    ratingCount: 30,
    workersHired: 210,
    jobsCompleted: 19,
    paymentOnTimePercent: 85,
    since: 2022,
  );

  static const guptaInteriors = Contractor(
    id: 'c5',
    company: 'Gupta Interiors',
    ownerName: 'Sanjay Gupta',
    phone: '+919876500005',
    area: 'Indira Nagar, Lucknow',
    mobileVerified: true,
    identityVerified: false,
    rating: 0,
    ratingCount: 0,
    workersHired: 3,
    jobsCompleted: 1,
    paymentOnTimePercent: 0,
    since: 2026,
  );

  DateTime d(int offset) => today.add(Duration(days: offset));

  /// The worker's live job (started yesterday).
  late final Job activeJob = Job(
    id: 'j100',
    skillId: 'MASON',
    contractor: sharmaBuilders,
    area: 'Gomti Nagar',
    city: 'Lucknow',
    landmark: 'Patrakarpuram chauraha ke paas, nayi building',
    distanceKm: 6.2,
    days: 4,
    wage: 750,
    startDate: d(-1),
    schedule: standardSchedule,
    category: WorkCategory.construction,
    physical: PhysicalLevel.medium,
    environment: WorkEnvironment.outdoor,
    conditions: const [WorkCondition.dust, WorkCondition.height],
    workersNeeded: 6,
    workersFilled: 6,
    status: JobStatus.inProgress,
    paymentFrequency: PaymentFrequency.daily,
    postedAt: d(-3),
  );

  List<Job> openJobs() => [
        Job(
          id: 'j101',
          skillId: 'MASON',
          contractor: rajConstruction,
          area: 'Aliganj',
          city: 'Lucknow',
          landmark: 'Kapoorthala ke peeche, Sector B',
          distanceKm: 4.2,
          days: 3,
          wage: 800,
          startDate: d(4),
          schedule: standardSchedule,
          category: WorkCategory.construction,
          physical: PhysicalLevel.medium,
          environment: WorkEnvironment.outdoor,
          conditions: const [WorkCondition.heavyLifting, WorkCondition.dust],
          workersNeeded: 4,
          workersFilled: 1,
          status: JobStatus.partiallyFilled,
          paymentFrequency: PaymentFrequency.endOfJob,
          note: 'Deewar aur plaster ka kaam. Auzaar site par milenge.',
          postedAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        Job(
          id: 'j102',
          skillId: 'TILE',
          contractor: guptaInteriors,
          area: 'Indira Nagar',
          city: 'Lucknow',
          distanceKm: 3.1,
          days: 2,
          wage: 850,
          startDate: d(1),
          schedule: standardSchedule,
          category: WorkCategory.construction,
          physical: PhysicalLevel.light,
          environment: WorkEnvironment.indoor,
          conditions: const [WorkCondition.dust],
          workersNeeded: 2,
          paymentFrequency: PaymentFrequency.endOfJob,
          postedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Job(
          id: 'j103',
          skillId: 'ROAD',
          contractor: metroRoad,
          area: 'Chinhat',
          city: 'Lucknow',
          distanceKm: 8.5,
          days: 7,
          wage: 650,
          startDate: d(8),
          schedule: roadSchedule,
          category: WorkCategory.road,
          physical: PhysicalLevel.heavy,
          environment: WorkEnvironment.outdoor,
          conditions: const [WorkCondition.roadTraffic, WorkCondition.heat, WorkCondition.machinery],
          workersNeeded: 20,
          workersFilled: 11,
          status: JobStatus.partiallyFilled,
          paymentFrequency: PaymentFrequency.weekly,
          postedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Job(
          id: 'j104',
          skillId: 'FARM',
          contractor: kisanAgro,
          area: 'Bakshi Ka Talab',
          city: 'Lucknow',
          distanceKm: 14,
          days: 5,
          wage: 500,
          startDate: d(5),
          schedule: farmSchedule,
          category: WorkCategory.agriculture,
          physical: PhysicalLevel.heavy,
          environment: WorkEnvironment.outdoor,
          conditions: const [WorkCondition.heat, WorkCondition.chemical],
          workersNeeded: 15,
          workersFilled: 4,
          status: JobStatus.partiallyFilled,
          paymentFrequency: PaymentFrequency.daily,
          note: 'Dhaan ki katai. Khana farm par milega.',
          postedAt: DateTime.now().subtract(const Duration(hours: 9)),
        ),
        Job(
          id: 'j105',
          skillId: 'HELPER',
          contractor: rajConstruction,
          area: 'Hazratganj',
          city: 'Lucknow',
          distanceKm: 5,
          days: 2,
          wage: 600,
          startDate: d(2),
          schedule: standardSchedule,
          category: WorkCategory.construction,
          status: JobStatus.cancelled,
          postedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Job(
          id: 'j106',
          skillId: 'LOADING',
          contractor: metroRoad,
          area: 'Transport Nagar',
          city: 'Lucknow',
          distanceKm: 9,
          days: 1,
          wage: 600,
          startDate: d(-1),
          schedule: standardSchedule,
          category: WorkCategory.loading,
          physical: PhysicalLevel.heavy,
          conditions: const [WorkCondition.heavyLifting],
          status: JobStatus.expired,
          postedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

  /// Extra job used by "Demo: naya kaam bhejo".
  Job demoIncomingJob(int n) => Job(
        id: 'j2${n.toString().padLeft(2, '0')}',
        skillId: 'MASON',
        contractor: rajConstruction,
        area: 'Mahanagar',
        city: 'Lucknow',
        distanceKm: 3.4,
        days: 2,
        wage: 850,
        startDate: d(10 + n * 3),
        schedule: standardSchedule,
        category: WorkCategory.construction,
        conditions: const [WorkCondition.height],
        workersNeeded: 3,
        paymentFrequency: PaymentFrequency.endOfJob,
      );

  List<PaymentEntry> payments() => [
        PaymentEntry(id: 'p1', contractor: 'Sharma Builders', workTitle: 'Raj Mistri', days: 1, amount: 750, date: d(-1), status: PaymentStatus.pending, jobId: 'j100'),
        PaymentEntry(id: 'p2', contractor: 'Gupta Interiors', workTitle: 'Tile ka kaam', days: 2, amount: 1600, date: d(-4), status: PaymentStatus.paid),
        PaymentEntry(id: 'p3', contractor: 'Raj Construction', workTitle: 'Raj Mistri', days: 3, amount: 2400, date: d(-9), status: PaymentStatus.paid),
        PaymentEntry(id: 'p4', contractor: 'Verma Contractors', workTitle: 'Construction Helper', days: 5, amount: 3500, date: d(-16), status: PaymentStatus.paid),
        PaymentEntry(id: 'p5', contractor: 'Raj Construction', workTitle: 'Raj Mistri', days: 6, amount: 4800, date: d(-24), status: PaymentStatus.paid),
        PaymentEntry(id: 'p6', contractor: 'Kisan Agro Farm', workTitle: 'Khet ka kaam', days: 6, amount: 3000, date: d(-33), status: PaymentStatus.paid),
      ];
}
