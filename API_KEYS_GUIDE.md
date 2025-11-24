# 🔐 API Keys 관리 가이드

## ⚠️ 중요: API 키 보안

이 프로젝트는 **민감한 API 키**를 사용합니다. 절대로 Git에 커밋하지 마세요!

---

## 📋 필요한 API 키

### 1. 네이버 지도 Client ID
- **용도**: 지도 표시
- **발급처**: [네이버 클라우드 플랫폼](https://www.ncloud.com/)
- **비용**: 무료 (월 10만 건)

### 2. 공공데이터포털 AED API Key
- **용도**: 전국 AED 위치 정보
- **발급처**: [공공데이터포털](https://www.data.go.kr/)
- **비용**: 무료

---

## 🚀 설정 방법

### 1단계: API 키 파일 생성

```bash
# 예제 파일 복사
cp lib/config/api_keys.example.dart lib/config/api_keys.dart
```

### 2단계: API 키 입력

`lib/config/api_keys.dart` 파일을 열고 실제 키 입력:

```dart
class ApiKeys {
  // 🗺️ 네이버 지도 Client ID
  static const String naverMapClientId = 'abcd1234efgh5678'; // ← 여기에 입력!
  
  // 🚑 공공데이터포털 AED API Key
  static const String publicDataApiKey = 'xyz789...'; // ← 여기에 입력!
}
```

### 3단계: 앱 실행

```bash
flutter run
```

---

## 🗺️ 네이버 지도 Client ID 발급 방법

### 1. 네이버 클라우드 플랫폼 접속
[https://www.ncloud.com/](https://www.ncloud.com/)

### 2. Console > AI·NAVER API

### 3. Application 등록
```
Application 이름: 911Calling
Service: Maps ✅
API 선택: Dynamic Map ✅
Android 패키지 이름: com.emergency.guide.projects
```

### 4. Client ID 복사
등록 완료 후 "인증 정보"에서 Client ID 확인

---

## 🚑 공공데이터 AED API Key 발급 방법

### 1. 공공데이터포털 접속
[https://www.data.go.kr/](https://www.data.go.kr/)

### 2. 검색
"자동심장충격기" 검색

### 3. 활용신청
"자동심장충격기(AED) 정보조회 서비스" 활용신청

### 4. API Key 확인
마이페이지 > 오픈API > 인증키 확인

---

## 🔒 보안 체크리스트

- [x] `.gitignore`에 `lib/config/api_keys.dart` 포함
- [x] `.env` 파일 `.gitignore`에 포함
- [x] `api_keys.example.dart` 파일에는 실제 키 없음
- [ ] 팀원에게 API 키를 **안전한 방법**으로 공유 (Slack DM, 1Password 등)
- [ ] GitHub에 커밋하기 전에 `git status` 확인

---

## 🚨 API 키가 노출된 경우

### 즉시 조치사항

1. **네이버 지도 API**
   - 네이버 클라우드 Console 접속
   - 해당 Application 삭제
   - 새로운 Client ID 발급

2. **공공데이터 API**
   - 공공데이터포털 접속
   - 해당 API Key 삭제 요청
   - 새로운 Key 발급

3. **Git 히스토리 정리**
   ```bash
   # BFG Repo-Cleaner 사용 (권장)
   # https://rtyley.github.io/bfg-repo-cleaner/
   
   # 또는 git filter-branch
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch lib/config/api_keys.dart" \
     --prune-empty --tag-name-filter cat -- --all
   
   git push origin --force --all
   ```

---

## 👥 팀 프로젝트인 경우

### 방법 1: 환경 변수 (권장)
```bash
# .env 파일 생성
NAVER_MAP_CLIENT_ID=your_key
PUBLIC_DATA_API_KEY=your_key

# flutter_dotenv 패키지 사용
flutter pub add flutter_dotenv
```

### 방법 2: 안전한 공유
- **1Password** 팀 볼트
- **LastPass** 공유 폴더
- **Slack** 비밀 메시지
- **직접 전달** (절대로 GitHub Issue나 Pull Request에 쓰지 마세요!)

---

## 📚 추가 리소스

- [네이버 지도 SDK 문서](https://navermaps.github.io/android-map-sdk/)
- [공공데이터포털 가이드](https://www.data.go.kr/ugs/selectPublicDataUseGuideView.do)
- [Flutter 환경 변수 관리](https://pub.dev/packages/flutter_dotenv)

---

## 💡 FAQ

**Q: API 키를 실수로 커밋했어요!**  
A: 즉시 API 키를 재발급하고, Git 히스토리에서 제거하세요.

**Q: 팀원과 API 키를 어떻게 공유하나요?**  
A: 1Password, Slack DM 등 안전한 방법을 사용하세요. GitHub에는 절대 올리지 마세요.

**Q: Firebase는 어떻게 하나요?**  
A: Firebase는 `firebase_options.dart`가 자동 생성되며, 이 파일은 팀과 공유해도 비교적 안전합니다.

---

**마지막 업데이트**: 2025-11-24
