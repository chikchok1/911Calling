# 🚀 빠른 시작 가이드

## 현재 상황
Git 병합 과정에서 `aed_locator_tab.dart` 파일이 손상되어 앱 전체가 실행되지 않는 문제가 발생했습니다.

## ✅ 수정 완료
주요 문제들을 모두 수정했습니다!

---

## 📝 지금 바로 해야 할 일

### 1️⃣ 의존성 업데이트 (필수)
```bash
cd C:\Users\YangJinWon\Desktop\projects
flutter clean
flutter pub get
```

### 2️⃣ API 키 설정 (필수)

#### 📍 네이버 지도 Client ID 발급

1. **네이버 클라우드 플랫폼 가입**
   - https://www.ncloud.com/ 접속
   - 회원가입/로그인

2. **Application 등록**
   - Console > Services > AI·NAVER API 선택
   - Application 이름 등록
   - "Maps" 서비스 추가
   
3. **Client ID 확인**
   - 등록된 Application > 인증 정보
   - Client ID 복사

4. **패키지명 설정**
   - Android: `com.emergency.guide.projects`
   - 저장

#### 🏥 공공데이터 AED API Key 발급

1. **공공데이터포털 가입**
   - https://www.data.go.kr/ 접속
   - 회원가입/로그인

2. **API 신청**
   - 검색창에 "자동심장충격기" 입력
   - "전국자동심장충격기설치위치정보표준데이터" 선택
   - 활용신청 버튼 클릭

3. **승인 대기**
   - 즉시 승인됨 (보통 1-2분 소요)
   - 마이페이지 > 오픈API > 개발계정

4. **인증키 확인**
   - 일반 인증키(Encoding) 복사

### 3️⃣ API 키 입력

**파일 열기**: `lib/config/api_keys.dart`

```dart
class ApiKeys {
  // 여기에 발급받은 Client ID 붙여넣기
  static const String naverMapClientId = '여기에_Client_ID_입력';
  
  // 여기에 발급받은 API Key 붙여넣기  
  static const String publicDataApiKey = '여기에_인증키_입력';
}
```

**저장** (Ctrl+S)

### 4️⃣ 앱 실행
```bash
flutter run
```

---

## 🔧 문제 해결

### ❌ 오류: `api_keys.dart` not found
```bash
# api_keys.dart 파일이 있는지 확인
ls lib/config/api_keys.dart

# 없다면 예제 파일 복사
cp lib/config/api_keys.example.dart lib/config/api_keys.dart
```

### ❌ 오류: Client ID not provided
- `api_keys.dart` 파일을 열고 실제 Client ID를 입력했는지 확인
- `YOUR_NAVER_CLIENT_ID_HERE`를 실제 값으로 교체

### ❌ 오류: Permission denied
```bash
# 위치 권한 설정
# Android: 설정 > 앱 > 권한 > 위치
# iOS: 설정 > 개인정보 보호 > 위치 서비스
```

### ❌ 지도가 안 나옴
1. 네이버 Client ID 확인
2. 패키지명이 `com.emergency.guide.projects`인지 확인
3. 인터넷 연결 확인

---

## 📱 앱 사용 방법

### 1. 홈 탭 (응급 SOS)
- 빨간 SOS 버튼 탭
- 119 자동 연결
- 위치 자동 전송

### 2. 가이드 탭
- 심폐소생술 방법
- AED 사용법
- 응급 상황 대처

### 3. AI 분석 탭
- 증상 체크
- 마이크 버튼으로 음성 입력
- AI 응급 분석
- 음성 안내

### 4. AED 탭
- 지도에서 가까운 AED 확인
- 거리 및 도보 시간 표시
- 길찾기 기능
- 주변 사용자에게 요청

---

## 🎯 테스트 체크리스트

앱 실행 후 다음 기능들을 확인하세요:

- [ ] 앱이 실행됨
- [ ] 하단 네비게이션 바가 보임
- [ ] 4개 탭 전환이 됨
- [ ] AED 탭에서 지도가 로딩됨
- [ ] 위치 권한 요청이 나타남
- [ ] AI 탭에서 음성 입력이 작동함

---

## 📚 추가 문서

자세한 내용은 다음 문서를 참고하세요:

- `FIX_REPORT.md` - 상세한 수정 내역
- `API_KEYS_GUIDE.md` - API 키 발급 가이드
- `README.md` - 프로젝트 전체 설명

---

## 💬 도움이 필요하신가요?

### 에러 메시지를 확인하세요
```bash
flutter run --verbose
```

### 일반적인 명령어
```bash
# 캐시 정리
flutter clean

# 패키지 재설치
flutter pub get

# 빌드
flutter build apk

# 디바이스 확인
flutter devices
```

---

## 🎉 완료!

이제 앱이 정상적으로 작동할 것입니다!

**문제가 계속되면**:
1. 터미널의 에러 메시지 전체를 복사
2. `FIX_REPORT.md`의 "문제 해결" 섹션 참고
3. 필요시 도움 요청

**즐거운 개발 되세요!** 🚀
