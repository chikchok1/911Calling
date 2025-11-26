import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../home_screen.dart';

/// 회원가입 화면 (이메일 인증 포함)
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // 텍스트 컨트롤러
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 질환/병명 입력용
  final TextEditingController _diseaseController = TextEditingController();
  final TextEditingController _medicalRecordController = TextEditingController();

  // 보호자 연락처 입력용
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();

  // 리스트
  final List<String> _diseaseHistory = [];
  final List<String> _medicalRecords = [];
  final List<EmergencyContact> _emergencyContacts = [];

  // 이메일 인증 관련
  User? _tempUser; // 임시로 생성된 Firebase Auth 사용자
  bool _isEmailSent = false; // 이메일 전송 여부
  bool _isEmailVerified = false; // 이메일 인증 완료 여부
  
  // 로딩 상태
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _diseaseController.dispose();
    _medicalRecordController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  /// 이메일 인증 메일 전송
  Future<void> _sendEmailVerification() async {
    // 이메일/비밀번호 검증
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    print('🔍 디버그: 입력된 이메일 = "$email"');
    print('🔍 디버그: 이메일 길이 = ${email.length}');
    print('🔍 디버그: @포함 여부 = ${email.contains('@')}');
    print('🔍 디버그: .포함 여부 = ${email.contains('.')}');
    print('🔍 디버그: 공백 포함 여부 = ${email.contains(' ')}');
    
    if (email.isEmpty) {
      _showErrorDialog('이메일을 입력해주세요.');
      return;
    }

    if (!email.contains('@')) {
      _showErrorDialog('이메일에 @가 포함되어야 합니다.');
      return;
    }
    
    if (!email.contains('.')) {
      _showErrorDialog('올바른 이메일 형식이 아닙니다.\n예: example@email.com');
      return;
    }
    
    if (email.contains(' ')) {
      _showErrorDialog('이메일에 공백이 포함되어 있습니다.\n공백을 제거해주세요.');
      return;
    }
    
    // 기본 이메일 형식 검증 (정규식)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog('유효하지 않은 이메일 형식입니다.\n\n올바른 예: user@example.com');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('비밀번호를 입력해주세요.');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('비밀번호는 최소 6자 이상이어야 합니다.');
      return;
    }

    if (password != _passwordConfirmController.text) {
      _showErrorDialog('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== 이메일 인증 메일 전송 시작 ===');
      print('📧 전송할 이메일: "$email"');
      
      // Firebase Auth 계정 생성
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      if (user == null) {
        throw Exception('계정 생성에 실패했습니다.');
      }

      print('✅ Firebase Auth 계정 생성 완료: ${user.uid}');

      // 이메일 인증 링크 전송
      await _authService.sendEmailVerification();
      print('✅ 이메일 인증 링크 전송 완료');

      setState(() {
        _tempUser = user;
        _isEmailSent = true;
        _isLoading = false;
      });

      _showSuccessDialog(
        '인증 메일이 전송되었습니다!\n\n'
        '📫 $email\n\n'
        '이메일을 확인하고 인증 링크를 클릭해주세요.\n'
        '인증 후 "인증 확인" 버튼을 눌러주세요.'
      );
    } catch (e) {
      print('❌ 이메일 인증 메일 전송 실패: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 이메일 인증 메일 재전송
  Future<void> _resendEmailVerification() async {
    if (_tempUser == null) {
      _showErrorDialog('먼저 "인증 메일 전송" 버튼을 클릭해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('📫 이메일 인증 메일 재전송 중...');
      await _authService.sendEmailVerification();
      
      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog('인증 메일을 다시 전송했습니다!\n이메일을 확인해주세요.');
    } catch (e) {
      print('❌ 재전송 실패: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 이메일 인증 확인
  Future<void> _checkEmailVerification() async {
    if (_tempUser == null) {
      _showErrorDialog('먼저 "인증 메일 전송" 버튼을 클릭해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 이메일 인증 상태 확인 중...');
      
      // 사용자 정보 새로고침
      await _authService.reloadUser();
      
      // 현재 사용자 가져오기
      final currentUser = _authService.currentUser;
      
      if (currentUser == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      if (currentUser.emailVerified) {
        print('✅ 이메일 인증 완료!');
        setState(() {
          _isEmailVerified = true;
          _isLoading = false;
        });
        _showSuccessDialog('이메일 인증이 완료되었습니다!\n이제 회원가입을 완료할 수 있습니다.');
      } else {
        print('❌ 이메일 인증 미완료');
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          '아직 이메일 인증이 완료되지 않았습니다.\n\n'
          '이메일을 확인하고 인증 링크를 클릭한 후\n'
          '다시 "인증 확인" 버튼을 눌러주세요.\n\n'
          '메일이 오지 않았다면 "재전송" 버튼을 눌러주세요.'
        );
      }
    } catch (e) {
      print('❌ 인증 확인 실패: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// 질환 추가
  void _addDisease() {
    final disease = _diseaseController.text.trim();
    if (disease.isNotEmpty && !_diseaseHistory.contains(disease)) {
      setState(() {
        _diseaseHistory.add(disease);
        _diseaseController.clear();
      });
    }
  }

  /// 병명 추가
  void _addMedicalRecord() {
    final record = _medicalRecordController.text.trim();
    if (record.isNotEmpty && !_medicalRecords.contains(record)) {
      setState(() {
        _medicalRecords.add(record);
        _medicalRecordController.clear();
      });
    }
  }

  /// 보호자 추가
  void _addEmergencyContact() {
    final name = _emergencyNameController.text.trim();
    final phone = _emergencyPhoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showErrorDialog('보호자 이름과 전화번호를 모두 입력해주세요.');
      return;
    }

    setState(() {
      _emergencyContacts.add(EmergencyContact(name: name, phone: phone));
      _emergencyNameController.clear();
      _emergencyPhoneController.clear();
    });
  }

  /// 회원가입 완료
  Future<void> _completeSignUp() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 이메일 인증 확인
    if (!_isEmailVerified) {
      _showErrorDialog(
        '이메일 인증을 완료해주세요.\n\n'
        '1. "인증 메일 전송" 버튼 클릭\n'
        '2. 이메일에서 인증 링크 클릭\n'
        '3. "인증 확인" 버튼 클릭'
      );
      return;
    }

    // 보호자 연락처 확인
    if (_emergencyContacts.isEmpty) {
      _showErrorDialog('최소 1명의 보호자 연락처를 등록해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== 회원가입 완료 시작 ===');

      if (_tempUser == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      // Firestore에 사용자 문서 생성
      print('💾 Firestore 사용자 문서 생성 중...');
      await _firestoreService.createUser(
        uid: _tempUser!.uid,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        verifiedPhone: false,
        diseaseHistory: _diseaseHistory,
        medicalRecords: _medicalRecords,
        emergencyContacts: _emergencyContacts,
      );
      print('✅ Firestore 사용자 문서 생성 완료!');

      setState(() {
        _isLoading = false;
      });

      // 홈 화면으로 이동
      if (mounted) {
        _showSuccessDialog(
          '🎉 회원가입이 완료되었습니다!\n\n'
          '환영합니다, ${_nameController.text.trim()}님!',
          onConfirm: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        );
      }
    } catch (e) {
      print('❌ 회원가입 완료 실패: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('회원가입 중 오류가 발생했습니다.\n\n에러: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  /// 성공 다이얼로그
  void _showSuccessDialog(String message, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('성공'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: const Text('확인'),
          ),
        ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.amber[700],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 타이틀
                  const Text(
                    '119 긴급신고 앱',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '응급 상황에 필요한 정보를 등록해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 이메일
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isEmailSent, // 메일 전송 후 수정 불가
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 (최소 6자)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    enabled: !_isEmailSent, // 메일 전송 후 수정 불가
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 최소 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 확인
                  TextFormField(
                    controller: _passwordConfirmController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    enabled: !_isEmailSent, // 메일 전송 후 수정 불가
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ========== 이메일 인증 섹션 ==========
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isEmailVerified ? Colors.green[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isEmailVerified ? Colors.green : Colors.blue,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isEmailVerified ? Icons.check_circle : Icons.email,
                              color: _isEmailVerified ? Colors.green : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEmailVerified ? '✅ 이메일 인증 완료' : '📧 이메일 인증',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isEmailVerified ? Colors.green[900] : Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (!_isEmailSent) ...[
                          // 인증 메일 전송 전
                          const Text(
                            '이메일과 비밀번호를 입력한 후\n아래 버튼을 눌러 인증 메일을 받으세요.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _sendEmailVerification,
                            icon: const Icon(Icons.send),
                            label: const Text('인증 메일 전송'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ] else if (!_isEmailVerified) ...[
                          // 인증 메일 전송 후, 인증 미완료
                          Text(
                            '📫 ${_emailController.text.trim()}\n\n'
                            '위 이메일로 인증 링크를 전송했습니다.\n'
                            '이메일을 확인하고 링크를 클릭한 후\n'
                            '아래 "인증 확인" 버튼을 눌러주세요.',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _resendEmailVerification,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('재전송'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                    side: const BorderSide(color: Colors.orange),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _checkEmailVerification,
                                  icon: const Icon(Icons.check),
                                  label: const Text('인증 확인'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '💡 Tip: 메일이 오지 않았다면 스팸 폴더를 확인하세요.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ] else ...[
                          // 인증 완료
                          const Text(
                            '✅ 이메일 인증이 완료되었습니다!\n이제 아래 정보를 입력하고 회원가입을 완료하세요.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  // 이름
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '이름',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이름을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 전화번호 (인증 없이 입력만)
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: '전화번호 (예: 010-1234-5678)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      helperText: '응급 상황 시 연락받을 전화번호를 입력하세요',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '전화번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  // 질환 정보
                  const Text(
                    '보유 질환 정보 (선택사항)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _diseaseController,
                          decoration: const InputDecoration(
                            hintText: '예: 고혈압, 당뇨',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addDisease,
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        iconSize: 36,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _diseaseHistory.map((disease) {
                      return Chip(
                        label: Text(disease),
                        backgroundColor: Colors.red[100],
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _diseaseHistory.remove(disease);
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // 과거 병명
                  const Text(
                    '과거 진단 병명 (선택사항)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _medicalRecordController,
                          decoration: const InputDecoration(
                            hintText: '예: 심근경색, 뇌졸중',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addMedicalRecord,
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        iconSize: 36,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _medicalRecords.map((record) {
                      return Chip(
                        label: Text(record),
                        backgroundColor: Colors.orange[100],
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _medicalRecords.remove(record);
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // 보호자 연락처
                  const Text(
                    '보호자/가족 연락처 (최소 1명 필수)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(
                      labelText: '보호자 이름',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emergencyPhoneController,
                          decoration: const InputDecoration(
                            labelText: '보호자 전화번호',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addEmergencyContact,
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        iconSize: 36,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._emergencyContacts.map((contact) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(contact.name),
                        subtitle: Text(contact.phone),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _emergencyContacts.remove(contact);
                            });
                          },
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // 회원가입 완료 버튼
                  ElevatedButton(
                    onPressed: _isEmailVerified ? _completeSignUp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmailVerified ? Colors.amber[700] : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: Text(_isEmailVerified ? '회원가입 완료' : '이메일 인증을 먼저 완료하세요'),
                  ),

                  const SizedBox(height: 16),

                  // 로그인 화면으로 이동
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('이미 계정이 있으신가요? 로그인'),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
