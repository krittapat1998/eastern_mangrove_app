import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'area_card.dart' show getMangroveStatusColor;

class MangroveMapTab extends StatelessWidget {
  final List<Map<String, dynamic>> filteredAreas;
  final Position? currentPosition;
  final Widget Function() buildFilterChips;
  final void Function(Map<String, dynamic>) onAreaTap;
  final VoidCallback onAddPressed;

  const MangroveMapTab({
    super.key,
    required this.filteredAreas,
    required this.currentPosition,
    required this.buildFilterChips,
    required this.onAreaTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final areasWithLocation = filteredAreas
        .where((a) => a['latitude'] != null && a['longitude'] != null)
        .toList();

    double centerLat;
    double centerLon;
    double zoom;

    if (areasWithLocation.isEmpty) {
      centerLat = 13.6904;
      centerLon = 101.0779;
      zoom = 9.0;
    } else {
      centerLat = areasWithLocation.fold(0.0, (sum, a) {
            final lat = a['latitude'];
            return sum +
                (lat is num
                    ? lat.toDouble()
                    : double.tryParse(lat.toString()) ?? 0.0);
          }) /
          areasWithLocation.length;

      centerLon = areasWithLocation.fold(0.0, (sum, a) {
            final lon = a['longitude'];
            return sum +
                (lon is num
                    ? lon.toDouble()
                    : double.tryParse(lon.toString()) ?? 0.0);
          }) /
          areasWithLocation.length;

      zoom = 10.0;
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'กรองตามสถานะ',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              buildFilterChips(),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLon),
                  initialZoom: zoom,
                  minZoom: 5,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.example.eastern_mangrove_app',
                  ),
                  if (currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(currentPosition!.latitude,
                              currentPosition!.longitude),
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (areasWithLocation.isNotEmpty)
                    MarkerLayer(
                      markers: areasWithLocation.map((area) {
                        final lat = area['latitude'];
                        final lon = area['longitude'];
                        final latDouble = lat is num
                            ? lat.toDouble()
                            : double.tryParse(lat.toString()) ?? 0.0;
                        final lonDouble = lon is num
                            ? lon.toDouble()
                            : double.tryParse(lon.toString()) ?? 0.0;

                        return Marker(
                          point: LatLng(latDouble, lonDouble),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => onAreaTap(area),
                            child: Icon(
                              Icons.eco,
                              color: getMangroveStatusColor(
                                  area['conservation_status'] ?? ''),
                              size: 40,
                              shadows: const [
                                Shadow(
                                    color: Colors.white, blurRadius: 8),
                                Shadow(
                                    color: Colors.white, blurRadius: 4),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
              if (filteredAreas.isEmpty)
                Container(
                  color: Colors.black26,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined,
                                size: 64,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'ยังไม่มีข้อมูลพื้นที่ป่าชายเลน',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'กดปุ่ม + ด้านล่างเพื่อเพิ่มพื้นที่',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (filteredAreas.isNotEmpty && areasWithLocation.isEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'ยังไม่มีพื้นที่ที่ระบุพิกัด\nเพิ่มพิกัดในการแก้ไขพื้นที่',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: onAddPressed,
                  backgroundColor: const Color(0xFF2E7D32),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
