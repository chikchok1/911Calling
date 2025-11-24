import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/quick_check.dart';
import '../models/ai_analysis_result.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../utils/ui_helper.dart';
import '../widgets/quick_check_grid.dart';
import '../widgets/situation_input_card.dart';
import '../widgets/analysis_result_card.dart';

class AIAnalysisTab extends StatefulWidget {
  const AIAnalysisTab({super.key});

  @override
  State<AIAnalysisTab> createState() => _AIAnalysisTabState();
}

class _AIAnalysisTabState extends State<AIAnalysisTab> {
  // Services
  late final TTSService _ttsService;
  late final STTService _sttService;
  late final AIService _aiService;

  // State
  bool _isLoading = false;
  bool _showAiResponse = false;
  final Set<String> _selectedChecks = {};
  final TextEditingController _textController = TextEditingController();

  AIAnalysisResult? _analysisResult;

  // Data
  final List<QuickCheck> _quickChecks = QuickCheck.defaultChecks;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// 서비스 초기화
  Future<void> _initializeServices() async {
    _ttsService = TTSService();
    _sttService = STTService();
    _aiService = AIService();

    // TTS 초기화
    try {
      await _ttsService.initialize();
    } catch (e) {
      if (mounted) {
        UIHelper.showError(context, '음성 안내 기능을 사용할 수 없습니다');
      }
    }

    // 상태 변경 리스너 설정
    _ttsService.onSpeakingStateChanged = (isSpeaking) {
      if (mounted) setState(() {});
    };

    _sttService.onListeningStateChanged = (isListening) {
      if (mounted) setState(() {});
    };

    _sttService.onResult = (text) {
      setState(() {
        _textController.text = text;
      });
    };
  }

  /// 음성 입력 토글
  Future<void> _handleVoiceInput() async {
    try {
      await _sttService.toggleListening();
    } on PermissionPermanentlyDeniedException catch (e) {
      if (mounted) {
        UIHelper.showPermissionSnackBar(context, e.toString());
      }
    } on PermissionDeniedException catch (e) {
      if (mounted) {
        UIHelper.showError(context, e.toString());
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showError(context, e.toString());
      }
    }
  }

  /// 빠른 체크 토글
  void _toggleCheck(String id) {
    setState(() {
      if (_selectedChecks.contains(id)) {
        _selectedChecks.remove(id);
      } else {
        _selectedChecks.add(id);
      }
    });
  }

  /// AI 분석 시작
  Future<void> _handleAnalyze() async {
    if (_selectedChecks.isEmpty && _textController.text.isEmpty) {
      UIHelper.showError(context, '환자 상태를 입력해주세요');
      return;
    }

    FocusScope.of(context).unfocus();
    await _ttsService.stop();

    setState(() {
      _isLoading = true;
      _showAiResponse = false;
    });

    try {
      final rawResult = await _aiService.analyzeWithAI(
        conscious: _selectedChecks.contains('conscious'),
        breathing: _selectedChecks.contains('breathing'),
        pulse: _selectedChecks.contains('pulse'),
        trauma: _selectedChecks.contains('visible_injury'),
        userText: _textController.text,
      );

      final result = AIAnalysisResult.fromRawText(rawResult);

      if (!mounted) return;

      setState(() {
        _analysisResult = result;
        _showAiResponse = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      UIHelper.showError(context, '오류 발생: $e');
    }
  }

  /// YouTube 검색
  Future<void> _launchYoutubeSearch() async {
    if (_analysisResult == null) return;

    final keyword = _analysisResult!.searchKeyword.isNotEmpty
        ? _analysisResult!.searchKeyword
        : _analysisResult!.judgment;
    final query = "$keyword 응급처치";
    final url = Uri.parse(
      "https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'URL을 열 수 없습니다';
      }
    } catch (e) {
      debugPrint('YouTube 링크 열기 실패: $e');
      if (mounted) {
        UIHelper.showError(context, 'YouTube를 열 수 없습니다');
      }
    }
  }

  /// 음성 안내
  Future<void> _handleSpeak() async {
    if (!_ttsService.isAvailable) {
      UIHelper.showError(context, '음성 안내 기능을 사용할 수 없습니다');
      return;
    }

    if (_ttsService.isSpeaking) {
      await _ttsService.stop();
      return;
    }

    if (_analysisResult == null) return;

    String textToSpeak =
        "응급 상황 분석 결과, ${_analysisResult!.judgment} 입니다. 행동 수칙을 안내합니다. ";
    for (int i = 0; i < _analysisResult!.steps.length; i++) {
      textToSpeak += "${i + 1}번째, ${_analysisResult!.steps[i]}. ".replaceAll(
        RegExp(r'^\d+\.'),
        '',
      );
    }

    try {
      await _ttsService.speak(textToSpeak);
    } catch (e) {
      if (mounted) {
        UIHelper.showError(context, '음성 재생 중 오류가 발생했습니다');
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.red[400]!;
    final lightColor = Colors.red[50]!;

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(primaryColor),
                const SizedBox(height: 24),
                _buildQuickCheckSection(primaryColor),
                const SizedBox(height: 24),
                _buildSituationInputSection(primaryColor, lightColor),
                const SizedBox(height: 24),
                _buildAnalyzeButton(primaryColor),
                if (_showAiResponse && _analysisResult != null) ...[
                  const SizedBox(height: 30),
                  _buildResultSection(primaryColor, lightColor),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 헤더
  Widget _buildHeader(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.monitor_heart_outlined, color: primaryColor, size: 28),
            const SizedBox(width: 8),
            const Text(
              'AI 응급 분석',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '환자의 증상을 선택하거나 말씀해주세요.',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      ],
    );
  }

  /// 빠른 상태 체크 섹션
  Widget _buildQuickCheckSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 상태 체크',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        QuickCheckGrid(
          checks: _quickChecks,
          selectedIds: _selectedChecks,
          onToggle: _toggleCheck,
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  /// 상황 입력 섹션
  Widget _buildSituationInputSection(Color primaryColor, Color lightColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상황 설명',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SituationInputCard(
          controller: _textController,
          isListening: _sttService.isListening,
          onMicPressed: _handleVoiceInput,
          primaryColor: primaryColor,
          lightColor: lightColor,
        ),
      ],
    );
  }

  /// 분석 버튼
  Widget _buildAnalyzeButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAnalyze,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '응급 분석 시작',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// 결과 섹션
  Widget _buildResultSection(Color primaryColor, Color lightColor) {
    return AnalysisResultCard(
      judgment: _analysisResult!.judgment,
      steps: _analysisResult!.steps,
      onYoutubePressed: _launchYoutubeSearch,
      onSpeakPressed: _handleSpeak,
      isSpeaking: _ttsService.isSpeaking,
      ttsAvailable: _ttsService.isAvailable,
      primaryColor: primaryColor,
      lightColor: lightColor,
    );
  }
}
