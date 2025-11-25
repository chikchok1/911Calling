import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'firebase_options.dart';
import 'config/api_keys.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📌 .env 파일 로드
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env 파일 로드 성공');
  } catch (e) {
    print('❌ .env 파일 로드 실패: $e');
  }

  // 📌 화면 세로 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 📌 Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 성공');
  } catch (e) {
    print('❌ Firebase 초기화 실패: $e');
  }

  // 📌 네이버 지도 SDK 초기화
  try {
    await NaverMapSdk.instance.initialize(clientId: ApiKeys.naverMapClientId);
    print('✅ 네이버 지도 SDK 초기화 성공');
  } catch (e) {
    print('❌ 네이버 지도 SDK 초기화 실패: $e');
    print('💡 lib/config/api_keys.dart 파일에 올바른 Client ID를 입력했는지 확인하세요!');
  }

  runApp(const EmergencyResponseApp());
}

class EmergencyResponseApp extends StatelessWidget {
  const EmergencyResponseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '응급 구조 도우미',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red,
        ),
        useMaterial3: true,
        fontFamily: 'NotoSans',
      ),
      home: const HomeScreen(),
    );
  }
}
