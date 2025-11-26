import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// AI 서비스 - Gemini API를 사용한 응급 상황 분석 및 가이드 제공
class AIService {
  // 환경 변수에서 API 키 로드
  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String _modelName = "gemini-2.0-flash";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent";

  // ========================================
  // 1. AI 응급 상황 분석 (AI Analysis Tab용)
  // ========================================

  Future<String> analyzeWithAI({
    required bool conscious,
    required bool breathing,
    required bool pulse,
    required bool trauma,
    required String userText,
  }) async {
    debugPrint("🔍 [AIService] 분석 시작...");

    try {
      if (apiKey.isEmpty) {
        debugPrint("❌ [AIService] API Key 없음");
        return "API 키가 설정되지 않았습니다. .env 파일을 확인해주세요.";
      }

      final promptText = _buildPrompt(
        conscious: conscious,
        breathing: breathing,
        pulse: pulse,
        trauma: trauma,
        userText: userText,
      );

      debugPrint("📤 [AIService] 서버로 요청 전송 중...");
      final url = Uri.parse("$_baseUrl?key=$apiKey");

      // 타임아웃을 10초로 설정
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": promptText},
                  ],
                },
              ],
              "generationConfig": {"temperature": 0.3, "maxOutputTokens": 1024},
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("📥 [AIService] 응답 수신 완료 (상태코드: ${response.statusCode})");

      if (response.statusCode != 200) {
        debugPrint("❌ [AIService] 서버 에러: ${response.body}");
        return "서버 연결 오류 (${response.statusCode})";
      }

      // ✅ 개선: JSON 파싱 및 응답 구조 검증 강화
      debugPrint("⚙️ [AIService] 데이터 해석 중...");
      final data = await compute(_parseJson, response.body);

      // candidates 배열이 비어있거나 없는 경우
      final candidates = data["candidates"];
      if (candidates == null || candidates.isEmpty) {
        debugPrint("❌ [AIService] candidates가 비어있음");
        return "AI가 응답을 생성하지 못했습니다. 입력 내용을 확인해주세요.";
      }

      // finishReason 확인 (안전 필터링 등)
      final finishReason = candidates[0]["finishReason"];
      if (finishReason == "SAFETY") {
        debugPrint("⚠️ [AIService] 안전 필터링으로 차단됨");
        return "안전 정책으로 인해 응답을 생성할 수 없습니다. 입력 내용을 수정해주세요.";
      }

      // content > parts 구조 검증
      final content = candidates[0]["content"];
      if (content == null) {
        debugPrint("❌ [AIService] content가 없음");
        return "AI 응답 형식이 올바르지 않습니다.";
      }

      final parts = content["parts"];
      if (parts == null || parts.isEmpty) {
        debugPrint("❌ [AIService] parts가 비어있음");
        return "AI 응답을 해석할 수 없습니다.";
      }

      // text 추출
      final text = parts[0]["text"];
      if (text == null || text.isEmpty) {
        debugPrint("❌ [AIService] text가 비어있음");
        return "분석 내용이 없습니다.";
      }

      debugPrint("✅ [AIService] 분석 완료!");
      return text;
    } on TimeoutException {
      debugPrint("⏰ [AIService] 시간 초과 발생");
      return "응답 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.";
    } on FormatException catch (e) {
      debugPrint("💥 [AIService] JSON 파싱 에러: $e");
      return "응답 데이터 형식 오류가 발생했습니다.";
    } catch (e) {
      debugPrint("💥 [AIService] 시스템 에러: $e");
      return "시스템 에러 발생: $e";
    }
  }

  /// 응급 분석용 프롬프트 생성
  String _buildPrompt({
    required bool conscious,
    required bool breathing,
    required bool pulse,
    required bool trauma,
    required String userText,
  }) {
    String consciousState = conscious ? "의식 명료" : "미확인";
    String breathingState = breathing ? "호흡 정상" : "미확인";
    String pulseState = pulse
        ? "맥박 감지됨"
        : (conscious && breathing ? "정상 추정" : "미확인");
    String traumaState = trauma ? "외상 발견" : "없음";

    return """
당신은 응급 상황 데이터를 보고 일반인에게 행동 지침을 주는 **'응급 구조 도우미'**이다.
사용자가 당황하지 않고 따라 할 수 있도록 **구체적인 행동 방법(How-to)**을 알려주어야 한다.

[입력 정보]
- 의식: $consciousState
- 호흡: $breathingState
- 맥박: $pulseState
- 외상: $traumaState
- 사용자 메모: "$userText"

[필수 출력 형식] - 아래 형식을 반드시 지킬 것.
✅ 판단: [환자 상태 요약 (예: 코피 및 빈혈 의심)]
🔍 검색어: [유튜브 검색용 핵심 질환명 단 1개 (예: 코피)]
🩺 행동 수칙:
1. [가장 시급한 처치법 (구체적인 동작 묘사, 40자 이내)]
2. [추가 처치 또는 주의사항 (40자 이내)]
3. [증상 지속 시 방문해야 할 구체적인 진료과 (예: 이비인후과, 응급실 등)]

[작성 가이드라인]
1. **추상적인 단어 금지**: '지혈하세요' 대신 '고개를 숙이고 콧볼을 5분간 잡으세요'라고 쓸 것.
2. **행동 묘사**: '안정을 취하세요' 대신 '편평한 곳에 눕히고 다리를 올려주세요' 처럼 구체적으로 쓸 것.
3. **진료과 명시**: 단순히 '병원 방문'이라고 하지 말고, 증상에 맞는 '진료과(내과, 외과 등)'를 콕 집어줄 것.
""";
  }

  // ========================================
  // 2. 응급 가이드 검색 (Guide Tab용)
  // ========================================

  /// 응급 상황에 대한 가이드 제공
  ///
  /// [query] 사용자가 입력한 응급 상황 또는 증상
  /// 예: "심장이 아파요", "화상을 입었어요"
  Future<String> getEmergencyGuide(String query) async {
    debugPrint("📖 [AIService - Guide] 가이드 검색 시작: $query");

    try {
      if (apiKey.isEmpty) {
        debugPrint("❌ [AIService - Guide] API Key 없음");
        return 'Gemini API 키가 설정되지 않았습니다.\n.env 파일에서 GEMINI_API_KEY를 설정해 주세요.';
      }

      final promptText = _buildGuidePrompt(query);
      final url = Uri.parse("$_baseUrl?key=$apiKey");

      debugPrint("📤 [AIService - Guide] 서버로 요청 전송 중...");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": promptText},
                  ],
                },
              ],
              "generationConfig": {"temperature": 0.4, "maxOutputTokens": 200},
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
        "📥 [AIService - Guide] 응답 수신 완료 (상태코드: ${response.statusCode})",
      );

      if (response.statusCode != 200) {
        debugPrint("❌ [AIService - Guide] 서버 에러: ${response.body}");
        return '서버 연결 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      }

      debugPrint("📄 [AIService - Guide] 응답 본문: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...");
      
      final data = await compute(_parseJson, response.body);
      debugPrint("🔍 [AIService - Guide] 파싱된 데이터 구조: ${data.keys}");
      
      final text = _extractTextFromResponse(data);
      debugPrint("📝 [AIService - Guide] 추출된 텍스트 길이: ${text.length}");

      if (text.isEmpty) {
        debugPrint("⚠️ [AIService - Guide] 텍스트가 비어있음. 전체 응답: $data");
        return '응답을 생성할 수 없습니다.\n다른 방식으로 질문해주세요.';
      }

      debugPrint("✅ [AIService - Guide] 가이드 생성 완료!");
      return text;
    } on TimeoutException {
      debugPrint("⏰ [AIService - Guide] 시간 초과 발생");
      return '응답 시간이 초과되었습니다.\n네트워크 연결을 확인해주세요.';
    } catch (e) {
      debugPrint("💥 [AIService - Guide] 에러: $e");
      return '일시적인 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
    }
  }

  /// 가이드 검색용 프롬프트 생성
  String _buildGuidePrompt(String query) {
    return """
당신은 응급처치 전문가입니다. 다음 상황에 대해 **매우 짧고 간단하게** 응급처치 방법을 알려주세요.

상황: $query

아래 형식으로만 답변하세요:

상황: [10자 이내로 요약]

응급처치:
1. [20자 이내]
2. [20자 이내]
3. [20자 이내]

주의: [15자 이내]
병원: [10자 이내]

**중요**: 각 항목은 반드시 지정된 글자 수를 초과하지 마세요. 매우 짧게 핵심만 작성하세요.
""";
  }

  // ========================================
  // 3. 공통 유틸리티 메서드
  // ========================================

  /// Gemini API 응답에서 텍스트 추출
  String _extractTextFromResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        debugPrint("❌ [AIService] candidates가 비어있음");
        return '';
      }

      // finishReason 확인
      final finishReason = candidates[0]['finishReason'];
      if (finishReason == 'SAFETY') {
        debugPrint("⚠️ [AIService] 안전 필터링으로 차단됨");
        return '안전 정책으로 인해 응답을 생성할 수 없습니다.\n입력 내용을 수정해주세요.';
      }

      final content = candidates[0]['content'];
      if (content == null) {
        debugPrint("❌ [AIService] content가 없음");
        return '';
      }

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        debugPrint("❌ [AIService] parts가 비어있음");
        return '';
      }

      // 모든 parts의 텍스트 결합
      final buffer = StringBuffer();
      for (final part in parts) {
        final text = part['text']?.toString() ?? '';
        if (text.isNotEmpty) {
          buffer.writeln(text);
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      debugPrint("💥 [AIService] 응답 파싱 에러: $e");
      return '';
    }
  }
}

// Isolate에서 실행될 JSON 파싱 함수
Map<String, dynamic> _parseJson(String responseBody) {
  return jsonDecode(responseBody);
}
