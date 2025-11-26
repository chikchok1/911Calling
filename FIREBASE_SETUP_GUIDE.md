# 🔥 Firebase 초기 설정 가이드

## ⚠️ 현재 문제 상황

회원가입 시 다음과 같은 에러가 발생합니다:

```
오류
회원가입 중 오류가 발생했습니다: An internal error has occurred.
[ CONFIGURATION_NOT_FOUND ]
```

이는 **Firebase Console에서 필수 설정이 완료되지 않았기 때문**입니다.

---

## 🎯 해결 방법

### 1단계: Firebase Console 접속

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택 (911Calling 프로젝트)

---

### 2단계: Authentication 설정 ✅ 필수!

#### 2.1 Email/Password 로그인 활성화

1. 왼쪽 메뉴 → **Authentication** 클릭
2. **Sign-in method** 탭 클릭
3. **이메일/비밀번호** 찾기
4. **사용 설정** 토글 ON
5. **저장** 버튼 클릭

**스크린샷 예시:**
```
┌─────────────────────────────────────┐
│ Sign-in providers                   │
├─────────────────────────────────────┤
│ Email/Password      [  사용 설정  ] │ ← 이것을 ON으로!
│ Phone                               │
│ Google                              │
│ Facebook                            │
└─────────────────────────────────────┘
```

#### 2.2 확인 방법

- "이메일/비밀번호" 옆에 **활성화** 표시가 보이면 성공!

---

### 3단계: Firestore Database 생성 ✅ 필수!

#### 3.1 Firestore 생성

1. 왼쪽 메뉴 → **Firestore Database** 클릭
2. **데이터베이스 만들기** 버튼 클릭
3. **테스트 모드로 시작** 선택 (개발 단계)
   ```
   ⚠️ 프로덕션 배포 전 보안 규칙을 반드시 변경하세요!
   ```
4. **위치 선택:** `asia-northeast3 (Seoul)` 권장
5. **사용 설정** 클릭

#### 3.2 보안 규칙 설정 (임시)

개발 단계에서는 다음과 같이 설정하세요:

**Firestore → 규칙 탭**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 개발 단계: 모든 읽기/쓰기 허용 (임시)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **주의:** 프로덕션 배포 시 반드시 보안 규칙을 변경하세요!

**프로덕션용 규칙 (권장):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // users 컬렉션: 본인만 읽기/쓰기 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

### 4단계: 앱 재실행

설정을 변경한 후 **앱을 완전히 재시작**하세요.

```bash
# 터미널에서 실행
cd /Users/jun/Documents/GitHub/911Calling

# 앱 중지 후 재시작
flutter run
```

---

## 📋 설정 체크리스트

아래 항목을 모두 확인하세요:

- [ ] ✅ Firebase Console → Authentication → Email/Password **활성화**
- [ ] ✅ Firebase Console → Firestore Database **생성 완료**
- [ ] ✅ Firestore 보안 규칙 **테스트 모드로 설정**
- [ ] ✅ `google-services.json` 파일 존재 확인 (`android/app/`)
- [ ] ✅ `GoogleService-Info.plist` 파일 존재 확인 (`ios/Runner/`)
- [ ] ✅ 앱 재시작

---

## 🔍 문제 해결

### 문제 1: "CONFIGURATION_NOT_FOUND" 에러

**원인:**
- Firebase Authentication Email/Password 로그인 비활성화
- Firebase 프로젝트가 올바르게 연결되지 않음

**해결:**
1. Firebase Console → Authentication → Sign-in method
2. Email/Password **사용 설정** 확인
3. 앱 재빌드: `flutter clean && flutter run`

---

### 문제 2: Firestore 저장 실패

**원인:**
- Firestore Database가 생성되지 않음
- 보안 규칙이 너무 엄격함

**해결:**
1. Firebase Console → Firestore Database 생성
2. 규칙 탭 → 테스트 모드로 변경
3. **게시** 버튼 클릭

---

### 문제 3: google-services.json 파일이 없음

**원인:**
- Firebase 프로젝트에 Android 앱 등록 안 됨

**해결:**
1. Firebase Console → 프로젝트 설정 (⚙️)
2. **내 앱** → Android 앱 추가
3. **패키지 이름:** `com.example.projects` 입력
4. `google-services.json` 다운로드
5. 파일을 `android/app/` 폴더에 복사

```bash
cp ~/Downloads/google-services.json /Users/jun/Documents/GitHub/911Calling/android/app/
```

---

### 문제 4: "email-already-in-use" 에러

**원인:**
- 이미 가입된 이메일로 재가입 시도

**해결:**
1. 다른 이메일로 테스트
2. 또는 Firebase Console → Authentication → Users
3. 기존 사용자 삭제 후 재시도

---

## 📊 Firebase 프로젝트 확인

### 현재 연결된 프로젝트 확인

**Android:**
```bash
cat /Users/jun/Documents/GitHub/911Calling/android/app/google-services.json | grep project_id
```

**iOS:**
```bash
cat /Users/jun/Documents/GitHub/911Calling/ios/Runner/GoogleService-Info.plist | grep PROJECT_ID
```

---

## 🧪 테스트 방법

### 1. 회원가입 테스트

```
1. 앱 실행
2. "회원가입" 버튼 클릭
3. 이메일: test@example.com
4. 비밀번호: test1234
5. 이름: 테스터
6. 전화번호: 010-1234-5678
7. "건너뛰기" 클릭 (전화번호 인증)
8. 보호자: mom / 010-0000-9393
9. "회원가입" 버튼 클릭
```

**성공 시:**
- "회원가입이 완료되었습니다!" 메시지
- 홈 화면으로 이동

**실패 시:**
- Firebase Console 설정 재확인
- 로그 확인: 터미널에서 에러 메시지 확인

---

### 2. Firebase Console에서 확인

#### Authentication 확인
1. Firebase Console → Authentication → Users
2. 방금 가입한 사용자 이메일이 보이면 ✅ 성공

#### Firestore 확인
1. Firebase Console → Firestore Database
2. `users` 컬렉션 → 사용자 문서 확인
3. 이메일, 이름, 전화번호 등 데이터가 저장되어 있으면 ✅ 성공

---

## 🎓 설정 완료 후 앱 동작

### 회원가입 플로우 (정상 작동)

```
1. 이메일/비밀번호/이름 입력
   ↓
2. 전화번호 입력 → "건너뛰기" (Phone Auth 설정 없을 경우)
   ↓
3. 질환/병명/보호자 정보 입력
   ↓
4. "회원가입" 버튼 클릭
   ↓
5. Firebase Auth 계정 생성 ✅
   ↓
6. Firestore 사용자 문서 저장 ✅
   ↓
7. 홈 화면으로 이동 ✅
```

---

## 📚 참고 자료

### Firebase 공식 문서
- [Firebase Authentication 시작하기](https://firebase.google.com/docs/auth/flutter/start)
- [Cloud Firestore 시작하기](https://firebase.google.com/docs/firestore/quickstart)
- [Flutter Firebase Setup](https://firebase.flutter.dev/docs/overview)

### Flutter 공식 문서
- [firebase_core 패키지](https://pub.dev/packages/firebase_core)
- [firebase_auth 패키지](https://pub.dev/packages/firebase_auth)
- [cloud_firestore 패키지](https://pub.dev/packages/cloud_firestore)

---

## ⚡ 빠른 설정 가이드 (요약)

### 필수 3단계

1️⃣ **Firebase Console → Authentication → Email/Password 활성화**

2️⃣ **Firebase Console → Firestore Database 생성 (테스트 모드)**

3️⃣ **앱 재시작: `flutter run`**

---

## 💡 추가 팁

### 개발 단계
- ✅ Firestore 테스트 모드 사용
- ✅ 전화번호 인증 건너뛰기 활용
- ✅ 테스트 이메일 여러 개 준비 (test1@example.com, test2@example.com...)

### 프로덕션 배포 전
- ⚠️ Firestore 보안 규칙 강화
- ⚠️ Phone Authentication 설정 완료
- ⚠️ SHA-1 지문 등록 (Android)
- ⚠️ APNs 인증서 등록 (iOS)

---

## 🔧 현재 앱의 임시 해결책

만약 Firebase 설정을 완료할 수 없는 상황이라면, 현재 코드는 다음과 같이 동작합니다:

1. **Firebase Auth 실패 시:**
   - 명확한 에러 메시지 표시
   - 설정 방법 안내

2. **Firestore 실패 시:**
   - Auth 계정은 생성됨
   - 프로필 정보는 나중에 입력 가능
   - 로그인은 정상 작동

이렇게 하면 일부 기능은 제한되지만 앱을 계속 사용할 수 있습니다.

---

**작성일:** 2024년 11월 26일  
**문서 버전:** 1.0  
**대상:** Firebase 초기 설정을 위한 가이드
