# 네이버 지도 인증 오류 해결 가이드

## 🚨 현재 오류
```
[NaverMapSdk] Authorization failed: [401] Unauthorized client
```

이 오류는 **네이버 지도 Client ID가 유효하지 않거나** 제대로 등록되지 않아서 발생합니다.

---

## ✅ 해결 방법 (5분 소요)

### 1단계: 네이버 클라우드 플랫폼 접속
```
https://www.ncloud.com/
```
- 네이버 계정으로 로그인

### 2단계: Console 이동
- 우측 상단 **"Console"** 버튼 클릭

### 3단계: Maps API 신청
1. 좌측 메뉴에서 **"Services"** 클릭
2. **"AI·NAVER API"** 선택
3. **"Application 등록"** 버튼 클릭

### 4단계: Application 정보 입력

**필수 입력 사항:**

| 항목 | 입력 값 | 설명 |
|------|---------|------|
| Application 이름 | `911Calling` | 아무 이름이나 가능 |
| Service 선택 | `Maps` 체크 ✅ | 반드시 체크! |
| Service 환경 | `Mobile Dynamic Map` 체크 ✅ | 반드시 체크! |
| **Android 패키지 이름** | `com.example.projects` | ⚠️ 정확히 입력! |
| Bundle ID (iOS) | 비워두기 | 선택사항 |

**⚠️ 주의: Android 패키지 이름은 정확히 `com.example.projects`로 입력하세요!**

### 5단계: 등록 완료 후 Client ID 복사
- 등록이 완료되면 **Client ID**가 표시됩니다
- 예: `abcd1234efgh5678` (실제로는 더 긴 문자열)
- 이 값을 복사하세요

### 6단계: 프로젝트에 Client ID 적용

`lib/main.dart` 파일을 열고:

```dart
await NaverMapSdk.instance.initialize(
  clientId: 'YOUR_NAVER_CLIENT_ID', // ← 여기에 복사한 Client ID 붙여넣기
);
```

**수정 예시:**
```dart
await NaverMapSdk.instance.initialize(
  clientId: 'abcd1234efgh5678', // ← 발급받은 실제 Client ID
);
```

### 7단계: 앱 재실행
```bash
# 터미널에서 실행
flutter clean
flutter run
```

---

## 📱 확인 방법

앱이 정상 실행되면:
- ✅ 지도가 흰색이 아닌 실제 지도가 표시됨
- ✅ 네이버 로고가 좌측 하단에 표시됨
- ✅ 도로, 건물 등이 보임
- ✅ 에러 메시지가 사라짐

---

## 🔍 문제 해결

### Q1. Client ID를 어디서 확인하나요?
A: 네이버 클라우드 플랫폼 > Console > AI·NAVER API > 등록한 애플리케이션 클릭

### Q2. "패키지 이름이 일치하지 않습니다" 오류
A: Android 패키지 이름을 정확히 `com.example.projects`로 입력했는지 확인

### Q3. 여전히 401 오류가 나요
A: 
1. Client ID를 정확히 복사했는지 확인 (공백 없이)
2. 앱을 완전히 종료하고 재실행
3. `flutter clean` 후 다시 빌드

### Q4. iOS에서도 설정해야 하나요?
A: Android만 사용한다면 Bundle ID는 비워두셔도 됩니다

---

## 💡 참고 사항

### 무료 사용량
- 월 10만 건까지 무료
- 911Calling 앱 정도면 충분함

### API 키 보안
- Client ID는 공개되어도 괜찮습니다
- 패키지 이름으로 보호됨

### 추가 설정
- API 호출 제한 설정 가능
- 사용량 모니터링 가능

---

## 📞 추가 도움이 필요하면

1. 네이버 클라우드 문서: https://guide.ncloud-docs.com/docs/naveropenapi-maps-overview
2. Flutter Naver Map 문서: https://pub.dev/packages/flutter_naver_map

---

**Client ID를 발급받은 후 `lib/main.dart`에 적용하고 앱을 재실행하세요!**
