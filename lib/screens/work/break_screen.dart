import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';

/// Calm full-screen "Abhi Break Hai" with countdown.
class BreakScreen extends StatefulWidget {
  const BreakScreen({super.key});

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) voice.speak(_spoken(AppScope.read(context)));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  BreakSlot? _current(AppState s) {
    final p = s.todayPhase;
    return p?.kind == DayPhaseKind.onBreak ? p!.slot : null;
  }

  BreakSlot? _next(AppState s) {
    final a = s.todayAssignment;
    if (a == null) return null;
    final now = Fmt.minutesOf(s.timeOfDay);
    return a.job.schedule.breaks.where((b) => Fmt.minutesOf(b.start) > now).firstOrNull;
  }

  String _spoken(AppState s) {
    final cur = _current(s);
    if (cur != null) {
      return 'Aapka ${cur.label} ${Fmt.timeSpoken(cur.start)} se ${Fmt.timeSpoken(cur.end)} tak hai. Aaram kijiye.';
    }
    final next = _next(s);
    if (next != null) return 'Abhi break nahi hai. Agla ${next.label} ${Fmt.timeSpoken(next.start)} hoga.';
    return 'Aaj ke saare break ho chuke hain.';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cur = _current(s);
    final next = _next(s);
    final now = Fmt.minutesOf(s.timeOfDay);
    final left = cur == null ? 0 : (Fmt.minutesOf(cur.end) - now).clamp(0, 999);
    return Scaffold(
      backgroundColor: cur != null ? AppColors.yellowTint : AppColors.cream,
      appBar: ksAppBar(context, title: 'Break', speak: _spoken(s)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            children: [
              const Spacer(),
              Text(cur == null ? '⏱️' : (cur.isLunch ? '🍛' : '☕'), style: const TextStyle(fontSize: 96)),
              const SizedBox(height: Space.l),
              Text(cur != null ? 'Abhi Break Hai' : 'Abhi break nahi hai',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: Space.s),
              if (cur != null) ...[
                Text('${cur.label} · ${Fmt.time(cur.start)} – ${Fmt.time(cur.end)}',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: Space.xl),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: BoxDecoration(color: AppColors.charcoal, borderRadius: BorderRadius.circular(Radii.l)),
                  child: Column(
                    children: [
                      Text('$left min', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.yellow)),
                      const Text('baaki hain', style: TextStyle(fontSize: 18, color: AppColors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: Space.l),
                const Text('Phone rakh dijiye, aaram kijiye.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: AppColors.charcoalSoft)),
              ] else if (next != null)
                Text('Agla ${next.label}: ${Fmt.time(next.start)} – ${Fmt.time(next.end)}',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))
              else
                const Text('Aaj ke saare break ho chuke hain.', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              KsButton(label: 'Theek hai', icon: Icons.check_rounded, height: 72, onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
