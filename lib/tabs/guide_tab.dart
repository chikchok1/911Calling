import 'package:flutter/material.dart';

class GuideTab extends StatefulWidget {
  const GuideTab({super.key});

  @override
  State<GuideTab> createState() => _GuideTabState();
}

class _GuideTabState extends State<GuideTab> {
  String? _selectedGuide;

  final List<EmergencyType> _emergencyTypes = [
    EmergencyType(
      id: 'cardiac',
      title: '심정지',
      icon: Icons.favorite,
      color: Colors.red[600]!,
      bgColor: Colors.red[50]!,
      description: 'CPR 및 AED 사용법',
      steps: ['의식 확인', '119 신고', '가슴압박 시작', 'AED 사용'],
    ),
    EmergencyType(
      id: 'choking',
      title: '기도 막힘',
      icon: Icons.air,
      color: Colors.blue[600]!,
      bgColor: Colors.blue[50]!,
      description: '하임리히법 안내',
      steps: ['환자 상태 확인', '복부 압박', '이물질 제거', '호흡 확인'],
    ),
    EmergencyType(
      id: 'bleeding',
      title: '출혈',
      icon: Icons.water_drop,
      color: Colors.red[700]!,
      bgColor: Colors.red[50]!,
      description: '지혈 및 압박법',
      steps: ['깨끗한 천 준비', '직접 압박', '상처 부위 높이기', '압박 유지'],
    ),
    EmergencyType(
      id: 'burn',
      title: '화상',
      icon: Icons.local_fire_department,
      color: Colors.orange[600]!,
      bgColor: Colors.orange[50]!,
      description: '화상 응급처치',
      steps: ['열원 제거', '찬물로 식히기', '물집 보호', '깨끗한 천으로 덮기'],
    ),
    EmergencyType(
      id: 'seizure',
      title: '경련/발작',
      icon: Icons.warning,
      color: Colors.purple[600]!,
      bgColor: Colors.purple[50]!,
      description: '발작 시 대응법',
      steps: ['주변 정리', '옆으로 눕히기', '시간 체크', '움직임 관찰'],
    ),
    EmergencyType(
      id: 'infant',
      title: '영유아 응급',
      icon: Icons.child_care,
      color: Colors.pink[600]!,
      bgColor: Colors.pink[50]!,
      description: '영유아 특화 처치',
      steps: ['두 손가락 압박', '부드러운 압박', '호흡 확인', '즉시 신고'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedEmergency = _emergencyTypes.firstWhere(
          (e) => e.id == _selectedGuide,
      orElse: () => _emergencyTypes[0],
    );

    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            const Text(
              '상황별 응급 가이드',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '응급 상황을 선택하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Type Selection or Detail View
            if (_selectedGuide == null)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _emergencyTypes.length,
                itemBuilder: (context, index) {
                  final emergency = _emergencyTypes[index];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedGuide = emergency.id;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            emergency.icon,
                            size: 32,
                            color: emergency.color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            emergency.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else ...[
              // Back Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedGuide = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('목록으로 돌아가기'),
                ),
              ),
              const SizedBox(height: 16),

              // Emergency Detail Card
              Container(
                decoration: BoxDecoration(
                  color: selectedEmergency.bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            selectedEmergency.icon,
                            color: selectedEmergency.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedEmergency.title} 응급처치',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                selectedEmergency.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Badges
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildBadge('단계별 안내', true),
                        _buildBadge('텍스트', false),
                        _buildBadge('음성', false),
                        _buildBadge('영상', false),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Steps
                    ...selectedEmergency.steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedEmergency.color,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selectedEmergency.color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Media Options
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Text('🔊', style: TextStyle(fontSize: 16)),
                            label: const Text('음성 안내', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Text('📹', style: TextStyle(fontSize: 16)),
                            label: const Text('영상 가이드', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBadge(String label, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.red : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPrimary ? Colors.red : Colors.grey[400]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isPrimary ? Colors.white : Colors.grey[700],
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class EmergencyType {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String description;
  final List<String> steps;

  EmergencyType({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.description,
    required this.steps,
  });
}
