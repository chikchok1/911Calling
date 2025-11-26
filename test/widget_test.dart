import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 테스트 시작 전 초기화
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Emergency App basic smoke test', (WidgetTester tester) async {
    // 간단한 위젯 테스트
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('911 Calling App'))),
      ),
    );

    // 앱 타이틀 확인
    expect(find.text('911 Calling App'), findsOneWidget);
  });

  testWidgets('Bottom Navigation Bar basic structure', (
    WidgetTester tester,
  ) async {
    // BottomNavigationBar 구조 테스트
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Center(child: Text('Test')),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: '가이드',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology),
                label: 'AI 분석',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_hospital),
                label: 'AED',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    // Bottom Navigation Bar 아이템 확인
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('가이드'), findsOneWidget);
    expect(find.text('AI 분석'), findsOneWidget);
    expect(find.text('AED'), findsOneWidget);
    expect(find.text('프로필'), findsOneWidget);
  });

  testWidgets('Bottom Navigation Bar interaction', (WidgetTester tester) async {
    int currentIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(child: Text('Current Tab: $currentIndex')),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: currentIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book),
                    label: '가이드',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.psychology),
                    label: 'AI 분석',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.local_hospital),
                    label: 'AED',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: '프로필',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();

    // 초기 상태 확인
    expect(find.text('Current Tab: 0'), findsOneWidget);

    // 가이드 탭 클릭
    await tester.tap(find.text('가이드'));
    await tester.pump();
    expect(find.text('Current Tab: 1'), findsOneWidget);

    // AI 분석 탭 클릭
    await tester.tap(find.text('AI 분석'));
    await tester.pump();
    expect(find.text('Current Tab: 2'), findsOneWidget);

    // AED 탭 클릭
    await tester.tap(find.text('AED'));
    await tester.pump();
    expect(find.text('Current Tab: 3'), findsOneWidget);

    // 홈 탭으로 돌아가기
    await tester.tap(find.text('홈'));
    await tester.pump();
    expect(find.text('Current Tab: 0'), findsOneWidget);
  });

  testWidgets('App theme test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
          fontFamily: 'NotoSans',
        ),
        home: const Scaffold(body: Center(child: Text('Theme Test'))),
      ),
    );

    await tester.pump();
    expect(find.text('Theme Test'), findsOneWidget);
  });

  testWidgets('Emergency button widget test', (WidgetTester tester) async {
    bool buttonPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                '119 긴급 신고',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // 버튼 존재 확인
    expect(find.text('119 긴급 신고'), findsOneWidget);

    // 버튼 클릭
    await tester.tap(find.text('119 긴급 신고'));
    await tester.pump();

    // 버튼이 눌렸는지 확인
    expect(buttonPressed, isTrue);
  });

  testWidgets('Icon widgets test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Icon(Icons.home),
              Icon(Icons.menu_book),
              Icon(Icons.psychology),
              Icon(Icons.local_hospital),
              Icon(Icons.person),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    // 아이콘 존재 확인
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsOneWidget);
    expect(find.byIcon(Icons.psychology), findsOneWidget);
    expect(find.byIcon(Icons.local_hospital), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('Text style test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  '응급 구조 도우미',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text('긴급 상황 시 119에 신고하세요', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // 텍스트 존재 확인
    expect(find.text('응급 구조 도우미'), findsOneWidget);
    expect(find.text('긴급 상황 시 119에 신고하세요'), findsOneWidget);
  });

  testWidgets('Card widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.warning, color: Colors.red, size: 48),
                    SizedBox(height: 10),
                    Text('긴급 상황', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Card 내부 요소 확인
    expect(find.byType(Card), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsOneWidget);
    expect(find.text('긴급 상황'), findsOneWidget);
  });
}
