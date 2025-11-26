import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Firestore 데이터베이스 서비스
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // users 컬렉션 참조
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 새로운 사용자 문서 생성
  ///
  /// [uid] Firebase Auth에서 생성된 사용자 UID
  /// [email] 이메일
  /// [name] 이름
  /// [phoneNumber] 전화번호
  /// [verifiedPhone] 전화번호 인증 여부 (필수: true)
  /// [diseaseHistory] 질환 정보 리스트
  /// [medicalRecords] 과거 병명 리스트
  /// [emergencyContacts] 보호자 연락처 리스트
  Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    required String phoneNumber,
    required bool verifiedPhone,
    required List<String> diseaseHistory,
    required List<String> medicalRecords,
    required List<EmergencyContact> emergencyContacts,
  }) async {
    try {
      print('\n=== Firestore 사용자 문서 생성 시작 ===');
      print('UID: $uid');
      print('Email: $email');
      print('Name: $name');
      print('PhoneNumber: $phoneNumber');
      print('VerifiedPhone: $verifiedPhone');

      final userModel = UserModel(
        uid: uid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        verifiedPhone: verifiedPhone,
        diseaseHistory: diseaseHistory,
        medicalRecords: medicalRecords,
        emergencyContacts: emergencyContacts,
        createdAt: DateTime.now(),
      );

      await _usersCollection.doc(uid).set(userModel.toFirestore());

      print('✅ Firestore 사용자 문서 생성 완료!');
    } catch (e) {
      print('❌ Firestore 사용자 생성 실패: $e');
      throw Exception('사용자 정보 저장에 실패했습니다.');
    }
  }

  /// 사용자 정보 가져오기
  Future<UserModel?> getUser(String uid) async {
    try {
      print('\n=== Firestore 사용자 조회: $uid ===');

      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) {
        print('⚠️ 사용자 문서가 존재하지 않습니다.');
        return null;
      }

      final user = UserModel.fromFirestore(doc);
      print('✅ 사용자 조회 완료: ${user.name}');

      return user;
    } catch (e) {
      print('❌ 사용자 조회 실패: $e');
      return null;
    }
  }

  /// 사용자 정보 실시간 스트림
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        print('⚠️ 사용자 문서가 존재하지 않습니다.');
        return null;
      }
      return UserModel.fromFirestore(doc);
    });
  }

  /// 사용자 정보 업데이트
  Future<void> updateUser({
    required String uid,
    String? name,
    String? phoneNumber,
    List<String>? diseaseHistory,
    List<String>? medicalRecords,
    List<EmergencyContact>? emergencyContacts,
  }) async {
    try {
      print('\n=== Firestore 사용자 정보 업데이트: $uid ===');

      final Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (diseaseHistory != null) updates['diseaseHistory'] = diseaseHistory;
      if (medicalRecords != null) updates['medicalRecords'] = medicalRecords;
      if (emergencyContacts != null) {
        updates['emergencyContacts'] = emergencyContacts
            .map((e) => e.toMap())
            .toList();
      }

      if (updates.isEmpty) {
        print('⚠️ 업데이트할 항목이 없습니다.');
        return;
      }

      await _usersCollection.doc(uid).update(updates);
      print('✅ 사용자 정보 업데이트 완료!');
    } catch (e) {
      print('❌ 사용자 정보 업데이트 실패: $e');
      throw Exception('사용자 정보 업데이트에 실패했습니다.');
    }
  }

  /// 질환 정보 추가
  Future<void> addDiseaseHistory(String uid, String disease) async {
    try {
      print('➕ 질환 추가: $disease');

      await _usersCollection.doc(uid).update({
        'diseaseHistory': FieldValue.arrayUnion([disease]),
      });

      print('✅ 질환 추가 완료');
    } catch (e) {
      print('❌ 질환 추가 실패: $e');
      throw Exception('질환 추가에 실패했습니다.');
    }
  }

  /// 질환 정보 삭제
  Future<void> removeDiseaseHistory(String uid, String disease) async {
    try {
      print('➖ 질환 삭제: $disease');

      await _usersCollection.doc(uid).update({
        'diseaseHistory': FieldValue.arrayRemove([disease]),
      });

      print('✅ 질환 삭제 완료');
    } catch (e) {
      print('❌ 질환 삭제 실패: $e');
      throw Exception('질환 삭제에 실패했습니다.');
    }
  }

  /// 과거 병명 추가
  Future<void> addMedicalRecord(String uid, String record) async {
    try {
      print('➕ 병명 추가: $record');

      await _usersCollection.doc(uid).update({
        'medicalRecords': FieldValue.arrayUnion([record]),
      });

      print('✅ 병명 추가 완료');
    } catch (e) {
      print('❌ 병명 추가 실패: $e');
      throw Exception('병명 추가에 실패했습니다.');
    }
  }

  /// 과거 병명 삭제
  Future<void> removeMedicalRecord(String uid, String record) async {
    try {
      print('➖ 병명 삭제: $record');

      await _usersCollection.doc(uid).update({
        'medicalRecords': FieldValue.arrayRemove([record]),
      });

      print('✅ 병명 삭제 완료');
    } catch (e) {
      print('❌ 병명 삭제 실패: $e');
      throw Exception('병명 삭제에 실패했습니다.');
    }
  }

  /// 보호자 연락처 추가
  Future<void> addEmergencyContact(String uid, EmergencyContact contact) async {
    try {
      print('➕ 보호자 추가: ${contact.name} (${contact.phone})');

      await _usersCollection.doc(uid).update({
        'emergencyContacts': FieldValue.arrayUnion([contact.toMap()]),
      });

      print('✅ 보호자 추가 완료');
    } catch (e) {
      print('❌ 보호자 추가 실패: $e');
      throw Exception('보호자 연락처 추가에 실패했습니다.');
    }
  }

  /// 보호자 연락처 삭제
  Future<void> removeEmergencyContact(
    String uid,
    EmergencyContact contact,
  ) async {
    try {
      print('➖ 보호자 삭제: ${contact.name} (${contact.phone})');

      await _usersCollection.doc(uid).update({
        'emergencyContacts': FieldValue.arrayRemove([contact.toMap()]),
      });

      print('✅ 보호자 삭제 완료');
    } catch (e) {
      print('❌ 보호자 삭제 실패: $e');
      throw Exception('보호자 연락처 삭제에 실패했습니다.');
    }
  }

  /// 사용자 문서 삭제
  Future<void> deleteUser(String uid) async {
    try {
      print('🗑️ 사용자 문서 삭제: $uid');

      await _usersCollection.doc(uid).delete();

      print('✅ 사용자 문서 삭제 완료');
    } catch (e) {
      print('❌ 사용자 문서 삭제 실패: $e');
      throw Exception('사용자 정보 삭제에 실패했습니다.');
    }
  }

  /// 전화번호 인증 여부 확인
  Future<bool> isPhoneVerified(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      return data['verifiedPhone'] ?? false;
    } catch (e) {
      print('❌ 전화번호 인증 확인 실패: $e');
      return false;
    }
  }
}
