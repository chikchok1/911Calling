import 'package:flutter/material.dart';

class AIAnalysisTab extends StatefulWidget {
  const AIAnalysisTab({super.key});

  @override
  State<AIAnalysisTab> createState() => _AIAnalysisTabState();
}

class _AIAnalysisTabState extends State<AIAnalysisTab> {
  bool _isListening = false;
  final Set<String> _selectedChecks = {};
  final TextEditingController _textController = TextEditingController();
  bool _showAiResponse = false;

  final List<QuickCheck> _quickChecks = [
    QuickCheck(id: 'conscious', label: '의식 있음', icon: Icons.psychology),
    QuickCheck(id: 'breathing', label: '호흡 정상', icon: Icons.air),
    QuickCheck(id: 'pulse', label: '맥박 감지', icon: Icons.favorite),
    QuickCheck(id: 'visible_injury', label: '외상 확인', icon: Icons.visibility),
  ];

  void _toggleCheck(String id) {
    setState(() {
      if (_selectedChecks.contains(id)) {
        _selectedChecks.remove(id);
      } else {
        _selectedChecks.add(id);
      }
    });
  }

  void _handleAnalyze() {
    if (_selectedChecks.isEmpty && _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환자 상태를 입력해주세요')),
      );
      return;
    }

    setState(() {
      _showAiResponse = true;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
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
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Input Card
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

                    // Quick Checks Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
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

                    // Voice Input Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isListening = !_isListening;
                          });

                          if (_isListening) {
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  _isListening = false;
                                });
                              }
                            });
                          }
                        },
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 20,
                        ),
                        label: Text(
                          _isListening ? '듣는 중...' : '음성으로 설명하기',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isListening ? Colors.red : Colors.white,
                          foregroundColor: _isListening ? Colors.white : Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: _isListening ? Colors.red : Colors.grey[300]!,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Text Input
                    TextField(
                      controller: _textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '환자 상태를 입력하세요...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
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

                    // Analyze Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleAnalyze,
                        icon: const Icon(Icons.psychology, size: 20),
                        label: const Text('AI 분석 시작', style: TextStyle(fontSize: 14)),
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

              // AI Response Card
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
                      // Header
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AI 분석 결과',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Text(
                              '긴급',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '즉시 수행해야 할 조치',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Steps
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.air, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'CPR 즉시 시작',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStep(1, '119에 즉시 신고하세요'),
                            _buildStep(2, '환자를 평평한 곳에 눕히세요'),
                            _buildStep(3, '가슴 중앙에 손을 올리고 강하고 빠르게 압박하세요'),
                            _buildStep(4, '주변에 AED를 요청하세요'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Text('📹', style: TextStyle(fontSize: 14)),
                              label: const Text('영상 보기', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Text('🔊', style: TextStyle(fontSize: 14)),
                              label: const Text('음성 듣기', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
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
            decoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(fontSize: 12),
              ),
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

  QuickCheck({
    required this.id,
    required this.label,
    required this.icon,
  });
}
