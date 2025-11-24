import 'package:flutter/material.dart';

/// 환자 상태 빠른 체크 항목 모델
class QuickCheck {
  final String id;
  final String label;
  final IconData icon;

  const QuickCheck({
    required this.id,
    required this.label,
    required this.icon,
  });

  static List<QuickCheck> get defaultChecks => [
        const QuickCheck(
          id: 'conscious',
          label: '의식 있음',
          icon: Icons.psychology,
        ),
        const QuickCheck(
          id: 'breathing',
          label: '호흡 정상',
          icon: Icons.air,
        ),
        const QuickCheck(
          id: 'pulse',
          label: '맥박 감지',
          icon: Icons.favorite,
        ),
        const QuickCheck(
          id: 'visible_injury',
          label: '외상 확인',
          icon: Icons.visibility,
        ),
      ];
}
