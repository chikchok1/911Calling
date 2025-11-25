import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/aed_service.dart';

class AEDLocatorTab extends StatefulWidget {
  const AEDLocatorTab({super.key});

  @override
  State<AEDLocatorTab> createState() => _AEDLocatorTabState();
}

class _AEDLocatorTabState extends State<AEDLocatorTab> {
  Position? _currentPosition;
  List<AEDData> _nearbyAEDs = [];
  bool _isLoadingAEDs = false;
  NaverMapController? _mapController;
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });
      await _loadAEDsForCurrentLocation();
    }
  }

  Future<void> _updateMapCenter() async {
    if (_mapController == null) return;
    
    final cameraPosition = await _mapController!.getCameraPosition();
    if (mounted) {
      setState(() {
        _currentPosition = Position(
          latitude: cameraPosition.target.latitude,
          longitude: cameraPosition.target.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });
    }
  }

  Future<void> _loadAEDsForCurrentLocation() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingAEDs = true;
    });

    try {
      final aeds = await AEDService.getNearbyAEDs(_currentPosition!);
      if (mounted) {
        setState(() {
          _nearbyAEDs = aeds;
          _isLoadingAEDs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAEDs = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AED 검색 실패: $e')),
        );
      }
    }
  }

  void _showAEDInfo(AEDData aed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bolt, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                aed.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.location_on, '주소', aed.address),
            if (aed.institution != null)
              _buildInfoRow(Icons.business, '설치기관', aed.institution!),
            if (aed.phone != null)
              _buildInfoRow(Icons.phone, '연락처', aed.phone!),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: aed.available ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    aed.available ? Icons.check_circle : Icons.cancel,
                    color: aed.available ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    aed.available ? '사용 가능' : '사용 중',
                    style: TextStyle(
                      color: aed.available ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAED(aed);
            },
            icon: const Icon(Icons.directions),
            label: const Text('길찾기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAED(AEDData aed) {
    // 네이버 지도로 길찾기
    if (_mapController != null && _currentPosition != null) {
      _mapController!.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(aed.latitude, aed.longitude),
          zoom: 16,
        ),
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${aed.name}로 안내를 시작합니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'AED 위치 안내',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '가장 가까운 AED를 찾아드립니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _currentPosition == null
                    ? _buildLoadingMap()
                    : _buildNaverMap(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // AED Request Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

          const SizedBox(height: 16),

          // AED List
          Expanded(
            flex: 2,
            child: _nearbyAEDs.isEmpty
                ? _buildEmptyState()
                : _buildAEDList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '위치 정보를 가져오는 중...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNaverMap() {
    return Stack(
      children: [
        NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 15,
            ),
            locationButtonEnable: true,
          ),
          onMapReady: (controller) {
            _mapController = controller;
            _mapControllerCompleter.complete(controller);
            
            // Add markers for AEDs
            for (var aed in _nearbyAEDs) {
              controller.addOverlay(
                NMarker(
                  id: aed.id,
                  position: NLatLng(aed.latitude, aed.longitude),
                  caption: NOverlayCaption(text: aed.name),
                ),
              );
            }
          },
        ),
        
        // Search button
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: _buildSearchButton(),
          ),
        ),
        
        // Loading indicator
        if (_isLoadingAEDs)
          Positioned(
            bottom: 70,
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
          color: aed.available ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: aed.available ? Colors.green[200]! : Colors.grey[300]!,
          ),
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
                      color: aed.available ? Colors.amber[600] : Colors.grey[400],
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
                            Icon(Icons.navigation, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              distanceStr,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '도보 $walkingTime',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
                const SnackBar(
                  content: Text('주변 사용자에게 AED 요청을 전송했습니다'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
            ),
            child: const Text('요청'),
          ),
        ],
      ),
    );
  }
}
