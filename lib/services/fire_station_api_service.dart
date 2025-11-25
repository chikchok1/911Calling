import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/fire_station.dart';

/// 소방서 공공데이터 API 서비스
class FireStationApiService {
  static const String baseUrl = 'https://api.odcloud.kr/api/15048243/v1';

  /// 전체 소방서 목록 가져오기
  static Future<List<FireStation>> fetchAllFireStations() async {
    final apiKey = dotenv.env['FIRE_STATION_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('❌ FIRE_STATION_API_KEY가 .env 파일에 없습니다');
      return [];
    }

    try {
      // 여러 데이터셋을 가져와야 할 수 있음 (날짜별로 구분되어 있음)
      final datasets = [
        'uddi:818f12a7-70c1-4aff-81a0-80d5db5be9fb', // 2020년 데이터
        'uddi:a7630967-737e-4f06-84bc-f3e7b131f4a9', // 2024년 데이터
        'uddi:c6523118-231e-42ad-81a6-d771e4f8e374', // 2025년 데이터
      ];

      List<FireStation> allStations = [];

      // 가장 최신 데이터셋부터 시도
      for (final dataset in datasets.reversed) {
        final stations = await _fetchFromDataset(dataset, apiKey);
        if (stations.isNotEmpty) {
          print(
            '✅ ${stations.length}개 소방서 데이터 로드 성공 (${dataset.split(':').last.substring(0, 8)})',
          );
          allStations = stations;
          break; // 하나라도 성공하면 중단
        }
      }

      return allStations;
    } catch (e) {
      print('❌ 소방서 API 호출 오류: $e');
      return [];
    }
  }

  /// 특정 데이터셋에서 소방서 목록 가져오기
  static Future<List<FireStation>> _fetchFromDataset(
    String dataset,
    String apiKey,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/$dataset?'
        'page=1&perPage=1000&'
        'serviceKey=$apiKey',
      );

      print('🔍 소방서 API 호출 중: $dataset');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedBody);

        final List<dynamic> data = jsonData['data'] ?? [];

        if (data.isEmpty) {
          print('⚠️ 데이터가 비어있음');
          return [];
        }

        final List<FireStation> stations = [];

        for (final item in data) {
          try {
            // 필드명이 다를 수 있으므로 여러 경우를 체크
            final name = item['소방서명'] ?? item['기관명'] ?? item['name'] ?? '';

            final address =
                item['소재지도로명주소'] ?? item['주소'] ?? item['address'] ?? '';

            final lat = _parseDouble(
              item['위도'] ?? item['latitude'] ?? item['lat'],
            );

            final lng = _parseDouble(
              item['경도'] ?? item['longitude'] ?? item['lng'],
            );

            final phone = item['전화번호'] ?? item['대표전화'] ?? item['phone'] ?? '';

            // 위도/경도가 유효한 데이터만 추가
            if (name.isNotEmpty && lat != 0.0 && lng != 0.0) {
              stations.add(
                FireStation(
                  name: name,
                  address: address,
                  latitude: lat,
                  longitude: lng,
                  phone: phone,
                ),
              );
            }
          } catch (e) {
            // 개별 항목 파싱 실패는 무시하고 계속
            continue;
          }
        }

        return stations;
      } else {
        print('❌ API 응답 오류: ${response.statusCode}');
        print('응답 내용: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ 데이터셋 호출 오류: $e');
      return [];
    }
  }

  /// 문자열을 double로 안전하게 변환
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }
}
