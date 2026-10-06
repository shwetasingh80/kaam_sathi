import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';

/// Screen 42 — optional identity + skill verification.
/// Documents never reach contractors; they only see "✓ Verified".
class SkillVerificationScreen extends StatefulWidget {
  const SkillVerificationScreen({super.key});

  @override
  State<SkillVerificationScreen> createState() => _SkillVerificationScreenState();
}

class _Method {
  const _Method(this.emoji, this.title, this.hint, this.steps);
  final String emoji;
  final String title;
  final String hint;
  final List<String> steps;
}

const _methods = [
  _Method('🤝', 'Pichhle contractor se confirm', 'Jinke saath kaam kiya, wo bata denge',
      ['Contractor ka naam ya number chunein', 'Hum unse 1 call par pooch lenge']),
  _Method('🧪', 'Skill test', 'Site par 1 ghante ka chhota test',
      ['Paas ke test centre par jayein', 'Kaam karke dikhayein']),
  _Method('📜', 'Training certificate', 'Agar koi training ki hai',
      ['Certificate ki photo kheenchein', 'Team check karegi']),
  _Method('🎯', 'Platform assessment', 'Phone par kuch sawal — bolkar jawab',
      ['5 aasaan sawal sunein', 'Bolkar jawab dein']),
  _Method('📒', 'Kaam ka record', 'KaamSaathi par poore kiye kaam',
      ['3 kaam poore hone par apne aap verify']),
  _Method('⭐', 'Ratings', 'Contractor ki achhi rating se',
      ['4+ rating ke 5 kaam par apne aap verify']),
];

class _SkillVerificationScreenState extends State<SkillVerificationScreen> {
  /// Skills with a pending request (local to this build).
  static final Set<String> _pending = {};

  Future<void> _startMethod(String skillId, _Method m) async {
    final skill = SkillCatalog.byId(skillId);
    final ok = await confirmAction(
      context,
      emoji: m.emoji,
      title: m.title,
      speech: '${skill.name} verify karne ke liye: ${m.steps.join('. ')}. Kya request bhejein?',
      yesLabel: 'Haan, request bhejo',
      noLabel: 'Abhi nahi',
      details: Column(
        children: [
          for (var i = 0; i < m.steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.charcoal,
                    child: Text('${i + 1}', style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(m.steps[i], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
        ],
      ),
    );
    if (!ok || !mounted) return;
    setState(() => _pending.add(skillId));
    voice.speak('Request bhej di gayi. 2 se 3 din mein verify hoga.');
    showSnack(context, 'Request bhej di gayi — 2-3 din mein verify hoga', icon: Icons.send_rounded);
  }

  Future<void> _pickMethod(String skillId) async {
    final m = await showModalBottomSheet<_Method>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('${SkillCatalog.byId(skillId).name} kaise verify karein?',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            for (final m in _methods) ...[
              SelectTile(title: m.title, subtitle: m.hint, emoji: m.emoji, selected: false, onTap: () => Navigator.pop(ctx, m)),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
    if (m != null) await _startMethod(skillId, m);
  }

  Future<void> _verifyIdentity() async {
    final state = AppScope.read(context);
    final ok = await confirmAction(
      context,
      emoji: '🪪',
      title: 'Pehchaan verify karein?',
      speech: 'Aapki pehchaan sirf KaamSaathi team dekhegi. Contractor ko sirf verified ka nishaan dikhega. Kya verify karein?',
      yesLabel: 'Haan, verify karo',
      noLabel: 'Abhi nahi',
    );
    if (!ok || !mounted) return;
    state.profile.identityVerified = true;
    await state.saveProfile();
    voice.speak('Aapki pehchaan verify ho gayi.');
    if (mounted) showSnack(context, 'Identity Verified ✓', icon: Icons.verified_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).profile;
    return Scaffold(
      appBar: ksAppBar(context, title: 'Verify karein', speak: 'Verify hone se contractor aap par zyada bharosa karte hain aur zyada kaam milta hai.'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          KsCard(
            color: AppColors.yellowTint,
            borderColor: AppColors.yellow,
            child: const Row(
              children: [
                Text('🏅', style: TextStyle(fontSize: 40)),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Verify hone par zyada aur achha kaam milta hai.',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SectionTitle('Pehchaan (Identity)'),
          KsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🪪', style: TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: p.identityVerified
                          ? const TrustBadge('Identity Verified')
                          : const Text('Pehchaan verify nahi hai', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                if (!p.identityVerified) ...[
                  const SizedBox(height: 8),
                  const Text('Zaroori nahi hai — aapki marzi.', style: TextStyle(fontSize: 16, color: AppColors.muted)),
                  const SizedBox(height: 12),
                  KsButton(label: 'Verify karein', icon: Icons.verified_user_rounded, onPressed: _verifyIdentity),
                ],
              ],
            ),
          ),
          const SectionTitle('Mere kaam (skills)'),
          if (p.skills.isEmpty)
            const EmptyState(emoji: '🧱', title: 'Pehle skill chunein', subtitle: 'Profile badlein → Kaam (skills)', compact: true),
          for (final id in p.skills) ...[
            Builder(builder: (context) {
              final s = SkillCatalog.byId(id);
              final verified = p.verifiedSkills.contains(id);
              final pending = !verified && _pending.contains(id);
              return KsCard(
                onTap: verified || pending ? null : () => _pickMethod(id),
                child: Row(
                  children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          if (verified)
                            const StatusPill(label: 'Skill Verified ✓', bg: AppColors.greenTint, fg: AppColors.greenDark, icon: Icons.verified_rounded)
                          else if (pending)
                            const StatusPill(label: 'Pending', bg: AppColors.orangeTint, fg: AppColors.orangeDark, icon: Icons.hourglass_top_rounded)
                          else
                            const StatusPill(label: 'Verify nahi', bg: AppColors.divider, fg: AppColors.charcoalSoft, icon: Icons.help_outline_rounded),
                        ],
                      ),
                    ),
                    if (!verified && !pending)
                      const Text('Verify', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.blueTint, borderRadius: BorderRadius.circular(Radii.m)),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, color: AppColors.blueDark),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Aapke documents contractor ko nahi dikhaye jaate — sirf ✓ Verified dikhta hai.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.blueDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
