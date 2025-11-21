import 'package:flutter/material.dart';

class GuideTab extends StatefulWidget {
  const GuideTab({super.key});

  @override
  State<GuideTab> createState() => _GuideTabState();
}

class _GuideTabState extends State<GuideTab> {
  String? _selectedGuide;

  // --- 원래 있던 전체 리스트는 그대로 유지 ---
  final List<EmergencyType> _emergencyTypes = [
    EmergencyType(
      id: 'cardiac',
      title: '심정지',
      icon: Icons.favorite,
      color: Colors.red,
      bgColor: Colors.red,
      description: 'CPR 및 AED 사용법',
      steps: ['의식 확인', '119 신고', '가슴압박 시작', 'AED 사용'],
    ),
    EmergencyType(
      id: 'choking',
      title: '기도 막힘',
      icon: Icons.air,
      color: Colors.blue,
      bgColor: Colors.blue,
      description: '하임리히법 안내',
      steps: ['상태 확인', '복부 밀기', '이물질 제거', '호흡 확인'],
    ),
    EmergencyType(
      id: 'bleeding',
      title: '출혈',
      icon: Icons.water_drop,
      color: Colors.red,
      bgColor: Colors.red,
      description: '지혈 및 압박법',
      steps: ['상처 확인', '직접 압박', '상처 높이기', '압박 유지'],
    ),
    EmergencyType(
      id: 'burn',
      title: '화상',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      bgColor: Colors.orange,
      description: '화상 응급처치',
      steps: ['열원 제거', '찬물로 식히기', '물집 보호', '천으로 덮기'],
    ),
    EmergencyType(
      id: 'seizure',
      title: '발작/경련',
      icon: Icons.warning,
      color: Colors.purple,
      bgColor: Colors.purple,
      description: '발작 시 대응법',
      steps: ['주변 정리', '머리 보호', '옆으로 눕히기', '시간 체크'],
    ),
    EmergencyType(
      id: 'infant',
      title: '영유아 응급',
      icon: Icons.child_care,
      color: Colors.pink,
      bgColor: Colors.pink,
      description: '영유아 특화 응급처치',
      steps: ['두 손가락 압박', '부드러운 압박', '호흡 확인', '즉시 신고'],
    ),
    EmergencyType(
      id: 'fracture',
      title: '골절',
      icon: Icons.accessibility_new,
      color: Colors.teal,
      bgColor: Colors.teal,
      description: '골절 시 응급 대처',
      steps: ['움직이지 않게 고정', '냉찜질', '압박 금지', '119 신고'],
    ),
    EmergencyType(
      id: 'poison',
      title: '중독',
      icon: Icons.warning_amber,
      color: Colors.green,
      bgColor: Colors.green,
      description: '중독 응급처치',
      steps: ['노출 차단', '의식 확인', '구토 유도 금지', '119 신고'],
    ),
    EmergencyType(
      id: 'hypoglycemia',
      title: '저혈당',
      icon: Icons.local_cafe,
      color: Colors.brown,
      bgColor: Colors.brown,
      description: '저혈당 처리',
      steps: ['증상 확인', '당 섭취', '휴식', '호전 없으면 119'],
    ),
    EmergencyType(
      id: 'dehydration',
      title: '탈수',
      icon: Icons.opacity,
      color: Colors.blueGrey,
      bgColor: Colors.blueGrey,
      description: '탈수 응급처치',
      steps: ['시원한 곳으로 이동', '수분 보충', '휴식', '심하면 병원 방문'],
    ),
    EmergencyType(
      id: 'heatstroke',
      title: '열사병',
      icon: Icons.wb_sunny,
      color: Colors.deepOrange,
      bgColor: Colors.deepOrange,
      description: '고열 환경에서 발생',
      steps: ['즉시 그늘 이동', '옷 느슨하게', '물 보급', '필요시 병원'],
    ),
    EmergencyType(
      id: 'hypothermia',
      title: '저체온증',
      icon: Icons.ac_unit,
      color: Colors.lightBlue,
      bgColor: Colors.lightBlue,
      description: '저체온증 응급처치',
      steps: ['따뜻한 곳 이동', '젖은 옷 제거', '담요 덮기', '서서히 체온 올리기'],
    ),
    EmergencyType(
      id: 'traffic',
      title: '교통사고',
      icon: Icons.car_crash,
      color: Colors.indigo,
      bgColor: Colors.indigo,
      description: '사고 현장 응급 대처',
      steps: ['현장 안전 확보', '환자 확인', '출혈 여부 확인', '즉시 신고'],
    ),
    EmergencyType(
      id: 'animal',
      title: '동물 상처',
      icon: Icons.pets,
      color: Colors.brown,
      bgColor: Colors.brown,
      description: '개·고양이·야생동물 상처',
      steps: ['상처 세척', '지혈', '소독', '병원 방문'],
    ),
  ];

  // --- 보기 좋은 카테고리 그룹 ---
  final Map<String, List<String>> _groups = {
    "🔥 생명 위급": ['cardiac', 'choking', 'seizure'],
    "🩹 일반 응급": ['bleeding', 'burn', 'fracture', 'dehydration', 'hypoglycemia'],
    "☣ 환경·상황": ['poison', 'heatstroke', 'hypothermia'],
    "🚑 사고/외상": ['traffic', 'animal'],
    "👶 영유아": ['infant'],
  };

  @override
  Widget build(BuildContext context) {
    final selectedEmergency = _emergencyTypes
        .firstWhere((e) => e.id == _selectedGuide, orElse: () => _emergencyTypes[0]);

    return Scaffold(
      body: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _selectedGuide == null
              ? _buildCategoryList()
              : _buildDetail(selectedEmergency),
        ),
      ),
    );
  }

  // ------------------------------ 리스트 화면 ------------------------------
  Widget _buildCategoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상황별 응급 가이드',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 4),
        Text("응급 상황을 선택하세요", style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),

        ..._groups.entries.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.key,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ...group.value.map((id) {
                final item = _emergencyTypes.firstWhere((e) => e.id == id);
                return _buildListItem(item);
              }),

              const SizedBox(height: 18),
            ],
          );
        }),
      ],
    );
  }

  // 리스트 아이템 디자인
  Widget _buildListItem(EmergencyType e) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGuide = e.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(e.icon, size: 32, color: e.color),
            const SizedBox(width: 16),
            Text(e.title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // ------------------------------ 상세 화면 ------------------------------
  Widget _buildDetail(EmergencyType e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => setState(() => _selectedGuide = null),
          icon: const Icon(Icons.arrow_back),
          label: const Text("목록으로 돌아가기"),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: e.bgColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(e.icon, size: 34, color: e.color),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${e.title} 응급처치",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(e.description,
                            style: TextStyle(color: Colors.grey[600])),
                      ]),
                ],
              ),

              const SizedBox(height: 20),

              ...e.steps.asMap().entries.map((entry) {
                return _buildStepItem(entry.key, entry.value, e.color);
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(int index, String step, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)
          ]),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(.18),
            child: Text("${index + 1}",
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(step)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------

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
