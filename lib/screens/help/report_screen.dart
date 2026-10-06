import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';

/// Screens 45/46 — generic report (unsafe, payment, harassment, fraud…).
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.type, this.jobId});
  final ReportType type;
  final String? jobId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _jobId;
  final Set<String> _chips = {};
  String _spoken = '';
  final _text = TextEditingController();
  ActionResult? _result;

  static const _chipsByType = <ReportType, List<String>>{
    ReportType.unsafe: ['Helmet / belt nahi', 'Oonchai par bina suraksha', 'Bijli ka khatra', 'Deewar / gaddha girne ka dar', 'Machine kharab'],
    ReportType.payment: ['Poora paisa nahi mila', 'Kuch bhi nahi mila', 'Der se de rahe hain', 'Kam paisa diya'],
    ReportType.wrongWage: ['Bataya zyada, diya kam', 'Overtime nahi diya', 'Kaam badal diya'],
    ReportType.harassment: ['Gaali di', 'Maar-peet', 'Dhamki di', 'Zabardasti kaam'],
    ReportType.fraud: ['Paise maange', 'Document maange', 'Kaam tha hi nahi'],
    ReportType.fakeJob: ['Jagah par koi nahi tha', 'Number band hai', 'Kaam tha hi nahi'],
    ReportType.location: ['Jagah bahut door thi', 'Pata galat tha'],
    ReportType.injury: ['Haath / pair mein chot', 'Gir gaya', 'Kat gaya', 'Sir mein chot', 'Bijli ka jhatka'],
  };

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    _jobId = widget.jobId ?? state.currentAssignment?.job.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => voice.speak('${widget.type.label}. Kya hua? Bolkar batayein ya neeche chunein.'));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<Assignment> _jobs(AppState s) {
    final list = [...s.liveAssignments, ...s.pastAssignments];
    return list.take(5).toList();
  }

  Future<void> _submit() async {
    final state = AppScope.read(context);
    final details = [..._chips, if (_spoken.isNotEmpty) _spoken, if (_text.text.trim().isNotEmpty) _text.text.trim()].join(' · ');
    final job = _jobId == null ? null : state.jobById(_jobId!);
    final ok = await confirmAction(
      context,
      emoji: widget.type.emoji,
      title: 'Shikayat bhejein?',
      speech: '${widget.type.label}${job == null ? '' : ', ${job.contractor.company}'} ki shikayat bhejein?',
      yesLabel: 'Haan, bhejo',
      noLabel: 'Nahi',
    );
    if (!ok || !mounted) return;
    final r = state.submitReport(widget.type, jobId: _jobId, details: details.isEmpty ? null : details);
    setState(() => _result = r);
    voice.speak(r.speech);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (_result != null) return _success(state);
    final jobs = _jobs(state);
    return Scaffold(
      appBar: ksAppBar(context, title: '${widget.type.emoji} ${widget.type.label}', speak: 'Kya hua? Bolkar batayein ya neeche chunein.'),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (jobs.isNotEmpty) ...[
                  const SectionTitle('Kis kaam ke baare mein?', padding: EdgeInsets.fromLTRB(4, 8, 4, 10)),
                  for (final a in jobs) ...[
                    SelectTile(
                      title: a.job.contractor.company,
                      subtitle: '${a.job.skill.name} · ${a.job.area} · ${Fmt.date(a.job.startDate)}',
                      emoji: a.job.skill.emoji,
                      selected: _jobId == a.job.id,
                      onTap: () => setState(() => _jobId = _jobId == a.job.id ? null : a.job.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                const SectionTitle('Kya hua?'),
                VoiceInputBar(
                  prompt: 'Bolkar batayein',
                  example: 'Contractor ne paisa nahi diya',
                  onResult: (t) => setState(() => _spoken = t),
                ),
                if (_spoken.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  KsCard(
                    color: AppColors.yellowTint,
                    borderColor: AppColors.yellow,
                    child: Row(
                      children: [
                        const Icon(Icons.format_quote_rounded),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_spoken, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                        IconButton(onPressed: () => setState(() => _spoken = ''), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _chipsByType[widget.type] ?? const <String>[])
                      FilterChip(
                        label: Text(c),
                        selected: _chips.contains(c),
                        onSelected: (v) => setState(() => v ? _chips.add(c) : _chips.remove(c)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _text,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(hintText: 'Aur kuch likhna ho (zaroori nahi)'),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 20, color: AppColors.muted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Aapka naam contractor ko bina poochhe nahi bataya jayega.',
                          style: TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: KsButton(label: 'Shikayat bhejein', icon: Icons.send_rounded, kind: KsButtonKind.dark, onPressed: _submit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _success(AppState state) {
    final r = _result!;
    final ticket = state.reports.isEmpty ? null : state.reports.first;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Shikayat darj', speak: r.speech),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SuccessCheck(color: r.queued ? AppColors.orange : AppColors.green),
              const SizedBox(height: 20),
              Text(r.queued ? 'Shikayat save ho gayi' : 'Shikayat darj ho gayi',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              if (ticket != null) ...[
                const SizedBox(height: 8),
                StatusPill(label: 'Number: ${ticket.id}', bg: AppColors.charcoal, fg: AppColors.yellow, large: true),
              ],
              const SizedBox(height: 14),
              Text(
                r.queued ? r.message : 'Support team 24 ghante mein call karegi.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SpeakButton(text: r.speech),
              const SizedBox(height: 28),
              if (widget.type == ReportType.injury || widget.type == ReportType.harassment) ...[
                KsButton(
                  label: '112 Emergency call',
                  emoji: '🚨',
                  kind: KsButtonKind.danger,
                  onPressed: () => callPhone(context, '112', who: '112 Emergency'),
                ),
                const SizedBox(height: 12),
              ],
              KsButton(label: 'Theek hai', icon: Icons.check_rounded, onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
