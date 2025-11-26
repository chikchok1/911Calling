import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/fire_station.dart';
import '../services/fire_station_api_service.dart';

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
  Position? _currentPosition; // GPS 위치 저장
  String? _currentAddress; // 현재 주소
  FireStation? _nearestFireStation; // 가장 가까운 소방서
  List<FireStation> _allFireStations = []; // API에서 가져온 전체 소방서

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

    // 소방서 데이터 미리 로드
    _loadFireStations();
  }

  /// 소방서 데이터 로드
  Future<void> _loadFireStations() async {
    final stations = await FireStationApiService.fetchAllFireStations();
    setState(() {
      _allFireStations = stations;
    });

    if (stations.isEmpty) {
      // API 실패 시 하드코딩된 데이터 사용
      debugPrint('⚠️ API 실패, 하드코딩된 데이터 사용');
      setState(() {
        _allFireStations = FireStationData.stations;
      });
    }
  }

  void _handleEmergencyCall() {
    if (_isEmergency) return; // 이미 실행 중이면 무시

    setState(() {
      _isEmergency = true;
      _isRecording = true;
      _elapsedSeconds = 0;
      _logs.clear(); // 로그 초기화
    });

    // 즉시 GPS 위치 가져오기 시작
    _getCurrentLocation();

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
            child: const Text('확인'),
          ),
        ],
      ),
    );
    // ✅ 1초 후 자동으로 팝업 닫기
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  // 시간대별로 가짜 로그를 추가하여 "작동하는 척" 하는 함수
  void _updateScenario(int seconds) {
    if (seconds == 1) _addLog('119 신고 접수 시작', seconds);
    // 3초에는 실제 GPS 데이터와 주소가 로그에 표시됨
    if (seconds == 3 && _currentPosition != null) {
      final locationText =
          _currentAddress ??
          '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
      _addLog('GPS 위치 확보 ($locationText)', seconds);
    } else if (seconds == 3) {
      _addLog('GPS 위치 확보 중...', seconds);
    }
    if (seconds == 5 && _nearestFireStation != null) {
      _addLog('관할 소방서(${_nearestFireStation!.name}) 자동 매칭', seconds);
    } else if (seconds == 5) {
      _addLog('관할 소방서 검색 중...', seconds);
    }
    if (seconds == 8) _addLog('주변 사용자 5명에게 긴급 알림 전송', seconds);
    if (seconds == 12) _addLog('상황실 음성 송출 채널 연결됨', seconds);
  }

  void _addLog(String text, int time) {
    _logs.insert(0, {'text': text, 'time': time}); // 최신 로그가 위로 오게
  }

  // GPS 위치 가져오기 (개선된 버전)
  Future<void> _getCurrentLocation() async {
    try {
      // 위치 권한 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ GPS 서비스가 비활성화되어 있습니다');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ 위치 권한이 거부되었습니다');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ 위치 권한이 영구적으로 거부되었습니다');
        return;
      }

      // ✅ 1단계: 마지막 알려진 위치 먼저 사용 (빠른 응답)
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setState(() {
          _currentPosition = lastKnown;
        });
        debugPrint(
          '📍 캐시된 위치 사용: ${lastKnown.latitude}, ${lastKnown.longitude}',
        );
        _getAddressFromCoordinates(lastKnown);
        _findNearestFireStation(lastKnown);
      }

      // ✅ 2단계: 현재 위치 정확하게 가져오기 (백그라운드에서 업데이트)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // 5초 제한
      );

      setState(() {
        _currentPosition = position;
      });

      debugPrint('📍 GPS 위치 업데이트: ${position.latitude}, ${position.longitude}');

      // 주소 변환
      _getAddressFromCoordinates(position);

      // GPS 확보 후 가까운 소방서 다시 찾기
      _findNearestFireStation(position);
    } catch (e) {
      debugPrint('❌ GPS 오류: $e');

      // ✅ GPS 실패 시에도 마지막 위치라도 사용
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && _currentPosition == null) {
          setState(() {
            _currentPosition = lastKnown;
          });
          debugPrint(
            '⚠️ GPS 실패, 마지막 위치 사용: ${lastKnown.latitude}, ${lastKnown.longitude}',
          );
          _getAddressFromCoordinates(lastKnown);
          _findNearestFireStation(lastKnown);
        }
      } catch (e2) {
        debugPrint('❌ 마지막 위치도 없음: $e2');
      }
    }
  }

  // GPS 좌표를 주소로 변환
  Future<void> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // 주소 포맷: "시/도 구/군 동"
        final address = [
          place.administrativeArea ?? '', // 시/도 (예: 부산광역시)
          place.locality ?? place.subAdministrativeArea ?? '', // 구/군 (예: 해운대구)
          place.subLocality ?? place.thoroughfare ?? '', // 동/길 (예: 우동1동)
        ].where((s) => s.isNotEmpty).join(' ');

        setState(() {
          _currentAddress = address;
        });

        debugPrint('📍 주소 변환 성공: $address');
      }
    } catch (e) {
      debugPrint('❌ 주소 변환 실패: $e');
      // 주소 변환 실패 시 좌표 사용
    }
  }

  // 가장 가까운 소방서 찾기
  void _findNearestFireStation(Position currentPosition) {
    if (_allFireStations.isEmpty) {
      debugPrint('❌ 소방서 데이터가 비어있습니다');
      return;
    }

    FireStation? nearest;
    double minDistance = double.infinity;

    for (final station in _allFireStations) {
      // 하버사인 공식으로 거리 계산
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        station.latitude,
        station.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = station;
      }
    }

    setState(() {
      _nearestFireStation = nearest;
    });

    if (nearest != null) {
      debugPrint(
        '🚒 가장 가까운 소방서: ${nearest.name} (${(minDistance / 1000).toStringAsFixed(1)}km)',
      );
    }
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

  @override
  Widget build(BuildContext context) {
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
                ),
              ),
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
