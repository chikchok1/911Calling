# AED 위치 안내 - 빠른 시작 가이드

## 즉시 테스트하기 (5분 완료)

### 1단계: 패키지 설치 (1분)
터미널에서 실행:
```bash
cd /Users/jun/Documents/GitHub/911Calling
flutter pub get
```

### 2단계: 네이버 지도 API 키 발급 (3분)

1. **네이버 클라우드 플랫폼 접속**
   - https://www.ncloud.com/
   - 네이버 계정으로 로그인

2. **Console 이동**
   - 우측 상단 "Console" 클릭

3. **Maps API 신청**
   - 좌측 메뉴에서 "Services" > "AI·NAVER API" 선택
   - "Application 등록" 버튼 클릭
   - Application 이름: `911Calling` 입력
   - Services: `Maps` 선택
   - Service 환경: `Mobile Dynamic Map` 선택
   - "등록" 버튼 클릭

4. **Client ID 복사**
   - 등록 완료 후 표시되는 "Client ID" 복사

### 3단계: Client ID 적용 (1분)

`lib/main.dart` 파일 열기:
```dart
// 이 부분을 찾아서
await NaverMapSdk.instance.initialize(
  clientId: 'YOUR_NAVER_MAP_CLIENT_ID', // 이 부분을
  ...
);

// 이렇게 변경 (복사한 Client ID 붙여넣기)
await NaverMapSdk.instance.initialize(
  clientId: 'abcdefghij1234567890', // 예시: 실제 발급받은 ID로 변경
  ...
);
```

### 4단계: 앱 실행
```bash
# Android
flutter run

# iOS  
flutter run
```

## 테스트 시나리오

### 시나리오 1: 기본 기능 테스트
1. 앱 실행 시 위치 권한 허용
2. 지도에 현재 위치(파란 점)와 AED 위치(노란 볼트) 확인
3. 하단 목록에서 가장 가까운 AED 확인

### 시나리오 2: AED 상세 정보 확인
1. 지도의 AED 마커 클릭
2. 바텀시트에서 상세 정보 확인 (주소, 거리, 도보 시간)
3. "길찾기" 버튼으로 해당 위치로 지도 이동
4. "공유" 버튼으로 정보 공유

### 시나리오 3: AED 요청
1. "주변 사용자에게 AED 요청" 버튼 클릭
2. 확인 다이얼로그에서 "요청" 클릭
3. 성공 메시지 확인

### 시나리오 4: 목록에서 AED 선택
1. 하단 AED 목록 스크롤
2. 원하는 AED 항목 클릭하여 상세 정보 확인
3. 또는 "길찾기" 버튼으로 바로 지도 이동

## 주요 수정 사항 요약

### 추가된 파일
```
lib/
├── services/
│   ├── location_service.dart    # GPS 위치 관리
│   └── aed_service.dart         # AED 데이터 관리
└── tabs/
    └── aed_locator_tab.dart     # 메인 화면 (완전 새로 작성)
```

### 수정된 파일
```
- pubspec.yaml                    # 패키지 추가
- lib/main.dart                   # 네이버 지도 SDK 초기화
- android/app/src/main/AndroidManifest.xml  # 위치 권한
- ios/Runner/Info.plist          # 위치 권한
```

### 새로운 기능
✅ 네이버 지도 API 통합
✅ 실시간 GPS 위치 추적
✅ 주변 AED 자동 검색 및 정렬
✅ 거리 및 도보 시간 자동 계산
✅ 지도 마커 인터랙션
✅ AED 상세 정보 바텀시트
✅ 길찾기 및 공유 기능

## 현재 사용 중인 샘플 데이터

서울 강남 지역 기준 6개 AED:
1. 강남역 1번 출구 (37.4980, 127.0276)
2. GS25 편의점 (37.4995, 127.0297)
3. 시청 1층 로비 (37.5665, 126.9780)
4. 종합병원 응급실 (37.5050, 127.0263)
5. 선릉역 2번 출구 (37.5045, 127.0490)
6. 삼성역 코엑스몰 (37.5115, 127.0590)

## 다음 단계

### 실제 데이터 연동
실제 AED 데이터를 사용하려면 `AED_SETUP_GUIDE.md`의 "6. AED 데이터 소스" 섹션을 참고하세요.

### 추가 기능 구현
- [ ] 119 신고 연동
- [ ] 네이버 지도 앱 길찾기 연동
- [ ] AED 사용법 가이드
- [ ] 즐겨찾기 기능

## 문제가 발생하면?

### 지도가 표시되지 않음
→ Client ID를 다시 확인하세요

### 위치를 가져올 수 없음
→ 설정에서 위치 권한을 허용했는지 확인하세요

### 빌드 오류
→ `flutter clean && flutter pub get` 실행 후 다시 시도하세요

### 기타 문제
→ `AED_SETUP_GUIDE.md`의 "8. 문제 해결" 섹션을 참고하세요

---

**Tip**: 에뮬레이터에서 테스트 시 위치를 시뮬레이션할 수 있습니다:
- Android Studio: Extended Controls > Location
- Xcode Simulator: Features > Location > Custom Location
