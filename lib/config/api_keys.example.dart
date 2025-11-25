/// 🔐 API Keys Configuration
/// 
/// ⚠️ 중요: 이 파일은 .gitignore에 포함되어 있습니다!
/// 
/// 사용 방법:
/// 1. 이 파일을 복사해서 `api_keys.dart`로 저장
/// 2. 아래 값들을 실제 API 키로 교체
/// 3. 절대로 Git에 커밋하지 마세요!

class ApiKeys {
  // 🗺️ 네이버 지도 Client ID
  // 발급: https://www.ncloud.com/
  static const String naverMapClientId = 'YOUR_NAVER_CLIENT_ID_HERE';
  
  // 🚑 공공데이터포털 AED API Key
  // 발급: https://www.data.go.kr/
  static const String publicDataApiKey = 'YOUR_PUBLIC_DATA_API_KEY_HERE';
  
  // 🔥 Firebase API Key (선택사항)
  // firebase_options.dart에서 자동 생성됨
  // static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY_HERE';
}
