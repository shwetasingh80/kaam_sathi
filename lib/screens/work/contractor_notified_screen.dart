import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';

/// What the contractor received after an absence / leave (screen 36).
class ContractorNotifiedScreen extends StatelessWidget {
  const ContractorNotifiedScreen({super.key});

  static IconData _iconFor(String option) {
    final o = option.toLowerCase();
    if (o.contains('call')) return Icons.call_rounded;
    if (o.contains('replacement')) return Icons.person_search_rounded;
    if (o.contains('manzoor')) return Icons.check_circle_rounded;
    if (o.contains('kam workers')) return Icons.groups_rounded;
    if (o.contains('bina paise')) return Icons.money_off_rounded;
    if (o.contains('payment')) return Icons.payments_rounded;
    return Icons.support_agent_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final msgs = s.contractorMessages;
    final a = s.todayAssignment ?? s.currentAssignment;
    final status = s.todayStatus;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Contractor ko bheja gaya', speak: msgs.isEmpty ? null : 'Contractor ko ye sandesh bheja gaya: ${msgs.first.text}'),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: msgs.isEmpty
                ? const EmptyState(emoji: '📭', title: 'Abhi koi sandesh nahi bheja gaya')
                : ListView(
                    padding: const EdgeInsets.all(Space.l),
                    children: [
                      if (a != null)
                        Row(
                          children: [
                            Expanded(child: Text(a.job.contractor.company, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                            StatusPill.attendance(status),
                          ],
                        ),
                      const SizedBox(height: Space.m),
                      for (final (i, m) in msgs.indexed) ...[
                        _Bubble(message: m, now: s.now),
                        if (i == 0 && m.options.isNotEmpty) ...[
                          const SizedBox(height: Space.m),
                          const Text('Contractor ke paas ye options hain:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final o in m.options)
                                Chip(avatar: Icon(_iconFor(o), size: 20, color: AppColors.charcoal), label: Text(o)),
                            ],
                          ),
                          const SizedBox(height: Space.l),
                        ],
                        const SizedBox(height: Space.m),
                      ],
                      if (status == AttendanceStatus.absentSick || status == AttendanceStatus.absentEmergency) ...[
                        const SizedBox(height: Space.s),
                        KsButton(
                          label: 'Demo: contractor ne chhutti manzoor ki',
                          icon: Icons.science_rounded,
                          kind: KsButtonKind.secondary,
                          onPressed: () {
                            s.contractorApprovesAbsence();
                            voice.speak('Aapki aaj ki chhutti manzoor ho gayi hai.');
                          },
                        ),
                      ],
                      if (a != null) ...[
                        const SizedBox(height: Space.m),
                        KsButton(
                          label: 'Contractor ko call karein',
                          icon: Icons.call_rounded,
                          kind: KsButtonKind.dark,
                          onPressed: () => callPhone(context, a.job.contractor.phone, who: a.job.contractor.company),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.now});
  final ContractorMessage message;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(Space.l),
        decoration: const BoxDecoration(
          color: AppColors.yellowTint,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Radii.l),
            topRight: Radius.circular(Radii.l),
            bottomLeft: Radius.circular(Radii.l),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.done_all_rounded, size: 18, color: AppColors.greenDark),
                const SizedBox(width: 4),
                Text('Bheja gaya · ${Fmt.ago(message.time, now)}', style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
