import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// STT(Speech-to-Text) 서비스
class STTService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  bool get isListening => _isListening;

  Function(String)? onResult;
  Function(bool)? onListeningStateChanged;

  /// 음성 인식 시작/중지
  Future<void> toggleListening() async {
    if (_isListening) {
      await stop();
    } else {
      await start();
    }
  }

  /// 음성 인식 시작
  Future<void> start() async {
    // 권한 확인 및 요청
    var status = await Permission.microphone.status;

    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      throw PermissionPermanentlyDeniedException();
    }

    if (status != PermissionStatus.granted) {
      throw PermissionDeniedException();
    }

    // 음성 인식 초기화 및 시작
    bool available = await _speech.initialize(
      onStatus: (val) {
        debugPrint('STT 상태 변경: $val');
        if (val == 'done' || val == 'notListening') {
          _isListening = false;
          onListeningStateChanged?.call(false);
        }
      },
      onError: (val) {
        debugPrint('음성 인식 에러: $val');
        _isListening = false;
        onListeningStateChanged?.call(false);
        throw STTException(val.errorMsg);
      },
    );

    if (!available) {
      throw Exception('음성 인식을 사용할 수 없습니다');
    }

    _isListening = true;
    onListeningStateChanged?.call(true);

    _speech.listen(
      onResult: (val) {
        onResult?.call(val.recognizedWords);
        
        // 최종 결과가 나오면 자동으로 중지
        if (val.finalResult) {
          debugPrint('STT 최종 결과 수신, 자동 중지');
          stop();
        }
      },
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 30), // 최대 30초
      pauseFor: const Duration(seconds: 3), // 3초 침묵 시 자동 종료
    );
  }

  /// 음성 인식 중지
  Future<void> stop() async {
    _isListening = false;
    onListeningStateChanged?.call(false);
    await _speech.stop();
  }

  /// 리소스 정리
  void dispose() {
    _speech.stop();
  }
}

/// 권한 관련 예외
class PermissionDeniedException implements Exception {
  @override
  String toString() => '마이크 권한이 필요합니다';
}

class PermissionPermanentlyDeniedException implements Exception {
  @override
  String toString() => '설정에서 마이크 권한을 허용해주세요';
}

/// STT 예외
class STTException implements Exception {
  final String message;
  STTException(this.message);

  @override
  String toString() => '음성 인식 오류: $message';
}
