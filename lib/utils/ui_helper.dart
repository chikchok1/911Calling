import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// UI 유틸리티 함수들
class UIHelper {
  /// SnackBar 표시
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  /// 에러 SnackBar 표시
  static void showError(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      duration: const Duration(seconds: 3),
    );
  }

  /// 권한 설정 화면으로 이동하는 SnackBar
  static void showPermissionSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: '설정',
        onPressed: () => openAppSettings(),
      ),
    );
  }

  /// 로딩 다이얼로그 표시
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? '처리 중...'),
          ],
        ),
      ),
    );
  }

  /// 다이얼로그 닫기
  static void closeDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
