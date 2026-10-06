import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import 'onboarding_scaffold.dart';
import 'work_pref_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const _cities = ['Lucknow', 'Kanpur', 'Varanasi', 'Prayagraj', 'Agra'];
  static const _distances = [2, 5, 10, 20];

  late String _city = AppScope.read(context).profile.city;
  late int _km = AppScope.read(context).profile.maxDistanceKm;
  late final TextEditingController _area = TextEditingController(text: AppScope.read(context).profile.area);
  late final TextEditingController _otherCity =
      TextEditingController(text: _cities.contains(_city) ? '' : _city);
  late bool _other = !_cities.contains(_city);

  @override
  void dispose() {
    _area.dispose();
    _otherCity.dispose();
    super.dispose();
  }

  void _onVoice(String text) {
    var t = text.trim();
    // Detect a known city in speech.
    for (final c in _cities) {
      if (t.toLowerCase().contains(c.toLowerCase())) {
        setState(() {
          _city = c;
          _other = false;
        });
        t = t.replaceAll(RegExp(c, caseSensitive: false), '');
      }
    }
    t = t.replaceAll(RegExp(r'\b(main|mai|mein|me|rehta|rahta|hoon|hun|hu|mohalla|area|ka|ki|se|aur)\b', caseSensitive: false), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isNotEmpty) {
      setState(() => _area.text = t.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' '));
    }
    voice.speak('Aap ${_area.text.isEmpty ? '' : '${_area.text}, '}$_city mein rehte hain.');
  }

  void _next() {
    final s = AppScope.read(context);
    final city = _other ? _otherCity.text.trim() : _city;
    s.profile
      ..city = city.isEmpty ? 'Lucknow' : city
      ..area = _area.text.trim()
      ..maxDistanceKm = _km;
    s.saveProfile();
    finishStep(context, editMode: widget.editMode, next: () => const WorkPrefScreen());
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 8,
      editMode: widget.editMode,
      title: 'Aap kahan rehte hain?',
      speech: 'Aap kis shahar aur mohalle mein rehte hain? Aur kitni door tak kaam par ja sakte hain?',
      onPrimary: _next,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🏙️ Shahar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _cities)
                BigChoiceChip(
                  label: c,
                  selected: !_other && _city == c,
                  onTap: () {
                    setState(() {
                      _city = c;
                      _other = false;
                    });
                    voice.speak(c);
                  },
                ),
              BigChoiceChip(label: 'Aur shahar', selected: _other, onTap: () => setState(() => _other = true)),
            ],
          ),
          if (_other) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _otherCity,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(hintText: 'Shahar ka naam', prefixIcon: Icon(Icons.location_city_rounded)),
            ),
          ],
          _label('📍 Mohalla / Area'),
          TextField(
            controller: _area,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(hintText: 'Jaise: Kapoorthala', prefixIcon: Icon(Icons.home_rounded)),
          ),
          const SizedBox(height: 12),
          VoiceInputBar(prompt: 'Mohalla bolkar batayein', example: 'Main Kapoorthala, Lucknow mein rehta hoon', onResult: _onVoice),
          _label('🚶 Kitni door tak kaam karenge?'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final d in _distances)
                BigChoiceChip(
                  label: '$d km',
                  selected: _km == d,
                  onTap: () {
                    setState(() => _km = d);
                    voice.speak('$d kilometer tak');
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _km <= 2 ? 'Paidal doori' : (_km <= 5 ? 'Cycle se pahunch sakte hain' : (_km <= 10 ? 'Bus / tempo se' : 'Door ka kaam bhi chalega')),
            style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
