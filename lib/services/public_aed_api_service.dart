import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:geolocator/geolocator.dart';
import 'aed_service.dart';
import 'location_service.dart';

class PublicAEDApiService {
  // 공공데이터포털 API 키 (api_keys.dart에서 관리)
  static String get serviceKey => '여기다가 키 넣으세요';

  // API 엔드포인트
  static const String baseUrl =
      'https://apis.data.go.kr/B552657/AEDInfoInqireService';

  /// 자동심장충격기 위치정보 조회
  /// Q0: 시도명 (예: 서울특별시)
  /// Q1: 시군구명 (예: 강남구)
  /// pageNo: 페이지 번호
  /// numOfRows: 한 페이지 결과 수
  static Future<List<AEDData>> getAEDLocationInfo({
    String? sido, // 시도명 (예: 서울특별시)
    String? sigungu, // 시군구명 (예: 강남구)
    int pageNo = 1,
    int numOfRows = 100,
  }) async {
    try {
      // API URL 구성
      final queryParams = {
        'serviceKey': serviceKey,
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
      };

      if (sido != null && sido.isNotEmpty) {
        queryParams['Q0'] = sido;
      }
      if (sigungu != null && sigungu.isNotEmpty) {
        queryParams['Q1'] = sigungu;
      }

      final uri = Uri.parse(
        '$baseUrl/getAedLcinfoInqire',
      ).replace(queryParameters: queryParams);

      print('📡 Fetching AED data from public API...');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // XML 파싱
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        List<AEDData> aedList = [];

        for (var item in items) {
          try {
            // XML에서 필요한 정보 추출
            final id = _getElementText(item, 'rnum') ?? '';
            final org = _getElementText(item, 'org') ?? '';
            final buildPlace = _getElementText(item, 'buildPlace') ?? '';
            final buildAddress = _getElementText(item, 'buildAddress') ?? '';
            final clerkTel = _getElementText(item, 'clerkTel');
            final manager = _getElementText(item, 'manager');

            // 위도, 경도
            final wgs84Lat = _getElementText(item, 'wgs84Lat');
            final wgs84Lon = _getElementText(item, 'wgs84Lon');

            // 위경도가 없으면 스킵
            if (wgs84Lat == null || wgs84Lon == null) continue;

            final latitude = double.tryParse(wgs84Lat);
            final longitude = double.tryParse(wgs84Lon);

            if (latitude == null || longitude == null) continue;

            // AEDData 객체 생성
            aedList.add(
              AEDData(
                id: 'public_$id',
                name: buildPlace.isNotEmpty ? buildPlace : org,
                address: buildAddress,
                latitude: latitude,
                longitude: longitude,
                available: true, // 기본값으로 사용 가능
                phone: clerkTel,
                institution: manager ?? org,
              ),
            );
          } catch (e) {
            print('⚠️ Error parsing AED item: $e');
            continue;
          }
        }

        print('✅ Fetched ${aedList.length} AEDs from public API');
        return aedList;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching AED data: $e');
      return [];
    }
  }

  /// 현재 위치 기반 주변 AED 검색
  static Future<List<AEDData>> getNearbyAEDsFromPublicAPI(
    Position position, {
    double radiusKm = 5.0,
  }) async {
    try {
      // 시도명과 시군구명 추출 (여기서는 서울 기준으로 예시)
      // 실제로는 역지오코딩을 사용하여 현재 위치의 시도/시군구를 얻어야 함

      // 일단 서울특별시 전체 데이터 가져오기
      List<AEDData> allAEDs = await getAEDLocationInfo(
        sido: '서울특별시',
        numOfRows: 1000, // 많은 데이터 가져오기
      );

      // 반경 내 필터링
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
      print('❌ Error in getNearbyAEDsFromPublicAPI: $e');
      return [];
    }
  }

  /// 지역별로 AED 검색 (시도, 시군구 지정)
  static Future<List<AEDData>> searchAEDsByRegion({
    required String sido,
    String? sigungu,
    Position? userPosition,
    double? radiusKm,
  }) async {
    List<AEDData> aeds = await getAEDLocationInfo(
      sido: sido,
      sigungu: sigungu,
      numOfRows: 1000,
    );

    // 사용자 위치가 있고 반경이 지정된 경우 필터링
    if (userPosition != null && radiusKm != null) {
      aeds = aeds.where((aed) {
        double distance = aed.getDistanceFrom(userPosition);
        return distance <= radiusKm * 1000;
      }).toList();

      // 거리순 정렬
      aeds.sort((a, b) {
        double distA = a.getDistanceFrom(userPosition);
        double distB = b.getDistanceFrom(userPosition);
        return distA.compareTo(distB);
      });
    }

    return aeds;
  }

  /// XML 요소에서 텍스트 추출 헬퍼 함수
  static String? _getElementText(xml.XmlElement parent, String tagName) {
    try {
      final element = parent.findElements(tagName).firstOrNull;
      return element?.innerText.trim();
    } catch (e) {
      return null;
    }
  }
}

// 주요 시도 목록
class KoreanRegions {
  static const List<String> sidoList = [
    '서울특별시',
    '부산광역시',
    '대구광역시',
    '인천광역시',
    '광주광역시',
    '대전광역시',
    '울산광역시',
    '세종특별자치시',
    '경기도',
    '강원도',
    '충청북도',
    '충청남도',
    '전라북도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도',
  ];

  // 서울시 구 목록
  static const List<String> seoulGu = [
    '강남구',
    '강동구',
    '강북구',
    '강서구',
    '관악구',
    '광진구',
    '구로구',
    '금천구',
    '노원구',
    '도봉구',
    '동대문구',
    '동작구',
    '마포구',
    '서대문구',
    '서초구',
    '성동구',
    '성북구',
    '송파구',
    '양천구',
    '영등포구',
    '용산구',
    '은평구',
    '종로구',
    '중구',
    '중랑구',
  ];
}
