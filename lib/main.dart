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

  // 네이버 지도 SDK 초기화 (신규 API - flutter_naver_map 1.4.1+1)
  try {
    await FlutterNaverMap().init(
      clientId: 's0jlbu865h', // 네이버 클라우드 플랫폼 Client ID
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
