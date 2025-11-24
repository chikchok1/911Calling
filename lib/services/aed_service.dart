import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class AEDData {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool available;
  final String? phone;
  final String? institution;

  AEDData({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.available = true,
    this.phone,
    this.institution,
  });

  // 현재 위치로부터의 거리 계산
  double getDistanceFrom(Position position) {
    return LocationService.calculateDistance(
      position.latitude,
      position.longitude,
      latitude,
      longitude,
    );
  }

  // Factory constructor for JSON
  factory AEDData.fromJson(Map<String, dynamic> json) {
    return AEDData(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      available: json['available'] as bool? ?? true,
      phone: json['phone'] as String?,
      institution: json['institution'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'available': available,
      'phone': phone,
      'institution': institution,
    };
  }
}

class AEDService {
  // 샘플 AED 데이터 (서울 강남 지역 기준)
  // 실제로는 공공데이터포털 API나 Firebase에서 가져와야 함
  static List<AEDData> _getSampleAEDs() {
    return [
      AEDData(
        id: 'aed001',
        name: '강남역 1번 출구',
        address: '서울특별시 강남구 역삼동',
        latitude: 37.4980,
        longitude: 127.0276,
        available: true,
        institution: '서울교통공사',
      ),
      AEDData(
        id: 'aed002',
        name: 'GS25 편의점',
        address: '서울특별시 강남구 테헤란로',
        latitude: 37.4995,
        longitude: 127.0297,
        available: true,
        institution: 'GS리테일',
      ),
      AEDData(
        id: 'aed003',
        name: '시청 1층 로비',
        address: '서울특별시 중구 태평로',
        latitude: 37.5665,
        longitude: 126.9780,
        available: false,
        institution: '서울특별시청',
      ),
      AEDData(
        id: 'aed004',
        name: '종합병원 응급실',
        address: '서울특별시 강남구 논현동',
        latitude: 37.5050,
        longitude: 127.0263,
        available: true,
        phone: '02-1234-5678',
        institution: '강남종합병원',
      ),
      AEDData(
        id: 'aed005',
        name: '선릉역 2번 출구',
        address: '서울특별시 강남구 대치동',
        latitude: 37.5045,
        longitude: 127.0490,
        available: true,
        institution: '서울교통공사',
      ),
      AEDData(
        id: 'aed006',
        name: '삼성역 코엑스몰',
        address: '서울특별시 강남구 삼성동',
        latitude: 37.5115,
        longitude: 127.0590,
        available: true,
        institution: '코엑스',
      ),
    ];
  }

  // 현재 위치 주변의 AED 찾기
  static Future<List<AEDData>> getNearbyAEDs(Position position, {double radiusKm = 5.0}) async {
    try {
      // 실제로는 API 호출이나 Firebase 쿼리를 해야 함
      // 여기서는 샘플 데이터 사용
      List<AEDData> allAEDs = _getSampleAEDs();
      
      // 반경 내의 AED 필터링
      List<AEDData> nearbyAEDs = allAEDs.where((aed) {
        double distance = aed.getDistanceFrom(position);
        return distance <= radiusKm * 1000; // km를 m로 변환
      }).toList();
      
      // 거리순 정렬
      nearbyAEDs.sort((a, b) {
        double distA = a.getDistanceFrom(position);
        double distB = b.getDistanceFrom(position);
        return distA.compareTo(distB);
      });
      
      return nearbyAEDs;
    } catch (e) {
      print('Error fetching nearby AEDs: $e');
      return [];
    }
  }

  // 공공데이터포털 API 호출 (실제 구현 예시)
  // static Future<List<AEDData>> fetchAEDsFromAPI(Position position, {double radiusKm = 5.0}) async {
  //   try {
  //     final String apiKey = 'YOUR_API_KEY';
  //     final String url = 'http://apis.data.go.kr/B552657/AEDInfoInqireService/...';
  //     
  //     final response = await http.get(Uri.parse(url));
  //     
  //     if (response.statusCode == 200) {
  //       // Parse XML or JSON response
  //       // Convert to List<AEDData>
  //       return [];
  //     }
  //   } catch (e) {
  //     print('Error fetching AEDs from API: $e');
  //   }
  //   return [];
  // }

  // 랜덤으로 AED 사용 가능 여부 변경 (테스트용)
  static void randomizeAvailability(List<AEDData> aeds) {
    final random = Random();
    for (var aed in aeds) {
      // 80% 확률로 사용 가능
      // aed.available = random.nextDouble() > 0.2;
    }
  }
}
