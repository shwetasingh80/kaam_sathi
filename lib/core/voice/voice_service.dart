import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceStatus { idle, listening, processing, speaking, error, offline, permissionDenied, unavailable }

/// Thin wrapper over device TTS + speech recognition with UI-friendly state.
///
/// All failures are swallowed into [status] so screens can show the right
/// friendly message ("Samajh nahi aaya. Dobara boliye.") instead of crashing.
class VoiceService extends ChangeNotifier {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _ttsReady = false;
  bool _sttInitialized = false;
  bool _sttAvailable = false;
  String? _localeId;

  VoiceStatus status = VoiceStatus.idle;

  /// Live (partial) transcript while listening.
  String transcript = '';

  /// 0..1 microphone level for the waveform.
  double level = 0;

  /// Text currently / last spoken (shown as caption for hearing-impaired users).
  String? caption;

  /// User setting: when true, TTS is silent (captions still show).
  bool muted = false;

  Completer<void>? _speakDone;

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(_onSpeakEnd);
      _tts.setCancelHandler(_onSpeakEnd);
      _tts.setErrorHandler((_) => _onSpeakEnd());
    } catch (_) {
      // TTS not available on this platform — captions still work.
    }
    _ttsReady = true;
  }

  void _onSpeakEnd() {
    if (status == VoiceStatus.speaking) _set(VoiceStatus.idle);
    if (_speakDone != null && !_speakDone!.isCompleted) _speakDone!.complete();
  }

  void _set(VoiceStatus s) {
    status = s;
    notifyListeners();
  }

  bool _notifyScheduled = false;

  /// Voice state is often changed from a screen's `dispose()` (stop speaking /
  /// reset), which runs while the widget tree is locked. Notifying listeners
  /// then throws "setState() called when widget tree was locked", so during a
  /// frame the notification is deferred to just after it.
  @override
  void notifyListeners() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final inFrame = phase == SchedulerPhase.persistentCallbacks || phase == SchedulerPhase.midFrameMicrotasks;
    if (!inFrame) {
      super.notifyListeners();
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      super.notifyListeners();
    });
  }

  /// Speaks [text] and completes when finished (or immediately if muted).
  Future<void> speak(String text) async {
    caption = text;
    await stopListening();
    if (muted) {
      notifyListeners();
      return;
    }
    await _ensureTts();
    _speakDone = Completer<void>();
    _set(VoiceStatus.speaking);
    try {
      await _tts.stop();
      await _tts.speak(text).timeout(Duration(seconds: 6 + text.length ~/ 8));
    } catch (_) {
      // ignore — plugin missing or timed out
    }
    _onSpeakEnd();
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _onSpeakEnd();
  }

  bool get isSpeaking => status == VoiceStatus.speaking;
  bool get isListening => status == VoiceStatus.listening;

  Future<bool> _ensureStt() async {
    if (_sttInitialized) return _sttAvailable;
    try {
      _sttAvailable = await _stt.initialize(
        onError: _onSttError,
        onStatus: (_) {},
        debugLogging: false,
      );
      if (_sttAvailable) {
        final locales = await _stt.locales();
        _localeId = locales
                .where((l) => l.localeId.toLowerCase().replaceAll('-', '_') == 'hi_in')
                .map((l) => l.localeId)
                .firstOrNull ??
            locales.where((l) => l.localeId.toLowerCase().startsWith('hi')).map((l) => l.localeId).firstOrNull ??
            'hi_IN';
      }
    } catch (_) {
      _sttAvailable = false;
    }
    _sttInitialized = true;
    return _sttAvailable;
  }

  /// Triggers the system microphone permission prompt (onboarding).
  Future<bool> requestMicPermission() async {
    final ok = await _ensureStt();
    if (!ok) {
      // Permission may have been denied on first init; allow retry next time.
      _sttInitialized = false;
    }
    return ok;
  }

  Future<bool> get hasMicPermission async {
    try {
      return await _stt.hasPermission;
    } catch (_) {
      return false;
    }
  }

  Completer<String?>? _listenDone;

  void _onSttError(SpeechRecognitionError e) {
    final done = _listenDone;
    if (done != null && !done.isCompleted) {
      // "no match" / timeout → treat as not understood
      done.complete(transcript.trim().isEmpty ? null : transcript);
    }
  }

  /// Listens once and returns the final transcript, or null when nothing was
  /// understood. Sets [status] to permissionDenied / unavailable as needed.
  Future<String?> listen({Duration listenFor = const Duration(seconds: 10)}) async {
    await stopSpeaking();
    transcript = '';
    level = 0;
    final ok = await _ensureStt();
    if (!ok) {
      var denied = false;
      try {
        denied = !(await _stt.hasPermission);
      } catch (_) {}
      _set(denied ? VoiceStatus.permissionDenied : VoiceStatus.unavailable);
      return null;
    }
    _listenDone = Completer<String?>();
    _set(VoiceStatus.listening);
    try {
      await _stt.listen(
        onResult: _onResult,
        onSoundLevelChange: (l) {
          // Android reports roughly -2..10 dB.
          level = ((l + 2) / 12).clamp(0.0, 1.0);
          notifyListeners();
        },
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: listenFor,
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      _set(VoiceStatus.error);
      return null;
    }
    final result = await _listenDone!.future.timeout(
      listenFor + const Duration(seconds: 4),
      onTimeout: () => transcript.trim().isEmpty ? null : transcript,
    );
    try {
      await _stt.stop();
    } catch (_) {}
    level = 0;
    _set(result == null ? VoiceStatus.error : VoiceStatus.processing);
    return result;
  }

  void _onResult(SpeechRecognitionResult r) {
    transcript = r.recognizedWords;
    notifyListeners();
    if (r.finalResult) {
      final done = _listenDone;
      if (done != null && !done.isCompleted) {
        done.complete(transcript.trim().isEmpty ? null : transcript);
      }
    }
  }

  Future<void> stopListening() async {
    if (status != VoiceStatus.listening) return;
    try {
      await _stt.stop();
    } catch (_) {}
    final done = _listenDone;
    if (done != null && !done.isCompleted) {
      done.complete(transcript.trim().isEmpty ? null : transcript);
    }
  }

  /// Used by screens to set non-listening states (processing/offline/idle).
  void setStatus(VoiceStatus s) => _set(s);

  /// Simulated input (typed / suggestion chips) — goes through the exact same
  /// pipeline as real speech.
  void setTranscript(String text) {
    transcript = text;
    notifyListeners();
  }

  void reset() {
    transcript = '';
    level = 0;
    _set(VoiceStatus.idle);
  }

  void setMuted(bool v) {
    muted = v;
    if (v) stopSpeaking();
    notifyListeners();
  }
}
