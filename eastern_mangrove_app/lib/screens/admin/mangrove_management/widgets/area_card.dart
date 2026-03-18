import 'package:flutter/material.dart';

Color getMangroveStatusColor(String status) {
  switch (status) {
    case 'protected':
      return Colors.green;
    case 'monitored':
      return Colors.blue;
    case 'threatened':
      return Colors.orange;
    case 'restored':
      return Colors.teal;
    case 'excellent':
      return Colors.green.shade700;
    case 'good':
      return Colors.green;
    case 'moderate':
      return Colors.orange;
    case 'poor':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class MangroveAreaCard extends StatelessWidget {
  final Map<String, dynamic> area;
  final Map<String, String> conservationStatusMap;
  final VoidCallback onTap;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(int) onDelete;

  const MangroveAreaCard({
    super.key,
    required this.area,
    required this.conservationStatusMap,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final areaName = area['area_name'] ?? '';
    final location = area['location'] ?? '';
    final province = area['province'] ?? '';
    final sizeHectares = area['size_hectares'];
    final status = area['conservation_status'] ?? '';
    final description = area['description'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          areaName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$location, $province',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => onEdit(area),
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => onDelete(area['id'] as int),
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (sizeHectares != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.square_foot,
                              size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '$sizeHectares ไร่',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (status.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            getMangroveStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: getMangroveStatusColor(status)
                                .withOpacity(0.3)),
                      ),
                      child: Text(
                        conservationStatusMap[status] ?? status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: getMangroveStatusColor(status),
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
}
