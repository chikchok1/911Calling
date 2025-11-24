# 🚑 911 Calling - 응급 AED 위치 안내 앱

긴급 상황에서 가장 가까운 자동심장충격기(AED)를 빠르게 찾을 수 있는 Flutter 앱입니다.

## ✨ 주요 기능

- 🗺️ **실시간 지도**: 네이버 지도 기반 실시간 위치 추적
- 📍 **GPS 추적**: 사용자의 현재 위치를 10m 단위로 자동 업데이트
- 🚑 **AED 검색**: 공공데이터포털 API를 통한 전국 AED 위치 정보
- 📏 **거리 계산**: 현재 위치에서 각 AED까지의 거리 및 도보 시간 표시
- 🔍 **지역별 검색**: 서울, 부산, 대구 등 전국 17개 시도 검색
- 👥 **응급 요청**: 주변 앱 사용자에게 AED 요청 전송

## 🎯 기술 스택

- **Framework**: Flutter 3.10+
- **언어**: Dart 3.0+
- **지도**: flutter_naver_map 1.4.1+1
- **위치**: geolocator 13.0.2
- **백엔드**: Firebase
- **API**: 공공데이터포털 AED 정보조회 서비스

## 🚀 시작하기

### 1. 요구사항

```bash
Flutter SDK: >=3.10.0
Dart SDK: >=3.0.0
```

### 2. 저장소 클론

```bash
git clone https://github.com/yourusername/911Calling.git
cd 911Calling
```

### 3. 패키지 설치

```bash
flutter pub get
```

### 4. API 키 설정 ⚠️ 중요!

#### 방법 1: API 키 파일 생성 (권장)

```bash
# 예제 파일 복사
cp lib/config/api_keys.example.dart lib/config/api_keys.dart
```

`lib/config/api_keys.dart` 파일을 열고 실제 API 키 입력:

```dart
class ApiKeys {
  static const String naverMapClientId = 'YOUR_NAVER_CLIENT_ID';
  static const String publicDataApiKey = 'YOUR_PUBLIC_DATA_API_KEY';
}
```

#### API 키 발급 방법

**네이버 지도 Client ID**:
1. [네이버 클라우드 플랫폼](https://www.ncloud.com/) 접속
2. Console > AI·NAVER API > Application 등록
3. Dynamic Map 선택, Android 패키지: `com.emergency.guide.projects`

**공공데이터 AED API Key**:
1. [공공데이터포털](https://www.data.go.kr/) 접속
2. "자동심장충격기" 검색 > 활용신청
3. 마이페이지에서 인증키 확인

📚 **상세 가이드**: [API_KEYS_GUIDE.md](./API_KEYS_GUIDE.md) 참고

### 5. 앱 실행

```bash
flutter run
```

## 📱 지원 플랫폼

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ⚠️ Web (부분 지원 - 지도 기능 제한)

## 📂 프로젝트 구조

```
lib/
├── config/
│   ├── api_keys.dart           # API 키 (gitignore)
│   └── api_keys.example.dart   # API 키 예제
├── screens/
│   └── home_screen.dart        # 메인 화면
├── tabs/
│   ├── aed_locator_tab.dart    # AED 위치 탭
│   ├── guide_tab.dart          # 가이드 탭
│   └── ai_tab.dart             # AI 분석 탭
├── services/
│   ├── location_service.dart       # GPS 위치 서비스
│   ├── aed_service.dart           # AED 데이터 관리
│   └── public_aed_api_service.dart # 공공 API 연동
└── main.dart                   # 앱 진입점
```

## 🔒 보안

이 프로젝트는 민감한 API 키를 사용합니다:

- ✅ `lib/config/api_keys.dart`는 `.gitignore`에 포함됨
- ✅ 예제 파일(`api_keys.example.dart`)만 Git에 포함됨
- ⚠️ 절대로 실제 API 키를 GitHub에 커밋하지 마세요!

자세한 내용은 [API_KEYS_GUIDE.md](./API_KEYS_GUIDE.md)를 참고하세요.

## 🛠️ 개발

### 디버그 빌드

```bash
flutter run --debug
```

### 릴리즈 빌드

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### 테스트

```bash
flutter test
```

## 📊 주요 화면

### 1. AED 위치 안내
- 실시간 GPS 추적
- 네이버 지도 통합
- 주변 AED 검색 (반경 10km)
- 거리 및 도보 시간 표시

### 2. 가이드
- 심폐소생술 (CPR) 가이드
- AED 사용법
- 응급 상황 대처 방법

### 3. AI 분석
- 응급 상황 판단
- 증상 분석
- 응급처치 조언

## 🤝 기여

기여는 언제나 환영합니다!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 라이선스

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 개발자

- **Name**: Your Name
- **Email**: your.email@example.com
- **GitHub**: [@yourusername](https://github.com/yourusername)

## 🙏 감사의 말

- [네이버 지도 SDK](https://navermaps.github.io/android-map-sdk/)
- [공공데이터포털](https://www.data.go.kr/)
- [Flutter](https://flutter.dev/)

## 📞 문의

문제가 있거나 질문이 있으신가요? [Issues](https://github.com/yourusername/911Calling/issues)를 열어주세요!

---

**⚠️ 주의**: 이 앱은 긴급 상황에서 참고용으로만 사용하세요. 실제 응급 상황 시 119에 먼저 연락하세요!
