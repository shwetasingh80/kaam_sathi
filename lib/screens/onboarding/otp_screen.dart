import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/voice/intent_parser.dart';
import '../../data/app_state.dart';
import '../../widgets/widgets.dart';
import 'name_screen.dart';
import 'onboarding_scaffold.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _demoOtp = '1234';
  String _code = '';
  String? _error;
  int _seconds = 30;
  Timer? _timer;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) t.cancel();
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _add(String d) {
    if (_code.length >= 4 || _verifying) return;
    setState(() {
      _code += d;
      _error = null;
    });
    if (_code.length == 4) _verify();
  }

  void _back() {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  void _onVoice(String text) {
    final d = IntentParser.normalize(text).replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length < 4) {
      voice.speak('OTP samajh nahi aaya. Chaar ank boliye.');
      return;
    }
    setState(() => _code = d.substring(0, 4));
    _verify();
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    if (_code == _demoOtp) {
      final s = AppScope.read(context);
      s.profile.mobileVerified = true;
      s.saveProfile();
      voice.speak('Number verify ho gaya.');
      setState(() => _verifying = false);
      push(context, const NameScreen());
    } else {
      setState(() {
        _verifying = false;
        _error = 'OTP galat hai. Dobara daaliye.';
        _code = '';
      });
      voice.speak('OTP galat hai. Message mein aaya chaar ank ka number dobara daaliye.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 2,
      title: 'Message mein aaya OTP daaliye',
      subtitle: '+91 ${widget.phone} par bheja gaya',
      speech: 'Aapke phone par chaar ank ka OTP bheja gaya hai. Use daaliye.',
      primaryLabel: 'Verify karein',
      onPrimary: _code.length == 4 && !_verifying ? _verify : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.blueTint, borderRadius: BorderRadius.circular(Radii.s)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_rounded, color: AppColors.blueDark),
                SizedBox(width: 8),
                Text('Demo OTP: $_demoOtp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blueDark)),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 64,
                  height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Radii.m),
                    border: Border.all(
                      color: _error != null ? AppColors.red : (i == _code.length ? AppColors.yellow : AppColors.border),
                      width: i == _code.length || _error != null ? 3 : 2,
                    ),
                  ),
                  child: Text(i < _code.length ? _code[i] : '', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          if (_verifying) const Padding(padding: EdgeInsets.only(top: 12), child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_rounded, color: AppColors.redDark),
                const SizedBox(width: 6),
                Text(_error!, style: const TextStyle(color: AppColors.redDark, fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
          const SizedBox(height: 8),
          _seconds > 0
              ? Text('Naya OTP $_seconds second mein', style: const TextStyle(fontSize: 16, color: AppColors.muted, fontWeight: FontWeight.w700))
              : TextButton.icon(
                  onPressed: () {
                    _startTimer();
                    showSnack(context, 'Naya OTP bheja gaya', icon: Icons.sms_rounded);
                    voice.speak('Naya OTP bheja gaya.');
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('OTP dobara bhejein', style: TextStyle(fontSize: 17)),
                ),
          const SizedBox(height: Space.s),
          BigKeypad(onDigit: _add, onBackspace: _back),
          const SizedBox(height: Space.l),
          VoiceInputBar(prompt: 'OTP bolkar batayein', example: '1 2 3 4', onResult: _onVoice),
        ],
      ),
    );
  }
}
