import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import 'onboarding_scaffold.dart';
import 'photo_screen.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key, this.editMode = false});
  final bool editMode;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final TextEditingController _c = TextEditingController(text: AppScope.read(context).profile.name);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _clean(String raw) {
    var t = raw.trim();
    // "Mera naam Rakesh Kumar hai" → "Rakesh Kumar"
    t = t.replaceAll(RegExp(r'^(mera|meraa|मेरा)\s+(naam|nam|नाम)\s+', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\s+(hai|he|है)$', caseSensitive: false), '');
    return t
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.length == 1 ? w.toUpperCase() : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Future<void> _onVoice(String text) async {
    final name = _clean(text);
    if (name.isEmpty) return;
    final ok = await confirmAction(
      context,
      emoji: '🙂',
      title: name,
      speech: 'Aapka naam $name hai. Sahi hai?',
      yesLabel: 'Haan',
      noLabel: 'Dobara Bolo',
    );
    if (ok) setState(() => _c.text = name);
  }

  void _next() {
    final name = _clean(_c.text);
    if (name.isEmpty) return;
    final s = AppScope.read(context);
    s.profile.name = name;
    s.saveProfile();
    voice.speak('Namaste $name ji.');
    finishStep(context, editMode: widget.editMode, next: () => const PhotoScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 3,
      editMode: widget.editMode,
      title: 'Aapka naam kya hai?',
      speech: 'Aapka naam kya hai? Bolkar batayiye.',
      onPrimary: _c.text.trim().isEmpty ? null : _next,
      body: TextField(
        controller: _c,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        decoration: const InputDecoration(hintText: 'Jaise: Rakesh Kumar', prefixIcon: Icon(Icons.person_rounded, size: 30)),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _next(),
      ),
      voiceBar: VoiceInputBar(prompt: 'Naam bolkar batayein', example: 'Mera naam Rakesh Kumar hai', onResult: _onVoice),
    );
  }
}
