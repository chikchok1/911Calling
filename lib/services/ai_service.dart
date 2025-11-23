import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  // 환경 변수에서 API 키 로드
  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String _modelName = "gemini-2.0-flash";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent";

  Future<String> analyzeWithAI({
    required bool conscious,
    required bool breathing,
    required bool pulse,
    required bool trauma,
    required String userText,
  }) async {
    print("🔍 [AIService] 분석 시작..."); // 로그 추가

    try {
      if (apiKey.isEmpty) {
        print("❌ [AIService] API Key 없음");
        return "API 키가 설정되지 않았습니다. .env 파일을 확인해주세요.";
      }

      final promptText = _buildPrompt(
        conscious: conscious,
        breathing: breathing,
        pulse: pulse,
        trauma: trauma,
        userText: userText,
      );

      print("📤 [AIService] 서버로 요청 전송 중...");
      final url = Uri.parse("$_baseUrl?key=$apiKey");

      // 타임아웃을 10초로 단축하여 멈춤 현상 완화
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

      print("📥 [AIService] 응답 수신 완료 (상태코드: ${response.statusCode})");

      if (response.statusCode != 200) {
        print("❌ [AIService] 서버 에러: ${response.body}");
        return "서버 연결 오류 (${response.statusCode})";
      }

      // JSON 파싱
      print("⚙️ [AIService] 데이터 해석 중...");
      final data = await compute(_parseJson, response.body);
      final parts = data["candidates"]?[0]?["content"]?["parts"];

      if (parts == null || parts.isEmpty) {
        return "AI 응답을 해석할 수 없습니다.";
      }

      print("✅ [AIService] 분석 완료!");
      return parts[0]["text"] ?? "분석 내용이 없습니다.";
    } on TimeoutException {
      print("⏰ [AIService] 시간 초과 발생");
      return "응답 시간이 초과되었습니다. (10초 경과)";
    } catch (e) {
      print("💥 [AIService] 시스템 에러: $e");
      return "시스템 에러 발생: $e";
    }
  }

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
}

Map<String, dynamic> _parseJson(String responseBody) {
  return jsonDecode(responseBody);
}
