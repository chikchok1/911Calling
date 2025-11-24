import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class EmergencyTab extends StatefulWidget {
  const EmergencyTab({super.key});

  @override
  State<EmergencyTab> createState() => _EmergencyTabState();
}

class _EmergencyTabState extends State<EmergencyTab>
    with TickerProviderStateMixin {
  bool _isEmergency = false;
  bool _isRecording = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // 시나리오 로그를 위한 리스트
  final List<Map<String, dynamic>> _logs = [];

  // 애니메이션 컨트롤러들
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // 버튼 심장박동 애니메이션
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // 음성 파형 애니메이션
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  // 🔴 CPR 관련 변수들
  int _cprCount = 0;
  int _cprSeconds = 0;
  bool _cprRunning = false;
  Timer? _cprTimer;

  // 119 긴급 신고 처리
  void _handleEmergencyCall() {
    if (_isEmergency) return; // 이미 실행 중이면 무시

    setState(() {
      _isEmergency = true;
      _isRecording = true;
      _elapsedSeconds = 0;
      _logs.clear(); // 로그 초기화
    });

    // 타이머 시작
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        _updateScenario(_elapsedSeconds); // 시간대별 시나리오 실행
      });
    });

    // 팝업 띄우기 (조금 더 있어보이는 내용으로 수정)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('긴급 신고 접수'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('119 상황실로 위치와 현장 음성이 실시간 전송됩니다.'),
            SizedBox(height: 8),
            Text('전송 중...', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인 (시뮬레이션 시작)'),
          ),
        ],
      ),
    );
  }

  // 시간대별로 가짜 로그를 추가하여 "작동하는 척" 하는 함수
  void _updateScenario(int seconds) {
    if (seconds == 1) _addLog('119 신고 접수 시작', seconds);
    if (seconds == 3) _addLog('GPS 위치 확보 (37.5665, 126.9780)', seconds);
    if (seconds == 5) _addLog('관할 소방서(중부소방서) 자동 매칭', seconds);
    if (seconds == 8) _addLog('주변 사용자 5명에게 긴급 알림 전송', seconds);
    if (seconds == 12) _addLog('상황실 음성 송출 채널 연결됨', seconds);
  }

  void _addLog(String text, int time) {
    _logs.insert(0, {'text': text, 'time': time}); // 최신 로그가 위로 오게
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
    _pulseController.dispose();
    _waveController.dispose();
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
<<<<<<< HEAD
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
=======
    return SafeArea(
      child: SingleChildScrollView(
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
>>>>>>> 61acae3 (style: 응급 구조 도우미 탭 UI 개선 및 SafeArea 적용)
                ),
              ),
<<<<<<< HEAD
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
=======
              const SizedBox(height: 4),
              Text(
                '골든타임을 지키는 스마트 응급 대응',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Emergency Button Area
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse Effect (물결 애니메이션)
                    if (_isEmergency)
                      FadeTransition(
                        opacity: Tween(
                          begin: 0.5,
                          end: 0.0,
                        ).animate(_pulseController),
                        child: ScaleTransition(
                          scale: Tween(
                            begin: 1.0,
                            end: 1.5,
                          ).animate(_pulseController),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),

                    // Main Button
                    GestureDetector(
                      onTap: _handleEmergencyCall,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isEmergency
                                ? [
                                    const Color(0xFFD32F2F),
                                    const Color(0xFFB71C1C),
                                  ]
                                : [
                                    const Color(0xFFEF5350),
                                    const Color(0xFFE53935),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEmergency
                                  ? Icons.phone_in_talk
                                  : Icons.touch_app,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEmergency ? '연결됨' : 'SOS 호출',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_isEmergency)
                              Text(
                                _formatTime(_elapsedSeconds),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Recording & Status Card
              if (_isRecording) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade100, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Audio Visualizer (가짜 파형) - 화면 떨림 방지를 위해 수정됨
                      Container(
                        height: 60, // ★ 핵심: 높이를 60으로 고정해서 부모가 흔들리지 않게 함
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(10, (index) {
                            return AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, child) {
                                // 랜덤한 높이 변화로 목소리 파형 흉내
                                final value = sin(
                                  _waveController.value * 2 * pi + index,
                                );
                                final height = 10 + 20 * value.abs();

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  width: 4,
                                  height:
                                      height, // 이 높이가 변해도 부모(height:60)는 안 변함
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "상황실에 음성이 실시간 공유되고 있습니다.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Dynamic Logs (실시간 로그)
                      SizedBox(
                        height: 150, // 높이 고정
                        child: _logs.isEmpty
                            ? const Center(child: Text("연결 준비 중..."))
                            : ListView.builder(
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final item = _logs[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _formatTime(item['time']),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item['text'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _stopRecording,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('상황 종료 및 전송 중지'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // 대기 상태일 때 보여줄 설명 패널
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "위급 상황 시 SOS 버튼을 누르면\n즉시 119 연결 및 위치 공유가 시작됩니다.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
