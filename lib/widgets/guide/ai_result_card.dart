import 'package:flutter/material.dart';

class AiResultCard extends StatefulWidget {
  final String rawText;

  const AiResultCard({super.key, required this.rawText});

  @override
  State<AiResultCard> createState() => _AiResultCardState();
}

class _AiResultCardState extends State<AiResultCard> {
  bool showMore = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String? title;
    List<String> steps = [];
    List<String> extraLines = [];

    final stepReg = RegExp(r'^\s*([0-9]+)[\).\s]');

    for (final line in lines) {
      if (title == null && !stepReg.hasMatch(line)) {
        title = line.replaceAll('**', '');
      } else if (stepReg.hasMatch(line)) {
        steps.add(line.replaceFirst(stepReg, '').trim());
      } else {
        extraLines.add(line);
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          if (title != null) _buildTitle(title),
          const SizedBox(height: 12),
          if (extraLines.isNotEmpty) _buildSummary(extraLines),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((entry) => _buildStep(entry.key, entry.value)),
          const SizedBox(height: 6),
          if (extraLines.length > 3) _buildExpandButton(),
          if (showMore) _buildDetailedText(extraLines),
          const SizedBox(height: 8),
          _buildWarning(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: const [
        Icon(Icons.medical_information, size: 20, color: Colors.red),
        SizedBox(width: 8),
        Text(
          'AI 응급 안내',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
  }

  Widget _buildSummary(List<String> extraLines) {
    return Text(
      extraLines.take(3).join('\n'),
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }

  Widget _buildStep(int idx, String stepText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red),
            ),
            child: Center(
              child: Text(
                '${idx + 1}',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stepText,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return InkWell(
      onTap: () => setState(() => showMore = !showMore),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          showMore ? "▲ 자세한 설명 접기" : "▼ 자세한 설명 보기",
          style: const TextStyle(
            fontSize: 12,
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedText(List<String> extraLines) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        extraLines.skip(3).join('\n'),
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _buildWarning() {
    return const Text(
      '※ 생명 위급 시 반드시 119를 먼저 호출하세요.',
      style: TextStyle(fontSize: 11, color: Colors.redAccent),
    );
  }
}
