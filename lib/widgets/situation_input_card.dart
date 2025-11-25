import 'package:flutter/material.dart';

/// 상황 설명 입력 카드
class SituationInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final VoidCallback onMicPressed;
  final Color primaryColor;
  final Color lightColor;

  const SituationInputCard({
    super.key,
    required this.controller,
    required this.isListening,
    required this.onMicPressed,
    required this.primaryColor,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 음성 입력 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onMicPressed,
              icon: Icon(
                isListening ? Icons.graphic_eq : Icons.mic,
                size: 22,
              ),
              label: Text(
                isListening ? '듣고 있습니다...' : '음성으로 설명하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                backgroundColor: isListening ? lightColor : Colors.white,
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 텍스트 입력
          TextField(
            controller: controller,
            maxLines: 2,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: '또는 증상을 글로 입력해주세요.',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
