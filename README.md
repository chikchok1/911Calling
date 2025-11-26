# 🚑 911 Calling App - 응급 구조 도우미

> 실시간 위치 기반 응급 상황 대응 및 AI 기반 응급처치 가이드를 제공하는 Flutter 애플리케이션

[![Flutter](https://img.shields.io/badge/Flutter-3.10.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://www.android.com)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)](https://firebase.google.com)

---

## ⚠️ 플랫폼 지원

| 플랫폼 | 상태 | 비고 |
|--------|------|------|
| 📱 **Android** | ✅ **지원** | API Level 21+ |
| 🍎 **iOS** | ❌ 미지원 | v2.0 예정 |
| 🌐 **Web** | ❌ 미지원 | 향후 계획 |

---

## 🎯 프로젝트 개요

응급 상황에서 신속한 대응을 돕는 종합 응급 구조 애플리케이션입니다.

### 핵심 기능

- 🚨 **119 긴급 신고**: 원터치 신고 및 실시간 위치 전송
- 🤖 **AI 상황 분석**: Google Gemini API 기반 응급 상황 판단
- 📍 **AED 위치 찾기**: 네이버 지도 연동 AED 검색
- 📖 **응급처치 가이드**: 상황별 단계별 대응 매뉴얼
- 🎙️ **음성 지원**: STT/TTS 핸즈프리 작동

---

## 🛠 기술 스택

- **Frontend**: Flutter 3.10+, Dart 3.10+
- **Backend**: Firebase (Auth, Firestore), Google Gemini API
- **Maps**: Google Maps, Naver Maps
- **Voice**: Speech-to-Text, Text-to-Speech
- **APIs**: 공공데이터 소방서/AED API

---

## 🚀 빠른 시작

### 1. 필수 도구 설치
```bash
# Flutter SDK 3.10.0+ 설치
# Android Studio 설치
# Git 설치
```

### 2. 프로젝트 클론 및 설치
```bash
git clone https://github.com/chikchok/911-calling-app.git
cd projects
flutter pub get
```

### 3. 환경 변수 설정
```bash
# .env 파일 생성
copy .env.example .env  # Windows
cp .env.example .env    # macOS/Linux

# .env 파일에 API 키 입력
GEMINI_API_KEY=your_key
FIRE_STATION_API_KEY=your_key
AED_API_KEY=your_key
GOOGLE_MAPS_API_KEY_ANDROID=your_key
NAVER_MAP_CLIENT_ID=your_key
```

### 4. Firebase 설정
1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. Android 앱 추가 (패키지명: `com.emergency.guide.projects`)
3. `google-services.json` 다운로드
4. `android/app/` 디렉토리에 배치

### 5. 앱 실행
```bash
flutter run
```

---

## 📚 상세 가이드

자세한 설정 방법은 다음 가이드를 참조하세요:

- [API_KEYS_GUIDE.md](./API_KEYS_GUIDE.md) - API 키 발급 방법
- [AED_SETUP_GUIDE.md](./AED_SETUP_GUIDE.md) - AED 기능 설정
- [NAVER_MAP_FIX.md](./NAVER_MAP_FIX.md) - 네이버 맵 이슈 해결

---

## 🔧 주요 문제 해결

### Firebase 초기화 오류
```bash
flutterfire configure
```

### 네이버 맵 인증 실패
- Client ID 확인
- AndroidManifest.xml의 meta-data 확인
- 자세한 내용: [NAVER_MAP_FIX.md](./NAVER_MAP_FIX.md)

### Gradle 빌드 오류
```bash
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get
```

---

## 📁 프로젝트 구조

```
projects/
├── lib/
│   ├── screens/     # UI 화면
│   ├── services/    # 비즈니스 로직
│   ├── models/      # 데이터 모델
│   ├── widgets/     # 재사용 위젯
│   └── tabs/        # 탭 화면
├── android/         # Android 설정
├── assets/          # 리소스
└── test/            # 테스트
```

---

## 🧪 테스트

```bash
flutter test                 # 전체 테스트
flutter test --coverage      # 커버리지 생성
```

**현재 테스트 커버리지**: 85%

---

## 📲 APK 배포 (ADB 사용)

개발자가 아닌 사용자에게 APK를 설치하려면 ADB(Android Debug Bridge)를 사용할 수 있습니다.

### 📌 1) ADB 설치 (Windows)

**방법 1: Android SDK Platform Tools 다운로드**
```bash
# 1. 다운로드
https://developer.android.com/studio/releases/platform-tools

# 2. 압축 해제 후 환경 변수 등록
# 시스템 속성 > 환경 변수 > Path에 추가
C:\your\path\platform-tools
```

**방법 2: Chocolatey 사용 (권장)**
```bash
choco install adb
```

### 📌 2) 스마트폰 USB 디버깅 활성화

1. **개발자 옵션 활성화**
   - 설정 > 휴대전화 정보 > 빌드 번호를 7번 연속 탭

2. **USB 디버깅 켜기**
   - 설정 > 개발자 옵션 > USB 디버깅 활성화

3. **USB 연결 및 인증**
   - USB로 PC와 연결
   - 스마트폰 화면에 나타나는 "USB 디버깅 허용" 팝업 승인

4. **연결 확인**
```bash
adb devices
# 기기 목록에 스마트폰이 표시되어야 합니다
# 예: List of devices attached
#     ABC123XYZ    device
```

### 📌 3) APK 설치

```bash
# APK 파일이 현재 경로에 있을 경우
adb install app-release.apk

# APK가 다른 경로에 있을 경우
adb install "C:/your/path/app-release.apk"

# 기존 앱을 덮어쓰기로 설치 (업데이트)
adb install -r app-release.apk
```

### 📌 4) 문제 해결

**기기가 인식되지 않을 때:**
```bash
# ADB 서버 재시작
adb kill-server
adb start-server
adb devices
```

**설치 실패 시:**
```bash
# 기존 앱 제거 후 재설치
adb uninstall com.emergency.guide.projects
adb install app-release.apk
```

**여러 기기가 연결되어 있을 때:**
```bash
# 특정 기기에 설치
adb -s [DEVICE_ID] install app-release.apk
```

---

## 🔄 버전

**v1.0.0** (2025-11-26) - Android 전용 초기 릴리즈

### 향후 계획
- [ ] v2.0.0: iOS 플랫폼 지원
- [ ] v2.1.0: 웹 버전
- [ ] v2.2.0: 알림 기능
- [ ] v2.3.0: 오프라인 모드
- [ ] v2.4.0: 다국어 지원

---

## 🤝 기여하기

1. Fork 프로젝트
2. Feature Branch 생성 (`git checkout -b feature/AmazingFeature`)
3. 변경사항 커밋 (`git commit -m 'Add AmazingFeature'`)
4. Branch에 Push (`git push origin feature/AmazingFeature`)
5. Pull Request 생성

### 코드 스타일
- Dart 공식 스타일 가이드 준수
- `flutter analyze` 통과 필수

---

## 📝 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 참조

---

## 👨‍💻 개발자

**YangJinWon (chikchok)**
- GitHub: [@chikchok1](https://github.com/chikchok1)

**SimDongJin (Diongjin)**
- GitHub: [@Diongjin](https://github.com/Diongjin)

**KangJunHwa (JunHwaKang)**
- GitHub: [@JunHwaKang](https://github.com/JunHwaKang)

---

---

<div align="center">

## ⚠️ 중요 고지 ⚠️

**📱 현재 Android만 지원됩니다**

**이 앱은 응급 상황 대응을 돕는 보조 도구입니다.**

**실제 응급 상황에서는 반드시 119에 신고하고 전문가의 지시를 따르세요.**

---

</div>
