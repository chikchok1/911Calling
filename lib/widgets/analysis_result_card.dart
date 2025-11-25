import 'package:flutter/material.dart';

/// AI 분석 결과 카드
class AnalysisResultCard extends StatelessWidget {
  final String judgment;
  final List<String> steps;
  final VoidCallback onYoutubePressed;
  final VoidCallback onSpeakPressed;
  final bool isSpeaking;
  final bool ttsAvailable;
  final Color primaryColor;
  final Color lightColor;

  const AnalysisResultCard({
    super.key,
    required this.judgment,
    required this.steps,
    required this.onYoutubePressed,
    required this.onSpeakPressed,
    required this.isSpeaking,
    required this.ttsAvailable,
    required this.primaryColor,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '분석 결과',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '응급 가이드',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 판단 결과
          Text(
            judgment,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // 행동 수칙
          if (steps.isNotEmpty)
            ...steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: lightColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // 액션 버튼들
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onYoutubePressed,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('관련 영상'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: ttsAvailable ? onSpeakPressed : null,
                  icon: Icon(
                    isSpeaking ? Icons.stop : Icons.volume_up,
                    color: isSpeaking ? Colors.white : primaryColor,
                  ),
                  label: Text(
                    isSpeaking ? '멈추기' : '음성 안내',
                    style: TextStyle(
                      color: isSpeaking ? Colors.white : primaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSpeaking ? primaryColor : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
