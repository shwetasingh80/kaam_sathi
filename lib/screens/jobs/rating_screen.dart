import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../help/report_screen.dart';

/// Rate the contractor after a job is completed.
class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key, required this.jobId});
  final String jobId;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  static const _faces = [('😡', 'Bahut bura'), ('😕', 'Bura'), ('😐', 'Theek'), ('🙂', 'Achha'), ('😍', 'Bahut achha')];

  int? _stars;
  bool? _paidOnTime;
  bool? _asPromised;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final j = AppScope.read(context).jobById(widget.jobId);
      if (j != null) voice.speak('${j.contractor.company} ke saath kaam kaisa raha? Ek chehra chunein.');
    });
  }

  void _submit(AppState s, Assignment a) {
    s.rateContractor(a, _stars!);
    setState(() => _done = true);
    voice.speak('Dhanyavaad! Aapki rating se doosre mazdooron ko madad milegi.');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.assignmentFor(widget.jobId);
    if (a == null) {
      return Scaffold(appBar: ksAppBar(context, title: 'Rating'), body: const Center(child: EmptyState(emoji: '⭐', title: 'Kaam nahi mila')));
    }
    final j = a.job;
    if (_done) {
      return Scaffold(
        appBar: ksAppBar(context, title: 'Rating'),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            const Center(child: SuccessCheck()),
            const SizedBox(height: 20),
            const Text('Dhanyavaad!', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const Text('Aapki rating se doosre mazdooron ko madad milegi.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: AppColors.charcoalSoft)),
            const SizedBox(height: 24),
            if (_paidOnTime == false) ...[
              KsCard(
                color: AppColors.orangeTint,
                borderColor: AppColors.orangeTint,
                child: Column(
                  children: [
                    const Text('Paisa nahi mila? Hum madad karenge.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.orangeDark)),
                    const SizedBox(height: 12),
                    KsButton(
                      label: 'Payment ki shikayat karein',
                      emoji: '💰',
                      kind: KsButtonKind.dark,
                      onPressed: () => pushReplacement(context, ReportScreen(type: ReportType.payment, jobId: j.id)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            KsButton(label: 'Home par jaayein', icon: Icons.home_rounded, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: ksAppBar(context, title: 'Rating dein', speak: '${j.contractor.company} ke saath kaam kaisa raha? Ek chehra chunein.'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text('${j.contractor.company} ke saath kaam kaisa raha?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < _faces.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: _stars == i + 1,
                          label: _faces[i].$2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _stars = i + 1);
                              voice.speak(_faces[i].$2);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _stars == i + 1 ? AppColors.yellow : AppColors.white,
                                borderRadius: BorderRadius.circular(Radii.m),
                                border: Border.all(color: _stars == i + 1 ? AppColors.charcoal : AppColors.border, width: _stars == i + 1 ? 2.5 : 1.5),
                              ),
                              child: Column(
                                children: [
                                  AnimatedScale(
                                    scale: _stars == i + 1 ? 1.2 : 1,
                                    duration: const Duration(milliseconds: 180),
                                    child: Text(_faces[i].$1, style: const TextStyle(fontSize: 36)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_faces[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _YesNo(
                  emoji: '💰',
                  question: 'Paisa samay par mila?',
                  value: _paidOnTime,
                  onChanged: (v) => setState(() => _paidOnTime = v),
                ),
                const SizedBox(height: 12),
                _YesNo(
                  emoji: '🧱',
                  question: 'Kaam waisa hi tha jaisa bataya?',
                  value: _asPromised,
                  onChanged: (v) => setState(() => _asPromised = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: KsButton(
                label: 'Rating bhejein',
                icon: Icons.send_rounded,
                onPressed: _stars == null ? null : () => _submit(s, a),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YesNo extends StatelessWidget {
  const _YesNo({required this.emoji, required this.question, required this.value, required this.onChanged});
  final String emoji;
  final String question;
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return KsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(child: Text(question, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              SpeakButton(text: question, label: '', compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SelectTile(title: 'Haan', emoji: '👍', selected: value == true, onTap: () => onChanged(true)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SelectTile(title: 'Nahi', emoji: '👎', selected: value == false, onTap: () => onChanged(false)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
