import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 정보 모델
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final bool verifiedPhone;
  final List<String> diseaseHistory;      // 질환 정보
  final List<String> medicalRecords;      // 과거 병명
  final List<EmergencyContact> emergencyContacts; // 보호자 연락처
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.verifiedPhone,
    required this.diseaseHistory,
    required this.medicalRecords,
    required this.emergencyContacts,
    required this.createdAt,
  });

  /// Firestore에서 가져온 데이터를 UserModel로 변환
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      verifiedPhone: data['verifiedPhone'] ?? false,
      diseaseHistory: List<String>.from(data['diseaseHistory'] ?? []),
      medicalRecords: List<String>.from(data['medicalRecords'] ?? []),
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>? ?? [])
          .map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// UserModel을 Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'verifiedPhone': verifiedPhone,
      'diseaseHistory': diseaseHistory,
      'medicalRecords': medicalRecords,
      'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// copyWith 메서드 (업데이트 시 사용)
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phoneNumber,
    bool? verifiedPhone,
    List<String>? diseaseHistory,
    List<String>? medicalRecords,
    List<EmergencyContact>? emergencyContacts,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verifiedPhone: verifiedPhone ?? this.verifiedPhone,
      diseaseHistory: diseaseHistory ?? this.diseaseHistory,
      medicalRecords: medicalRecords ?? this.medicalRecords,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 보호자/가족 연락처 모델
class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.phone,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}
