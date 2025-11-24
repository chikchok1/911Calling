import 'package:flutter/material.dart';

class AEDLocatorTab extends StatelessWidget {
  const AEDLocatorTab({super.key});

  @override
  Widget build(BuildContext context) {
    final nearbyAEDs = [
      AEDLocation(
        id: 1,
        name: '강남역 1번 출구',
        distance: '120m',
        time: '2분',
        available: true,
      ),
      AEDLocation(
        id: 2,
        name: 'GS25 편의점',
        distance: '250m',
        time: '3분',
        available: true,
      ),
      AEDLocation(
        id: 3,
        name: '시청 1층 로비',
        distance: '380m',
        time: '5분',
        available: false,
      ),
      AEDLocation(
        id: 4,
        name: '종합병원 응급실',
        distance: '450m',
        time: '6분',
        available: true,
      ),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            const Text(
              'AED 위치 안내',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '가장 가까운 AED를 찾아드립니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Map Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Map Placeholder
                  Container(
                    height: 192,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.green[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Center Content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '내 위치 기반 AED 지도',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '4개 AED 발견',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Mock AED Markers
                        Positioned(
                          top: 40,
                          left: 80,
                          child: _buildAEDMarker(true),
                        ),
                        Positioned(
                          top: 100,
                          right: 60,
                          child: _buildAEDMarker(true),
                        ),
                        Positioned(
                          bottom: 50,
                          left: 140,
                          child: _buildAEDMarker(false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Request AED Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('AED 요청'),
                            content: const Text('주변 앱 사용자에게 AED 요청을 전송하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('주변 사용자에게 AED 요청을 전송했습니다'),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[700],
                                ),
                                child: const Text('요청'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.people, size: 20),
                      label: const Text('주변 사용자에게 AED 요청'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nearby AEDs List Header
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '가까운 AED 목록',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Nearby AEDs List
            ...nearbyAEDs.map((aed) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: aed.available ? Colors.green[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: aed.available ? Colors.green[200]! : Colors.grey[200]!,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // AED Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: aed.available ? Colors.amber[500] : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  aed.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: aed.available ? Colors.green : Colors.grey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  aed.available ? '사용 가능' : '사용 중',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.navigation,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                aed.distance,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '도보 ${aed.time}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Navigate Button
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${aed.name}로 길찾기를 시작합니다'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('길찾기', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 8),

            // Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.bolt,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AED 요청 기능:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '긴급 버튼을 누르면 주변 앱 사용자에게 "AED를 가져다 달라"는 알림이 전송됩니다.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '심정지 환자의 경우 4분 이내 AED 사용 시 생존율이 크게 증가합니다.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAEDMarker(bool isAvailable) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isAvailable ? Colors.amber[500] : Colors.grey[400],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.bolt,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class AEDLocation {
  final int id;
  final String name;
  final String distance;
  final String time;
  final bool available;

  AEDLocation({
    required this.id,
    required this.name,
    required this.distance,
    required this.time,
    required this.available,
  });
}
