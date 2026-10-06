import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import '../main_shell.dart';
import 'language_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  bool _minTimePassed = false;
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _minTimePassed = true;
      _maybeRoute();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context); // rebuild when state becomes ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRoute());
  }

  void _maybeRoute() {
    if (!mounted || _routed || !_minTimePassed) return;
    final s = AppScope.read(context);
    if (!s.ready) return;
    _routed = true;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => s.onboarded ? const MainShell() : const LanguageScreen(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppScope.of(context);
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(fade),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KsLogo(size: 260),
                  const SizedBox(height: 32),
                  const SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 6)),
                  const SizedBox(height: 16),
                  Text('Padhne ki zarurat nahi', style: TextStyle(fontSize: 17, color: AppColors.muted.withValues(alpha: 0.9), fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
