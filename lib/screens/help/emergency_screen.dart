import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../profile/edit_profile_screen.dart';
import 'report_screen.dart';

/// Screen 44 — Emergency.
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  static const _intro = 'Ghabraiye mat. Neeche se madad chunein.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => voice.speak(_intro));
  }

  Future<void> _addContact() async {
    final state = AppScope.read(context);
    final n = await showNumberPad(context, title: 'Ghar wale ka number');
    if (n == null || n.isEmpty) return;
    state.profile.emergencyContact = n;
    await state.saveProfile();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final contact = state.profile.emergencyContact;
    final a = state.currentAssignment;
    return Scaffold(
      backgroundColor: AppColors.redTint,
      appBar: AppBar(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.white, size: 28),
        toolbarHeight: 64,
        titleSpacing: 0,
        title: const Text('Emergency', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: SpeakButton(text: _intro, label: '', compact: true, dark: true))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text('Ghabraiye mat.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.redDark)),
          const Text('Neeche se madad chunein.', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          _BigCall(emoji: '🚓', title: '112', subtitle: 'Police / Emergency', onTap: () => callPhone(context, '112', who: '112 Emergency')),
          const SizedBox(height: 12),
          _BigCall(emoji: '🚑', title: '108', subtitle: 'Ambulance', onTap: () => callPhone(context, '108', who: 'Ambulance')),
          const SizedBox(height: 12),
          if (contact != null)
            KsButton(
              label: 'Ghar wale ko call',
              subtitle: contact,
              emoji: '👨‍👩‍👧',
              kind: KsButtonKind.dark,
              height: 76,
              onPressed: () => callPhone(context, contact, who: 'Ghar wale'),
            )
          else
            KsButton(
              label: 'Ghar wale ka number jodein',
              emoji: '➕',
              kind: KsButtonKind.secondary,
              onPressed: _addContact,
            ),
          const SizedBox(height: 12),
          KsButton(
            label: 'Contractor ko call',
            subtitle: a?.job.contractor.company ?? 'Abhi koi kaam nahi',
            icon: Icons.call_rounded,
            kind: KsButtonKind.secondary,
            height: 76,
            onPressed: a == null ? null : () => callPhone(context, a.job.contractor.phone, who: a.job.contractor.company),
          ),
          const SizedBox(height: 12),
          KsButton(
            label: 'Chot lagi — contractor ko batao',
            emoji: '🩹',
            kind: KsButtonKind.primary,
            onPressed: () => push(context, ReportScreen(type: ReportType.injury, jobId: a?.job.id)),
          ),
        ],
      ),
    );
  }
}

class _BigCall extends StatelessWidget {
  const _BigCall({required this.emoji, required this.title, required this.subtitle, required this.onTap});
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$subtitle $title call karein',
      excludeSemantics: true,
      child: Material(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(Radii.l),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.l),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.white, height: 1)),
                      Text(subtitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.white,
                  child: Icon(Icons.call_rounded, color: AppColors.red, size: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
