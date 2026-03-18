import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../models/models.dart';
import '../../../../services/api_client.dart';

Future<Map<String, double>?> _showLocationPicker(
  BuildContext context, {
  double? initialLat,
  double? initialLon,
  Position? currentPosition,
}) async {
  double selectedLat =
      initialLat ?? currentPosition?.latitude ?? 13.6904;
  double selectedLon =
      initialLon ?? currentPosition?.longitude ?? 100.7503;

  return showDialog<Map<String, double>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('เลือกตำแหน่งบนแผนที่'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(selectedLat, selectedLon),
              initialZoom: 13,
              onTap: (tapPosition, point) {
                setDialogState(() {
                  selectedLat = point.latitude;
                  selectedLon = point.longitude;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.eastern_mangrove_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(selectedLat, selectedLon),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'lat': selectedLat,
                'lon': selectedLon,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    ),
  );
}

void showMangroveAddAreaDialog(
  BuildContext context, {
  Map<String, dynamic>? existingArea,
  required List<String> provinces,
  required Map<String, String> conservationStatusMap,
  required ApiClient apiClient,
  required Position? currentPosition,
  required Future<Map<String, double>?> Function() getCurrentLocation,
  required Future<void> Function() onSuccess,
}) {
  // --- Text controllers ---
  final areaNameController =
      TextEditingController(text: existingArea?['area_name'] ?? '');
  final locationController =
      TextEditingController(text: existingArea?['location'] ?? '');
  final sizeController = TextEditingController(
      text: existingArea?['size_hectares']?.toString() ?? '');

  String speciesText = '';
  if (existingArea?['mangrove_species'] != null) {
    final species = existingArea!['mangrove_species'];
    speciesText =
        species is List ? species.join(', ') : species.toString();
  }
  final speciesController = TextEditingController(text: speciesText);

  final descriptionController =
      TextEditingController(text: existingArea?['description'] ?? '');
  final yearController = TextEditingController(
      text: existingArea?['established_year']?.toString() ?? '');
  final organizationController = TextEditingController(
      text: existingArea?['managing_organization'] ?? '');

  String threatsText = '';
  if (existingArea?['threats'] != null) {
    final threats = existingArea!['threats'];
    threatsText =
        threats is List ? threats.join(', ') : threats.toString();
  }
  final threatsController = TextEditingController(text: threatsText);

  String activitiesText = '';
  if (existingArea?['conservation_activities'] != null) {
    final activities = existingArea!['conservation_activities'];
    activitiesText =
        activities is List ? activities.join(', ') : activities.toString();
  }
  final activitiesController =
      TextEditingController(text: activitiesText);

  String selectedProvince =
      existingArea?['province'] ?? 'ฉะเชิงเทรา';
  String selectedStatus =
      existingArea?['conservation_status'] ?? 'protected';

  double? selectedLat;
  double? selectedLon;
  if (existingArea != null) {
    if (existingArea['latitude'] != null) {
      selectedLat = existingArea['latitude'] is String
          ? double.tryParse(existingArea['latitude'])
          : existingArea['latitude']?.toDouble();
    }
    if (existingArea['longitude'] != null) {
      selectedLon = existingArea['longitude'] is String
          ? double.tryParse(existingArea['longitude'])
          : existingArea['longitude']?.toDouble();
    }
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        String? dialogError;
        return StatefulBuilder(
          builder: (ctx, setInnerState) => AlertDialog(
            title: Text(existingArea == null
                ? 'เพิ่มพื้นที่ป่าชายเลน'
                : 'แก้ไขพื้นที่ป่าชายเลน'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: areaNameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อพื้นที่ *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.eco),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: locationController,
                            decoration: const InputDecoration(
                              labelText: 'สถานที่ *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedProvince,
                            decoration: const InputDecoration(
                              labelText: 'จังหวัด *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                            items: provinces
                                .where((p) => p != 'ทั้งหมด')
                                .map((p) => DropdownMenuItem(
                                    value: p, child: Text(p)))
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedProvince = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sizeController,
                            decoration: const InputDecoration(
                              labelText: 'ขนาดพื้นที่ (ไร่)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.square_foot),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'สถานะการอนุรักษ์',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.shield),
                            ),
                            items: conservationStatusMap.entries
                                .map((e) => DropdownMenuItem(
                                    value: e.key, child: Text(e.value)))
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: speciesController,
                      decoration: const InputDecoration(
                        labelText: 'พันธุ์ไม้ป่าชายเลน',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.nature),
                        hintText: 'เช่น โกงกาง, ตะบูน, แสม',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'คำอธิบาย',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: yearController,
                            decoration: const InputDecoration(
                              labelText: 'ปีที่ก่อตั้ง',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: organizationController,
                            decoration: const InputDecoration(
                              labelText: 'องค์กรดูแล',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: threatsController,
                      decoration: const InputDecoration(
                        labelText: 'ภัยคุกคาม',
                        border: OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.warning, color: Colors.red),
                        hintText: 'ระบุภัยคุกคามที่อาจเกิดขึ้น',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: activitiesController,
                      decoration: const InputDecoration(
                        labelText: 'กิจกรรมอนุรักษ์',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.volunteer_activism,
                            color: Colors.green),
                        hintText: 'ระบุกิจกรรมอนุรักษ์ที่ดำเนินการ',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Location Picker card
                    Card(
                      elevation: 2,
                      color: selectedLat == null || selectedLon == null
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: selectedLat == null || selectedLon == null
                              ? Colors.orange.shade300
                              : Colors.green.shade300,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final loc = await _showLocationPicker(
                            ctx,
                            initialLat: selectedLat,
                            initialLon: selectedLon,
                            currentPosition: currentPosition,
                          );
                          if (loc != null) {
                            setDialogState(() {
                              selectedLat = loc['lat'];
                              selectedLon = loc['lon'];
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                selectedLat == null || selectedLon == null
                                    ? Icons.add_location_alt
                                    : Icons.check_circle,
                                color: selectedLat == null ||
                                        selectedLon == null
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedLat == null ||
                                              selectedLon == null
                                          ? 'เลือกตำแหน่งบนแผนที่'
                                          : 'ตำแหน่งที่เลือก',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: selectedLat == null ||
                                                selectedLon == null
                                            ? Colors.orange.shade700
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                    if (selectedLat != null &&
                                        selectedLon != null)
                                      Text(
                                        'Lat: ${selectedLat!.toStringAsFixed(6)}\nLon: ${selectedLon!.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final loc = await getCurrentLocation();
                          if (loc != null) {
                            setDialogState(() {
                              selectedLat = loc['lat'];
                              selectedLon = loc['lon'];
                            });
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('ได้รับตำแหน่งปัจจุบันแล้ว'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.my_location),
                        label: const Text('ใช้ตำแหน่งปัจจุบัน'),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.blue.shade400),
                          foregroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border:
                              Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dialogError!,
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (areaNameController.text.isEmpty ||
                      locationController.text.isEmpty) {
                    setInnerState(() {
                      dialogError =
                          'กรุณากรอกข้อมูลที่จำเป็น (ชื่อพื้นที่, สถานที่)';
                    });
                    return;
                  }

                  if (selectedLat == null || selectedLon == null) {
                    setInnerState(() {
                      dialogError =
                          '⚠️ กรุณาเลือกตำแหน่งพื้นที่ — กดการ์ด "เลือกตำแหน่งบนแผนที่" หรือ "ใช้ตำแหน่งปัจจุบัน"';
                    });
                    return;
                  }

                  final areaData = {
                    'area_name': areaNameController.text,
                    'location': locationController.text,
                    'province': selectedProvince,
                    'size_hectares': sizeController.text.isNotEmpty
                        ? double.tryParse(sizeController.text)
                        : null,
                    'mangrove_species':
                        speciesController.text.isNotEmpty
                            ? speciesController.text
                            : null,
                    'conservation_status': selectedStatus,
                    'latitude': selectedLat,
                    'longitude': selectedLon,
                    'description': descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                    'established_year': yearController.text.isNotEmpty
                        ? int.tryParse(yearController.text)
                        : null,
                    'managing_organization':
                        organizationController.text.isNotEmpty
                            ? organizationController.text
                            : null,
                    'threats': threatsController.text.isNotEmpty
                        ? threatsController.text
                        : null,
                    'conservation_activities':
                        activitiesController.text.isNotEmpty
                            ? activitiesController.text
                            : null,
                  };

                  Navigator.pop(ctx);

                  try {
                    final ApiResponse<Map<String, dynamic>> response;
                    if (existingArea == null) {
                      response =
                          await apiClient.createMangroveArea(areaData);
                    } else {
                      response = await apiClient.updateMangroveArea(
                          existingArea['id'], areaData);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response.message ??
                              (response.success
                                  ? 'บันทึกสำเร็จ'
                                  : 'เกิดข้อผิดพลาด')),
                          backgroundColor: response.success
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                      if (response.success) await onSuccess();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('เกิดข้อผิดพลาด: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child:
                    Text(existingArea == null ? 'เพิ่ม' : 'บันทึก'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
