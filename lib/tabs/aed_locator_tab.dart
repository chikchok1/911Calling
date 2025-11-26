import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/aed_service.dart';
import '../services/public_aed_api_service.dart';
import '../services/directions_service.dart';

class AEDLocatorTab extends StatefulWidget {
  const AEDLocatorTab({super.key});

  @override
  State<AEDLocatorTab> createState() => _AEDLocatorTabState();
}

class _AEDLocatorTabState extends State<AEDLocatorTab> {
  NaverMapController? _mapController;
  Position? _currentPosition;
  List<AEDData> _nearbyAEDs = [];
  bool _isLoading = true;
  bool _isLoadingAEDs = false;
  String? _errorMessage;
  bool _usePublicAPI = true;
  String _currentRegion = '서울특별시';
  NLatLng? _mapCenter;
  double _currentZoom = 15.0;
  bool _isMapFullScreen = false; // 지도 전체화면 모드

  // 실시간 위치 추적용
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTrackingLocation = true; // 기본적으로 추적 활성화

  // 마커 관리용
  final Set<NMarker> _aedMarkers = {};
  NMarker? _myLocationMarker;

  // 🆕 경로 안내용
  RouteResult? _currentRoute;
  NPathOverlay? _routePathOverlay;
  bool _isCalculatingRoute = false;
  AEDData? _selectedAED;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  /// 초기 위치 설정
  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('=== 위치 권한 요청 시작 ===');

      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _errorMessage = '위치 권한이 필요합니다.\n설정에서 위치 권한을 허용해주세요.';
          _isLoading = false;
        });
        return;
      }

      print('✅ 현재 위치: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = position;
        _mapCenter = NLatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // 실시간 위치 추적 시작
      _startLocationTracking();
    } catch (e) {
      print('❌ 위치 초기화 오류: $e');
      setState(() {
        _errorMessage = '위치를 가져오는 중 오류가 발생했습니다.\n$e';
        _isLoading = false;
      });
    }
  }

  /// 실시간 위치 추적 시작
  void _startLocationTracking() {
    print('🎯 실시간 위치 추적 시작');

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10미터 이동 시마다 업데이트
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            print('📍 위치 업데이트: ${position.latitude}, ${position.longitude}');

            setState(() {
              _currentPosition = position;
              _mapCenter = NLatLng(position.latitude, position.longitude);
            });

            // 추적 모드일 때만 카메라 이동
            if (_isTrackingLocation && _mapController != null) {
              _moveCameraToPosition(position, animate: true);
            }

            // 내 위치 마커 업데이트
            _updateMyLocationMarker();
          },
          onError: (error) {
            print('❌ 위치 스트림 오류: $error');
          },
        );

    setState(() {
      _isTrackingLocation = true;
    });
  }

  /// 실시간 위치 추적 토글
  void _toggleLocationTracking() {
    setState(() {
      _isTrackingLocation = !_isTrackingLocation;
    });

    if (_isTrackingLocation && _currentPosition != null) {
      // 추적 재개 시 현재 위치로 이동
      _moveCameraToPosition(_currentPosition!, animate: true);
    }
  }

  /// 현재 위치로 카메라 이동 (API 업데이트됨)
  Future<void> moveToCurrentLocation() async {
    if (_mapController == null) return;

    final position = await LocationService.getCurrentLocation();
    if (position == null) return;

    setState(() {
      _currentPosition = position;
      _mapCenter = NLatLng(position.latitude, position.longitude);
      _isTrackingLocation = true; // 추적 모드 활성화
    });

    await _moveCameraToPosition(position, animate: true);
    await _loadAEDsForCurrentLocation();
  }

  /// 위치로 카메라 이동 (새 API 사용)
  Future<void> _moveCameraToPosition(
    Position position, {
    bool animate = false,
  }) async {
    if (_mapController == null) return;

    final cameraUpdate = NCameraUpdate.withParams(
      target: NLatLng(position.latitude, position.longitude),
      zoom: _currentZoom,
    );

    if (animate) {
      cameraUpdate.setAnimation(
        animation: NCameraAnimation.easing,
        duration: const Duration(milliseconds: 500),
      );
    }

    await _mapController!.updateCamera(cameraUpdate);
  }

  /// 내 위치 마커 업데이트
  Future<void> _updateMyLocationMarker() async {
    if (_mapController == null || _currentPosition == null || !mounted) return;

    try {
      // 새로운 마커 생성
      final newMarker = NMarker(
        id: 'my_location',
        position: NLatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
      );

      final icon = await NOverlayImage.fromWidget(
        widget: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.navigation, color: Colors.white, size: 16),
        ),
        size: const Size(30, 30),
        context: context,
      );

      newMarker.setIcon(icon);
      _myLocationMarker = newMarker;

      // 모든 마커 다시 추가 (내 위치 + AED)
      await _refreshAllMarkers();
    } catch (e) {
      print('❌ 마커 업데이트 오류: $e');
    }
  }

  /// 주변 AED 검색
  Future<void> _loadAEDsForCurrentLocation() async {
    if (_mapCenter == null) return;

    setState(() {
      _isLoadingAEDs = true;
    });

    try {
      print('\n=== AED 데이터 로딩 시작 ===');
      print('지도 중심: ${_mapCenter!.latitude}, ${_mapCenter!.longitude}');

      final tempPosition = Position(
        latitude: _mapCenter!.latitude,
        longitude: _mapCenter!.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      List<AEDData> aeds = [];

      if (_usePublicAPI) {
        print('📡 공공 API 호출 중... (지역: $_currentRegion)');
        aeds = await PublicAEDApiService.searchAEDsByRegion(
          sido: _currentRegion,
          userPosition: tempPosition,
          radiusKm: 10.0,
        );
        print('✅ 공공 API에서 ${aeds.length}개 AED 가져옴');
      } else {
        print('📦 샘플 데이터 사용 중...');
        aeds = await AEDService.getNearbyAEDs(tempPosition, radiusKm: 10.0);
      }

      setState(() {
        _nearbyAEDs = aeds;
        _isLoadingAEDs = false;
      });

      await _updateAEDMarkers();
    } catch (e) {
      print('❌ AED 로딩 오류: $e');
      setState(() {
        _isLoadingAEDs = false;
      });
    }
  }

  /// AED 마커 업데이트 (새 API 사용)
  Future<void> _updateAEDMarkers() async {
    if (_mapController == null || !mounted) return;

    print('\n=== AED 마커 업데이트 시작 ===');

    try {
      // 새로운 AED 마커 생성
      _aedMarkers.clear();

      print('⚡ AED 마커 ${_nearbyAEDs.length}개 생성 중...');
      for (int i = 0; i < _nearbyAEDs.length && i < 100; i++) {
        final aed = _nearbyAEDs[i];

        final marker = NMarker(
          id: 'aed_${aed.id}',
          position: NLatLng(aed.latitude, aed.longitude),
        );

        final icon = await NOverlayImage.fromWidget(
          widget: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.amber[700],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
          size: const Size(36, 36),
          context: context,
        );

        marker.setIcon(icon);
        marker.setOnTapListener((overlay) {
          _showAEDInfo(aed);
        });

        _aedMarkers.add(marker);
      }

      await _refreshAllMarkers();
      print('✅ AED 마커 업데이트 완료!');
    } catch (e) {
      print('❌ AED 마커 업데이트 오류: $e');
    }
  }

  /// 모든 마커 새로고침 (새 API 사용)
  Future<void> _refreshAllMarkers() async {
    if (_mapController == null) return;

    try {
      // 기존 마커 모두 제거
      await _mapController!.clearOverlays(type: NOverlayType.marker);

      // 새 마커 세트 생성
      final allMarkers = <NMarker>{};

      // 내 위치 마커 추가
      if (_myLocationMarker != null) {
        allMarkers.add(_myLocationMarker!);
      }

      // AED 마커 추가
      allMarkers.addAll(_aedMarkers);

      // 모든 마커 한 번에 추가
      if (allMarkers.isNotEmpty) {
        await _mapController!.addOverlayAll(allMarkers);
      }
    } catch (e) {
      print('❌ 마커 새로고침 오류: $e');
    }
  }

  /// 지도 준비 완료
  void _onMapReady(NaverMapController controller) async {
    print('\n=== 지도 준비 완료! ===');
    _mapController = controller;

    // 현재 위치로 이동
    if (_currentPosition != null) {
      await _moveCameraToPosition(_currentPosition!, animate: false);
    }

    // 초기 AED 데이터 로드
    await _loadAEDsForCurrentLocation();

    // 내 위치 마커 추가
    await _updateMyLocationMarker();
  }

  /// 지도 중심 업데이트
  Future<void> _updateMapCenter() async {
    if (_mapController == null) return;

    final cameraPosition = await _mapController!.getCameraPosition();
    setState(() {
      _mapCenter = cameraPosition.target;
      _currentZoom = cameraPosition.zoom;
    });
    print(
      '📍 지도 중심: ${_mapCenter!.latitude}, ${_mapCenter!.longitude}, zoom: $_currentZoom',
    );
  }

  /// AED 상세 정보 표시
  void _showAEDInfo(AEDData aed) {
    if (_currentPosition == null) return;

    final distance = aed.getDistanceFrom(_currentPosition!);
    final distanceStr = LocationService.formatDistance(distance);
    final walkingTime = LocationService.calculateWalkingTime(distance);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aed.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                            '사용 가능',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.location_on, '주소', aed.address),
              if (aed.institution != null)
                _buildInfoRow(Icons.business, '관리기관', aed.institution!),
              if (aed.phone != null)
                _buildInfoRow(Icons.phone, '연락처', aed.phone!),
              _buildInfoRow(Icons.navigation, '거리', distanceStr),
              _buildInfoRow(Icons.access_time, '도보', walkingTime),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToAED(aed);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('길찾기'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.share),
                      label: const Text('공유'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// AED로 네비게이션 (새 API 사용)
  void _navigateToAED(AEDData aed) async {
    if (_mapController == null) return;

    final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
      target: NLatLng(aed.latitude, aed.longitude),
      zoom: 17,
    );

    cameraUpdate.setAnimation(
      animation: NCameraAnimation.easing,
      duration: const Duration(milliseconds: 800),
    );

    await _mapController!.updateCamera(cameraUpdate);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${aed.name}로 이동합니다'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 지역 선택 다이얼로그
  void _showRegionSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지역 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: KoreanRegions.sidoList.length,
            itemBuilder: (context, index) {
              final region = KoreanRegions.sidoList[index];
              return ListTile(
                title: Text(region),
                selected: _currentRegion == region,
                trailing: _currentRegion == region
                    ? const Icon(Icons.check, color: Colors.amber)
                    : null,
                onTap: () {
                  setState(() {
                    _currentRegion = region;
                  });
                  Navigator.pop(context);
                  _loadAEDsForCurrentLocation();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('위치 정보를 불러오는 중...'),
                ],
              ),
            )
          : _errorMessage != null
          ? _buildErrorWidget()
          : _buildMapWithList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '알 수 없는 오류가 발생했습니다',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWithList() {
    // 전체화면 모드
    if (_isMapFullScreen) {
      return Stack(
        children: [
          // 전체 지도
          _mapCenter == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    NaverMap(
                      options: NaverMapViewOptions(
                        initialCameraPosition: NCameraPosition(
                          target: _mapCenter!,
                          zoom: _currentZoom,
                        ),
                        locationButtonEnable: false,
                        mapType: NMapType.basic,
                        activeLayerGroups: [
                          NLayerGroup.building,
                          NLayerGroup.transit,
                        ],
                      ),
                      onMapReady: _onMapReady,
                    ),

                    // 닫기 버튼
                    Positioned(
                      top: 48,
                      left: 12,
                      child: _buildMapIconButton(
                        icon: Icons.close_fullscreen,
                        onPressed: () {
                          setState(() {
                            _isMapFullScreen = false;
                          });
                        },
                        color: Colors.red,
                      ),
                    ),

                    // 기존 컨트롤 버튼들
                    Positioned(
                      top: 48,
                      right: 12,
                      child: Column(
                        children: [
                          _buildMapIconButton(
                            icon: _isTrackingLocation
                                ? Icons.gps_fixed
                                : Icons.gps_not_fixed,
                            onPressed: _toggleLocationTracking,
                            color: _isTrackingLocation ? Colors.blue : null,
                          ),
                          const SizedBox(height: 8),
                          _buildMapIconButton(
                            icon: Icons.my_location,
                            onPressed: moveToCurrentLocation,
                          ),
                          const SizedBox(height: 8),
                          _buildMapIconButton(
                            icon: Icons.add,
                            onPressed: () async {
                              if (_mapController == null) return;
                              final pos = await _mapController!
                                  .getCameraPosition();
                              final update = NCameraUpdate.withParams(
                                zoom: pos.zoom + 1,
                              );
                              await _mapController!.updateCamera(update);
                              setState(() {
                                _currentZoom = pos.zoom + 1;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMapIconButton(
                            icon: Icons.remove,
                            onPressed: () async {
                              if (_mapController == null) return;
                              final pos = await _mapController!
                                  .getCameraPosition();
                              final update = NCameraUpdate.withParams(
                                zoom: pos.zoom - 1,
                              );
                              await _mapController!.updateCamera(update);
                              setState(() {
                                _currentZoom = pos.zoom - 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_isTrackingLocation)
                      Positioned(
                        top: 104,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.radio_button_checked,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '실시간 추적 중',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_isLoadingAEDs)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'AED 검색 중...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      );
    }

    // 기본 모드
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AED 위치 안내',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '가장 가까운 AED를 찾아드립니다',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _usePublicAPI ? '공공 API' : '샘플',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _usePublicAPI,
                      onChanged: (value) {
                        setState(() {
                          _usePublicAPI = value;
                        });
                        _loadAEDsForCurrentLocation();
                      },
                      activeColor: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 지도
        Expanded(
          flex: 3,
          child: _mapCenter == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    NaverMap(
                      options: NaverMapViewOptions(
                        initialCameraPosition: NCameraPosition(
                          target: _mapCenter!,
                          zoom: _currentZoom,
                        ),
                        locationButtonEnable: false,
                        mapType: NMapType.basic,
                        activeLayerGroups: [
                          NLayerGroup.building,
                          NLayerGroup.transit,
                        ],
                      ),
                      onMapReady: _onMapReady,
                    ),

                    // 지역 선택
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildCompactButton(
                        onTap: _showRegionSelector,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _currentRegion,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 14),
                          ],
                        ),
                      ),
                    ),

                    // 컨트롤 버튼
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        children: [
                          // GPS 추적 토글
                          _buildMapIconButton(
                            icon: _isTrackingLocation
                                ? Icons.gps_fixed
                                : Icons.gps_not_fixed,
                            onPressed: _toggleLocationTracking,
                            color: _isTrackingLocation ? Colors.blue : null,
                          ),
                          const SizedBox(height: 8),
                          // 내 위치로
                          _buildMapIconButton(
                            icon: Icons.my_location,
                            onPressed: moveToCurrentLocation,
                          ),
                          const SizedBox(height: 8),
                          // 확대
                          _buildMapIconButton(
                            icon: Icons.add,
                            onPressed: () async {
                              if (_mapController == null) return;
                              final pos = await _mapController!
                                  .getCameraPosition();
                              final update = NCameraUpdate.withParams(
                                zoom: pos.zoom + 1,
                              );
                              await _mapController!.updateCamera(update);
                              setState(() {
                                _currentZoom = pos.zoom + 1;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          // 축소
                          _buildMapIconButton(
                            icon: Icons.remove,
                            onPressed: () async {
                              if (_mapController == null) return;
                              final pos = await _mapController!
                                  .getCameraPosition();
                              final update = NCameraUpdate.withParams(
                                zoom: pos.zoom - 1,
                              );
                              await _mapController!.updateCamera(update);
                              setState(() {
                                _currentZoom = pos.zoom - 1;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          // 전체화면
                          _buildMapIconButton(
                            icon: Icons.fullscreen,
                            onPressed: () {
                              setState(() {
                                _isMapFullScreen = true;
                              });
                            },
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),

                    // 추적 상태
                    if (_isTrackingLocation)
                      Positioned(
                        top: 58,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.radio_button_checked,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '실시간 추적 중',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 이 지역 검색
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildSearchButton()),
                    ),

                    // 로딩
                    if (_isLoadingAEDs)
                      Positioned(
                        bottom: 58,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'AED 검색 중...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),

        // AED 요청 버튼
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAEDRequestDialog,
              icon: const Icon(Icons.people, size: 18),
              label: const Text(
                '주변 사용자에게 AED 요청',
                style: TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // AED 목록 (높이 증가 & 스크롤 가능)
        Expanded(
          flex: 3,
          child: _nearbyAEDs.isEmpty ? _buildEmptyState() : _buildAEDList(),
        ),
      ],
    );
  }

  Widget _buildCompactButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 18,
            color: color != null ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.amber[700],
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _updateMapCenter();
            await _loadAEDsForCurrentLocation();
          },
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  '이 지역 검색',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '이 지역에 AED가 없습니다',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadAEDsForCurrentLocation,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('다시 검색'),
          ),
        ],
      ),
    );
  }

  Widget _buildAEDList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '가까운 AED',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_nearbyAEDs.length}개',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _nearbyAEDs.length,
            itemBuilder: (context, index) {
              return _buildAEDListItem(_nearbyAEDs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAEDListItem(AEDData aed) {
    if (_currentPosition == null) return const SizedBox.shrink();

    final distance = aed.getDistanceFrom(_currentPosition!);
    final distanceStr = LocationService.formatDistance(distance);
    final walkingTime = LocationService.calculateWalkingTime(distance);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAEDInfo(aed),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aed.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.navigation,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '도보 $walkingTime',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _navigateToAED(aed),
                    icon: const Icon(Icons.directions, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.amber[100],
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAEDRequestDialog() {
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
                const SnackBar(content: Text('주변 사용자에게 AED 요청을 전송했습니다')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
            child: const Text('요청'),
          ),
        ],
      ),
    );
  }
}
