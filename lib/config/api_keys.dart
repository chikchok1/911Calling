/// 🔐 API Keys Configuration
///
/// 모든 API 키가 하드코딩되어 있습니다.
/// 이 파일은 이제 Git에 포함됩니다.

class ApiKeys {
  // 🗺️ 네이버 지도 Client ID
  // 발급: https://www.ncloud.com/ > Console > AI·NAVER API
  // Application 등록 > Dynamic Map 선택
  // Android 패키지 이름: com.emergency.guide.projects
  static const String naverMapClientId = 's0jlbu865h';

  // 🚑 공공데이터포털 AED API Key
  // 발급: https://www.data.go.kr/ > 자동심장충격기(AED) 정보조회 서비스
  static const String publicDataApiKey =
      '195a040fe3deffc304ac8e3a10c7a72fcf3a2493a4c1e6e27129c15d5f02ec53';
}
