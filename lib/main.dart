// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------
  // 📌 1. .env 파일 로드
  // -------------------------------------------------------
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env 파일 로드 성공');
  } catch (e) {
    print('❌ .env 파일 로드 실패: $e');
  }

  // -------------------------------------------------------
  // 📌 2. 화면 세로 방향 고정
  // -------------------------------------------------------
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // -------------------------------------------------------
  // 📌 3. Firebase 초기화
  // -------------------------------------------------------
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 성공');
  } catch (e) {
    print('❌ Firebase 초기화 실패: $e');
  }

  // -------------------------------------------------------
  // 📌 4. 네이버 지도 초기화
  // -------------------------------------------------------
  try {
    await FlutterNaverMap().init(
      clientId: 's0jlbu865h', // Naver Cloud Platform Client ID
      onAuthFailed: (ex) {
        switch (ex) {
          case NQuotaExceededException(:final message):
            print('❌ 지도 사용량 초과: $message');
            break;

          case NUnauthorizedClientException() ||
              NClientUnspecifiedException() ||
              NAnotherAuthFailedException():
            print('❌ 네이버 지도 인증 실패: $ex');
            print('💡 클라우드 콘솔 확인하세요:');
            print('   - Dynamic Map 서비스 활성화 필요');
            print('   - Android 패키지: com.emergency.guide.projects 등록');
            print('   - Debug 패키지: com.emergency.guide.projects.debug 등록');
            break;
        }
      },
    );
    print('✅ 네이버 지도 SDK 초기화 성공');
  } catch (e) {
    print('❌ 네이버 지도 SDK 초기화 실패: $e');
  }

  // -------------------------------------------------------
  // 📌 5. 앱 실행
  // -------------------------------------------------------
  runApp(const EmergencyApp());
}

class EmergencyApp extends StatelessWidget {
  const EmergencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '911 Calling App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
        fontFamily: 'NotoSans',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 🔄 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 🔑 로그인 상태
          if (snapshot.hasData && snapshot.data != null) {
            print('✅ 로그인된 사용자: ${snapshot.data!.uid}');
            return const HomeScreen();
          }

          // ❗ 비로그인 상태
          print('⚠️ 로그인되지 않은 상태');
          return const LoginScreen();
        },
      ),
    );
  }
}
