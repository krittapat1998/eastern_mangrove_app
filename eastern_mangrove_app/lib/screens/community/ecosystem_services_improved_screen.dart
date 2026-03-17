import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class EcosystemServicesImprovedScreen extends StatefulWidget {
  const EcosystemServicesImprovedScreen({super.key});

  @override
  State<EcosystemServicesImprovedScreen> createState() => _EcosystemServicesImprovedScreenState();
}

class _EcosystemServicesImprovedScreenState extends State<EcosystemServicesImprovedScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'ทั้งหมด';

  // ประเภททรัพยากรตามขอบเขตงาน
  final Map<String, String> _resourceTypes = {
    'ไม้ฟืน': 'firewood',
    'ปู': 'crab',
    'กุ้ง': 'shrimp',
    'หอย': 'shellfish',
    'ปลา': 'fish',
    'อื่นๆ': 'other_resource',
  };

  // ประเภทกิจกรรมตามขอบเขตงาน
  final Map<String, String> _activityTypes = {
    'นำเที่ยว': 'tour_guide',
    'รับกลุ่มสัมมนา': 'seminar',
    'ค่ายการเรียนรู้': 'learning_camp',
    'อื่นๆ': 'other_activity',
  };

  final Map<String, String> _filterTypes = {
    'ทั้งหมด': 'all',
    'ทรัพยากร': 'resource',
    'กิจกรรม': 'activity',
  };

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

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
    print('📥 Loading ecosystem services...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getEcosystemServices();
      print('📊 Load response: success=${response.success}, count=${response.data?.length ?? 0}');
      
      if (response.success && response.data != null) {
        // Debug each service
        for (var service in response.data!) {
          print('  📦 ${service['service_name']}: category=${service['category']}, type=${service['service_type']}');
        }
        
        setState(() {
          _services = response.data!;
          _isLoading = false;
        });
        print('✅ Loaded ${_services.length} services');
        
        // Summary by category
        final resourceCount = _services.where((s) => (s['category'] ?? 'resource') == 'resource').length;
        final activityCount = _services.where((s) => (s['category'] ?? 'resource') == 'activity').length;
        print('📊 Summary: $resourceCount resources, $activityCount activities');
      } else {
        print('⚠️ Failed to load: ${response.message}');
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading services: $e');
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    print('🔍 Filtering services: total=${_services.length}, filter=$_selectedFilter');
    
    if (_selectedFilter == 'ทั้งหมด') {
      print('  ↳ Showing all ${_services.length} services');
      return _services;
    }
    
    final typeValue = _filterTypes[_selectedFilter];
    print('  ↳ Filter value: $typeValue');
    
    final filtered = _services.where((s) {
      final category = s['category'] ?? 'resource';
      final match = category == typeValue;
      if (!match) {
        print('    ✗ ${s['service_name']}: category=$category (expected $typeValue)');
      } else {
        print('    ✓ ${s['service_name']}: category=$category');
      }
      return match;
    }).toList();
    
    print('  ↳ Result: ${filtered.length} services match filter');
    return filtered;
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceTypeSelectionDialog(),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มข้อมูล'),
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
                        'ยังไม่มีข้อมูล',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'กดปุ่ม + ด้านล่างเพื่อเพิ่มข้อมูล',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredServices.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(_filteredServices[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryAndFilter() {
    final totalValue = _services.fold<double>(
      0,
      (sum, service) => sum + _parseDouble(service['economic_value']),
    );
    
    // Count by category for summary
    final resourceCount = _services.where((s) => (s['category'] ?? 'resource') == 'resource').length;
    final activityCount = _services.where((s) => (s['category'] ?? 'resource') == 'activity').length;

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
                  'ทรัพยากร',
                  '$resourceCount',
                  Icons.inventory_2,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'กิจกรรม',
                  '$activityCount',
                  Icons.groups,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'มูลค่ารวม',
                  '฿${_formatNumber(totalValue)}',
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterTypes.keys.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        print('🔍 Filter changed to: $filter (${_filterTypes[filter]})');
                        print('📊 Filtered results: ${_filteredServices.length} items');
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildServiceCard(Map<String, dynamic> service) {
    final category = service['category'] ?? 'resource';
    final isResource = category == 'resource';
    
    // Debug logging
    print('🎴 Card: ${service['service_name']} - category: $category, isResource: $isResource');
    
    IconData icon;
    Color color;
    String categoryLabel;
    
    if (isResource) {
      icon = Icons.inventory_2;
      color = Colors.amber.shade700;
      categoryLabel = 'ทรัพยากร';
    } else {
      icon = Icons.groups;
      color = Colors.blue.shade700;
      categoryLabel = 'กิจกรรม';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditServiceDialog(service),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                categoryLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                service['service_name'] ?? 'ไม่มีชื่อ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getServiceTypeName(service['service_type']),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('แก้ไข'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('ลบ', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditServiceDialog(service);
                      } else if (value == 'delete') {
                        _confirmDelete(service['id']);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (isResource) ...[
                _buildInfoRow(
                  Icons.scale,
                  'น้ำหนัก',
                  '${_formatNumber(service['quantity'])} ${service['unit'] ?? 'กก.'}',
                ),
                _buildInfoRow(
                  Icons.attach_money,
                  'ราคา/หน่วย',
                  '฿${_formatNumber(service['unit_price'] ?? 0)}',
                ),
              ] else ...[
                _buildInfoRow(
                  Icons.people,
                  'จำนวนคน',
                  '${service['participants'] ?? 0} คน',
                ),
                _buildInfoRow(
                  Icons.person,
                  'ค่าใช้จ่าย/คน',
                  '฿${_formatNumber(service['price_per_person'] ?? 0)}',
                ),
              ],
              _buildInfoRow(
                Icons.monetization_on,
                'มูลค่ารวม',
                '฿${_formatNumber(service['economic_value'])}',
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'เดือน/ปี',
                '${service['month']}/${service['year']}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceTypeName(String? type) {
    // Check resource types first
    for (var entry in _resourceTypes.entries) {
      if (entry.value == type) return entry.key;
    }
    // Then check activity types
    for (var entry in _activityTypes.entries) {
      if (entry.value == type) return entry.key;
    }
    return type ?? 'ไม่ระบุ';
  }

  String _formatNumber(dynamic value) {
    final num = _parseDouble(value);
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(2)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(2)}K';
    }
    return num.toStringAsFixed(2);
  }

  void _showServiceTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกประเภทข้อมูล'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.amber),
              title: const Text('ทรัพยากรที่เก็บได้'),
              subtitle: const Text('ไม้ฟืน, ปู, กุ้ง, หอย, ปลา'),
              onTap: () {
                Navigator.pop(context);
                _showAddResourceDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.groups, color: Colors.blue),
              title: const Text('กิจกรรม/การท่องเที่ยว'),
              subtitle: const Text('นำเที่ยว, รับกลุ่มสัมมนา'),
              onTap: () {
                Navigator.pop(context);
                _showAddActivityDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddResourceDialog([Map<String, dynamic>? existingService]) {
    String selectedType = existingService?['service_type'] ?? 'firewood';
    final nameController = TextEditingController(
      text: existingService?['service_name'] ?? '',
    );
    final quantityController = TextEditingController(
      text: existingService?['quantity']?.toString() ?? '',
    );
    final unitController = TextEditingController(
      text: existingService?['unit'] ?? 'กก.',
    );
    final unitPriceController = TextEditingController(
      text: existingService?['unit_price']?.toString() ?? '',
    );
    final yearController = TextEditingController(
      text: existingService?['year']?.toString() ?? DateTime.now().year.toString(),
    );
    final monthController = TextEditingController(
      text: existingService?['month']?.toString() ?? DateTime.now().month.toString(),
    );
    final descriptionController = TextEditingController(
      text: existingService?['description'] ?? '',
    );

    double calculatedValue = 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateCalculation() {
            final quantity = double.tryParse(quantityController.text) ?? 0.0;
            final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
            setDialogState(() {
              calculatedValue = quantity * unitPrice;
            });
          }

          return AlertDialog(
            title: Text(existingService == null ? 'เพิ่มทรัพยากร' : 'แก้ไขทรัพยากร'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ประเภททรัพยากร:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._resourceTypes.entries.map((entry) => RadioListTile<String>(
                        title: Text(entry.key),
                        value: entry.value,
                        groupValue: selectedType,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedType = value!;
                            if (entry.key != 'อื่นๆ') {
                              nameController.text = entry.key;
                            }
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อทรัพยากร',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: quantityController,
                          decoration: const InputDecoration(
                            labelText: 'น้ำหนัก',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.scale),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => updateCalculation(),
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
                    controller: unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'ราคาต่อหน่วย (บาท)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      helperText: 'ราคา/กก. หรือ /หน่วย',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => updateCalculation(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'มูลค่ารวม:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '฿${calculatedValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: monthController,
                          decoration: const InputDecoration(
                            labelText: 'เดือน (1-12)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: yearController,
                          decoration: const InputDecoration(
                            labelText: 'ปี (พ.ศ.)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'หมายเหตุ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
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
                  // Validate before save
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณากรอกชื่อทรัพยากร'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  if (quantityController.text.trim().isEmpty || 
                      (double.tryParse(quantityController.text) ?? 0) <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณากรอกน้ำหนัก (มากกว่า 0)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  if (unitPriceController.text.trim().isEmpty || 
                      (double.tryParse(unitPriceController.text) ?? 0) <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณากรอกราคาต่อหน่วย (มากกว่า 0)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  updateCalculation(); // Ensure final calculation
                  
                  final dataMap = {
                    'category': 'resource',
                    'serviceType': selectedType,
                    'serviceName': nameController.text.trim(),
                    'quantity': double.tryParse(quantityController.text) ?? 0.0,
                    'unit': unitController.text.trim(),
                    'unitPrice': double.tryParse(unitPriceController.text) ?? 0.0,
                    'economicValue': calculatedValue,
                    'year': int.tryParse(yearController.text) ?? DateTime.now().year,
                    'month': int.tryParse(monthController.text) ?? DateTime.now().month,
                    'description': descriptionController.text.trim(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('บันทึก', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddActivityDialog([Map<String, dynamic>? existingService]) {
    String selectedType = existingService?['service_type'] ?? 'tour_guide';
    final nameController = TextEditingController(
      text: existingService?['service_name'] ?? '',
    );
    final participantsController = TextEditingController(
      text: existingService?['participants']?.toString() ?? '',
    );
    final pricePerPersonController = TextEditingController(
      text: existingService?['price_per_person']?.toString() ?? '',
    );
    final yearController = TextEditingController(
      text: existingService?['year']?.toString() ?? DateTime.now().year.toString(),
    );
    final monthController = TextEditingController(
      text: existingService?['month']?.toString() ?? DateTime.now().month.toString(),
    );
    final descriptionController = TextEditingController(
      text: existingService?['description'] ?? '',
    );

    double calculatedValue = 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateCalculation() {
            final participants = double.tryParse(participantsController.text) ?? 0.0;
            final pricePerPerson = double.tryParse(pricePerPersonController.text) ?? 0.0;
            setDialogState(() {
              calculatedValue = participants * pricePerPerson;
            });
          }

          return AlertDialog(
            title: Text(existingService == null ? 'เพิ่มกิจกรรม' : 'แก้ไขกิจกรรม'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ประเภทกิจกรรม:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._activityTypes.entries.map((entry) => RadioListTile<String>(
                        title: Text(entry.key),
                        value: entry.value,
                        groupValue: selectedType,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedType = value!;
                            if (entry.key != 'อื่นๆ') {
                              nameController.text = entry.key;
                            }
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อกิจกรรม',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: participantsController,
                    decoration: const InputDecoration(
                      labelText: 'จำนวนคน',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                      helperText: 'จำนวนผู้เข้าร่วมกิจกรรม',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => updateCalculation(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pricePerPersonController,
                    decoration: const InputDecoration(
                      labelText: 'ค่าใช้จ่ายต่อหัว (บาท/คน)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      helperText: 'ราคาต่อคน',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => updateCalculation(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'รายได้รวม:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '฿${calculatedValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: monthController,
                          decoration: const InputDecoration(
                            labelText: 'เดือน (1-12)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: yearController,
                          decoration: const InputDecoration(
                            labelText: 'ปี (พ.ศ.)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียดกิจกรรม',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
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
                  // Validate before save
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณากรอกชื่อกิจกรรม'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  if (participantsController.text.trim().isEmpty || 
                      (int.tryParse(participantsController.text) ?? 0) <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณากรอกจำนวนคน (มากกว่า 0)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  if (pricePerPersonController.text.trim().isEmpty || 
                      (double.tryParse(pricePerPersonController.text) ?? 0) <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('กรุณากรอกค่าใช้จ่ายต่อหัว (มากกว่า 0)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  updateCalculation(); // Ensure final calculation
                  
                  final dataMap = {
                    'category': 'activity',
                    'serviceType': selectedType,
                    'serviceName': nameController.text.trim(),
                    'participants': int.tryParse(participantsController.text) ?? 0,
                    'pricePerPerson': double.tryParse(pricePerPersonController.text) ?? 0.0,
                    'economicValue': calculatedValue,
                    'year': int.tryParse(yearController.text) ?? DateTime.now().year,
                    'month': int.tryParse(monthController.text) ?? DateTime.now().month,
                    'description': descriptionController.text.trim(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('บันทึก', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditServiceDialog(Map<String, dynamic> service) {
    final category = service['category'] ?? 'resource';
    if (category == 'resource') {
      _showAddResourceDialog(service);
    } else {
      _showAddActivityDialog(service);
    }
  }

  Future<void> _createService(Map<String, dynamic> dataMap) async {
    print('🌿 Creating service with data: $dataMap');
    
    // Validate required fields
    if (dataMap['serviceName'] == null || dataMap['serviceName'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อทรัพยากร/กิจกรรม'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (dataMap['economicValue'] == null || dataMap['economicValue'] <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน มูลค่าต้องมากกว่า 0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔵 Calling API createEcosystemService...');
      final response = await _apiClient.createEcosystemService(dataMap);
      print('✅ API Response: success=${response.success}, message=${response.message}');
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกข้อมูลสำเร็จ ✓'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        print('♻️ Reloading services list...');
        await _loadServices();
        print('✓ Services reloaded successfully');
      } else {
        print('❌ API returned error: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่สามารถบันทึกได้: ${response.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Exception in _createService: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateService(int id, Map<String, dynamic> dataMap) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.updateEcosystemService(id, dataMap);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แก้ไขข้อมูลสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadServices();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบข้อมูลนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.deleteEcosystemService(id);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบข้อมูลสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadServices();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
}
