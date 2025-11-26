import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/fire_station.dart';

/// 소방서 공공데이터 API 서비스
class FireStationApiService {
  // 소방서 좌표 데이터 API (위도/경도 포함)
  static const String baseUrl = 'https://api.odcloud.kr/api/15138232/v1';

  /// 전체 소방서 목록 가져오기
  static Future<List<FireStation>> fetchAllFireStations() async {
    final apiKey = dotenv.env['FIRE_STATION_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('❌ FIRE_STATION_API_KEY가 .env 파일에 없습니다');
      return [];
    }

    try {
      // 소방서 좌표 현황 데이터 (위도/경도 포함)
      final datasets = [
        'uddi:da0c6c93-f05a-453d-849f-e4c3697222e3', // 2024년 9월 데이터
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
      print('🔗 URL: ${url.toString()}');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print('📡 API 응답 상태: ${response.statusCode}');
      print('📝 응답 본문 길이: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = json.decode(decodedBody);

        print('📊 응답 구조 키: ${jsonData.keys.toList()}');

        final List<dynamic> data = jsonData['data'] ?? [];

        print('✅ ${data.length}개의 소방서 데이터 발견');

        if (data.isEmpty) {
          print('⚠️ 데이터가 비어있음');
          return [];
        }

        print('📋 데이터 필드명: ${data[0].keys.toList()}');

        // 첫 번째 항목의 전체 데이터 출력 (디버깅용)
        if (data.isNotEmpty) {
          print('🔍 첫 번째 데이터 전체:');
          data[0].forEach((key, value) {
            print('  "$key": $value (타입: ${value.runtimeType})');
          });
        }

        final List<FireStation> stations = [];

        for (final item in data) {
          try {
            // 소방서 좌표 데이터의 필드명
            final name =
                item['소방서 및 안전센터명'] ??
                item['소방서명'] ??
                item['소방서'] ??
                item['기관명'] ??
                '';
            final address = item['주소'] ?? item['소재지'] ?? '';
            final phone = item['전화번호'] ?? item['대표전화'] ?? '';

            // 위도/경도 - 공공데이터는 X좌표=위도, Y좌표=경도
            final lat = _parseDouble(
              item['X좌표'] ?? item['위도'] ?? item['latitude'],
            );
            final lng = _parseDouble(
              item['Y좌표'] ?? item['경도'] ?? item['longitude'],
            );

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
            } else {
              print('! 유효하지 않은 데이터: name=$name, lat=$lat, lng=$lng');
            }
          } catch (e) {
            // 개별 항목 파싱 실패는 무시하고 계속
            continue;
          }
        }

        print('✅ 최종적으로 ${stations.length}개의 소방서 데이터 파싱 완료');
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
