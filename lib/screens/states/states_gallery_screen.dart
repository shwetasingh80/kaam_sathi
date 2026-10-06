import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/widgets.dart';

/// Screens 47–50 / §41 — reference of every edge-case state, rendered with
/// the real components. Each card can be heard with 🔊.
class StatesGalleryScreen extends StatelessWidget {
  const StatesGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ksAppBar(context, title: 'App ke states'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const SectionTitle('Offline / Network', padding: EdgeInsets.fromLTRB(4, 8, 4, 10)),
          _Frame(
            label: 'Offline banner',
            speech: 'Internet nahi hai. Aapka request connection aate hi bhej diya jayega.',
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.charcoal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: AppColors.yellow, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Internet nahi hai. Purani jaankari dikh rahi hai.',
                            style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const _Message(
                  emoji: '📶',
                  title: 'Internet nahi hai',
                  sub: 'Aapka request connection aate hi bhej diya jayega.',
                  bg: AppColors.orangeTint,
                ),
              ],
            ),
          ),
          const _Frame(
            label: 'Server error (kabhi HTTP code nahi)',
            speech: 'Abhi connection mein dikkat hai. Thodi der baad koshish karein.',
            child: _Message(emoji: '🔌', title: 'Abhi connection mein dikkat hai', sub: 'Thodi der baad koshish karein.', bg: AppColors.redTint, retry: true),
          ),
          const SectionTitle('Kaam'),
          const _Frame(
            label: 'Koi kaam nahi (empty)',
            speech: 'Abhi koi naya kaam nahi hai. Naya kaam aate hi hum aapko bata denge.',
            child: EmptyState(emoji: '🔍', title: 'Abhi koi naya kaam nahi hai', subtitle: 'Naya kaam aate hi hum bata denge.', compact: true),
          ),
          const _Frame(
            label: 'Job expired',
            speech: 'Ye kaam ab available nahi hai.',
            child: _Message(emoji: '⌛', title: 'Ye kaam ab available nahi hai', sub: 'Dusre kaam dekhein.', bg: AppColors.divider),
          ),
          const _Frame(
            label: 'Contractor ne cancel kiya',
            speech: 'Contractor ne ye kaam cancel kar diya hai.',
            child: _Message(emoji: '❌', title: 'Contractor ne ye kaam cancel kar diya hai', sub: 'Aapke record par koi asar nahi.', bg: AppColors.redTint),
          ),
          const _Frame(
            label: 'Worker ne reject kiya',
            speech: 'Kaam reject kar diya gaya.',
            child: _Message(emoji: '👋', title: 'Kaam reject kar diya gaya', sub: 'Ye kaam dobara nahi dikhega.', bg: AppColors.blueTint),
          ),
          const _Frame(
            label: 'Pehle se dusre kaam par',
            speech: 'Is samay aap ek aur kaam par assigned hain.',
            child: _Message(emoji: '📅', title: 'Is samay aap ek aur kaam par assigned hain', sub: 'Dono kaam ki taarikh takra rahi hai.', bg: AppColors.orangeTint),
          ),
          const SectionTitle('Chhutti / Kaam chhodna'),
          const _Frame(
            label: 'Bimaar — jaankari bheji',
            speech: 'Contractor ko aapki tabiyat ki jaankari bhej di gayi.',
            child: _Message(emoji: '🤒', title: 'Contractor ko aapki tabiyat ki jaankari bhej di gayi', sub: 'Aaram kijiye. Ye no-show nahi hai.', bg: AppColors.orangeTint),
          ),
          const _Frame(
            label: 'Kaam chhoda',
            speech: 'Contractor ko bata diya gaya hai.',
            child: _Message(emoji: '🚪', title: 'Contractor ko bata diya gaya hai', sub: 'Aapke profile par koi saza nahi.', bg: AppColors.blueTint),
          ),
          const SectionTitle('Paisa'),
          _Frame(
            label: 'Payment pending',
            speech: 'Aapke 800 rupaye abhi pending hain.',
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aaj ki kamai', style: TextStyle(fontSize: 16, color: AppColors.muted, fontWeight: FontWeight.w700)),
                        Text('₹800', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  StatusPill(label: 'Pending', bg: AppColors.orangeTint, fg: AppColors.orangeDark, icon: Icons.schedule_rounded, large: true),
                ],
              ),
            ),
          ),
          const SectionTitle('Voice / Permission'),
          const _Frame(
            label: 'Mic permission nahi',
            speech: 'Voice feature use karne ke liye microphone permission chahiye. Settings kholein aur microphone allow karein.',
            child: _Message(
              emoji: '🎙️',
              title: 'Voice ke liye microphone permission chahiye',
              sub: 'Settings → Apps → KaamSaathi → Permission → Microphone → Allow',
              bg: AppColors.redTint,
            ),
          ),
          const _Frame(
            label: 'Samajh nahi aaya',
            speech: 'Main samajh nahi paaya. Thoda dheere boliye.',
            child: _Message(emoji: '🤔', title: 'Main samajh nahi paaya', sub: 'Thoda dheere boliye.', bg: AppColors.yellowTint, retry: true),
          ),
          _Frame(
            label: 'Voice assistant ke states',
            speech: 'Bolkar poochhein. Main sun raha hoon. Samajh raha hoon. Samajh nahi aaya, dobara boliye. Internet connection nahi hai.',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 12,
                children: [
                  _VoiceState(label: 'IDLE', caption: 'Bolkar poochhein', child: MicButton(size: 56, onTap: () {})),
                  _VoiceState(label: 'LISTENING', caption: 'Main sun raha hoon…', child: MicButton(size: 56, active: true, onTap: () {})),
                  const _VoiceState(
                    label: 'PROCESSING',
                    caption: 'Samajh raha hoon…',
                    child: SizedBox(width: 81, height: 81, child: Center(child: CircularProgressIndicator(strokeWidth: 6))),
                  ),
                  const _VoiceState(
                    label: 'SPEAKING',
                    caption: 'Jawab sun rahe hain',
                    child: SizedBox(width: 81, height: 81, child: Center(child: VoiceWaveform(height: 40, bars: 7))),
                  ),
                  _VoiceState(
                    label: 'ERROR',
                    caption: 'Dobara boliye',
                    child: MicButton(size: 56, icon: Icons.replay_rounded, onTap: () {}),
                  ),
                  const _VoiceState(
                    label: 'OFFLINE',
                    caption: 'Internet nahi hai',
                    child: SizedBox(
                      width: 81,
                      height: 81,
                      child: Center(
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.disabled,
                          child: Icon(Icons.mic_off_rounded, color: AppColors.charcoal, size: 30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.label, required this.speech, required this.child});
  final String label;
  final String speech;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KsCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label.toUpperCase(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.muted, letterSpacing: 0.8)),
                  ),
                  SpeakButton(text: speech, label: '', compact: true),
                ],
              ),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.emoji, required this.title, required this.sub, required this.bg, this.retry = false});
  final String emoji;
  final String title;
  final String sub;
  final Color bg;
  final bool retry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.m)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                    Text(sub, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.charcoalSoft)),
                  ],
                ),
              ),
            ],
          ),
          if (retry) ...[
            const SizedBox(height: 12),
            KsButton(label: 'Dobara koshish', icon: Icons.refresh_rounded, kind: KsButtonKind.secondary, height: 56, onPressed: () {}),
          ],
        ],
      ),
    );
  }
}

class _VoiceState extends StatelessWidget {
  const _VoiceState({required this.label, required this.caption, required this.child});
  final String label;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          child,
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
          Text(caption, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
