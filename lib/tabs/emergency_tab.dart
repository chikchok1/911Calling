import 'package:flutter/material.dart';
import 'dart:async';

class EmergencyTab extends StatefulWidget {
  const EmergencyTab({super.key});

  @override
  State<EmergencyTab> createState() => _EmergencyTabState();
}

class _EmergencyTabState extends State<EmergencyTab> {
  bool _isEmergency = false;
  bool _isRecording = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // 🔴 CPR 관련 변수들
  int _cprCount = 0;
  int _cprSeconds = 0;
  bool _cprRunning = false;
  Timer? _cprTimer;

  // 119 긴급 신고 처리
  void _handleEmergencyCall() {
    setState(() {
      _isEmergency = true;
      _isRecording = true;
      _elapsedSeconds = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });

    // Show emergency dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('119 신고'),
        content: const Text('119에 연결 중입니다...\n주변 사용자에게 알림을 전송합니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      _isEmergency = false;
    });
    _timer?.cancel();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cprTimer?.cancel();
    super.dispose();
  }

  // 🔻 CPR 로직들
  void _startCpr() {
    if (_cprRunning) return;

    _cprRunning = true;
    _cprTimer?.cancel();
    _cprTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _cprSeconds++;
      });
    });
  }

  void _pauseCpr() {
    _cprTimer?.cancel();
    setState(() {
      _cprRunning = false;
    });
  }

  void _resetCpr() {
    _cprTimer?.cancel();
    setState(() {
      _cprRunning = false;
      _cprSeconds = 0;
      _cprCount = 0;
    });
  }

  void _pressCompression() {
    if (!_cprRunning) _startCpr();
    setState(() {
      _cprCount++;
    });
  }

  // 심정지 상황 행동 요약 카드
  Widget _buildEmergencyGuideCard() {
    final steps = [
      {
        'num': '1',
        'icon': Icons.search,
        'title': '의식 · 호흡 확인',
        'desc': '어깨를 두드리며 반응과 정상 호흡 여부를 확인합니다.',
      },
      {
        'num': '2',
        'icon': Icons.phone_in_talk,
        'title': '119 신고 · AED 요청',
        'desc': '주변인에게 119 신고와 AED 요청을 맡기고 스피커폰을 켭니다.',
      },
      {
        'num': '3',
        'icon': Icons.favorite,
        'title': '가슴압박 시작',
        'desc': '흉부 중앙을 분당 100~120회 속도로 30회씩 강하고 빠르게 압박합니다.',
      },
      {
        'num': '4',
        'icon': Icons.bolt,
        'title': 'AED 사용',
        'desc': 'AED 전원을 켜고 패드를 붙인 뒤, 음성 안내에 따라 충격 후 즉시 압박을 재개합니다.',
      },
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '심정지 발생 시 행동 요약',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '119 신고 전후로 반드시 따라야 할 핵심 4단계입니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // 단계 리스트
          ...steps.map((step) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 번호 동그라미
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        step['num'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Icon(step['icon'] as IconData, size: 20, color: Colors.red),
                  const SizedBox(width: 10),

                  // 텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 8),
          const Text(
            '※ 실제 상황에서는 가능한 한 빠르게 CPR을 시작하고, AED가 도착하면 즉시 사용하세요.',
            style: TextStyle(fontSize: 11, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildCprCounterCard() {
    String formatted =
        '${(_cprSeconds ~/ 60).toString().padLeft(2, '0')}:${(_cprSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          const Text(
            "흉부 압박 카운트",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "경과 시간: $formatted",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // 동그란 카운터
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 4),
            ),
            child: Center(
              child: Text(
                _cprCount.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 압박 버튼
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: _pressCompression,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "압박",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 컨트롤 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _cprRunning ? _pauseCpr : _startCpr,
                child: Text(_cprRunning ? "일시정지" : "재개"),
              ),
              const SizedBox(width: 20),
              TextButton(onPressed: _resetCpr, child: const Text("초기화")),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            const Text(
              '응급 구조 도우미',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '골든타임을 지키는 스마트 응급 대응',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Emergency Button Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main Emergency Button
                  InkWell(
                    onTap: _handleEmergencyCall,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: _isEmergency
                            ? const Color(0xFF7F0000)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 48,
                              color: _isEmergency ? Colors.white : Colors.red,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEmergency ? '119 연결 중...' : '119 긴급 신고',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _isEmergency ? Colors.white : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Features Grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.people, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '주변 사용자',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '자동 알림',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '위치 전송',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '실시간 공유',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '버튼을 누르면 119 연결 및 주변 사용자에게 자동으로 알림이 전송됩니다',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ✅ 항상 119 카드 바로 아래에 CPR 카드 표시
            _buildEmergencyGuideCard(),

            const SizedBox(height: 16),

            // Recording Status Card는 예전처럼 신고 중일 때만 표시
            if (_isRecording) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[50]!, Colors.orange[50]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[200]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '상황 기록 중',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: _stopRecording,
                          icon: const Icon(Icons.stop_circle, size: 14),
                          label: const Text(
                            '중지',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Time and Status
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_elapsedSeconds),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.mic, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          '음성 기록',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.description,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '이벤트 로그',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Event Log
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '기록된 내용:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildEventItem('119 신고 접수', _elapsedSeconds - 120),
                          _buildEventItem(
                            '주변 사용자 알림 전송',
                            _elapsedSeconds - 115,
                          ),
                          _buildEventItem('CPR 가이드 시작', _elapsedSeconds - 90),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      '💾 모든 음성, 시간, 이벤트가 자동 저장되어 구조대원 및 의료진에게 전달됩니다',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(String text, int seconds) {
    final displayTime = seconds > 0 ? _formatTime(seconds) : '00:00';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '• $text',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          Text(
            displayTime,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
