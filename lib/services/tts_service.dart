import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS(Text-to-Speech) 서비스
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isAvailable = false;
  bool _isSpeaking = false;

  bool get isAvailable => _isAvailable;
  bool get isSpeaking => _isSpeaking;

  Function(bool)? onSpeakingStateChanged;

  /// TTS 초기화
  Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage("ko-KR");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingStateChanged?.call(false);
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        onSpeakingStateChanged?.call(false);
      });

      // ✅ 추가: 에러 핸들러 설정
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS 에러: $msg');
        _isSpeaking = false;
        onSpeakingStateChanged?.call(false);
      });

      _isAvailable = true;
    } catch (e) {
      debugPrint("TTS 초기화 에러: $e");
      _isAvailable = false;
      rethrow;
    }
  }

  /// 텍스트 음성 재생
  Future<void> speak(String text) async {
    if (!_isAvailable) {
      throw Exception('TTS를 사용할 수 없습니다');
    }

    // ✅ 상태 업데이트
    _isSpeaking = true;
    onSpeakingStateChanged?.call(true);

    try {
      await _flutterTts.speak(text);
      // 정상 실행 시 completionHandler가 상태를 false로 변경
    } catch (e) {
      // ✅ 에러 발생 시 즉시 상태 리셋
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
      debugPrint('TTS 재생 에러: $e');
      rethrow;
    }
  }

  /// 음성 중지
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    onSpeakingStateChanged?.call(false);
  }

  /// 리소스 정리
  void dispose() {
    onSpeakingStateChanged = null; // ✅ 추가: 콜백 제거
    _flutterTts.stop();
  }
}
