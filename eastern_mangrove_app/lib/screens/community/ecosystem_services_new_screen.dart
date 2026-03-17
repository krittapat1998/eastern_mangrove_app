import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class EcosystemServicesNewScreen extends StatefulWidget {
  const EcosystemServicesNewScreen({super.key});

  @override
  State<EcosystemServicesNewScreen> createState() => _EcosystemServicesNewScreenState();
}

class _EcosystemServicesNewScreenState extends State<EcosystemServicesNewScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'ทั้งหมด';

  final Map<String, String> _serviceTypes = {
    'ทั้งหมด': 'all',
    'การท่องเที่ยวเชิงนิเวศ': 'ecotourism',
    'การศึกษา': 'education',
    'การจัดหาทรัพยากร': 'provisioning',
    'การควบคุมสภาพแวดล้อม': 'regulating',
    'วัฒนธรรม': 'cultural',
    'นันทนาการ': 'recreation',
  };

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  // Helper function to safely parse double from API response
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getEcosystemServices();
      
      if (response.success && response.data != null) {
        setState(() {
          _services = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_selectedFilter == 'ทั้งหมด') {
      return _services;
    }
    final typeValue = _serviceTypes[_selectedFilter];
    return _services.where((s) => s['service_type'] == typeValue).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('บริการทางนิเวศของป่าชายเลน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServices,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceDialog(),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadServices,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryAndFilter(),
        Expanded(
          child: _filteredServices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'ยังไม่มีข้อมูลบริการทางนิเวศ\nกดปุ่ม + เพื่อเพิ่มข้อมูล',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = _filteredServices[index];
                    return _buildServiceCard(service);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryAndFilter() {
    final totalValue = _filteredServices.fold<double>(
      0,
      (sum, item) => sum + _parseDouble(item['economic_value']),
    );

    final totalBeneficiaries = _filteredServices.fold<int>(
      0,
      (sum, item) => sum + ((item['beneficiaries_count'] ?? 0) as num).toInt(),
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'มูลค่ารวม',
                  '${_formatNumber(totalValue)} บาท',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'ผู้รับประโยชน์',
                  '$totalBeneficiaries คน',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'รายการทั้งหมด',
                  '${_filteredServices.length}',
                  Icons.list_alt,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _serviceTypes.keys.map((type) {
                final isSelected = _selectedFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = type;
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: const Color(0xFF2E7D32),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final serviceType = service['service_type'] ?? '';
    final description = service['description'] ?? '';
    final economicValue = _parseDouble(service['economic_value']);
    final beneficiaries = service['beneficiaries_count'] ?? 0;
    final dateRecorded = service['date_recorded'] != null
        ? DateTime.parse(service['date_recorded'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showServiceDetails(service),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getServiceTypeColor(serviceType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getServiceTypeColor(serviceType).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getServiceTypeIcon(serviceType),
                          size: 16,
                          color: _getServiceTypeColor(serviceType),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getServiceTypeNameThai(serviceType),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getServiceTypeColor(serviceType),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showAddServiceDialog(existingService: service),
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDelete(service['id']),
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.monetization_on, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatNumber(economicValue)} บาท',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$beneficiaries คน',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
              if (dateRecorded != null) ...[
                const SizedBox(height: 8),
                Text(
                  'บันทึกเมื่อ: ${_formatDate(dateRecorded)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceTypeIcon(String type) {
    switch (type) {
      case 'ecotourism':
        return Icons.nature_people;
      case 'education':
        return Icons.school;
      case 'provisioning':
        return Icons.inventory;
      case 'regulating':
        return Icons.settings_applications;
      case 'cultural':
        return Icons.temple_buddhist;
      case 'recreation':
        return Icons.kayaking;
      default:
        return Icons.eco;
    }
  }

  Color _getServiceTypeColor(String type) {
    switch (type) {
      case 'ecotourism':
        return Colors.teal;
      case 'education':
        return Colors.blue;
      case 'provisioning':
        return Colors.green;
      case 'regulating':
        return Colors.purple;
      case 'cultural':
        return Colors.orange;
      case 'recreation':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getServiceTypeNameThai(String type) {
    switch (type) {
      case 'ecotourism':
        return 'ท่องเที่ยวเชิงนิเวศ';
      case 'education':
        return 'การศึกษา';
      case 'provisioning':
        return 'จัดหาทรัพยากร';
      case 'regulating':
        return 'ควบคุมสภาพแวดล้อม';
      case 'cultural':
        return 'วัฒนธรรม';
      case 'recreation':
        return 'นันทนาการ';
      default:
        return type;
    }
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year + 543}';
  }

  void _showServiceDetails(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getServiceTypeNameThai(service['service_type'] ?? '')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'คำอธิบาย:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(service['description'] ?? '-'),
              const SizedBox(height: 16),
              _buildDetailRow('มูลค่าทางเศรษฐกิจ', '${_formatNumber(_parseDouble(service['economic_value']))} บาท'),
              _buildDetailRow('ผู้รับประโยชน์', '${service['beneficiaries_count'] ?? 0} คน'),
              if (service['date_recorded'] != null)
                _buildDetailRow('วันที่บันทึก', _formatDate(DateTime.parse(service['date_recorded']))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog({Map<String, dynamic>? existingService}) {
    String selectedType = existingService?['service_type'] ?? 'ecotourism';
    final serviceNameController = TextEditingController(
      text: existingService?['service_name'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingService?['description'] ?? '',
    );
    final quantityController = TextEditingController(
      text: existingService?['quantity']?.toString() ?? '',
    );
    final unitController = TextEditingController(
      text: existingService?['unit'] ?? '',
    );
    final valueController = TextEditingController(
      text: existingService?['economic_value']?.toString() ?? '',
    );
    final yearController = TextEditingController(
      text: existingService?['year']?.toString() ?? DateTime.now().year.toString(),
    );
    final monthController = TextEditingController(
      text: existingService?['month']?.toString() ?? DateTime.now().month.toString(),
    );
    final beneficiariesController = TextEditingController(
      text: existingService?['beneficiaries_count']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingService == null ? 'เพิ่มบริการทางนิเวศ' : 'แก้ไขบริการทางนิเวศ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ประเภทบริการ:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...['ecotourism', 'education', 'provisioning', 'regulating', 'cultural', 'recreation']
                    .map((type) => RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(_getServiceTypeIcon(type), size: 20, color: _getServiceTypeColor(type)),
                              const SizedBox(width: 8),
                              Text(_getServiceTypeNameThai(type)),
                            ],
                          ),
                          value: type,
                          groupValue: selectedType,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ))
                    .toList(),
                const SizedBox(height: 16),
                TextField(
                  controller: serviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อบริการ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
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
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'จำนวน',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'หน่วย',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'มูลค่าทางเศรษฐกิจ (บาท)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: yearController,
                        decoration: const InputDecoration(
                          labelText: 'ปี (พ.ศ.)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: monthController,
                        decoration: const InputDecoration(
                          labelText: 'เดือน (1-12)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: beneficiariesController,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนผู้รับประโยชน์ (คน)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final dataMap = {
                  'serviceType': selectedType,
                  'serviceName': serviceNameController.text,
                  'quantity': double.tryParse(quantityController.text) ?? 0.0,
                  'unit': unitController.text,
                  'economicValue': double.tryParse(valueController.text) ?? 0.0,
                  'year': int.tryParse(yearController.text) ?? DateTime.now().year,
                  'month': int.tryParse(monthController.text) ?? DateTime.now().month,
                  'description': descriptionController.text,
                  'beneficiariesCount': int.tryParse(beneficiariesController.text) ?? 0,
                };

                Navigator.pop(context);

                if (existingService == null) {
                  await _createService(dataMap);
                } else {
                  await _updateService(existingService['id'], dataMap);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createService(Map<String, dynamic> dataMap) async {
    try {
      final response = await _apiClient.createEcosystemService(dataMap);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกบริการทางนิเวศสำเร็จ'), backgroundColor: Colors.green),
          );
          _loadServices();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.message}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateService(int id, Map<String, dynamic> dataMap) async {
    try {
      final response = await _apiClient.updateEcosystemService(id, dataMap);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัพเดทบริการทางนิเวศสำเร็จ'), backgroundColor: Colors.green),
          );
          _loadServices();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.message}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบบริการทางนิเวศนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteService(id);
    }
  }

  Future<void> _deleteService(int id) async {
    try {
      final response = await _apiClient.deleteEcosystemService(id);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบบริการทางนิเวศสำเร็จ'), backgroundColor: Colors.green),
          );
          _loadServices();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.message}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
