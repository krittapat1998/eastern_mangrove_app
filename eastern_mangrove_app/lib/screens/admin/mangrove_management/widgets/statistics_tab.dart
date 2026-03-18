import 'package:flutter/material.dart';
import 'area_card.dart' show getMangroveStatusColor;

class MangroveStatisticsTab extends StatelessWidget {
  final List<Map<String, dynamic>> areas;
  final Map<String, String> conservationStatusMap;

  const MangroveStatisticsTab({
    super.key,
    required this.areas,
    required this.conservationStatusMap,
  });

  @override
  Widget build(BuildContext context) {
    final provinceStats = <String, int>{};
    final statusStats = <String, int>{};
    double totalSize = 0;

    for (var area in areas) {
      final province = area['province'] ?? 'ไม่ระบุ';
      provinceStats[province] = (provinceStats[province] ?? 0) + 1;

      final status = area['conservation_status'] ?? 'ไม่ระบุ';
      statusStats[status] = (statusStats[status] ?? 0) + 1;

      if (area['size_hectares'] != null) {
        totalSize +=
            double.tryParse(area['size_hectares'].toString()) ?? 0;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco,
                          color: Color(0xFF2E7D32), size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'สถิติรวม',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                      'จำนวนพื้นที่ทั้งหมด', '${areas.length} แห่ง'),
                  _buildStatRow('พื้นที่รวมทั้งหมด',
                      '${totalSize.toStringAsFixed(2)} ไร่'),
                  _buildStatRow(
                    'พื้นที่เฉลี่ย',
                    areas.isEmpty
                        ? '0 ไร่'
                        : '${(totalSize / areas.length).toStringAsFixed(2)} ไร่',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'แยกตามจังหวัด',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: provinceStats.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value} แห่ง',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'สถานะการอนุรักษ์',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: statusStats.entries.map((entry) {
                  final color = getMangroveStatusColor(entry.key);
                  final label =
                      conservationStatusMap[entry.key] ?? entry.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(label)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value} แห่ง',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
