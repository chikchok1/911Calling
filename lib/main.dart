// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'config/api_keys.dart'; // ← API 키 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 네이버 지도 SDK 초기화
  try {
    await NaverMapSdk.instance.initialize(
      clientId: ApiKeys.naverMapClientId, // ← API 키 사용
    );
    print('✅ 네이버 지도 SDK 초기화 성공');
  } catch (e) {
    print('❌ 네이버 지도 SDK 초기화 실패: $e');
    print('💡 lib/config/api_keys.dart 파일에 올바른 Client ID를 입력했는지 확인하세요!');
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
