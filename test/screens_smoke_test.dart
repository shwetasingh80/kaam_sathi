import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaam_sathi/main.dart';
import 'package:kaam_sathi/core/app_theme.dart';
import 'package:kaam_sathi/data/app_state.dart';
import 'package:kaam_sathi/data/models.dart';
import 'package:kaam_sathi/screens/earnings/payment_history_screen.dart';
import 'package:kaam_sathi/screens/help/emergency_screen.dart';
import 'package:kaam_sathi/screens/help/help_screen.dart';
import 'package:kaam_sathi/screens/help/report_screen.dart';
import 'package:kaam_sathi/screens/help/unsafe_work_screen.dart';
import 'package:kaam_sathi/screens/jobs/contractor_profile_screen.dart';
import 'package:kaam_sathi/screens/jobs/job_accepted_screen.dart';
import 'package:kaam_sathi/screens/jobs/job_announcement_screen.dart';
import 'package:kaam_sathi/screens/jobs/job_details_screen.dart';
import 'package:kaam_sathi/screens/jobs/my_work_screen.dart';
import 'package:kaam_sathi/screens/jobs/rating_screen.dart';
import 'package:kaam_sathi/screens/main_shell.dart';
import 'package:kaam_sathi/screens/onboarding/availability_screen.dart';
import 'package:kaam_sathi/screens/onboarding/experience_screen.dart';
import 'package:kaam_sathi/screens/onboarding/language_screen.dart';
import 'package:kaam_sathi/screens/onboarding/location_screen.dart';
import 'package:kaam_sathi/screens/onboarding/name_screen.dart';
import 'package:kaam_sathi/screens/onboarding/otp_screen.dart';
import 'package:kaam_sathi/screens/onboarding/permissions_screen.dart';
import 'package:kaam_sathi/screens/onboarding/phone_screen.dart';
import 'package:kaam_sathi/screens/onboarding/photo_screen.dart';
import 'package:kaam_sathi/screens/onboarding/skills_screen.dart';
import 'package:kaam_sathi/screens/onboarding/wage_screen.dart';
import 'package:kaam_sathi/screens/onboarding/welcome_screen.dart';
import 'package:kaam_sathi/screens/onboarding/work_pref_screen.dart';
import 'package:kaam_sathi/screens/profile/edit_profile_screen.dart';
import 'package:kaam_sathi/screens/profile/settings_screen.dart';
import 'package:kaam_sathi/screens/profile/skill_verification_screen.dart';
import 'package:kaam_sathi/screens/profile/voice_log_screen.dart';
import 'package:kaam_sathi/screens/states/states_gallery_screen.dart';
import 'package:kaam_sathi/screens/voice/voice_assistant_screen.dart';
import 'package:kaam_sathi/screens/work/absence_screen.dart';
import 'package:kaam_sathi/screens/work/attendance_screen.dart';
import 'package:kaam_sathi/screens/work/break_screen.dart';
import 'package:kaam_sathi/screens/work/contractor_notified_screen.dart';
import 'package:kaam_sathi/screens/work/day_end_screen.dart';
import 'package:kaam_sathi/screens/work/leave_job_screen.dart';
import 'package:kaam_sathi/screens/work/today_work_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every screen on a small budget-phone viewport (360×740) with the
/// demo profile and fails on any exception (including layout overflow).
void main() {
  late AppState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    state = AppState();
    await state.init();
    state.loadDemoProfile();
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(
        theme: AppTheme.light,
        // Same locale setup as the real app (main.dart).
        locale: const Locale('hi', 'IN'),
        supportedLocales: const [Locale('hi', 'IN'), Locale('en', 'IN')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: screen,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));
  }

  final screens = <String, Widget Function()>{
    'MainShell home': () => const MainShell(),
    'Jobs tab': () => const MainShell(initialTab: 1),
    'Earnings tab': () => const MainShell(initialTab: 2),
    'Notifications tab': () => const MainShell(initialTab: 3),
    'Profile tab': () => const MainShell(initialTab: 4),
    'Language': () => const LanguageScreen(),
    'Welcome': () => const WelcomeScreen(),
    'Phone': () => const PhoneScreen(),
    'OTP': () => const OtpScreen(phone: '9876543210'),
    'Name': () => const NameScreen(),
    'Photo': () => const PhotoScreen(),
    'Skills': () => const SkillsScreen(),
    'Experience': () => const ExperienceScreen(),
    'Wage': () => const WageScreen(),
    'Location': () => const LocationScreen(),
    'WorkPref': () => const WorkPrefScreen(),
    'Availability': () => const AvailabilityScreen(),
    'Permissions': () => const PermissionsScreen(),
    'Voice assistant': () => const VoiceAssistantScreen(autoListen: false),
    'Job details': () => const JobDetailsScreen(jobId: 'j101'),
    'Job details (expired)': () => const JobDetailsScreen(jobId: 'j106'),
    'Job details (cancelled)': () => const JobDetailsScreen(jobId: 'j105'),
    'Job announcement': () => const JobAnnouncementScreen(jobId: 'j101'),
    'Job accepted': () => const JobAcceptedScreen(jobId: 'j100'),
    'My work': () => const MyWorkScreen(jobId: 'j100'),
    'Rating': () => const RatingScreen(jobId: 'j100'),
    'Today work': () => const TodayWorkScreen(),
    'Attendance': () => const AttendanceScreen(),
    'Break': () => const BreakScreen(),
    'Day end': () => const DayEndScreen(),
    'Absence': () => const AbsenceScreen(),
    'Absence (sick)': () => const AbsenceScreen(initialReason: AbsenceReason.sick),
    'Leave job': () => const LeaveJobScreen(jobId: 'j100'),
    'Contractor notified': () => const ContractorNotifiedScreen(),
    'Payment history': () => const PaymentHistoryScreen(),
    'Edit profile': () => const EditProfileScreen(),
    'Skill verification': () => const SkillVerificationScreen(),
    'Settings': () => const SettingsScreen(),
    'Voice log': () => const VoiceLogScreen(),
    'Help': () => const HelpScreen(),
    'Emergency': () => const EmergencyScreen(),
    'Report payment': () => const ReportScreen(type: ReportType.payment),
    'Unsafe work': () => const UnsafeWorkScreen(),
    'States gallery': () => const StatesGalleryScreen(),
  };

  screens.forEach((name, build) {
    testWidgets('renders: $name', (tester) async {
      await pumpScreen(tester, build());
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('renders: Contractor profile', (tester) async {
    await pumpScreen(tester, ContractorProfileScreen(contractor: state.jobById('j101')!.contractor));
    expect(tester.takeException(), isNull);
  });

  testWidgets('real app boots: splash → language screen (Hindi locale)', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = AppState();
    await tester.pumpWidget(KaamSaathiApp(state: app));
    await tester.runAsync(app.init);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.byType(LanguageScreen), findsOneWidget);
  });

  testWidgets('closing voice assistant does not notify during locked tree', (tester) async {
    await pumpScreen(tester, const MainShell());
    await tester.tap(find.text('BOLO').first);
    await tester.pumpAndSettle();
    // Home's MicButton/SpeakButton listen to VoiceService beneath the route.
    await tester.tap(find.byTooltip('Band karein'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('backend rules: conflict, accept, absence, leave', () {
    // Overlaps with the active Gomti Nagar job → refused.
    expect(state.acceptJob(state.jobById('j102')!).success, isFalse);
    // Expired / cancelled → refused.
    expect(state.acceptJob(state.jobById('j106')!).success, isFalse);
    expect(state.acceptJob(state.jobById('j105')!).success, isFalse);
    // Aliganj starts after the active job ends → accepted.
    expect(state.acceptJob(state.jobById('j101')!).success, isTrue);
    // Sick absence ≠ no-show.
    final r = state.reportAbsence(AbsenceReason.sick, AbsenceScope.todayOnly);
    expect(r.success, isTrue);
    expect(state.todayStatus, AttendanceStatus.absentSick);
    expect(state.reliability.noShows, 0);
    expect(state.contractorMessages, isNotEmpty);
  });
}
