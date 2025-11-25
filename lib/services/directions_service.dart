import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 네이버 Directions API를 사용한 경로 계산 서비스
class DirectionsService {
  // 🔑 네이버 클라우드 플랫폼 API 키 (하드코딩)
  static const String _clientId = 's0jlbu865h';
  static const String _clientSecret = 'Tv2RohyhTrAqs6eZBs1h6gC1DsZ9oxAp9Dc0qx5o';
  
  // 🚶 도보 경로 API 엔드포인트
  static const String _walkingApiUrl = 'https://naveropenapi.apigw.ntruss.com/map-direction-15/v1/walking';
  
  /// 도보 경로 계산
  /// 
  /// [start] 출발지 좌표 (내 위치)
  /// [goal] 도착지 좌표 (AED 위치)
  /// 
  /// Returns: [RouteResult] 경로 정보 (성공 시) 또는 null (실패 시)
  static Future<RouteResult?> getWalkingRoute({
    required NLatLng start,
    required NLatLng goal,
  }) async {
    try {
      print('\n=== 경로 계산 시작 ===');
      print('출발: ${start.latitude}, ${start.longitude}');
      print('도착: ${goal.latitude}, ${goal.longitude}');
      
      // API URL 구성 (경도,위도 순서 주의!)
      final uri = Uri.parse(
        '$_walkingApiUrl?start=${start.longitude},${start.latitude}&goal=${goal.longitude},${goal.latitude}&option=trafast',
      );
      
      // API 요청
      final response = await http.get(
        uri,
        headers: {
          'X-NCP-APIGW-API-KEY-ID': _clientId,
          'X-NCP-APIGW-API-KEY': _clientSecret,
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('경로 계산 시간 초과');
        },
      );
      
      print('응답 상태: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 응답 검증
        if (data['code'] != 0) {
          print('❌ API 에러: ${data['message']}');
          return null;
        }
        
        // 경로 데이터 추출
        final route = data['route']?['trafast']?[0];
        if (route == null) {
          print('❌ 경로 데이터 없음');
          return null;
        }
        
        // 경로 정보 파싱
        final summary = route['summary'];
        final pathData = route['path'] as List<dynamic>;
        
        // 좌표 리스트 변환 (경도, 위도 → NLatLng)
        final path = pathData.map((coord) {
          final lon = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          return NLatLng(lat, lon);
        }).toList();
        
        final result = RouteResult(
          path: path,
          distance: summary['distance'] as int,
          duration: summary['duration'] as int,
          bbox: _parseBbox(summary['bbox']),
        );
        
        print('✅ 경로 계산 완료!');
        print('   거리: ${result.distance}m');
        print('   시간: ${result.duration ~/ 60000}분');
        print('   경로점: ${path.length}개');
        
        return result;
        
      } else if (response.statusCode == 401) {
        print('❌ API 인증 실패 (401): Client ID/Secret 확인 필요');
        return null;
      } else if (response.statusCode == 403) {
        print('❌ API 권한 없음 (403): Directions API 활성화 필요');
        return null;
      } else {
        print('❌ API 요청 실패: ${response.statusCode}');
        print('   응답: ${response.body}');
        return null;
      }
      
    } catch (e, stackTrace) {
      print('❌ 경로 계산 오류: $e');
      print('스택 트레이스: $stackTrace');
      return null;
    }
  }
  
  /// Bbox 파싱 (경계 좌표)
  static List<NLatLng> _parseBbox(List<dynamic> bbox) {
    try {
      // bbox: [[lon1, lat1], [lon2, lat2]]
      final southwest = NLatLng(
        (bbox[0][1] as num).toDouble(),
        (bbox[0][0] as num).toDouble(),
      );
      final northeast = NLatLng(
        (bbox[1][1] as num).toDouble(),
        (bbox[1][0] as num).toDouble(),
      );
      return [southwest, northeast];
    } catch (e) {
      print('⚠️ Bbox 파싱 실패: $e');
      return [];
    }
  }
  
  /// 거리를 사람이 읽기 쉬운 형식으로 변환
  static String formatDistance(int meters) {
    if (meters < 1000) {
      return '${meters}m';
    } else {
      final km = (meters / 1000).toStringAsFixed(1);
      return '${km}km';
    }
  }
  
  /// 시간을 사람이 읽기 쉬운 형식으로 변환
  static String formatDuration(int milliseconds) {
    final minutes = (milliseconds / 60000).ceil();
    if (minutes < 60) {
      return '$minutes분';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours시간 ${mins}분';
    }
  }
}

/// 경로 결과 데이터 클래스
class RouteResult {
  /// 경로 좌표 리스트
  final List<NLatLng> path;
  
  /// 총 거리 (미터)
  final int distance;
  
  /// 예상 소요 시간 (밀리초)
  final int duration;
  
  /// 경계 좌표 (지도 줌 조정용) [southwest, northeast]
  final List<NLatLng> bbox;
  
  RouteResult({
    required this.path,
    required this.distance,
    required this.duration,
    required this.bbox,
  });
  
  /// 거리 포맷팅
  String get distanceText => DirectionsService.formatDistance(distance);
  
  /// 시간 포맷팅
  String get durationText => DirectionsService.formatDuration(duration);
}
