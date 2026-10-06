import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';

/// Screen §45 — audit log of voice actions (helps resolve disputes).
class VoiceLogScreen extends StatelessWidget {
  const VoiceLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final logs = state.voiceLogs;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Voice history'),
      body: logs.isEmpty
          ? const Center(
              child: EmptyState(
                emoji: '🎙️',
                title: 'Abhi koi voice command nahi',
                subtitle: 'Jo bhi aap bolkar karenge, yahan record rahega.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _LogCard(entry: logs[i], now: state.now, worker: state.profile.name),
            ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.entry, required this.now, required this.worker});
  final VoiceLogEntry entry;
  final DateTime now;
  final String worker;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final rows = <(String, String)>[
      ('Worker', worker),
      ('Intent', e.intent),
      for (final s in e.slots.entries) (s.key[0].toUpperCase() + s.key.substring(1), s.value),
      if (e.confirmation != null) ('Confirmation', e.confirmation!),
      if (e.action != null) ('Action', e.action!),
      if (e.result != null) ('Result', e.result!),
    ];
    return KsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: AppColors.charcoal),
              const SizedBox(width: 6),
              Text('${Fmt.time(TimeOfDay.fromDateTime(e.time))} · ${Fmt.date(e.time)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Voice: “${e.transcript}”', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 120, child: Text(k, style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600))),
                  Expanded(child: Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace'))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
