import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

/// 내 정보 페이지 (프로필)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 사용자 정보 로드
  Future<void> _loadUserData() async {
    final userId = _authService.currentUserId;

    if (userId == null) {
      print('❌ 로그인된 사용자가 없습니다.');
      _navigateToLogin();
      return;
    }

    try {
      final user = await _firestoreService.getUser(userId);

      if (user == null) {
        print('❌ 사용자 정보를 찾을 수 없습니다.');
        _navigateToLogin();
        return;
      }

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      print('✅ 사용자 정보 로드 완료: ${user.name}');
    } catch (e) {
      print('❌ 사용자 정보 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 로그인 화면으로 이동
  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// 로그아웃
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _authService.signOut();
      print('✅ 로그아웃 완료');
      _navigateToLogin();
    } catch (e) {
      print('❌ 로그아웃 실패: $e');
      _showErrorDialog('로그아웃 중 오류가 발생했습니다.');
    }
  }

  /// 질환 추가
  void _addDisease() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('질환 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '예: 고혈압, 당뇨',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final disease = controller.text.trim();
              if (disease.isEmpty) return;

              try {
                await _firestoreService.addDiseaseHistory(
                  _currentUser!.uid,
                  disease,
                );
                Navigator.of(context).pop();
                _loadUserData();
                _showSuccessMessage('질환이 추가되었습니다.');
              } catch (e) {
                _showErrorDialog('질환 추가에 실패했습니다.');
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  /// 질환 삭제
  Future<void> _removeDisease(String disease) async {
    final confirmed = await _showConfirmDialog('질환 삭제', '"$disease"를 삭제하시겠습니까?');
    if (!confirmed) return;

    try {
      await _firestoreService.removeDiseaseHistory(_currentUser!.uid, disease);
      _loadUserData();
      _showSuccessMessage('질환이 삭제되었습니다.');
    } catch (e) {
      _showErrorDialog('질환 삭제에 실패했습니다.');
    }
  }

  /// 병명 추가
  void _addMedicalRecord() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('병명 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '예: 심근경색, 뇌졸중',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final record = controller.text.trim();
              if (record.isEmpty) return;

              try {
                await _firestoreService.addMedicalRecord(
                  _currentUser!.uid,
                  record,
                );
                Navigator.of(context).pop();
                _loadUserData();
                _showSuccessMessage('병명이 추가되었습니다.');
              } catch (e) {
                _showErrorDialog('병명 추가에 실패했습니다.');
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  /// 병명 삭제
  Future<void> _removeMedicalRecord(String record) async {
    final confirmed = await _showConfirmDialog('병명 삭제', '"$record"를 삭제하시겠습니까?');
    if (!confirmed) return;

    try {
      await _firestoreService.removeMedicalRecord(_currentUser!.uid, record);
      _loadUserData();
      _showSuccessMessage('병명이 삭제되었습니다.');
    } catch (e) {
      _showErrorDialog('병명 삭제에 실패했습니다.');
    }
  }

  /// 보호자 추가
  void _addEmergencyContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보호자 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '전화번호',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                _showErrorDialog('이름과 전화번호를 모두 입력해주세요.');
                return;
              }

              try {
                await _firestoreService.addEmergencyContact(
                  _currentUser!.uid,
                  EmergencyContact(name: name, phone: phone),
                );
                Navigator.of(context).pop();
                _loadUserData();
                _showSuccessMessage('보호자가 추가되었습니다.');
              } catch (e) {
                _showErrorDialog('보호자 추가에 실패했습니다.');
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  /// 보호자 삭제
  Future<void> _removeEmergencyContact(EmergencyContact contact) async {
    final confirmed = await _showConfirmDialog(
      '보호자 삭제',
      '"${contact.name} (${contact.phone})"를 삭제하시겠습니까?',
    );
    if (!confirmed) return;

    try {
      await _firestoreService.removeEmergencyContact(_currentUser!.uid, contact);
      _loadUserData();
      _showSuccessMessage('보호자가 삭제되었습니다.');
    } catch (e) {
      _showErrorDialog('보호자 삭제에 실패했습니다.');
    }
  }

  /// 확인 다이얼로그
  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 성공 메시지
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('사용자 정보를 불러올 수 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        backgroundColor: Colors.amber[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 카드
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.amber[700],
                        child: Text(
                          _currentUser!.name.isNotEmpty
                              ? _currentUser!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentUser!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentUser!.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentUser!.phoneNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_currentUser!.verifiedPhone)
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 보유 질환
              _buildSectionHeader('보유 질환 정보', Icons.medical_services, _addDisease),
              const SizedBox(height: 8),
              if (_currentUser!.diseaseHistory.isEmpty)
                _buildEmptyState('등록된 질환이 없습니다.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentUser!.diseaseHistory.map((disease) {
                    return Chip(
                      label: Text(disease),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeDisease(disease),
                      backgroundColor: Colors.red[50],
                      deleteIconColor: Colors.red,
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),
              const Divider(),

              // 과거 병명
              _buildSectionHeader('과거 진단 병명', Icons.history, _addMedicalRecord),
              const SizedBox(height: 8),
              if (_currentUser!.medicalRecords.isEmpty)
                _buildEmptyState('등록된 병명이 없습니다.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentUser!.medicalRecords.map((record) {
                    return Chip(
                      label: Text(record),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeMedicalRecord(record),
                      backgroundColor: Colors.orange[50],
                      deleteIconColor: Colors.orange,
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),
              const Divider(),

              // 보호자 연락처
              _buildSectionHeader('보호자/가족 연락처', Icons.people, _addEmergencyContact),
              const SizedBox(height: 8),
              if (_currentUser!.emergencyContacts.isEmpty)
                _buildEmptyState('등록된 보호자가 없습니다.')
              else
                ..._currentUser!.emergencyContacts.map((contact) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber[700],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(contact.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeEmergencyContact(contact),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),
              const Divider(),

              // 가입 정보
              Text(
                '가입 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '가입일: ${_formatDate(_currentUser!.createdAt)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle, color: Colors.green),
          iconSize: 28,
        ),
      ],
    );
  }

  /// 빈 상태 표시
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
