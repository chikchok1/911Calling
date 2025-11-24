# 🚀 네이버 지도 Client ID 발급 가이드 (5분 완료!)

## 📋 요약
**Android 패키지 이름**: `com.emergency.guide.projects`  
**필요한 것**: 네이버 계정

---

## ✅ 단계별 가이드

### 1️⃣ 네이버 클라우드 플랫폼 접속
```
https://www.ncloud.com/
```
- 네이버 계정으로 로그인

### 2️⃣ Console 이동
- 우측 상단 **"Console"** 클릭

### 3️⃣ Maps API 신청
1. 좌측 메뉴 **"Services"** > **"AI·NAVER API"**
2. **"Application 등록"** 클릭

### 4️⃣ Application 정보 입력

| 항목 | 입력 값 | 중요도 |
|------|---------|--------|
| Application 이름 | `911Calling` | 아무거나 OK |
| Service 선택 | `Maps` ✅ | 필수! |
| Service 환경 | `Mobile Dynamic Map` ✅ | 필수! |
| **Android 패키지 이름** | `com.emergency.guide.projects` | ⚠️ 정확히! |

**⚠️ 가장 중요: Android 패키지 이름을 정확히 복사해서 입력하세요!**
```
com.emergency.guide.projects
```

### 5️⃣ Client ID 복사
- 등록 완료 후 표시되는 **Client ID** 복사
- 예시: `xjdke8vndk` (실제로는 더 긴 문자열)

### 6️⃣ 프로젝트에 적용
`lib/main.dart` 파일 열기:

**수정 전:**
```dart
await NaverMapSdk.instance.initialize(
  clientId: 'YOUR_NAVER_CLIENT_ID', // ← 이 부분
);
```

**수정 후:**
```dart
await NaverMapSdk.instance.initialize(
  clientId: 'xjdke8vndk', // ← 복사한 Client ID
);
```

### 7️⃣ 앱 재실행
```bash
flutter clean
flutter run
```

---

## ✨ 성공 확인

지도가 제대로 표시되면:
- ✅ 흰색 화면이 아닌 **실제 지도** 표시
- ✅ 좌측 하단에 **NAVER 로고** 표시
- ✅ 도로, 건물 등 보임
- ✅ 에러 메시지 사라짐

---

## 🐛 문제 해결

### "401 Unauthorized" 오류가 계속 나요
1. Client ID를 공백 없이 정확히 복사했는지 확인
2. Android 패키지 이름이 **정확히** `com.emergency.guide.projects`인지 확인
3. 앱을 완전히 종료하고 재실행

### Client ID는 어디서 다시 확인하나요?
- 네이버 클라우드 > Console > AI·NAVER API > 등록한 Application 클릭

### 지도는 보이는데 마커가 안 보여요
- "이 지역 검색" 버튼을 클릭하세요
- 우측 상단 스위치가 "공공 API"로 켜져 있는지 확인

---

## 📱 다음 단계

Client ID 적용 후:
1. 앱 재실행
2. 위치 권한 허용
3. 지도가 표시되는지 확인
4. "이 지역 검색" 버튼으로 AED 검색

---

**이제 `lib/main.dart`에 Client ID를 넣고 실행하세요!**
