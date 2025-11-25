import 'package:flutter/material.dart';
import '../../models/emergency_type.dart';

class StepCard extends StatelessWidget {
  final EmergencyType emergency;
  final int index;
  final String step;
  final VoidCallback onSpeakPressed;

  const StepCard({
    super.key,
    required this.emergency,
    required this.index,
    required this.step,
    required this.onSpeakPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: emergency.color, width: 2),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: emergency.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(step, style: const TextStyle(fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20),
              onPressed: onSpeakPressed,
            ),
          ],
        ),
      ),
    );
  }
}
