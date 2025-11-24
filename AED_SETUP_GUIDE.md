# AED 위치 안내 기능 설정 가이드

## 개요
네이버 지도 API와 GPS를 사용하여 주변 AED(자동심장충격기) 위치를 실시간으로 표시하는 기능입니다.

## 1. 네이버 지도 API 설정

### 1.1 네이버 클라우드 플랫폼 가입
1. [네이버 클라우드 플랫폼](https://www.ncloud.com/)에 접속
2. 회원가입 및 로그인
3. 콘솔로 이동

### 1.2 Maps Client ID 발급
1. 콘솔에서 **AI·NAVER API** 선택
2. **Application 등록** 클릭
3. 애플리케이션 정보 입력:
   - Application 이름: 911 Calling (또는 원하는 이름)
   - Service 선택: **Maps**
   - Service 환경: **Mobile Dynamic Map**
4. 등록 후 **Client ID** 복사

### 1.3 프로젝트에 Client ID 적용
`lib/main.dart` 파일을 열고 다음 부분을 수정:

```dart
await NaverMapSdk.instance.initialize(
  clientId: 'YOUR_NAVER_MAP_CLIENT_ID', // 발급받은 Client ID로 교체
  onMapError: (error, stackTrace) {
    print('NaverMap Error: $error');
    print(stackTrace);
  },
);
```

## 2. 패키지 설치

터미널에서 다음 명령어 실행:

```bash
cd /Users/jun/Documents/GitHub/911Calling
flutter pub get
```

## 3. 플랫폼별 추가 설정

### Android 설정
이미 `AndroidManifest.xml`에 위치 권한이 추가되어 있습니다:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `INTERNET`

### iOS 설정
이미 `Info.plist`에 위치 권한 설명이 추가되어 있습니다.

## 4. 실행 방법

```bash
# Android
flutter run

# iOS
flutter run
```

## 5. 기능 설명

### 주요 기능
1. **실시간 GPS 위치 추적**: 사용자의 현재 위치를 기반으로 주변 AED 검색
2. **네이버 지도 표시**: 사용자 위치와 주변 AED를 지도에 마커로 표시
3. **거리 계산**: 각 AED까지의 직선 거리 자동 계산
4. **도보 시간 계산**: 평균 시속 4km 기준으로 도보 시간 계산
5. **AED 상세 정보**: 마커 클릭 시 상세 정보 표시
6. **길찾기 기능**: AED 위치로 카메라 이동
7. **주변 사용자에게 AED 요청**: 긴급 상황 시 알림 전송

### 화면 구성
1. **지도 영역** (상단 300px)
   - 사용자 위치: 파란색 마커
   - AED 위치: 노란색/회색 볼트 아이콘
   - 사용 가능/사용 중 상태 표시

2. **AED 요청 버튼** (지도 아래)
   - 주변 앱 사용자에게 AED 요청 전송

3. **AED 목록** (하단 스크롤)
   - 거리순으로 정렬된 주변 AED 목록
   - 각 항목에 거리, 도보 시간, 상태 표시
   - 길찾기 버튼으로 빠른 네비게이션

## 6. AED 데이터 소스

현재는 샘플 데이터를 사용하고 있습니다. 실제 데이터를 사용하려면:

### 6.1 공공데이터포털 API 사용
1. [공공데이터포털](https://www.data.go.kr/) 접속
2. "자동심장충격기 설치 위치 정보" 검색
3. API 활용 신청
4. `lib/services/aed_service.dart`의 주석 처리된 `fetchAEDsFromAPI` 함수 구현

### 6.2 Firebase Firestore 사용
1. Firebase Console에서 Firestore 활성화
2. AED 데이터를 Firestore에 저장
3. `aed_service.dart`에서 Firestore 쿼리 구현:

```dart
Future<List<AEDData>> fetchAEDsFromFirestore(Position position) async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('aeds').get();
  
  return snapshot.docs
      .map((doc) => AEDData.fromJson(doc.data()))
      .toList();
}
```

## 7. 커스터마이징

### 검색 반경 변경
`lib/tabs/aed_locator_tab.dart`의 `_initializeLocation()` 함수에서:

```dart
List<AEDData> aeds = await AEDService.getNearbyAEDs(
  position, 
  radiusKm: 5.0,  // 이 값을 변경 (기본: 5km)
);
```

### 지도 초기 줌 레벨 변경
```dart
NaverMapViewOptions(
  initialCameraPosition: NCameraPosition(
    target: NLatLng(latitude, longitude),
    zoom: 15,  // 이 값을 변경 (기본: 15)
  ),
)
```

### 도보 속도 변경
`lib/services/location_service.dart`의 `calculateWalkingTime()` 함수에서:

```dart
const double walkingSpeedKmH = 4.0;  // 이 값을 변경 (기본: 4km/h)
```

## 8. 문제 해결

### 위치 권한 문제
- Android: 설정 > 앱 > 911Calling > 권한 > 위치 허용
- iOS: 설정 > 개인정보 보호 > 위치 서비스 > 911Calling 허용

### 지도가 표시되지 않는 경우
1. Client ID가 올바르게 입력되었는지 확인
2. 네이버 클라우드 플랫폼에서 Maps 서비스가 활성화되었는지 확인
3. 인터넷 연결 확인

### 빌드 오류
```bash
# 캐시 클리어
flutter clean
flutter pub get

# 다시 빌드
flutter run
```

## 9. 향후 개선 사항
- [ ] 실제 공공 API 연동
- [ ] AED 사용 가능 여부 실시간 업데이트
- [ ] 네이버 지도 앱 연동 길찾기
- [ ] AED 사용 방법 안내 추가
- [ ] 119 신고 연동
- [ ] 오프라인 모드 지원
- [ ] 즐겨찾기 AED 저장

## 10. 참고 자료
- [Flutter Naver Map 패키지](https://pub.dev/packages/flutter_naver_map)
- [Geolocator 패키지](https://pub.dev/packages/geolocator)
- [네이버 클라우드 플랫폼 문서](https://guide.ncloud-docs.com/docs/naveropenapiv3-maps-overview)
- [공공데이터포털](https://www.data.go.kr/)
