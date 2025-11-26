# 🔐 Firebase Authentication + Firestore 로그인 시스템 구현

## 📋 개요

119 긴급신고 앱에 **Firebase Authentication**과 **Firestore Database** 기반의 완전한 회원 관리 시스템을 구현했습니다.

### 주요 기능
- ✅ **회원가입** (전화번호 인증 필수)
- ✅ **로그인** (인증된 사용자만 접근)
- ✅ **로그아웃**
- ✅ **내 정보 관리** (실시간 업데이트)
- ✅ **질환 정보 관리**
- ✅ **과거 병명 관리**
- ✅ **보호자 연락처 관리**

---

## 🗂️ 프로젝트 구조

```
lib/
├── models/
│   └── user_model.dart              # 사용자 데이터 모델
├── services/
│   ├── auth_service.dart            # Firebase Auth 서비스
│   ├── firestore_service.dart       # Firestore DB 서비스
│   ├── directions_service.dart
│   ├── location_service.dart
│   ├── aed_service.dart
│   └── public_aed_api_service.dart
├── screens/
│   ├── auth/
│   │   ├── signup_screen.dart       # 회원가입 화면
│   │   └── login_screen.dart        # 로그인 화면
│   ├── profile/
│   │   └── profile_screen.dart      # 내 정보 화면
│   └── home_screen.dart
├── tabs/
│   ├── emergency_tab.dart
│   ├── guide_tab.dart
│   ├── ai_analysis_tab.dart
│   └── aed_locator_tab.dart
├── config/
├── main.dart                        # 앱 진입점 (인증 상태 관리)
└── firebase_options.dart
```

---

## 📦 패키지 의존성

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^4.2.1
  firebase_auth: ^5.3.3          # ⭐ 신규 추가
  cloud_firestore: ^6.1.0
  
  # 기타
  http: ^1.2.2
  geolocator: ^13.0.2
  permission_handler: ^11.3.1
  # ...
```

---

## 🔥 Firestore 데이터베이스 구조

### Collection: `users`

```javascript
users/{uid}/
  {
    email: "user@example.com",
    name: "홍길동",
    phoneNumber: "+821012345678",
    verifiedPhone: true,              // 전화번호 인증 여부 (필수)
    diseaseHistory: [                 // 보유 질환
      "고혈압",
      "당뇨"
    ],
    medicalRecords: [                 // 과거 병명
      "심근경색",
      "뇌졸중"
    ],
    emergencyContacts: [              // 보호자 연락처 (최소 1명)
      {
        name: "김보호",
        phone: "010-9876-5432"
      }
    ],
    createdAt: Timestamp(2024, 11, 25)
  }
```

---

## 📱 화면별 기능 설명

### 1. 회원가입 화면 (`signup_screen.dart`)

#### 입력 필드
| 필드 | 설명 | 필수 | 검증 |
|------|------|------|------|
| 이메일 | 로그인 ID | ✅ | `@` 포함 여부 |
| 비밀번호 | 최소 6자 | ✅ | 길이 검증 |
| 비밀번호 확인 | 일치 확인 | ✅ | 동일성 검증 |
| 이름 | 사용자 이름 | ✅ | 공백 불가 |
| 전화번호 | +82 형식 | ✅ | 전화번호 인증 필수 |
| 질환 정보 | 여러 개 입력 가능 | ❌ | - |
| 과거 병명 | 여러 개 입력 가능 | ❌ | - |
| 보호자 연락처 | 이름 + 전화번호 | ✅ | 최소 1명 |

#### 전화번호 인증 프로세스

```
1. 사용자가 전화번호 입력 (예: 010-1234-5678)
   ↓
2. 자동으로 +82 형식 변환 (+821012345678)
   ↓
3. Firebase Phone Auth로 인증번호 전송
   ↓
4. SMS로 받은 6자리 인증번호 입력
   ↓
5. 인증번호 검증
   ↓
6. ✅ 인증 완료 (녹색 체크 표시)
   ↓
7. 회원가입 버튼 활성화
```

#### 주요 함수
```dart
// 전화번호 인증 시작
Future<void> _sendVerificationCode()

// 인증번호 확인
Future<void> _verifyCode()

// 회원가입 실행
Future<void> _signUp()
```

#### 회원가입 절차
```dart
1. Firebase Auth 사용자 생성 (Email/Password)
   final user = await _authService.signUpWithEmail(email, password);

2. Firestore 사용자 문서 생성
   await _firestoreService.createUser(
     uid: user.uid,
     email: email,
     name: name,
     phoneNumber: phoneNumber,
     verifiedPhone: true,  // ⚠️ 필수
     diseaseHistory: [...],
     medicalRecords: [...],
     emergencyContacts: [...],
   );

3. 홈 화면으로 이동
   Navigator.pushReplacement(HomeScreen());
```

---

### 2. 로그인 화면 (`login_screen.dart`)

#### 로그인 절차

```dart
1. 이메일/비밀번호로 Firebase Auth 로그인
   final user = await _authService.signInWithEmail(email, password);

2. Firestore에서 사용자 정보 조회
   final userData = await _firestoreService.getUser(user.uid);

3. 전화번호 인증 여부 확인
   if (!userData.verifiedPhone) {
     await _authService.signOut();
     throw Exception('전화번호 인증이 완료되지 않은 계정입니다.');
   }

4. ✅ 로그인 성공 → HomeScreen 이동
```

#### 주요 기능
- ✅ 이메일/비밀번호 로그인
- ✅ 비밀번호 표시/숨기기 토글
- ✅ 비밀번호 재설정 이메일 전송
- ✅ 회원가입 화면 이동
- ✅ **전화번호 미인증 사용자 차단**

---

### 3. 내 정보 화면 (`profile_screen.dart`)

#### 표시 정보
- 👤 프로필 (이름, 이메일)
- 📱 전화번호 + 인증 상태
- 💊 보유 질환 정보 (Chip UI)
- 🏥 과거 진단 병명 (Chip UI)
- 👨‍👩‍👧 보호자 연락처 (Card UI)
- 📅 가입일

#### 실시간 업데이트 기능

```dart
// 질환 추가
await _firestoreService.addDiseaseHistory(uid, "고혈압");

// 질환 삭제
await _firestoreService.removeDiseaseHistory(uid, "고혈압");

// 병명 추가
await _firestoreService.addMedicalRecord(uid, "심근경색");

// 병명 삭제
await _firestoreService.removeMedicalRecord(uid, "심근경색");

// 보호자 추가
await _firestoreService.addEmergencyContact(uid, 
  EmergencyContact(name: "김보호", phone: "010-1234-5678")
);

// 보호자 삭제
await _firestoreService.removeEmergencyContact(uid, contact);
```

#### UI 특징
- 🔄 **당겨서 새로고침** (RefreshIndicator)
- 📊 **실시간 Firestore 연동**
- 🔴 질환 Chip (빨간색)
- 🟠 병명 Chip (주황색)
- 🟢 보호자 Card (아이콘 + 이름 + 전화번호)

---

## 🛠️ 서비스 계층 구조

### 1. AuthService (`auth_service.dart`)

Firebase Authentication 전담 서비스

```dart
class AuthService {
  // 회원가입
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  });

  // 로그인
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  });

  // 로그아웃
  Future<void> signOut();

  // 전화번호 인증 시작
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  });

  // 인증번호 검증
  Future<bool> verifyPhoneCredential(PhoneAuthCredential credential);

  // 비밀번호 재설정
  Future<void> sendPasswordResetEmail(String email);

  // 사용자 삭제
  Future<void> deleteUser();
}
```

#### 에러 처리 (한글 메시지)

| Firebase 에러 코드 | 한글 메시지 |
|-------------------|------------|
| `email-already-in-use` | 이미 사용 중인 이메일입니다. |
| `invalid-email` | 유효하지 않은 이메일 형식입니다. |
| `weak-password` | 비밀번호가 너무 약합니다. (최소 6자 이상) |
| `user-not-found` | 가입되지 않은 이메일입니다. |
| `wrong-password` | 비밀번호가 올바르지 않습니다. |
| `invalid-verification-code` | 인증번호가 올바르지 않습니다. |
| `session-expired` | 인증 시간이 만료되었습니다. |

---

### 2. FirestoreService (`firestore_service.dart`)

Firestore 데이터베이스 전담 서비스

```dart
class FirestoreService {
  // 사용자 생성
  Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    required bool verifiedPhone,
    required List<String> diseaseHistory,
    required List<String> medicalRecords,
    required List<EmergencyContact> emergencyContacts,
  });

  // 사용자 조회
  Future<UserModel?> getUser(String uid);

  // 사용자 실시간 스트림
  Stream<UserModel?> getUserStream(String uid);

  // 사용자 업데이트
  Future<void> updateUser({
    required String uid,
    String? name,
    String? phoneNumber,
    List<String>? diseaseHistory,
    List<String>? medicalRecords,
    List<EmergencyContact>? emergencyContacts,
  });

  // 질환 관리
  Future<void> addDiseaseHistory(String uid, String disease);
  Future<void> removeDiseaseHistory(String uid, String disease);

  // 병명 관리
  Future<void> addMedicalRecord(String uid, String record);
  Future<void> removeMedicalRecord(String uid, String record);

  // 보호자 관리
  Future<void> addEmergencyContact(String uid, EmergencyContact contact);
  Future<void> removeEmergencyContact(String uid, EmergencyContact contact);

  // 사용자 삭제
  Future<void> deleteUser(String uid);

  // 전화번호 인증 확인
  Future<bool> isPhoneVerified(String uid);
}
```

---

## 🔐 인증 상태 관리

### main.dart

앱 시작 시 로그인 상태에 따라 화면 분기

```dart
home: StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    // 로딩 중
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 로그인 상태 확인
    if (snapshot.hasData && snapshot.data != null) {
      print('✅ 로그인된 사용자: ${snapshot.data!.uid}');
      return const HomeScreen();
    } else {
      print('⚠️ 로그인되지 않은 상태');
      return const LoginScreen();
    }
  },
)
```

---

## 📊 데이터 모델

### UserModel (`user_model.dart`)

```dart
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final bool verifiedPhone;
  final List<String> diseaseHistory;
  final List<String> medicalRecords;
  final List<EmergencyContact> emergencyContacts;
  final DateTime createdAt;

  // Firestore → UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc);

  // UserModel → Firestore
  Map<String, dynamic> toFirestore();

  // 업데이트용
  UserModel copyWith({...});
}

class EmergencyContact {
  final String name;
  final String phone;

  factory EmergencyContact.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap();
}
```

---

## 🚀 설치 및 실행

### 1. 패키지 설치

```bash
cd /Users/jun/Documents/GitHub/911Calling
flutter pub get
```

### 2. Firebase 프로젝트 설정

#### Firebase Console 설정
1. **Authentication 활성화**
   - Email/Password 로그인 활성화
   - Phone 로그인 활성화

2. **Firestore Database 생성**
   - 테스트 모드로 시작 (보안 규칙은 나중에 설정)

#### Android 설정 (Phone Auth)

`android/app/build.gradle` 확인:
```gradle
android {
    defaultConfig {
        minSdkVersion 23  // Phone Auth는 최소 API 23 필요
    }
}
```

Firebase Console → 프로젝트 설정:
- SHA-1 지문 추가 (디버그 + 릴리즈)

```bash
# SHA-1 지문 확인
cd android
./gradlew signingReport
```

#### iOS 설정 (Phone Auth)

`ios/Runner/Info.plist`에 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

---

### 3. 앱 실행

```bash
flutter run
```

---

## 📱 사용 플로우

### 회원가입 → 로그인 → 정보 관리

```
1. 앱 시작
   ↓
2. LoginScreen 표시 (미로그인 시)
   ↓
3. "회원가입" 버튼 클릭
   ↓
4. 이메일, 비밀번호, 이름 입력
   ↓
5. 전화번호 입력 → "인증번호 전송"
   ↓
6. SMS로 받은 6자리 코드 입력
   ↓
7. "인증번호 확인" → ✅ 인증 완료
   ↓
8. 질환/병명/보호자 정보 입력
   ↓
9. "회원가입" 버튼 클릭
   ↓
10. Firebase Auth + Firestore 저장
   ↓
11. HomeScreen 이동
   ↓
12. 하단 "내 정보" 탭으로 프로필 확인
   ↓
13. 질환/병명/보호자 추가/삭제 가능
   ↓
14. 우측 상단 로그아웃 버튼
   ↓
15. LoginScreen으로 복귀
```

---

## 🔒 보안 규칙 (Firestore Security Rules)

### 권장 설정

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // users 컬렉션: 본인만 읽기/쓰기 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 기타 컬렉션은 인증된 사용자만 읽기 가능
    match /{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

---

## ⚠️ 주의사항 및 알려진 제한

### 1. 전화번호 인증 제한사항

**Firebase Phone Auth 무료 할당량:**
- 하루 10,000회 인증 요청
- 초과 시 과금 발생

**테스트용 전화번호 설정:**
- Firebase Console → Authentication → Phone
- "테스트 전화번호" 추가 가능 (실제 SMS 전송 없이 테스트)

### 2. Android SHA-1 지문 필수

Phone Auth는 SHA-1 지문 등록 필수입니다.

```bash
# 디버그 SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# 릴리즈 SHA-1
keytool -list -v -keystore your-release-key.jks -alias your-alias
```

### 3. iOS APN 인증서 (Production 배포 시)

iOS에서 Phone Auth를 사용하려면:
- Apple Developer → Certificates → APNs Key 생성
- Firebase Console → 프로젝트 설정 → Cloud Messaging → iOS APNs 인증서 업로드

### 4. 전화번호 형식

앱에서 자동으로 +82 형식으로 변환하지만, 사용자에게 명확히 안내:
- ✅ `010-1234-5678`
- ✅ `01012345678`
- ✅ `+821012345678`

---

## 🐛 문제 해결

### 문제 1: "전화번호 인증이 작동하지 않아요"

**해결 방법:**
1. Firebase Console에서 Phone Auth 활성화 확인
2. Android SHA-1 지문 등록 확인
3. 앱 재빌드 (`flutter clean && flutter run`)
4. 로그 확인: `print` 문으로 인증 단계별 확인

### 문제 2: "로그인 후 바로 로그아웃돼요"

**원인:** Firestore에 사용자 문서가 없거나 `verifiedPhone: false`

**해결 방법:**
```dart
// Firestore Console에서 직접 확인
users/{uid}/verifiedPhone → true로 변경
```

### 문제 3: "Firestore 읽기/쓰기 권한 오류"

**원인:** Firestore Security Rules가 테스트 모드가 아님

**해결 방법:**
```javascript
// 임시로 모든 접근 허용 (개발 중)
allow read, write: if true;

// 또는 인증된 사용자만
allow read, write: if request.auth != null;
```

---

## 📈 향후 개선 사항

### 기능 추가
- [ ] 이메일 인증 추가 (Email Verification)
- [ ] 소셜 로그인 (Google, Apple)
- [ ] 프로필 이미지 업로드
- [ ] 회원 탈퇴 기능
- [ ] 비밀번호 변경 기능
- [ ] 알림 설정 (Push Notification)

### 보안 강화
- [ ] 2단계 인증 (2FA)
- [ ] 세션 타임아웃
- [ ] 비정상 로그인 감지
- [ ] Firestore Security Rules 강화

### UX 개선
- [ ] 로딩 애니메이션
- [ ] 에러 메시지 개선
- [ ] 오프라인 지원 (Firestore Persistence)
- [ ] 다국어 지원 (i18n)

---

## 📚 참고 자료

### Firebase 공식 문서
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Firebase Phone Auth](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)

### Flutter 공식 문서
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt)

---

## 📝 변경 이력

### v1.0.0 (2024-11-25)
- ✅ Firebase Authentication 통합
- ✅ 전화번호 인증 구현
- ✅ Firestore 사용자 관리
- ✅ 회원가입/로그인/로그아웃
- ✅ 프로필 관리 화면
- ✅ 질환/병명/보호자 CRUD
- ✅ 실시간 데이터 동기화

---

## 👥 기여자

- **개발자:** Albert (jun)
- **프로젝트:** 911Calling - 119 긴급신고 앱
- **날짜:** 2024년 11월 25일

---

## 📄 라이센스

이 프로젝트는 개인 프로젝트이며 상업적 사용을 금지합니다.

---

## 💡 문의

문제가 발생하거나 질문이 있으시면 GitHub Issues를 이용해주세요.

**프로젝트 저장소:** `/Users/jun/Documents/GitHub/911Calling`

---

**마지막 업데이트:** 2024년 11월 25일
