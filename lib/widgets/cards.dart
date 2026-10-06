import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../screens/help/help_screen.dart';
import '../screens/voice/voice_assistant_screen.dart';
import 'common.dart';
import 'voice_widgets.dart';

/// Opens the phone dialer. Never fails loudly.
Future<void> callPhone(BuildContext context, String phone, {String? who}) async {
  if (who != null) voice.speak('$who ko phone laga rahe hain.');
  final ok = await launchUrl(Uri(scheme: 'tel', path: phone)).catchError((_) => false);
  if (!ok && context.mounted) showSnack(context, 'Phone nahi lag paaya. Number: $phone', icon: Icons.call_rounded);
}

/// Standard app bar: back, title, optional 🔊, always-visible 🆘 MADAD.
PreferredSizeWidget ksAppBar(
  BuildContext context, {
  required String title,
  String? speak,
  bool madad = true,
  List<Widget> actions = const [],
  bool showBack = true,
}) {
  return AppBar(
    automaticallyImplyLeading: showBack,
    toolbarHeight: 64,
    titleSpacing: showBack ? 0 : 16,
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    actions: [
      if (speak != null) Padding(padding: const EdgeInsets.only(right: 6), child: SpeakButton(text: speak, label: '', compact: true)),
      ...actions,
      if (madad) const Padding(padding: EdgeInsets.only(right: 12), child: MadadButton()),
    ],
  );
}

/// Red "🆘 Madad" pill — reachable from every screen.
class MadadButton extends StatelessWidget {
  const MadadButton({super.key, this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Madad — help aur emergency',
      excludeSemantics: true,
      child: Material(
        color: AppColors.red,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => push(context, const HelpScreen()),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: large ? 18 : 12, vertical: large ? 12 : 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🆘', style: TextStyle(fontSize: large ? 22 : 17)),
                const SizedBox(width: 6),
                Text('MADAD', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: large ? 18 : 15, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating voice shortcut (bottom-right) that opens the assistant.
class VoiceFab extends StatelessWidget {
  const VoiceFab({super.key, this.contextJob});
  final Job? contextJob;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bolkar poochhein',
      child: FloatingActionButton.large(
        heroTag: null,
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.charcoal,
        elevation: 4,
        shape: const CircleBorder(side: BorderSide(color: AppColors.charcoal, width: 3)),
        onPressed: () => push(context, VoiceAssistantScreen(contextJob: contextJob)),
        child: const Icon(Icons.mic_rounded, size: 40),
      ),
    );
  }
}

/// Compact job summary card for lists (screen 21 list + Kaam tab).
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, required this.onTap, this.isNew = false, this.status});

  final Job job;
  final VoidCallback onTap;
  final bool isNew;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final closed = !job.isAvailable && job.status != JobStatus.inProgress && job.status != JobStatus.filled;
    return KsCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderColor: isNew ? AppColors.yellow : AppColors.border,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: closed ? AppColors.divider : AppColors.yellowTint, borderRadius: BorderRadius.circular(18)),
                  child: Text(job.skill.emoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(job.skill.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                          ),
                          if (isNew) const StatusPill(label: 'NAYA', bg: AppColors.yellow, fg: AppColors.charcoal, icon: Icons.fiber_new_rounded),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: AppColors.muted),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text('${job.area} · ${job.distanceKm.toStringAsFixed(job.distanceKm % 1 == 0 ? 0 : 1)} km',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.business_rounded, size: 17, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Flexible(child: Text(job.contractor.company, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600))),
                          if (job.contractor.identityVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, size: 17, color: AppColors.green),
                          ],
                          if (job.contractor.rating > 0) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded, size: 18, color: AppColors.orange),
                            Text(job.contractor.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    runSpacing: 4,
                    children: [
                      _Fact(icon: Icons.currency_rupee_rounded, text: '${Fmt.rupees(job.wage)}/din', strong: true),
                      _Fact(icon: Icons.calendar_month_rounded, text: Fmt.days(job.days)),
                      _Fact(icon: Icons.schedule_rounded, text: Fmt.relativeDay(job.startDate, AppScope.of(context).now)),
                    ],
                  ),
                ),
                status ??
                    (closed
                        ? StatusPill(
                            label: job.status == JobStatus.cancelled ? 'Cancel' : 'Khatam',
                            bg: AppColors.redTint,
                            fg: AppColors.redDark,
                            icon: Icons.block_rounded,
                          )
                        : const Icon(Icons.chevron_right_rounded, size: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, this.strong = false});
  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: strong ? AppColors.greenDark : AppColors.muted),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: strong ? 18 : 15, fontWeight: strong ? FontWeight.w900 : FontWeight.w700, color: strong ? AppColors.greenDark : AppColors.charcoal)),
        ],
      ),
    );
  }
}

/// Contractor trust summary (screen 7 / 24 / 38).
class ContractorTrustCard extends StatelessWidget {
  const ContractorTrustCard({super.key, required this.contractor, this.onTap, this.showCall = false});
  final Contractor contractor;
  final VoidCallback? onTap;
  final bool showCall;

  @override
  Widget build(BuildContext context) {
    final c = contractor;
    final lowTrust = !c.identityVerified && c.ratingCount < 5;
    return KsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.charcoal, borderRadius: BorderRadius.circular(14)),
                child: Text(c.company.characters.first, style: const TextStyle(color: AppColors.yellow, fontSize: 26, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kaun de raha hai?', style: TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    Text(c.company, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                    Text(c.ownerName, style: const TextStyle(fontSize: 15, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 30),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              TrustBadge('Mobile verified', ok: c.mobileVerified),
              TrustBadge(c.identityVerified ? 'Pehchaan verified' : 'Pehchaan verify nahi', ok: c.identityVerified),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(emoji: '⭐', value: c.rating > 0 ? c.rating.toStringAsFixed(1) : 'Naya', label: 'Rating'),
              _Stat(emoji: '👷', value: '${c.workersHired}', label: 'Workers'),
              _Stat(emoji: '💰', value: c.paymentOnTimePercent > 0 ? '${c.paymentOnTimePercent}%' : '—', label: 'Samay par paisa'),
            ],
          ),
          if (lowTrust) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.orangeTint, borderRadius: BorderRadius.circular(Radii.s)),
              child: const Row(
                children: [
                  Icon(Icons.info_rounded, color: AppColors.orangeDark),
                  SizedBox(width: 8),
                  Expanded(child: Text('Naya contractor hai. Kaam shuru karne se pehle paisa aur samay pakka kar lein.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.orangeDark))),
                ],
              ),
            ),
          ],
          if (showCall) ...[
            const SizedBox(height: 12),
            KsButton(
              label: 'Contractor ko call karein',
              icon: Icons.call_rounded,
              kind: KsButtonKind.dark,
              onPressed: () => callPhone(context, c.phone, who: c.company),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.emoji, required this.value, required this.label});
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(Radii.s)),
        child: Column(
          children: [
            Text('$emoji $value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Big money tile — "Aaj ₹800".
class MoneyTile extends StatelessWidget {
  const MoneyTile({super.key, required this.label, required this.amount, this.color = AppColors.white, this.big = false, this.onTap, this.footer});
  final String label;
  final int amount;
  final Color color;
  final bool big;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return KsCard(
      color: color,
      onTap: onTap,
      borderColor: color == AppColors.white ? AppColors.border : color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.charcoalSoft)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Fmt.rupees(amount), style: TextStyle(fontSize: big ? 44 : 30, fontWeight: FontWeight.w900, height: 1.1)),
          ),
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}

/// Work condition chips ("⚠️ Bhaari saman") shown before accepting.
class ConditionChips extends StatelessWidget {
  const ConditionChips({super.key, required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      (job.physical.emoji, 'Mehnat: ${job.physical.label}'),
      (job.environment.emoji, job.environment.label),
      for (final c in job.conditions) (c.emoji, c.label),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (e, l) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Text('$e  $l', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

/// Vertical schedule timeline: Start → Break → Lunch → End, highlighting now.
class ScheduleTimeline extends StatelessWidget {
  const ScheduleTimeline({super.key, required this.schedule, this.now});
  final WorkSchedule schedule;
  final TimeOfDay? now;

  @override
  Widget build(BuildContext context) {
    final rows = <(TimeOfDay, String, String, bool)>[
      (schedule.start, '🟢', 'Kaam shuru', false),
      for (final b in schedule.breaks) ...[
        (b.start, b.isLunch ? '🍛' : '☕', '${b.label} (${Fmt.durationMinutes(b.minutes)})', true),
        (b.end, '🔨', 'Kaam dobara shuru', false),
      ],
      (schedule.end, '🏁', 'Kaam khatam', false),
    ];
    final nowMin = now == null ? null : Fmt.minutesOf(now!);
    var currentIdx = -1;
    if (nowMin != null) {
      for (var i = 0; i < rows.length; i++) {
        if (Fmt.minutesOf(rows[i].$1) <= nowMin) currentIdx = i;
      }
      if (nowMin >= Fmt.minutesOf(schedule.end)) currentIdx = rows.length - 1;
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 92,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(Fmt.time(rows[i].$1),
                        style: TextStyle(fontSize: 17, fontWeight: i == currentIdx ? FontWeight.w900 : FontWeight.w700, color: i < currentIdx ? AppColors.muted : AppColors.charcoal)),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(width: 3, height: 14, color: i == 0 ? Colors.transparent : AppColors.border),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == currentIdx ? AppColors.yellow : (i < currentIdx ? AppColors.charcoal : AppColors.white),
                          border: Border.all(color: AppColors.charcoal, width: 2.5),
                        ),
                      ),
                      Expanded(child: Container(width: 3, color: i == rows.length - 1 ? Colors.transparent : AppColors.border)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: i == currentIdx ? AppColors.yellowTint : (rows[i].$4 ? AppColors.orangeTint.withValues(alpha: 0.5) : Colors.transparent),
                      borderRadius: BorderRadius.circular(Radii.s),
                      border: i == currentIdx ? Border.all(color: AppColors.yellow, width: 2) : null,
                    ),
                    child: Row(
                      children: [
                        Text(rows[i].$2, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rows[i].$3, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                        if (i == currentIdx) const StatusPill(label: 'ABHI', bg: AppColors.charcoal, fg: AppColors.yellow),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
