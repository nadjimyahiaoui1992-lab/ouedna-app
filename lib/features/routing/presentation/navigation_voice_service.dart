import 'package:flutter_tts/flutter_tts.dart';

class NavigationVoiceService {
  NavigationVoiceService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;
  bool enabled = true;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(false);
      await _tts.setLanguage('ar-DZ');
      await _tts.setSpeechRate(0.47);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setAudioAttributesForNavigation();
    } catch (_) {
      // يبقى التطبيق صالحاً للملاحة حتى لو لم يتوفر محرك صوت عربي بالجهاز.
    } finally {
      _ready = true;
    }
  }

  Future<void> speak(String message) async {
    if (!enabled || message.trim().isEmpty) return;
    await initialize();
    try {
      await _tts.stop();
      await _tts.speak(message, focus: true);
    } catch (_) {
      // لا نوقف الملاحة المرئية عند تعذر النطق في محرك الجهاز.
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
