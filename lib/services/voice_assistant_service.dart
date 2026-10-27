import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VoiceAssistantService {
  static const MethodChannel _channel = MethodChannel('com.suryaprakash.honeyyyb/tts');

  static bool isSpeaking = false;
  static bool autoSpeakEnabled = true;

  /// Sanitizes text for natural speech synthesis (strips markdown formatting, symbols)
  static String sanitizeForSpeech(String text) {
    var cleaned = text;
    // Remove markdown bold / italics
    cleaned = cleaned.replaceAll('*', '');
    cleaned = cleaned.replaceAll('#', '');
    cleaned = cleaned.replaceAll('`', '');
    cleaned = cleaned.replaceAll('_', ' ');
    // Clean currency and special symbols for natural reading
    cleaned = cleaned.replaceAll('₹', ' Rupees ');
    cleaned = cleaned.replaceAll('Rs.', ' Rupees ');
    cleaned = cleaned.replaceAll('INR', ' Rupees ');
    // Remove emojis
    cleaned = cleaned.replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\u{2600}-\u{27BF}]', unicode: true), '');
    // Clean redundant spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// Speaks text using the native Android text-to-speech engine with a sweet, caring, female voice pitch
  static Future<bool> speak(String text, {double pitch = 1.28, double rate = 0.88}) async {
    final cleanText = sanitizeForSpeech(text);
    if (cleanText.isEmpty) return false;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        isSpeaking = true;
        final bool result = await _channel.invokeMethod<bool>('speak', {
          'text': cleanText,
          'pitch': pitch,
          'rate': rate,
        }) ?? false;
        return result;
      } catch (e) {
        isSpeaking = false;
        return false;
      }
    } else {
      isSpeaking = true;
      debugPrint('[VoiceAssistant simulated speech]: $cleanText');
      return true;
    }
  }

  /// Stops any currently active speech playback
  static Future<void> stop() async {
    isSpeaking = false;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('stop');
      } catch (e) {
        debugPrint('Error stopping TTS: $e');
      }
    }
  }
}
