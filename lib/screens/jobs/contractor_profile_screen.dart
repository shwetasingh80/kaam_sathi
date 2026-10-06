import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../help/report_screen.dart';

/// Screen 24 — contractor trust profile.
class ContractorProfileScreen extends StatelessWidget {
  const ContractorProfileScreen({super.key, required this.contractor});
  final Contractor contractor;

  static const _reviews = [
    ('Suresh Y.', 5, 'Paisa roz shaam ko mil gaya. Achha vyavhar.'),
    ('Manoj K.', 4, 'Kaam theek tha, lunch ka samay pakka mila.'),
    ('Ramesh P.', 4, 'Site par paani aur chhaanv ka intezaam tha.'),
  ];

  static const _reportTypes = [
    ReportType.fakeJob,
    ReportType.wrongWage,
    ReportType.payment,
    ReportType.unsafe,
    ReportType.harassment,
    ReportType.fraud,
    ReportType.location,
  ];

  @override
  Widget build(BuildContext context) {
    final c = contractor;
    final hasReviews = c.ratingCount > 0;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Contractor', speak: c.spokenTrust),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          KsCard(
            color: AppColors.charcoal,
            borderColor: AppColors.charcoal,
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(Radii.m)),
                  child: Text(c.company.characters.first, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.company, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.white)),
                      Text(c.ownerName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.yellowSoft)),
                      Text('📍 ${c.area}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SpeakButtonFull(text: c.spokenTrust),
          const SizedBox(height: 12),
          KsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrustBadge('Mobile verified', ok: c.mobileVerified),
                const SizedBox(height: 8),
                TrustBadge(c.identityVerified ? 'Pehchaan verified' : 'Pehchaan abhi verify nahi hui', ok: c.identityVerified),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _StatBox('⭐', hasReviews ? c.rating.toStringAsFixed(1) : 'Naya', hasReviews ? '${c.ratingCount} rating' : 'Abhi rating nahi'),
              _StatBox('👷', '${c.workersHired}', 'Workers ko kaam diya'),
              _StatBox('🏗️', '${c.jobsCompleted}', 'Kaam poore kiye'),
              _StatBox('📅', '${c.since}', 'Se platform par'),
            ],
          ),
          const SizedBox(height: 12),
          KsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Samay par paisa', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                    Text(c.paymentOnTimePercent > 0 ? '${c.paymentOnTimePercent}%' : '—',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: c.paymentOnTimePercent / 100,
                    minHeight: 14,
                    color: c.paymentOnTimePercent >= 90
                        ? AppColors.green
                        : c.paymentOnTimePercent >= 75
                            ? AppColors.orange
                            : AppColors.red,
                    backgroundColor: AppColors.divider,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.paymentOnTimePercent == 0
                      ? 'Abhi jaankari nahi hai'
                      : '100 mein se ${c.paymentOnTimePercent} baar paisa samay par diya',
                  style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KsButton(
            label: 'Contractor ko call karein',
            icon: Icons.call_rounded,
            kind: KsButtonKind.dark,
            onPressed: () => callPhone(context, c.phone, who: c.company),
          ),
          if (hasReviews) ...[
            const SectionTitle('Mazdooron ki baat'),
            for (final (name, stars, text) in _reviews) ...[
              KsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(name: name, size: 40),
                        const SizedBox(width: 10),
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                        Text('⭐' * stars, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(text, style: const TextStyle(fontSize: 17)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SectionTitle('Kuch galat laga? Shikayat karein'),
          KsCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final t in _reportTypes)
                  ListTile(
                    minTileHeight: 60,
                    leading: Text(t.emoji, style: const TextStyle(fontSize: 26)),
                    title: Text(t.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 28),
                    onTap: () => push(context, ReportScreen(type: t)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width speak button.
class SpeakButtonFull extends StatelessWidget {
  const SpeakButtonFull({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return KsButton(label: 'Contractor ke baare mein suno', emoji: '🔊', onPressed: () => voice.speak(text));
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.emoji, this.value, this.label);
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return KsCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(child: Text('$emoji $value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
