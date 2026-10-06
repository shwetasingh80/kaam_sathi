import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/voice/intent_parser.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import 'onboarding_scaffold.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  late String _digits = AppScope.read(context).profile.phone;
  String? _error;

  bool get _valid => _digits.length == 10 && RegExp(r'^[6-9]').hasMatch(_digits);

  void _add(String d) {
    if (_digits.length >= 10) return;
    setState(() {
      _digits += d;
      _error = null;
    });
  }

  void _back() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _onVoice(String text) {
    // Spoken numbers usually come back as digits ("98765 43210").
    var d = IntentParser.normalize(text).replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length > 10 && d.startsWith('91')) d = d.substring(d.length - 10);
    if (d.isEmpty) {
      voice.speak('Number samajh nahi aaya. Ek ek ank dheere boliye.');
      setState(() => _error = 'Number samajh nahi aaya. Dobara boliye.');
      return;
    }
    setState(() {
      _digits = d.length > 10 ? d.substring(0, 10) : d;
      _error = null;
    });
    voice.speak('Aapka number ${_digits.split('').join(' ')} hai.');
  }

  void _next() {
    if (!_valid) {
      setState(() => _error = 'Poora 10 ank ka mobile number daaliye');
      voice.speak('Poora das ank ka mobile number daaliye.');
      return;
    }
    final s = AppScope.read(context);
    s.profile.phone = _digits;
    s.saveProfile();
    voice.stopSpeaking();
    push(context, OtpScreen(phone: _digits));
  }

  String get _display {
    final d = _digits.padRight(10, '•');
    return '${d.substring(0, 5)} ${d.substring(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 1,
      title: 'Aapka mobile number?',
      speech: 'Apna mobile number daaliye. Neeche ke bade button dabaiye ya bolkar batayiye.',
      primaryLabel: 'OTP bhejein',
      onPrimary: _digits.length == 10 ? _next : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Radii.m),
              border: Border.all(color: _error != null ? AppColors.red : AppColors.yellow, width: 3),
            ),
            child: Row(
              children: [
                const Text('🇮🇳 +91', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.muted)),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(_display, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.error_rounded, color: AppColors.redDark),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.redDark, fontSize: 16, fontWeight: FontWeight.w700))),
              ]),
            ),
          const SizedBox(height: Space.l),
          BigKeypad(onDigit: _add, onBackspace: _back),
          const SizedBox(height: Space.l),
          VoiceInputBar(prompt: 'Number bolkar batayein', example: '98765 43210', onResult: _onVoice),
        ],
      ),
    );
  }
}
