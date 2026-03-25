import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../models/models.dart';
import '../../../../services/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionTitle(String title, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Color(0xFF2E7D32))),
      ],
    ),
  );
}

InputDecoration _fieldDecoration(String label, IconData icon, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Map location picker
// ─────────────────────────────────────────────────────────────────────────────

Future<Map<String, double>?> _showLocationPicker(
  BuildContext context, {
  double? initialLat,
  double? initialLon,
  Position? currentPosition,
}) async {
  double selectedLat = initialLat ?? currentPosition?.latitude ?? 13.6904;
  double selectedLon = initialLon ?? currentPosition?.longitude ?? 100.7503;

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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.eastern_mangrove_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(selectedLat, selectedLon),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
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
            onPressed: () => Navigator.pop(ctx, {'lat': selectedLat, 'lon': selectedLon}),
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

// ─────────────────────────────────────────────────────────────────────────────
// Main dialog
// ─────────────────────────────────────────────────────────────────────────────

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
  showDialog(
    context: context,
    builder: (ctx) => _MangroveAreaDialog(
      existingArea: existingArea,
      provinces: provinces,
      conservationStatusMap: conservationStatusMap,
      apiClient: apiClient,
      currentPosition: currentPosition,
      getCurrentLocation: getCurrentLocation,
      onSuccess: onSuccess,
    ),
  );
}

class _MangroveAreaDialog extends StatefulWidget {
  final Map<String, dynamic>? existingArea;
  final List<String> provinces;
  final Map<String, String> conservationStatusMap;
  final ApiClient apiClient;
  final Position? currentPosition;
  final Future<Map<String, double>?> Function() getCurrentLocation;
  final Future<void> Function() onSuccess;

  const _MangroveAreaDialog({
    required this.existingArea,
    required this.provinces,
    required this.conservationStatusMap,
    required this.apiClient,
    required this.currentPosition,
    required this.getCurrentLocation,
    required this.onSuccess,
  });

  @override
  State<_MangroveAreaDialog> createState() => _MangroveAreaDialogState();
}

class _MangroveAreaDialogState extends State<_MangroveAreaDialog> {
  late final TextEditingController areaNameController;
  late final TextEditingController locationController;
  late final TextEditingController sizeController;
  late final TextEditingController speciesController;
  late final TextEditingController descriptionController;
  late final TextEditingController yearController;
  late final TextEditingController organizationController;
  late final TextEditingController threatsController;
  late final TextEditingController activitiesController;

  late List<String> filteredProvinces;
  late String selectedProvince;
  late String selectedStatus;
  double? selectedLat;
  double? selectedLon;
  String? dialogError;

  @override
  void initState() {
    super.initState();
    final e = widget.existingArea;

    areaNameController = TextEditingController(text: e?['area_name'] ?? '');
    locationController = TextEditingController(text: e?['location'] ?? '');
    sizeController = TextEditingController(text: e?['size_hectares']?.toString() ?? '');
    descriptionController = TextEditingController(text: e?['description'] ?? '');
    yearController = TextEditingController(text: e?['established_year']?.toString() ?? '');
    organizationController = TextEditingController(text: e?['managing_organization'] ?? '');

    String speciesText = '';
    if (e?['mangrove_species'] != null) {
      final s = e!['mangrove_species'];
      speciesText = s is List ? s.join(', ') : s.toString();
    }
    speciesController = TextEditingController(text: speciesText);

    String threatsText = '';
    if (e?['threats'] != null) {
      final t = e!['threats'];
      threatsText = t is List ? t.join(', ') : t.toString();
    }
    threatsController = TextEditingController(text: threatsText);

    String activitiesText = '';
    if (e?['conservation_activities'] != null) {
      final a = e!['conservation_activities'];
      activitiesText = a is List ? a.join(', ') : a.toString();
    }
    activitiesController = TextEditingController(text: activitiesText);

    // Dropdowns
    filteredProvinces = widget.provinces.where((p) => p != 'ทั้งหมด').toList();
    final rawProvince = e?['province']?.toString().trim() ?? '';
    selectedProvince =
        filteredProvinces.contains(rawProvince) ? rawProvince : filteredProvinces.first;

    final rawStatus = e?['conservation_status']?.toString().trim() ?? '';
    selectedStatus =
        widget.conservationStatusMap.containsKey(rawStatus) ? rawStatus : 'protected';

    // Coordinates
    if (e?['latitude'] != null) {
      selectedLat = e!['latitude'] is num
          ? (e['latitude'] as num).toDouble()
          : double.tryParse(e['latitude'].toString());
    }
    if (e?['longitude'] != null) {
      selectedLon = e!['longitude'] is num
          ? (e['longitude'] as num).toDouble()
          : double.tryParse(e['longitude'].toString());
    }
  }

  @override
  void dispose() {
    areaNameController.dispose();
    locationController.dispose();
    sizeController.dispose();
    speciesController.dispose();
    descriptionController.dispose();
    yearController.dispose();
    organizationController.dispose();
    threatsController.dispose();
    activitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.existingArea;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          const Icon(Icons.park, color: Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Text(
            e == null ? 'เพิ่มพื้นที่ป่าชายเลน' : 'แก้ไขพื้นที่ป่าชายเลน',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ข้อมูลพื้นฐาน ──────────────────────────────────────────
                _sectionTitle('ข้อมูลพื้นฐาน', Icons.eco),
                TextField(
                  controller: areaNameController,
                  decoration: _fieldDecoration('ชื่อพื้นที่ *', Icons.forest),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: _fieldDecoration('จังหวัด *', Icons.location_city),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedProvince,
                      isDense: true,
                      isExpanded: true,
                      items: filteredProvinces
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedProvince = value!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: _fieldDecoration('สถานที่/ชื่อหมู่บ้าน *', Icons.location_on,
                      hint: 'เช่น บ้านคลองโคน ต.คลองโคน อ.เมือง'),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: _fieldDecoration('สถานะการอนุรักษ์', Icons.shield),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isDense: true,
                      isExpanded: true,
                      items: widget.conservationStatusMap.entries
                          .map((entry) =>
                              DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedStatus = value!),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // ── ขนาดและพันธุ์ไม้ ────────────────────────────────────────
                _sectionTitle('ขนาดและพันธุ์ไม้', Icons.nature),
                TextField(
                  controller: sizeController,
                  decoration: _fieldDecoration('ขนาดพื้นที่ (ไร่)', Icons.square_foot),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: speciesController,
                  decoration: _fieldDecoration('พันธุ์ไม้ป่าชายเลน', Icons.grass,
                      hint: 'เช่น โกงกาง, ตะบูน, แสม'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: _fieldDecoration('คำอธิบาย', Icons.description),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),
                // ── การจัดการ ──────────────────────────────────────────────
                _sectionTitle('การจัดการ', Icons.manage_accounts),
                TextField(
                  controller: yearController,
                  decoration: _fieldDecoration('ปีที่ก่อตั้ง (พ.ศ.)', Icons.calendar_today),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: organizationController,
                  decoration: _fieldDecoration('องค์กรดูแล', Icons.business),
                ),

                const SizedBox(height: 20),
                // ── ภัยคุกคามและกิจกรรม ──────────────────────────────────
                _sectionTitle('ภัยคุกคามและกิจกรรม', Icons.warning_amber),
                TextField(
                  controller: threatsController,
                  decoration: _fieldDecoration('ภัยคุกคาม', Icons.dangerous,
                      hint: 'ระบุภัยคุกคามที่อาจเกิดขึ้น'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: activitiesController,
                  decoration: _fieldDecoration('กิจกรรมอนุรักษ์', Icons.volunteer_activism,
                      hint: 'ระบุกิจกรรมอนุรักษ์ที่ดำเนินการ'),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),
                // ── ตำแหน่งพิกัด ──────────────────────────────────────────
                _sectionTitle('ตำแหน่งพิกัด', Icons.pin_drop),
                // Tap-to-pick card
                Card(
                  elevation: 2,
                  color: (selectedLat == null || selectedLon == null)
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: (selectedLat == null || selectedLon == null)
                          ? Colors.orange.shade300
                          : Colors.green.shade300,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final loc = await _showLocationPicker(
                        context,
                        initialLat: selectedLat,
                        initialLon: selectedLon,
                        currentPosition: widget.currentPosition,
                      );
                      if (loc != null) {
                        setState(() {
                          selectedLat = loc['lat'];
                          selectedLon = loc['lon'];
                          dialogError = null;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            (selectedLat == null || selectedLon == null)
                                ? Icons.add_location_alt
                                : Icons.check_circle,
                            color: (selectedLat == null || selectedLon == null)
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (selectedLat == null || selectedLon == null)
                                      ? 'แตะเพื่อเลือกตำแหน่งบนแผนที่'
                                      : 'ตำแหน่งที่เลือกแล้ว',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: (selectedLat == null || selectedLon == null)
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                                if (selectedLat != null && selectedLon != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Lat: ${selectedLat!.toStringAsFixed(6)}   Lon: ${selectedLon!.toStringAsFixed(6)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Current location button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final loc = await widget.getCurrentLocation();
                      if (loc != null) {
                        setState(() {
                          selectedLat = loc['lat'];
                          selectedLon = loc['lon'];
                          dialogError = null;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ได้รับตำแหน่งปัจจุบันแล้ว'),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.blue.shade400),
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                ),

                // Error banner
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogError!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton.icon(
            icon: Icon(e == null ? Icons.add : Icons.save),
            label: Text(e == null ? 'เพิ่ม' : 'บันทึก'),
            onPressed: () async {
              // Validation
              if (areaNameController.text.trim().isEmpty ||
                  locationController.text.trim().isEmpty) {
                setState(() {
                  dialogError = 'กรุณากรอกข้อมูลที่จำเป็น (ชื่อพื้นที่, สถานที่)';
                });
                return;
              }
              if (selectedLat == null || selectedLon == null) {
                setState(() {
                  dialogError =
                      'กรุณาเลือกตำแหน่งพื้นที่ — กดการ์ด "เลือกตำแหน่งบนแผนที่" หรือ "ใช้ตำแหน่งปัจจุบัน"';
                });
                return;
              }

              final areaData = {
                'area_name': areaNameController.text.trim(),
                'location': locationController.text.trim(),
                'province': selectedProvince,
                'size_hectares': sizeController.text.isNotEmpty
                    ? double.tryParse(sizeController.text)
                    : null,
                'mangrove_species':
                    speciesController.text.isNotEmpty ? speciesController.text.trim() : null,
                'conservation_status': selectedStatus,
                'latitude': selectedLat,
                'longitude': selectedLon,
                'description': descriptionController.text.isNotEmpty
                    ? descriptionController.text.trim()
                    : null,
                'established_year': yearController.text.isNotEmpty
                    ? int.tryParse(yearController.text)
                    : null,
                'managing_organization': organizationController.text.isNotEmpty
                    ? organizationController.text.trim()
                    : null,
                'threats':
                    threatsController.text.isNotEmpty ? threatsController.text.trim() : null,
                'conservation_activities': activitiesController.text.isNotEmpty
                    ? activitiesController.text.trim()
                    : null,
              };

              Navigator.pop(context);

              try {
                final ApiResponse<Map<String, dynamic>> response;
                if (e == null) {
                  response = await widget.apiClient.createMangroveArea(areaData);
                } else {
                  response = await widget.apiClient.updateMangroveArea(e['id'], areaData);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.message ??
                          (response.success ? 'บันทึกสำเร็จ' : 'เกิดข้อผิดพลาด')),
                      backgroundColor: response.success ? Colors.green : Colors.red,
                    ),
                  );
                  if (response.success) await widget.onSuccess();
                }
              } catch (err) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $err'),
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
          ),
        ],
      );
  }
}
