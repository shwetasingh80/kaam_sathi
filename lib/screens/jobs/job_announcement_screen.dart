import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../core/voice/intent_parser.dart';
import '../../core/voice/voice_service.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import 'job_details_screen.dart';

/// Screen 22 — full-screen voice announcement of a new job.
class JobAnnouncementScreen extends StatefulWidget {
  const JobAnnouncementScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<JobAnnouncementScreen> createState() => _JobAnnouncementScreenState();
}

class _JobAnnouncementScreenState extends State<JobAnnouncementScreen> {
  String? _hint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = AppScope.read(context);
      final j = s.jobById(widget.jobId);
      if (j == null) return;
      s.focusedJobId = j.id;
      s.markJobSeen(j.id);
      if (s.profile.autoAnnounce) voice.speak(j.announcement(s.profile.firstName));
    });
  }

  @override
  void dispose() {
    voice.stopSpeaking();
    super.dispose();
  }

  void _yes() {
    voice.stopSpeaking();
    pushReplacement(context, JobDetailsScreen(jobId: widget.jobId));
  }

  void _no(AppState s, Job j) {
    s.rejectJob(j);
    voice.speak('Theek hai. Ye kaam aapko dobara nahi dikhaya jayega.');
    Navigator.pop(context);
  }

  Future<void> _listen(AppState s, Job j) async {
    setState(() => _hint = null);
    final text = await voice.listen(listenFor: const Duration(seconds: 6));
    if (!mounted) return;
    voice.setStatus(VoiceStatus.idle);
    final yn = text == null ? null : IntentParser.parseYesNo(text);
    if (yn == true) return _yes();
    if (yn == false) return _no(s, j);
    setState(() => _hint = 'Samajh nahi aaya. “Haan” ya “Nahi” boliye.');
    voice.speak('Samajh nahi aaya. Haan ya nahi boliye.');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final j = s.jobById(widget.jobId);
    if (j == null) {
      return Scaffold(
        appBar: ksAppBar(context, title: 'Naya kaam'),
        body: const Center(child: EmptyState(emoji: '⌛', title: 'Ye kaam ab available nahi hai.')),
      );
    }
    final text = j.announcement(s.profile.firstName);
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        foregroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.white, size: 28),
        title: const Text('🔔 Naya kaam aaya hai', style: TextStyle(color: AppColors.white, fontSize: 21, fontWeight: FontWeight.w800)),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: MadadButton())],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            ListenableBuilder(
              listenable: voice,
              builder: (context, _) {
                final speaking = voice.isSpeaking;
                return Column(
                  children: [
                    MicButton(
                      size: 120,
                      active: speaking || voice.isListening,
                      icon: voice.isListening ? Icons.mic_rounded : Icons.volume_up_rounded,
                      label: voice.isListening ? 'BOLO' : 'SUNO',
                      onTap: () => speaking ? voice.stopSpeaking() : voice.speak(text),
                    ),
                    SizedBox(
                      height: 36,
                      child: speaking || voice.isListening
                          ? const VoiceWaveform(color: AppColors.yellow, height: 32)
                          : const Text('Sunne ke liye dabayein', style: TextStyle(color: AppColors.yellowSoft, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(Radii.xl)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(j.skill.emoji, style: const TextStyle(fontSize: 48)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(j.skill.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                            Text('📍 ${j.area}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Big(value: Fmt.rupees(j.wage), label: 'roz'),
                      _Big(value: '${j.days}', label: 'din'),
                      _Big(value: Fmt.time(j.schedule.start).replaceAll(':00', ''), label: 'se ${Fmt.time(j.schedule.end).replaceAll(':00', '')}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${j.contractor.company}${j.contractor.identityVerified ? ' ✓' : ''} · ${Fmt.relativeDay(j.startDate, s.now)} se',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Kya aap kaam dekhna chahte hain?',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            KsButton(label: 'Haan', icon: Icons.check_circle_rounded, kind: KsButtonKind.success, height: 72, onPressed: _yes),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: KsButton(label: 'Suno', emoji: '🔊', kind: KsButtonKind.primary, onPressed: () => voice.speak(text)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KsButton(label: 'Nahi', icon: Icons.close_rounded, kind: KsButtonKind.danger, onPressed: () => _no(s, j)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: voice,
              builder: (context, _) => TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.yellow),
                onPressed: voice.isListening ? voice.stopListening : () => _listen(s, j),
                icon: Icon(voice.isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded, size: 28),
                label: Text(voice.isListening ? 'Sun raha hoon… (Haan / Nahi)' : 'Ya bolkar jawab dein', style: const TextStyle(fontSize: 18)),
              ),
            ),
            if (_hint != null)
              Text(_hint!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.yellowSoft, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(Radii.s)),
        child: Column(
          children: [
            FittedBox(child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoalSoft)),
          ],
        ),
      ),
    );
  }
}
