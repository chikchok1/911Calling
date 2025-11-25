/// 소방서 정보 모델
class FireStation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;

  const FireStation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
  });
}

/// 전국 주요 소방서 데이터 (주요 도시만 포함)
class FireStationData {
  static const List<FireStation> stations = [
    // 부산
    FireStation(
      name: '부산진소방서',
      address: '부산 부산진구 동천로 107',
      latitude: 35.1628,
      longitude: 129.0530,
      phone: '051-760-5119',
    ),
    FireStation(
      name: '해운대소방서',
      address: '부산 해운대구 센텀중앙로 78',
      latitude: 35.1697,
      longitude: 129.1311,
      phone: '051-760-5619',
    ),
    FireStation(
      name: '동래소방서',
      address: '부산 동래구 명륜로 150',
      latitude: 35.2047,
      longitude: 129.0789,
      phone: '051-550-4119',
    ),
    FireStation(
      name: '남부소방서',
      address: '부산 남구 수영로 298',
      latitude: 35.1361,
      longitude: 129.0842,
      phone: '051-760-5819',
    ),
    FireStation(
      name: '북부소방서',
      address: '부산 북구 만덕대로 77',
      latitude: 35.2097,
      longitude: 129.0343,
      phone: '051-330-4119',
    ),
    FireStation(
      name: '사상소방서',
      address: '부산 사상구 학감대로 242',
      latitude: 35.1520,
      longitude: 128.9918,
      phone: '051-310-4119',
    ),

    // 서울
    FireStation(
      name: '중부소방서',
      address: '서울 중구 세종대로 17',
      latitude: 37.5665,
      longitude: 126.9780,
      phone: '02-2270-0119',
    ),
    FireStation(
      name: '강남소방서',
      address: '서울 강남구 개포로 617',
      latitude: 37.4959,
      longitude: 127.0664,
      phone: '02-3411-0119',
    ),
    FireStation(
      name: '송파소방서',
      address: '서울 송파구 중대로 264',
      latitude: 37.5048,
      longitude: 127.1143,
      phone: '02-2147-0119',
    ),
  ];
}
