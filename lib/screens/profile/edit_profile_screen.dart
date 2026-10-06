import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../widgets/widgets.dart';
import '../onboarding/availability_screen.dart';
import '../onboarding/experience_screen.dart';
import '../onboarding/location_screen.dart';
import '../onboarding/name_screen.dart';
import '../onboarding/photo_screen.dart';
import '../onboarding/skills_screen.dart';
import '../onboarding/wage_screen.dart';
import '../onboarding/work_pref_screen.dart';

/// Screen 41 — each row opens the matching onboarding step in edit mode.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  Future<void> _editEmergency(BuildContext context) async {
    final state = AppScope.read(context);
    final number = await showNumberPad(context, title: 'Ghar wale ka number', initial: state.profile.emergencyContact ?? '');
    if (number == null) return;
    state.profile.emergencyContact = number.isEmpty ? null : number;
    await state.saveProfile();
    if (context.mounted) {
      showSnack(context, 'Emergency number save ho gaya', icon: Icons.check_circle_rounded);
      voice.speak('Emergency number save ho gaya.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).profile;
    final rows = <(String, String, String, VoidCallback)>[
      ('🙂', 'Naam', p.name.isEmpty ? '—' : p.name, () => push(context, const NameScreen(editMode: true))),
      ('📷', 'Photo', p.photoPath == null ? 'Photo nahi hai' : 'Photo lagi hai ✓', () => push(context, const PhotoScreen(editMode: true))),
      ('🧱', 'Kaam (skills)', p.skills.isEmpty ? '—' : p.skills.map((s) => SkillCatalog.byId(s).name).join(', '),
          () => push(context, const SkillsScreen(editMode: true))),
      ('🧰', 'Experience', '${p.experienceYears} saal', () => push(context, const ExperienceScreen(editMode: true))),
      ('💰', 'Ek din ka paisa', '${Fmt.rupees(p.dailyWage)} / din', () => push(context, const WageScreen(editMode: true))),
      ('📍', 'Jagah aur doori', '${p.area.isEmpty ? p.city : '${p.area}, ${p.city}'} · ${p.maxDistanceKm} km',
          () => push(context, const LocationScreen(editMode: true))),
      ('🏗️', 'Kaisa kaam pasand', p.workPrefs.isEmpty ? 'Koi bhi' : p.workPrefs.map((w) => w.label).join(', '),
          () => push(context, const WorkPrefScreen(editMode: true))),
      ('🕒', 'Kab kaam karenge', '${p.availability.label} · ${p.shift.label}', () => push(context, const AvailabilityScreen(editMode: true))),
      ('📞', 'Emergency number', p.emergencyContact ?? 'Number jodein', () => _editEmergency(context)),
    ];
    return Scaffold(
      appBar: ksAppBar(context, title: 'Profile badlein', speak: 'Jo badalna hai, us par dabayein.'),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (emoji, label, value, onTap) = rows[i];
          return KsCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.yellowTint, borderRadius: BorderRadius.circular(16)),
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Big-digit number entry (no system keyboard needed).
Future<String?> showNumberPad(BuildContext context, {required String title, String initial = '', int maxLength = 10}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _NumberPad(title: title, initial: initial, maxLength: maxLength),
  );
}

class _NumberPad extends StatefulWidget {
  const _NumberPad({required this.title, required this.initial, required this.maxLength});
  final String title;
  final String initial;
  final int maxLength;

  @override
  State<_NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<_NumberPad> {
  late String _value = widget.initial;

  void _tap(String d) {
    if (_value.length >= widget.maxLength) return;
    setState(() => _value += d);
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {VoidCallback? onTap, IconData? icon}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Material(
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.m),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.m),
                onTap: onTap ?? () => _tap(label),
                child: SizedBox(
                  height: 64,
                  child: Center(
                    child: icon != null ? Icon(icon, size: 30) : Text(label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Radii.m),
              border: Border.all(color: AppColors.yellow, width: 3),
            ),
            child: Text(_value.isEmpty ? '— — —' : _value,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3)),
          ),
          const SizedBox(height: 12),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(children: [for (final d in row) key(d)]),
          Row(
            children: [
              key('', icon: Icons.backspace_rounded, onTap: () {
                if (_value.isNotEmpty) setState(() => _value = _value.substring(0, _value.length - 1));
              }),
              key('0'),
              key('', icon: Icons.check_rounded, onTap: () => Navigator.pop(context, _value)),
            ],
          ),
          const SizedBox(height: 10),
          KsButton(label: 'Save karein', icon: Icons.check_circle_rounded, onPressed: () => Navigator.pop(context, _value)),
        ],
      ),
    );
  }
}
