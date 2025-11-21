import 'package:flutter_test/flutter_test.dart';

import 'package:projects/main.dart';

void main() {
  testWidgets('Emergency Response App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EmergencyResponseApp());

    // Verify that the app title is displayed
    expect(find.text('응급 구조 도우미'), findsWidgets);
    
    // Verify that bottom navigation exists
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('가이드'), findsOneWidget);
    expect(find.text('AI 분석'), findsOneWidget);
    expect(find.text('AED'), findsOneWidget);

    // Verify the emergency button is displayed
    expect(find.text('119 긴급 신고'), findsOneWidget);
  });

  testWidgets('Bottom navigation works', (WidgetTester tester) async {
    await tester.pumpWidget(const EmergencyResponseApp());

    // Tap on 가이드 tab
    await tester.tap(find.text('가이드'));
    await tester.pumpAndSettle();

    // Verify guide tab content
    expect(find.text('상황별 응급 가이드'), findsOneWidget);

    // Tap on AI 분석 tab
    await tester.tap(find.text('AI 분석'));
    await tester.pumpAndSettle();

    // Verify AI analysis tab content
    expect(find.text('AI 기반 응급 상황 분석'), findsOneWidget);

    // Tap on AED tab
    await tester.tap(find.text('AED'));
    await tester.pumpAndSettle();

    // Verify AED tab content
    expect(find.text('AED 위치 안내'), findsOneWidget);

    // Go back to home tab
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();

    // Verify home tab content
    expect(find.text('119 긴급 신고'), findsOneWidget);
  });

  testWidgets('Emergency button interaction', (WidgetTester tester) async {
    await tester.pumpWidget(const EmergencyResponseApp());

    // Find and tap the emergency button
    final emergencyButton = find.text('119 긴급 신고');
    expect(emergencyButton, findsOneWidget);

    await tester.tap(emergencyButton);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('119 신고'), findsOneWidget);
    expect(find.text('119에 연결 중입니다...\n주변 사용자에게 알림을 전송합니다.'), findsOneWidget);
  });
}
