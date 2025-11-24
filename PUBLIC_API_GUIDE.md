# 공공 AED API 연동 완료! 🎉

## 변경 사항 요약

### 1. 추가된 파일
- `lib/services/public_aed_api_service.dart` - 공공데이터포털 AED API 연동

### 2. 수정된 파일
- `pubspec.yaml` - XML 파싱 패키지 추가
- `lib/tabs/aed_locator_tab.dart` - 공공 API 사용 + 디버깅 추가

### 3. 새로운 기능
✅ 실제 공공데이터포털 AED 정보 사용
✅ 서울시 전체 AED 데이터 검색
✅ 5km 반경 내 자동 필터링
✅ API 전환 스위치 (공공 API ↔ 샘플 데이터)
✅ 디버깅 정보 표시

## 즉시 실행하기

### 1단계: 패키지 설치
```bash
cd /Users/jun/Documents/GitHub/911Calling
flutter pub get
```

### 2단계: 앱 실행
```bash
flutter run
```

### 3단계: 테스트
1. 앱 실행 후 **위치 권한 허용**
2. 화면 우측 상단의 **스위치를 ON** (공공 API 모드)
3. 잠시 기다리면 실제 AED 데이터가 로딩됨
4. 지도에 노란색 마커로 AED 위치 표시
5. 하단 목록에서 거리순으로 정렬된 AED 확인

## 공공 API 정보

### 사용 중인 API
- **서비스명**: 자동심장충격기 설치 위치 정보
- **제공기관**: 보건복지부
- **End Point**: https://apis.data.go.kr/B552657/AEDInfoInqireService
- **API Key**: 이미 적용됨 (195a040fe3deffc304ac8e3a10c7a72fcf3a2493a4c1e6e27129c15d5f02ec53)

### API 사용 정보
```
lib/services/public_aed_api_service.dart 파일에 구현됨

주요 함수:
1. getAEDLocationInfo() - 시도/시군구별 AED 검색
2. getNearbyAEDsFromPublicAPI() - 현재 위치 기반 검색
3. searchAEDsByRegion() - 특정 지역 검색
```

## 현재 동작 방식

### 데이터 흐름
```
1. 사용자 위치 가져오기 (GPS)
   ↓
2. 공공 API 호출 (서울특별시 전체)
   - 최대 1000개 AED 정보 요청
   ↓
3. 5km 반경 내 필터링
   ↓
4. 거리순 정렬
   ↓
5. 지도에 마커 표시 + 목록 표시
```

### 지원 지역
현재는 **서울특별시** 전체를 검색합니다.
다른 지역을 추가하려면 `public_aed_api_service.dart`의 `getNearbyAEDsFromPublicAPI()` 함수를 수정하세요.

## 문제 해결

### 지도가 표시되지 않는 경우
1. **네이버 지도 Client ID 확인**
   - `lib/main.dart` 파일의 Client ID가 올바른지 확인
   - 현재: `254huu3e2n`

2. **위치 권한 확인**
   - 설정 > 앱 > 911Calling > 권한 > 위치 허용

3. **로그 확인**
   - 터미널에 출력되는 디버그 로그 확인
   - "지도 준비 완료!", "마커 추가 시작..." 등의 메시지 확인

### AED가 표시되지 않는 경우
1. **API 응답 확인**
   - 터미널 로그에서 "공공 API에서 X개 AED 가져옴" 확인
   - 0개면 API 호출 실패 또는 해당 지역에 데이터 없음

2. **네트워크 확인**
   - 인터넷 연결 확인
   - API 엔드포인트 접근 가능한지 확인

3. **스위치 확인**
   - 화면 우측 상단 스위치가 "공공 API"로 켜져 있는지 확인

### GPS 위치가 안 잡히는 경우
1. **에뮬레이터**
   - Android Studio: Extended Controls > Location에서 위치 설정
   - 기본 위치: 37.5665, 126.9780 (서울시청)

2. **실제 기기**
   - 설정에서 위치 서비스 켜기
   - 앱 재시작

## 디버깅 정보

### 화면 표시 정보
지도 좌측 상단에 현재 위치 좌표가 표시됩니다:
```
위치: 37.5665, 126.9780
```

### 터미널 로그
앱 실행 시 다음과 같은 로그가 출력됩니다:
```
위치 권한 요청 시작...
현재 위치: 37.5665, 126.9780
공공 API에서 AED 데이터 가져오는 중...
Fetching AED data from: https://apis.data.go.kr/...
Fetched 150 AEDs from public API
공공 API에서 42개 AED 가져옴
지도 준비 중...
지도 준비 완료!
마커 추가 시작...
내 위치 마커 추가: 37.5665, 126.9780
내 위치 마커 추가 완료
AED 마커 42개 추가 중...
AED 마커 추가: 강남역 1번 출구 (37.4980, 127.0276)
...
모든 마커 추가 완료!
```

## 추가 기능 구현 예정
- [ ] 다른 지역 지원 (부산, 대구 등)
- [ ] 역지오코딩으로 자동 지역 감지
- [ ] AED 사용 가능 여부 실시간 업데이트
- [ ] 길찾기 앱 연동
- [ ] 즐겨찾기 기능

## 참고
- 공공데이터포털: https://www.data.go.kr/
- 네이버 지도 API: https://www.ncloud.com/
- Flutter Naver Map: https://pub.dev/packages/flutter_naver_map

---

**주의**: 공공 API는 하루 요청 횟수 제한이 있을 수 있습니다. 
현재 사용 중인 API 키의 일일 트래픽은 1000건입니다.
