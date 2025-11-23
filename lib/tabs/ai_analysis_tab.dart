import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_service.dart';

class AIAnalysisTab extends StatefulWidget {
  const AIAnalysisTab({super.key});

  @override
  State<AIAnalysisTab> createState() => _AIAnalysisTabState();
}

class _AIAnalysisTabState extends State<AIAnalysisTab> {
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isLoading = false;
  bool _showAiResponse = false;
  bool _isSpeaking = false;

  final Set<String> _selectedChecks = {};
  final TextEditingController _textController = TextEditingController();

  String _aiJudgment = "";
  String _searchKeyword = "";
  List<String> _aiSteps = [];

  final List<QuickCheck> _quickChecks = [
    QuickCheck(id: 'conscious', label: '의식 있음', icon: Icons.psychology),
    QuickCheck(id: 'breathing', label: '호흡 정상', icon: Icons.air),
    QuickCheck(id: 'pulse', label: '맥박 감지', icon: Icons.favorite),
    QuickCheck(id: 'visible_injury', label: '외상 확인', icon: Icons.visibility),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _speech = stt.SpeechToText();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("ko-KR");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.6);

      _flutterTts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });

      _flutterTts.setCancelHandler(() {
        setState(() => _isSpeaking = false);
      });
    } catch (e) {
      print("TTS 초기화 에러: $e");
    }
  }

  void _listen() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다.')),
      );
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => print('음성 에러: $val'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
            });
          },
          localeId: 'ko_KR',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speakResult() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    if (_aiJudgment.isEmpty) return;

    String textToSpeak = "응급 상황 분석 결과, $_aiJudgment 입니다. 행동 수칙을 안내합니다. ";
    for (int i = 0; i < _aiSteps.length; i++) {
      textToSpeak += "${i + 1}번째, ${_aiSteps[i]}. ".replaceAll(
        RegExp(r'^\d+\.'),
        '',
      );
    }

    setState(() {
      _isSpeaking = true;
    });

    await _flutterTts.speak(textToSpeak);
  }

  Future<void> _launchYoutubeSearch() async {
    if (_searchKeyword.isEmpty && _aiJudgment.isEmpty) return;

    final keyword = _searchKeyword.isNotEmpty ? _searchKeyword : _aiJudgment;
    final query = "$keyword 응급처치";
    final url = Uri.parse(
      "https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }
  }

  void _toggleCheck(String id) {
    setState(() {
      if (_selectedChecks.contains(id)) {
        _selectedChecks.remove(id);
      } else {
        _selectedChecks.add(id);
      }
    });
  }

  void _handleAnalyze() async {
    if (_selectedChecks.isEmpty && _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환자 상태를 입력해주세요')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    await _flutterTts.stop();

    setState(() {
      _isLoading = true;
      _showAiResponse = false;
    });

    try {
      final aiService = AIService();
      final rawResult = await aiService.analyzeWithAI(
        conscious: _selectedChecks.contains('conscious'),
        breathing: _selectedChecks.contains('breathing'),
        pulse: _selectedChecks.contains('pulse'),
        trauma: _selectedChecks.contains('visible_injury'),
        userText: _textController.text,
      );

      String tempJudgment = "분석 결과 없음";
      String tempKeyword = "";
      List<String> tempSteps = [];

      final lines = rawResult.split('\n');
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

      if (tempKeyword.isEmpty) {
        tempKeyword = tempJudgment.split(',')[0].split(' ')[0];
      }

      if (!mounted) return;

      setState(() {
        _aiJudgment = tempJudgment;
        _searchKeyword = tempKeyword;
        _aiSteps = tempSteps;
        _showAiResponse = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'AI 기반 응급 상황 분석',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '환자 상태를 입력하세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '빠른 상태 체크',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: _quickChecks.length,
                          itemBuilder: (context, index) {
                            final check = _quickChecks[index];
                            final isSelected = _selectedChecks.contains(check.id);
                            return InkWell(
                              onTap: () => _toggleCheck(check.id),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.purple : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? Colors.purple : Colors.grey[300]!,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      check.icon,
                                      size: 16,
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        check.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _listen,
                            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 20),
                            label: Text(
                              _isListening ? '듣는 중...' : '음성으로 설명하기',
                              style: const TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isListening ? Colors.red : Colors.white,
                              foregroundColor: _isListening ? Colors.white : Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: _isListening ? Colors.red : Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _textController,
                          maxLines: 3,
                          cursorColor: Colors.red,
                          decoration: InputDecoration(
                            hintText: '환자 상태를 입력하세요...',
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.purple),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleAnalyze,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.psychology, size: 20),
                            label: Text(
                              _isLoading ? '분석 중...' : 'AI 분석 시작',
                              style: const TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showAiResponse) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AI 분석 결과',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: const Text(
                                  '긴급',
                                  style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _aiJudgment,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Colors.grey),
                          const SizedBox(height: 12),
                          if (_aiSteps.isEmpty)
                            const Text("구체적인 행동 수칙이 없습니다.")
                          else
                            ..._aiSteps.asMap().entries.map((entry) {
                              return _buildStep(entry.key + 1, entry.value);
                            }),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _launchYoutubeSearch,
                                  icon: const Text('📹'),
                                  label: const Text('영상 보기'),
                                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _speakResult,
                                  icon: Text(_isSpeaking ? '⏹' : '🔊'),
                                  label: Text(_isSpeaking ? '멈추기' : '음성 듣기'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _isSpeaking ? Colors.red[50] : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickCheck {
  final String id;
  final String label;
  final IconData icon;

  QuickCheck({required this.id, required this.label, required this.icon});
}
