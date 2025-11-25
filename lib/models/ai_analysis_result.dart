/// AI 분석 결과 모델
class AIAnalysisResult {
  final String judgment;
  final String searchKeyword;
  final List<String> steps;

  const AIAnalysisResult({
    required this.judgment,
    required this.searchKeyword,
    required this.steps,
  });

  factory AIAnalysisResult.fromRawText(String rawText) {
    String tempJudgment = "분석 결과 없음";
    String tempKeyword = "";
    List<String> tempSteps = [];

    final lines = rawText.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('✅ 판단:')) {
        tempJudgment = line.replaceAll('✅ 판단:', '').trim();
      } else if (line.startsWith('🔍 검색어:')) {
        tempKeyword = line.replaceAll('🔍 검색어:', '').trim();
      } else if (RegExp(r'^\d+\.').hasMatch(line)) {
        tempSteps.add(line.replaceFirst(RegExp(r'^\d+\.\s*'), ''));
      }
    }

    // 검색어가 비어있으면 판단 결과에서 첫 단어 추출
    if (tempKeyword.isEmpty) {
      tempKeyword = tempJudgment.split(',')[0].split(' ')[0];
    }

    return AIAnalysisResult(
      judgment: tempJudgment,
      searchKeyword: tempKeyword,
      steps: tempSteps,
    );
  }

  bool get isEmpty => judgment == "분석 결과 없음" && steps.isEmpty;
}
