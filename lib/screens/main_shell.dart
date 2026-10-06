import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_state.dart';
import '../widgets/widgets.dart';
import 'earnings/earnings_screen.dart';
import 'home/home_screen.dart';
import 'jobs/job_announcement_screen.dart';
import 'jobs/jobs_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

/// Bottom navigation: Home | Kaam | Kamai | Suchna | Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});
  final int initialTab;

  /// Current tab — any screen can switch tabs via [goTo].
  static final tab = ValueNotifier<int>(0);

  static const home = 0, jobs = 1, earnings = 2, notifications = 3, profile = 4;

  /// Pops back to the shell and opens [index].
  static void goTo(BuildContext context, int index) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    tab.value = index;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final AppState _state;
  bool _announcing = false;

  static const _pages = [
    HomeScreen(),
    JobsScreen(),
    EarningsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MainShell.tab.value = widget.initialTab;
    _state = AppScope.read(context);
    _state.addListener(_checkAnnouncement);
  }

  @override
  void dispose() {
    _state.removeListener(_checkAnnouncement);
    super.dispose();
  }

  /// New matching job → full-screen voice announcement (screen 22).
  void _checkAnnouncement() {
    if (_announcing || _state.pendingAnnouncementJobId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final id = _state.takePendingAnnouncement();
      if (id == null || !mounted) return;
      _announcing = true;
      await push(context, JobAnnouncementScreen(jobId: id));
      _announcing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final newJobs = s.newJobs.length;
    final unread = s.unreadCount;
    return ValueListenableBuilder<int>(
      valueListenable: MainShell.tab,
      builder: (context, index, _) {
        return PopScope(
          canPop: index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) MainShell.tab.value = 0;
          },
          child: Scaffold(
            body: IndexedStack(index: index, children: _pages),
            bottomNavigationBar: DecoratedBox(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => MainShell.tab.value = i,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Badge(isLabelVisible: newJobs > 0, label: Text('$newJobs'), child: const Icon(Icons.work_outline_rounded)),
                    selectedIcon: Badge(isLabelVisible: newJobs > 0, label: Text('$newJobs'), child: const Icon(Icons.work_rounded)),
                    label: 'Kaam',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                    label: 'Kamai',
                  ),
                  NavigationDestination(
                    icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_outlined)),
                    selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_rounded)),
                    label: 'Suchna',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
