import 'package:flutter/material.dart';
import '../models/quick_check.dart';

/// 빠른 상태 체크 그리드 위젯
class QuickCheckGrid extends StatelessWidget {
  final List<QuickCheck> checks;
  final Set<String> selectedIds;
  final Function(String) onToggle;
  final Color primaryColor;

  const QuickCheckGrid({
    super.key,
    required this.checks,
    required this.selectedIds,
    required this.onToggle,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: checks.length,
      itemBuilder: (context, index) {
        final check = checks[index];
        final isSelected = selectedIds.contains(check.id);
        
        return _QuickCheckItem(
          check: check,
          isSelected: isSelected,
          primaryColor: primaryColor,
          onTap: () => onToggle(check.id),
        );
      },
    );
  }
}

/// 개별 체크 항목
class _QuickCheckItem extends StatelessWidget {
  final QuickCheck check;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _QuickCheckItem({
    required this.check,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.red[100]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              check.icon,
              size: 18,
              color: isSelected ? Colors.white : primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              check.label,
              style: TextStyle(
                fontSize: 15,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
