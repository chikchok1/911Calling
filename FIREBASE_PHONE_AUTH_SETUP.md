# 🔥 Firebase Phone Authentication 설정 가이드

## ⚠️ 현재 문제 상황

회원가입 화면에서 전화번호 인증 시 다음과 같은 에러가 발생합니다:

```
오류
전화번호 인증 설정이 완료되지 않았습니다.

An internal error has occurred.
[ CONFIGURATION_NOT_FOUND ]
```

## 🎯 해결 방법

### 임시 해결책 (현재 적용됨) ✅

**전화번호 인증을 건너뛸 수 있도록 수정했습니다.**

1. "인증번호 전송" 버튼 클릭
2. CONFIGURATION_NOT_FOUND 에러 발생 시
3. **"건너뛰기" 버튼 표시**
4. 건너뛰기 클릭 → 전화번호 인증 없이 회원가입 가능

### 완전 해결책 (Firebase 설정 필요)

Firebase Phone Authentication을 완전히 활성화하려면 다음 단계를 따르세요.

---

## 📱 Android 설정

### 1. Firebase Console 설정

#### 1.1 Authentication 활성화

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택
3. **Authentication** → **Sign-in method**
4. **Phone** 클릭 → **사용 설정**

#### 1.2 SHA-1 지문 등록 (필수!)

Phone Auth는 Android에서 SHA-1 인증서 지문이 **필수**입니다.

**디버그 SHA-1 가져오기:**

```bash
cd /Users/jun/Documents/GitHub/911Calling/android

# macOS/Linux
./gradlew signingReport

# 또는
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**출력 예시:**
```
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

**Firebase Console에 등록:**

1. Firebase Console → **프로젝트 설정** (⚙️)
2. **내 앱** → Android 앱 선택
3. **SHA 인증서 지문** 섹션
4. **지문 추가** 버튼 클릭
5. SHA-1 값 입력

#### 1.3 google-services.json 다운로드

SHA-1 지문을 추가한 후 **새로운 `google-services.json` 파일을 다운로드**해야 합니다.

1. Firebase Console → 프로젝트 설정 → 내 앱
2. **google-services.json 다운로드**
3. 파일을 `android/app/` 폴더에 복사 (기존 파일 덮어쓰기)

```bash
cp ~/Downloads/google-services.json /Users/jun/Documents/GitHub/911Calling/android/app/
```

---

### 2. Android 코드 설정

#### 2.1 build.gradle 확인

**`android/build.gradle`** (프로젝트 레벨)

```gradle
buildscript {
    dependencies {
        // Firebase
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**`android/app/build.gradle`** (앱 레벨)

```gradle
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'  // ← 이 줄 필수!

android {
    defaultConfig {
        minSdkVersion 23  // Phone Auth는 최소 API 23 필요
        targetSdkVersion 34
    }
}

dependencies {
    // Firebase
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-auth'
}
```

#### 2.2 AndroidManifest.xml 확인

**`android/app/src/main/AndroidManifest.xml`**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 인터넷 권한 -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application
        android:name="${applicationName}"
        android:label="911Calling">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

---

### 3. 앱 재빌드

설정을 변경한 후 **반드시 클린 빌드**를 해야 합니다.

```bash
cd /Users/jun/Documents/GitHub/911Calling

# Flutter 클린
flutter clean

# 패키지 재설치
flutter pub get

# Android 빌드 클린
cd android
./gradlew clean
cd ..

# 앱 실행
flutter run
```

---

## 🍎 iOS 설정 (선택)

### 1. Firebase Console 설정

1. Authentication → Phone 활성화 (Android와 동일)

### 2. iOS 코드 설정

#### 2.1 Info.plist 설정

**`ios/Runner/Info.plist`**

```xml
<dict>
    <!-- 기존 설정들... -->
    
    <!-- Firebase Phone Auth용 URL Scheme -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <!-- GoogleService-Info.plist에서 REVERSED_CLIENT_ID 복사 -->
                <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
            </array>
        </dict>
    </array>
</dict>
```

**REVERSED_CLIENT_ID 찾기:**

`ios/Runner/GoogleService-Info.plist` 파일을 열고 `REVERSED_CLIENT_ID` 값을 찾습니다.

```xml
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.123456789012-abcdefg</string>
```

#### 2.2 Podfile 설정

**`ios/Podfile`**

```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

#### 2.3 iOS 재빌드

```bash
cd /Users/jun/Documents/GitHub/911Calling/ios
pod install
cd ..
flutter clean
flutter run
```

---

## 🧪 테스트 전화번호 설정 (권장)

실제 SMS를 보내지 않고 테스트하려면 **테스트 전화번호**를 설정하세요.

### Firebase Console 설정

1. Firebase Console → **Authentication**
2. **Sign-in method** → **Phone**
3. **테스트 전화번호** 섹션 확장
4. **전화번호 추가**

**예시:**
```
전화번호: +821012345678
인증 코드: 123456
```

이제 앱에서 `+821012345678`로 인증 시 실제 SMS 없이 `123456`을 입력하면 인증됩니다.

---

## 📊 Firebase 할당량 확인

### 무료 요금제 (Spark Plan)

- **하루 10,000회** 인증 요청 (무료)
- 초과 시 자동으로 차단됨

### 유료 요금제 (Blaze Plan)

- 10,000회 이후 **$0.06/인증** (약 70원)
- 월 50,000회 사용 시: $2,400 (약 3,000원)

**할당량 확인:**
Firebase Console → **Usage** → **Authentication**

---

## 🔍 문제 해결

### 문제 1: CONFIGURATION_NOT_FOUND

**원인:**
- SHA-1 지문이 등록되지 않음
- google-services.json이 오래된 버전
- Firebase Console에서 Phone Auth 비활성화

**해결:**
1. SHA-1 지문 확인 및 재등록
2. google-services.json 재다운로드
3. Phone Auth 활성화 확인
4. 앱 완전히 재빌드 (`flutter clean`)

---

### 문제 2: SMS가 전송되지 않음

**원인:**
- 전화번호 형식이 잘못됨
- Firebase 할당량 초과
- 통신사에서 SMS 차단

**해결:**
1. 전화번호 형식 확인: `+821012345678`
2. Firebase Console에서 할당량 확인
3. 테스트 전화번호로 테스트

---

### 문제 3: "too-many-requests" 에러

**원인:**
- 같은 전화번호로 너무 많은 요청

**해결:**
1. 1시간 대기 후 재시도
2. 테스트 전화번호 사용
3. 다른 전화번호로 테스트

---

### 문제 4: "invalid-phone-number" 에러

**원인:**
- 전화번호 형식 오류

**해결:**
```dart
// ✅ 올바른 형식
+821012345678  // 한국
+14155552671  // 미국

// ❌ 잘못된 형식
010-1234-5678
01012345678
```

---

## 📝 현재 앱 동작 방식

### 회원가입 플로우

```
1. 사용자가 전화번호 입력
   ↓
2. "인증번호 전송" 버튼 클릭
   ↓
3-1. Firebase 설정이 완료된 경우
     → SMS 전송 → 인증번호 입력 → 인증 완료
   
3-2. Firebase 설정이 없는 경우 (CONFIGURATION_NOT_FOUND)
     → 에러 다이얼로그 표시
     → "건너뛰기" 버튼 클릭 가능 ✅
     → 전화번호 인증 없이 회원가입 가능
```

### 코드 변경 사항

**signup_screen.dart 수정:**

1. **전화번호 인증 건너뛰기 기능 추가**
   ```dart
   void _skipPhoneVerification() {
     setState(() {
       _isPhoneVerified = true;
       _isCodeSent = false;
     });
     _showSuccessDialog('전화번호 인증을 건너뛰었습니다.');
   }
   ```

2. **에러 다이얼로그에 "건너뛰기" 버튼 추가**
   ```dart
   void _showErrorDialog(String message, {bool showSkipButton = false}) {
     // ...
     if (showSkipButton)
       TextButton(
         onPressed: () {
           Navigator.of(context).pop();
           _skipPhoneVerification();
         },
         child: const Text('건너뛰기'),
       ),
   }
   ```

3. **UI 항상 스크롤 가능하도록 수정**
   - Stack 구조로 변경
   - 로딩 오버레이 방식 적용

---

## ✅ 권장 사항

### 개발 단계

1. **테스트 전화번호 사용** (SMS 비용 절약)
2. **전화번호 인증 건너뛰기** 활용 (현재 구현됨)
3. 회원가입 테스트는 이메일/비밀번호만으로 진행

### 프로덕션 배포 전

1. **SHA-1 지문 등록** (디버그 + 릴리즈)
2. **Firebase Phone Auth 활성화**
3. **할당량 모니터링** 설정
4. **테스트 전화번호 삭제**

---

## 📚 참고 자료

### Firebase 공식 문서

- [Firebase Phone Authentication](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [SHA-1 인증서 지문](https://developers.google.com/android/guides/client-auth)
- [테스트 전화번호 설정](https://firebase.google.com/docs/auth/android/phone-auth#test-with-whitelisted-phone-numbers)

### Flutter 공식 문서

- [firebase_auth 패키지](https://pub.dev/packages/firebase_auth)
- [Phone Number Verification](https://firebase.flutter.dev/docs/auth/phone)

---

## 🎓 결론

현재 앱은 **전화번호 인증 없이도 회원가입이 가능**하도록 구현되어 있습니다.

Firebase Phone Auth 설정이 완료되면 자동으로 정상 작동하며, 설정이 없어도 사용자는 "건너뛰기" 버튼을 통해 회원가입을 진행할 수 있습니다.

프로덕션 배포 시에는 이 가이드를 따라 Firebase Phone Auth를 완전히 활성화하는 것을 권장합니다.

---

**작성일:** 2024년 11월 26일  
**문서 버전:** 1.0  
**마지막 업데이트:** 2024-11-26
