import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../earnings/payment_history_screen.dart';
import '../jobs/job_details_screen.dart';
import '../jobs/my_work_screen.dart';
import '../work/contractor_notified_screen.dart';

/// Suchna tab — all notifications, newest first, each can be heard.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _open(BuildContext context, AppState s, AppNotification n) {
    s.markRead(n);
    final id = n.jobId;
    switch (n.type) {
      case NotifType.newJob || NotifType.jobCancelled:
        if (id != null) push(context, JobDetailsScreen(jobId: id));
      case NotifType.jobAccepted || NotifType.workReminder || NotifType.attendance || NotifType.breakReminder || NotifType.contractorMessage:
        if (id != null && s.assignmentFor(id) != null) {
          push(context, MyWorkScreen(jobId: id));
        } else if (id != null) {
          push(context, JobDetailsScreen(jobId: id));
        } else {
          voice.speak(n.spoken);
        }
      case NotifType.paymentReceived || NotifType.paymentPending:
        push(context, const PaymentHistoryScreen());
      case NotifType.emergency || NotifType.replacement:
        push(context, const ContractorNotifiedScreen());
      case NotifType.system:
        voice.speak(n.spoken);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.notifications;
    final today = list.where((n) => Fmt.dayOnly(n.time) == s.today).toList();
    final older = list.where((n) => Fmt.dayOnly(n.time) != s.today).toList();
    final unread = s.unreadCount;
    final speech = unread == 0
        ? 'Koi nayi suchna nahi hai.'
        : 'Aapki $unread nayi suchna hain. ${list.where((n) => !n.read).take(3).map((n) => n.spoken).join(' ')}';

    return Scaffold(
      appBar: ksAppBar(
        context,
        title: 'Suchna',
        showBack: false,
        speak: speech,
        actions: [
          if (unread > 0)
            IconButton(
              onPressed: s.markAllRead,
              tooltip: 'Sab padh liya',
              iconSize: 28,
              icon: const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: EmptyState(emoji: '🔕', title: 'Koi suchna nahi hai', subtitle: 'Naya kaam ya paisa aate hi yahan dikhega.'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      if (today.isNotEmpty) ...[
                        const SectionTitle('Aaj', padding: EdgeInsets.fromLTRB(4, 8, 4, 10)),
                        for (final n in today) _Tile(n: n, now: s.now, onTap: () => _open(context, s, n)),
                      ],
                      if (older.isNotEmpty) ...[
                        const SectionTitle('Pehle'),
                        for (final n in older) _Tile(n: n, now: s.now, onTap: () => _open(context, s, n)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.n, required this.now, required this.onTap});
  final AppNotification n;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: '${n.read ? '' : 'Nayi suchna. '}${n.title}. ${n.body}',
        button: true,
        child: KsCard(
          onTap: onTap,
          color: n.read ? AppColors.white : AppColors.yellowTint,
          borderColor: n.read ? AppColors.border : AppColors.yellow,
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: n.type.bg, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                child: Text(n.type.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!n.read) ...[
                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(n.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 18, fontWeight: n.read ? FontWeight.w700 : FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: AppColors.charcoalSoft)),
                    const SizedBox(height: 4),
                    Text('${n.type.label} · ${Fmt.ago(n.time, now)}',
                        style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SpeakButton(text: n.spoken, label: '', compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
