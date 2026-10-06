import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../core/voice/intent_parser.dart';
import '../../core/voice/voice_service.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';

/// Mark attendance — one giant tap, or say "Main kaam par pahunch gaya".
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  ActionResult? _result;
  String? _hint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) voice.speak('Kaam par pahunch gaye? Neeche ka bada button dabayein, ya boliye: main kaam par pahunch gaya.');
    });
  }

  void _mark(AttendanceMethod method) {
    final r = AppScope.read(context).markAttendance(method);
    voice.speak(r.speech);
    setState(() => _result = r);
  }

  Future<void> _listen() async {
    setState(() => _hint = null);
    final text = await voice.listen(listenFor: const Duration(seconds: 7));
    if (!mounted) return;
    voice.setStatus(VoiceStatus.idle);
    if (text == null) {
      setState(() => _hint = 'Samajh nahi aaya. Dobara boliye.');
      voice.speak('Samajh nahi aaya. Dobara boliye.');
      return;
    }
    final p = IntentParser.parse(text);
    if (p.intent == VoiceIntent.markAttendance || p.intent == VoiceIntent.yes) {
      _mark(AttendanceMethod.voice);
    } else {
      setState(() => _hint = '“$text” — boliye: “Main kaam par pahunch gaya”');
      voice.speak('Attendance ke liye boliye: main kaam par pahunch gaya.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.todayAssignment;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Attendance'),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: a == null
                ? EmptyState(
                    emoji: '📅',
                    title: 'Aaj koi kaam assigned nahi hai',
                    action: KsButton(label: 'Wapas', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                  )
                : _result != null && _result!.success
                    ? _success(context, s)
                    : _form(context, s, a),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context, AppState s, Assignment a) {
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        Text('${a.job.contractor.company} · ${a.job.area}',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.l),
        Semantics(
          button: true,
          label: 'Main kaam par pahunch gaya — attendance lagayein',
          excludeSemantics: true,
          child: Material(
            color: AppColors.green,
            shape: const CircleBorder(side: BorderSide(color: AppColors.charcoal, width: 4)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _mark(AttendanceMethod.tap),
              child: const SizedBox(
                width: 240,
                height: 240,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👷', style: TextStyle(fontSize: 70)),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Main kaam par pahunch gaya',
                          textAlign: TextAlign.center, style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.15)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        ListenableBuilder(
          listenable: voice,
          builder: (context, _) {
            final listening = voice.isListening;
            return Column(
              children: [
                MicButton(onTap: listening ? voice.stopListening : _listen, size: 90, active: listening, label: 'BOLO'),
                Text(listening ? 'Main sun raha hoon…' : 'Ya bolkar: “Main kaam par pahunch gaya”',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                if (listening && voice.transcript.isNotEmpty)
                  Text('“${voice.transcript}”', style: const TextStyle(fontSize: 16, color: AppColors.muted)),
              ],
            );
          },
        ),
        if (_hint != null) ...[
          const SizedBox(height: 8),
          Text(_hint!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.redDark, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
        if (_result != null && !_result!.success) ...[
          const SizedBox(height: 12),
          Text(_result!.message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.redDark, fontWeight: FontWeight.w800, fontSize: 17)),
        ],
        const SizedBox(height: Space.xl),
        const Text('Aur tareeke (zaruri nahi)', style: TextStyle(fontSize: 16, color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('QR scan'),
              onPressed: () => _mark(AttendanceMethod.qr),
            ),
            ActionChip(
              avatar: const Icon(Icons.how_to_reg_rounded),
              label: const Text('Contractor confirm karega'),
              onPressed: () => _mark(AttendanceMethod.contractor),
            ),
            ActionChip(
              avatar: const Icon(Icons.my_location_rounded),
              label: const Text('Location (GPS)'),
              onPressed: () {
                const msg = 'Location kamzor hai — koi baat nahi, tap se attendance lag jayegi.';
                voice.speak(msg);
                showSnack(context, msg, icon: Icons.location_searching_rounded);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _success(BuildContext context, AppState s) {
    final r = _result!;
    final rec = s.todayRecord;
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        const SizedBox(height: Space.xl),
        const Center(child: SuccessCheck()),
        const SizedBox(height: Space.xl),
        Text(r.queued ? 'Attendance lag gayi' : r.message,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        if (rec?.checkIn != null) ...[
          const SizedBox(height: 8),
          Text('Samay: ${Fmt.time(TimeOfDay.fromDateTime(rec!.checkIn!))}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
        if (r.queued) ...[
          const SizedBox(height: Space.l),
          Container(
            padding: const EdgeInsets.all(Space.l),
            decoration: BoxDecoration(color: AppColors.orangeTint, borderRadius: BorderRadius.circular(Radii.m)),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.orangeDark),
                const SizedBox(width: 10),
                Expanded(child: Text(r.message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.orangeDark))),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.xxl),
        KsButton(label: 'Theek hai', icon: Icons.check_rounded, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
