import 'package:flutter/material.dart';
import '../../models/emergency_type.dart';

class EmergencyCard extends StatelessWidget {
  final EmergencyType emergency;
  final VoidCallback onTap;

  const EmergencyCard({
    super.key,
    required this.emergency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emergency.icon, size: 32, color: emergency.color),
            const SizedBox(height: 8),
            Text(
              emergency.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
