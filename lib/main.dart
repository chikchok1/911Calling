// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 네이버 지도 SDK 초기화 (신규 API - flutter_naver_map 1.4.1+1)
  try {
    await FlutterNaverMap().init(
      clientId: '여기다가 키 넣으세요', // 네이버 클라우드 플랫폼 Client ID
      onAuthFailed: (ex) {
        switch (ex) {
          case NQuotaExceededException(:final message):
            print('❌ 사용량 초과: $message');
            break;
          case NUnauthorizedClientException() ||
              NClientUnspecifiedException() ||
              NAnotherAuthFailedException():
            print('❌ 인증 실패: $ex');
            print('💡 네이버 클라우드 플랫폼 콘솔에서 확인 필요:');
            print('   1. Client ID: s0jlbu865h 가 유효한지');
            print('   2. Dynamic Map 서비스가 선택되어 있는지');
            print('   3. Android 패키지: com.emergency.guide.projects 가 등록되어 있는지');
            print(
              '   4. Debug 패키지: com.emergency.guide.projects.debug 도 등록했는지',
            );
            break;
        }
      },
    );
    print('✅ 네이버 지도 SDK 초기화 성공 (flutter_naver_map 1.4.1+1)');
  } catch (e) {
    print('❌ 네이버 지도 SDK 초기화 실패: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '911 Calling App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
