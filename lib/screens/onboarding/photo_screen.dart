import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import 'onboarding_scaffold.dart';
import 'skills_screen.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  late String? _path = AppScope.read(context).profile.photoPath;

  Future<void> _pick(ImageSource src) async {
    try {
      final f = await ImagePicker().pickImage(source: src, maxWidth: 800, imageQuality: 80, preferredCameraDevice: CameraDevice.front);
      if (f == null || !mounted) return;
      setState(() => _path = f.path);
      voice.speak('Photo lag gayi. Achhi hai!');
    } catch (_) {
      if (!mounted) return;
      showSnack(context, 'Camera nahi khul paaya. Baad mein koshish karein.', icon: Icons.no_photography_rounded);
    }
  }

  void _save({bool skip = false}) {
    final s = AppScope.read(context);
    if (!skip) {
      s.profile.photoPath = _path;
      s.saveProfile();
    }
    finishStep(context, editMode: widget.editMode, next: () => const SkillsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).profile.name;
    return OnboardingScaffold(
      step: 4,
      editMode: widget.editMode,
      title: 'Apni photo lagayein',
      subtitle: 'Photo se contractor aapko pehchanega',
      speech: 'Apni photo lagaiye. Photo se contractor aapko pehchanega aur bharosa badhega.',
      primaryLabel: _path == null ? 'Aage badhein' : 'Photo theek hai',
      onPrimary: _path == null ? null : _save,
      secondary: widget.editMode
          ? null
          : TextButton(
              onPressed: () => _save(skip: true),
              child: const Text('Baad mein lagaunga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
            ),
      body: Column(
        children: [
          Center(
            child: Stack(
              children: [
                Avatar(name: name, photoPath: _path, size: 180),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.charcoal, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 3)),
                    child: const Icon(Icons.photo_camera_rounded, color: AppColors.yellow, size: 28),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          KsButton(label: 'Camera se photo lein', icon: Icons.photo_camera_rounded, kind: KsButtonKind.dark, onPressed: () => _pick(ImageSource.camera)),
          const SizedBox(height: 12),
          KsButton(label: 'Gallery se chunein', icon: Icons.photo_library_rounded, kind: KsButtonKind.secondary, onPressed: () => _pick(ImageSource.gallery)),
          const SizedBox(height: Space.l),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.yellowTint, borderRadius: BorderRadius.circular(Radii.m)),
            child: const Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Expanded(child: Text('Roshni mein, seedha camera ki taraf dekhein', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
