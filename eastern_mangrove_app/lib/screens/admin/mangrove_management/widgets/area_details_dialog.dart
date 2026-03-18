import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'area_card.dart' show getMangroveStatusColor;

Future<void> openMangroveInGoogleMaps(
  BuildContext context,
  dynamic lat,
  dynamic lon,
  String label,
) async {
  if (lat == null || lon == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ ไม่พบข้อมูลตำแหน่ง'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  final double latitude =
      (lat is num) ? lat.toDouble() : double.parse(lat.toString());
  final double longitude =
      (lon is num) ? lon.toDouble() : double.parse(lon.toString());

  final String googleMapsUrl =
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
  final String googleMapsAppUrl =
      'geo:$latitude,$longitude?q=$latitude,$longitude($label)';

  try {
    final Uri geoUri = Uri.parse(googleMapsAppUrl);
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } else {
      final Uri webUri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'ไม่สามารถเปิด Google Maps ได้';
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเปิด Google Maps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Widget buildMangroveDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

void showMangroveAreaDetailsDialog(
  BuildContext context,
  Map<String, dynamic> area, {
  required Map<String, String> conservationStatusMap,
  required void Function(Map<String, dynamic>) onEdit,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(area['area_name'] ?? 'รายละเอียดพื้นที่'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            buildMangroveDetailRow(
                'สถานที่', '${area['location']}, ${area['province']}'),
            if (area['size_hectares'] != null)
              buildMangroveDetailRow(
                  'ขนาดพื้นที่', '${area['size_hectares']} ไร่'),
            if (area['conservation_status'] != null)
              buildMangroveDetailRow(
                'สถานะ',
                conservationStatusMap[area['conservation_status']] ??
                    area['conservation_status'],
              ),
            if (area['mangrove_species'] != null)
              buildMangroveDetailRow(
                'พันธุ์ไม้',
                area['mangrove_species'] is List
                    ? (area['mangrove_species'] as List).join(', ')
                    : area['mangrove_species'].toString(),
              ),
            if (area['established_year'] != null)
              buildMangroveDetailRow(
                  'ปีที่ก่อตั้ง', area['established_year'].toString()),
            if (area['managing_organization'] != null)
              buildMangroveDetailRow(
                  'องค์กรดูแล', area['managing_organization']),
            if (area['description'] != null &&
                area['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('คำอธิบาย:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(area['description']),
            ],
            if (area['threats'] != null &&
                area['threats'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'ภัยคุกคาม:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 4),
              Text(
                area['threats'] is List
                    ? (area['threats'] as List).join(', ')
                    : area['threats'].toString(),
              ),
            ],
            if (area['conservation_activities'] != null &&
                area['conservation_activities'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'กิจกรรมอนุรักษ์:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 4),
              Text(
                area['conservation_activities'] is List
                    ? (area['conservation_activities'] as List).join(', ')
                    : area['conservation_activities'].toString(),
              ),
            ],
            if (area['latitude'] != null && area['longitude'] != null) ...[
              const SizedBox(height: 16),
              buildMangroveDetailRow(
                  'พิกัด', '${area['latitude']}, ${area['longitude']}'),
            ],
          ],
        ),
      ),
      actions: [
        if (area['latitude'] != null && area['longitude'] != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              openMangroveInGoogleMaps(
                context,
                area['latitude'],
                area['longitude'],
                area['area_name'] ?? 'พื้นที่ป่าชายเลน',
              );
            },
            icon: const Icon(Icons.navigation),
            label: const Text('นำทาง'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('ปิด'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            onEdit(area);
          },
          icon: const Icon(Icons.edit),
          label: const Text('แก้ไข'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}
