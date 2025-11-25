import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // 위치 권한 확인 및 요청
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return status.isGranted;
  }

  // 현재 위치 가져오기
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // 두 지점 간의 거리 계산 (미터)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // 거리를 읽기 좋은 형태로 변환
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  // 도보 시간 계산 (평균 시속 4km 기준)
  static String calculateWalkingTime(double distanceInMeters) {
    const double walkingSpeedKmH = 4.0;
    double timeInMinutes = (distanceInMeters / 1000) / walkingSpeedKmH * 60;
    
    if (timeInMinutes < 1) {
      return '1분 미만';
    } else {
      return '${timeInMinutes.round()}분';
    }
  }
}
