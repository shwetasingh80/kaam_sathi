import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../onboarding/language_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'skill_verification_screen.dart';

/// Profile tab (screen 40) — trust-forward summary of the worker.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _chooseAvailability(BuildContext context) async {
    final state = AppScope.read(context);
    final picked = await showModalBottomSheet<Availability>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Abhi aap kya hain?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              for (final a in Availability.values) ...[
                SelectTile(
                  title: a.label,
                  emoji: a.emoji,
                  selected: state.profile.availability == a,
                  onTap: () => Navigator.pop(ctx, a),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      state.profile.availability = picked;
      await state.saveProfile();
      voice.speak('Aapka status badal diya gaya: ${picked.label}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile;
    final rel = state.reliability;

    return Scaffold(
      appBar: ksAppBar(
        context,
        title: 'Mera Profile',
        showBack: false,
        speak: p.spoken,
        actions: [
          IconButton(
            tooltip: 'Settings',
            iconSize: 30,
            onPressed: () => push(context, const SettingsScreen()),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      floatingActionButton: const VoiceFab(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
              children: [
                // ── Trust card
                KsCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        decoration: const BoxDecoration(color: AppColors.yellow),
                        child: Row(
                          children: [
                            Avatar(name: p.name, photoPath: p.photoPath, size: 84),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name.isEmpty ? 'Naam nahi diya' : p.name,
                                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                                  const SizedBox(height: 4),
                                  Text(p.primarySkill?.name ?? 'Skill chunein',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppColors.charcoal, size: 22),
                                      const SizedBox(width: 2),
                                      Text(p.rating > 0 ? p.rating.toStringAsFixed(1) : 'Nayi rating',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TrustBadge('Mobile Verified', ok: p.mobileVerified),
                            const SizedBox(height: 8),
                            if (p.identityVerified)
                              const TrustBadge('Identity Verified')
                            else
                              InkWell(
                                onTap: () => push(context, const SkillVerificationScreen()),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_moderator_rounded, color: AppColors.orangeDark, size: 22),
                                      SizedBox(width: 6),
                                      Text('Pehchaan verify karein',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.orangeDark, decoration: TextDecoration.underline)),
                                    ],
                                  ),
                                ),
                              ),
                            for (final id in p.verifiedSkills) ...[
                              const SizedBox(height: 8),
                              TrustBadge('${SkillCatalog.byId(id).name} Verified'),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _MiniStat(emoji: '🧰', value: '${p.experienceYears} saal', label: 'Experience'),
                                _MiniStat(emoji: '✅', value: '${p.jobsCompleted}', label: 'Kaam poore'),
                                _MiniStat(emoji: '⭐', value: p.rating > 0 ? p.rating.toStringAsFixed(1) : '—', label: 'Rating'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── Availability
                KsCard(
                  color: p.availability.bg,
                  borderColor: p.availability.bg,
                  onTap: () => _chooseAvailability(context),
                  child: Row(
                    children: [
                      Text(p.availability.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Abhi ka status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.charcoalSoft)),
                            Text(p.availability.label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: p.availability.fg)),
                          ],
                        ),
                      ),
                      const Text('Badlein', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
                const SectionTitle('Mere kaam (skills)'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < p.skills.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: i == 0 ? AppColors.yellowTint : AppColors.white,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: i == 0 ? AppColors.yellow : AppColors.border, width: i == 0 ? 2.5 : 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(SkillCatalog.byId(p.skills[i]).emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(SkillCatalog.byId(p.skills[i]).name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            if (i == 0) ...[
                              const SizedBox(width: 8),
                              const StatusPill(label: 'MUKHYA', bg: AppColors.charcoal, fg: AppColors.yellow),
                            ],
                            if (p.verifiedSkills.contains(p.skills[i])) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: AppColors.green, size: 20),
                            ],
                          ],
                        ),
                      ),
                    if (p.skills.isEmpty)
                      const Text('Abhi koi skill nahi chuni', style: TextStyle(fontSize: 17, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 12),
                KsCard(
                  child: Column(
                    children: [
                      InfoRow(emoji: '💰', question: 'Ek din ka paisa', answer: '${Fmt.rupees(p.dailyWage)} / din'),
                      const Divider(),
                      InfoRow(
                        emoji: '📍',
                        question: 'Kaam ki jagah',
                        answer: p.area.isEmpty ? p.city : '${p.area}, ${p.city}',
                        sub: '${p.maxDistanceKm} km tak',
                      ),
                      const Divider(),
                      InfoRow(emoji: p.shift.emoji, question: 'Kaam ka samay', answer: p.shift.label, sub: p.shift.hint),
                    ],
                  ),
                ),
                const SectionTitle('Mera record'),
                KsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${rel.attendancePercent}%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.greenDark)),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Haazri (attendance)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: rel.attendancePercent / 100,
                          minHeight: 12,
                          color: AppColors.green,
                          backgroundColor: AppColors.greenTint,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _RelRow(emoji: '✅', label: 'Kaam poore kiye', value: '${rel.completed}'),
                      _RelRow(emoji: '🟢', label: 'Haazir din', value: '${rel.presentDays}'),
                      _RelRow(emoji: '🤒', label: 'Bimaari ki chhutti', value: '${rel.sickDays}'),
                      _RelRow(emoji: '🚨', label: 'Emergency chhutti', value: '${rel.emergencyDays}'),
                      _RelRow(emoji: '🚫', label: 'Bina bataye nahi aaye', value: '${rel.noShows}'),
                      _RelRow(emoji: '🚪', label: 'Kaam chhoda', value: '${rel.leftJobs}'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.blueTint, borderRadius: BorderRadius.circular(Radii.s)),
                        child: const Row(
                          children: [
                            Icon(Icons.favorite_rounded, color: AppColors.blueDark),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Bimaari ki chhutti no-show nahi maani jaati. Bata kar chhutti lene se record kharab nahi hota.',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.blueDark)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                KsButton(label: 'Profile badlein', icon: Icons.edit_rounded, onPressed: () => push(context, const EditProfileScreen())),
                const SizedBox(height: 12),
                KsButton(
                  label: 'Skill verify karein',
                  icon: Icons.verified_user_rounded,
                  kind: KsButtonKind.dark,
                  onPressed: () => push(context, const SkillVerificationScreen()),
                ),
                const SizedBox(height: 12),
                KsButton(
                  label: 'Bhasha badlein',
                  emoji: '🗣️',
                  kind: KsButtonKind.secondary,
                  onPressed: () => push(context, const LanguageScreen(editMode: true)),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.lock_rounded, size: 20, color: AppColors.muted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Contractor ko sirf “✓ Identity Verified” dikhta hai — aapka ID card ya number kabhi nahi.',
                          style: TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.emoji, required this.value, required this.label});
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(Radii.s)),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RelRow extends StatelessWidget {
  const _RelRow({required this.emoji, required this.label, required this.value});
  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
