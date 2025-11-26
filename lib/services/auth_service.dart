import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firebase Authentication 서비스
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 로그인된 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  // 현재 사용자 UID
  String? get currentUserId => _auth.currentUser?.uid;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 이메일/비밀번호로 회원가입
  ///
  /// 주의: 이 메서드는 Firebase Auth에만 사용자를 생성합니다.
  /// Firestore 문서 생성은 FirestoreService에서 별도로 처리해야 합니다.
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 이메일 회원가입 시작: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase Auth 사용자 생성 완료: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ 회원가입 실패: ${e.code} - ${e.message}');

      // 한글 에러 메시지
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = '이미 사용 중인 이메일입니다.';
          break;
        case 'invalid-email':
          errorMessage = '유효하지 않은 이메일 형식입니다.';
          break;
        case 'operation-not-allowed':
          errorMessage = '이메일/비밀번호 로그인이 비활성화되어 있습니다.';
          break;
        case 'weak-password':
          errorMessage = '비밀번호가 너무 약합니다. (최소 6자 이상)';
          break;
        default:
          errorMessage = '회원가입 중 오류가 발생했습니다: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('❌ 알 수 없는 오류: $e');
      throw Exception('회원가입 중 알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 이메일/비밀번호로 로그인
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 이메일 로그인 시도: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ 로그인 성공: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ 로그인 실패: ${e.code} - ${e.message}');

      // 한글 에러 메시지
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '가입되지 않은 이메일입니다.';
          break;
        case 'wrong-password':
          errorMessage = '비밀번호가 올바르지 않습니다.';
          break;
        case 'invalid-email':
          errorMessage = '유효하지 않은 이메일 형식입니다.';
          break;
        case 'user-disabled':
          errorMessage = '비활성화된 계정입니다.';
          break;
        case 'too-many-requests':
          errorMessage = '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.';
          break;
        default:
          errorMessage = '로그인 중 오류가 발생했습니다: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('❌ 알 수 없는 오류: $e');
      throw Exception('로그인 중 알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      print('🔓 로그아웃 시작');
      await _auth.signOut();
      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 실패: $e');
      throw Exception('로그아웃 중 오류가 발생했습니다.');
    }
  }

  /// 전화번호 인증 - 인증번호 전송
  ///
  /// [phoneNumber] 형식: +82 10-1234-5678 또는 +821012345678
  /// [verificationCompleted] 자동 인증 완료 시 호출 (Android Only)
  /// [verificationFailed] 인증 실패 시 호출
  /// [codeSent] 인증번호 전송 완료 시 호출
  /// [codeAutoRetrievalTimeout] 자동 검색 타임아웃 시 호출
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    try {
      print('📱 전화번호 인증 시작: $phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          print('✅ 자동 인증 완료 (Android)');
          verificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ 인증 실패: ${e.code} - ${e.message}');
          verificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ 인증번호 전송 완료');
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ 자동 검색 타임아웃');
          codeAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      print('❌ 전화번호 인증 오류: $e');
      throw Exception('전화번호 인증 중 오류가 발생했습니다.');
    }
  }

  /// 인증번호로 PhoneAuthCredential 생성
  PhoneAuthCredential createPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// PhoneAuthCredential로 인증 (회원가입 전 전화번호 검증용)
  Future<bool> verifyPhoneCredential(PhoneAuthCredential credential) async {
    try {
      print('📱 전화번호 인증 시도');

      // 임시로 로그인하여 전화번호 인증 확인
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        print('✅ 전화번호 인증 성공');

        // 인증 후 임시 계정 삭제 (회원가입 전이므로)
        await userCredential.user!.delete();
        print('🗑️ 임시 인증 계정 삭제 완료');

        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ 전화번호 인증 실패: ${e.code} - ${e.message}');

      if (e.code == 'invalid-verification-code') {
        throw Exception('인증번호가 올바르지 않습니다.');
      } else if (e.code == 'session-expired') {
        throw Exception('인증 시간이 만료되었습니다. 다시 시도해주세요.');
      }

      throw Exception('전화번호 인증에 실패했습니다: ${e.message}');
    } catch (e) {
      print('❌ 알 수 없는 오류: $e');
      throw Exception('전화번호 인증 중 오류가 발생했습니다.');
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ 비밀번호 재설정 이메일 전송 완료');
    } catch (e) {
      print('❌ 비밀번호 재설정 실패: $e');
      throw Exception('비밀번호 재설정 이메일 전송에 실패했습니다.');
    }
  }

  /// 이메일 인증 링크 전송
  ///
  /// 회원가입 후 사용자의 이메일로 인증 링크를 전송합니다.
  /// 사용자가 링크를 클릭하면 emailVerified가 true로 변경됩니다.
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      if (user.emailVerified) {
        print('✅ 이미 이메일 인증이 완료된 사용자입니다.');
        return;
      }

      await user.sendEmailVerification();
      print('✅ 이메일 인증 링크 전송 완료: ${user.email}');
    } on FirebaseAuthException catch (e) {
      print('❌ 이메일 인증 전송 실패: ${e.code} - ${e.message}');

      if (e.code == 'too-many-requests') {
        throw Exception('너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.');
      }

      throw Exception('이메일 인증 링크 전송에 실패했습니다.');
    } catch (e) {
      print('❌ 알 수 없는 오류: $e');
      throw Exception('이메일 인증 중 오류가 발생했습니다.');
    }
  }

  /// 현재 사용자 정보 새로고침
  ///
  /// 이메일 인증 상태를 업데이트하기 위해 호출합니다.
  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        print('✅ 사용자 정보 새로고침 완료');
      }
    } catch (e) {
      print('❌ 사용자 정보 새로고침 실패: $e');
      throw Exception('사용자 정보 새로고침에 실패했습니다.');
    }
  }

  /// 이메일 인증 여부 확인
  ///
  /// 현재 사용자의 이메일 인증 여부를 반환합니다.
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// 사용자 삭제
  Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        print('✅ 사용자 삭제 완료');
      }
    } catch (e) {
      print('❌ 사용자 삭제 실패: $e');
      throw Exception('사용자 삭제에 실패했습니다.');
    }
  }
}
