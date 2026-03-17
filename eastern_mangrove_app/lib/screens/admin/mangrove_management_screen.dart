import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_client.dart';

class MangroveManagementScreen extends StatefulWidget {
  const MangroveManagementScreen({super.key});

  @override
  State<MangroveManagementScreen> createState() => _MangroveManagementScreenState();
}

class _MangroveManagementScreenState extends State<MangroveManagementScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;
  List<Map<String, dynamic>> _areas = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'ทั้งหมด';
  Position? _currentPosition;

  final List<String> _provinces = [
    'ทั้งหมด',
    'ฉะเชิงเทรา',
    'สมุทรปราการ',
    'ชลบุรี',
    'ระยอง',
    'จันทบุรี',
    'ตราด',
  ];

  final Map<String, String> _conservationStatusMap = {
    'protected': 'พื้นที่ปกป้อง',
    'monitored': 'พื้นที่เฝ้าระวัง',
    'threatened': 'พื้นที่เสี่ยง',
    'restored': 'พื้นที่ฟื้นฟู',
    // Legacy status from old database
    'excellent': 'สภาพดีเยี่ยม',
    'good': 'สภาพดี',
    'moderate': 'สภาพปานกลาง',
    'poor': 'สภาพเสื่อมโทรม',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAreas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        print('⚠️ Location permission not granted');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        print('✅ Current location: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('⚠️ Could not get current location: $e');
    }
  }

  Future<bool> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      
      return true;
    } catch (e) {
      print('⚠️ Error requesting location permission: $e');
      return false;
    }
  }

  Future<void> _loadAreas() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final province = _selectedFilter == 'ทั้งหมด' ? null : _selectedFilter;
      print('📍 Loading areas with filter: $province');
      
      final response = await _apiClient.getMangroveAreas(province: province);

      print('📍 Mangrove Areas Response: ${response.success}');
      print('📍 Response message: ${response.message}');
      print('📍 Response error: ${response.error}');
      print('📍 Data count: ${response.data?.length ?? 0}');
      
      if (!mounted) return;
      
      if (response.success) {
        setState(() {
          _areas = response.data ?? [];
          _isLoading = false;
          _errorMessage = null;
        });
        print('✅ Loaded ${_areas.length} mangrove areas');
      } else {
        final errorMsg = response.error ?? response.message ?? 'ไม่สามารถโหลดข้อมูลได้';
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
          _areas = [];
        });
        print('❌ API Error: $errorMsg');
      }
    } catch (e, stackTrace) {
      print('❌ Load areas error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
          _isLoading = false;
          _areas = [];
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAreas {
    if (_selectedFilter == 'ทั้งหมด') {
      return _areas;
    }
    return _areas.where((a) => a['province'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('จัดการพื้นที่ป่าชายเลน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF4CAF50),
          tabs: const [
            Tab(text: 'รายการพื้นที่', icon: Icon(Icons.list_alt)),
            Tab(text: 'แผนที่', icon: Icon(Icons.map)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAreas,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAreasTab(),
          _buildMapTab(),
        ],
      ),
    );
  }

  Widget _buildAreasTab() {
    if (_isLoading) {
      return Stack(
        children: [
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: () => _showAddAreaDialog(),
                backgroundColor: const Color(0xFF2E7D32),
                child: const Icon(Icons.add, size: 24),
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadAreas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองใหม่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showAddAreaDialog(),
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildSummaryAndFilter(),
            Expanded(
              child: _filteredAreas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'ยังไม่มีข้อมูลพื้นที่ป่าชายเลน\nกดปุ่ม + เพื่อเพิ่มพื้นที่',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredAreas.length,
                      itemBuilder: (context, index) {
                        final area = _filteredAreas[index];
                        return _buildAreaCard(area);
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddAreaDialog(),
            backgroundColor: const Color(0xFF2E7D32),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryAndFilter() {
    final protectedCount = _filteredAreas.where((a) => a['conservation_status'] == 'protected').length;
    final threatenedCount = _filteredAreas.where((a) => a['conservation_status'] == 'threatened').length;
    final totalSize = _filteredAreas.fold<double>(
      0,
      (sum, area) => sum + (area['size_hectares'] != null ? double.tryParse(area['size_hectares'].toString()) ?? 0 : 0),
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
                  'พื้นที่ทั้งหมด',
                  '${_filteredAreas.length}',
                  Icons.eco,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'พื้นที่ปกป้อง',
                  '$protectedCount',
                  Icons.shield,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'พื้นที่เสี่ยง',
                  '$threatenedCount',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.terrain, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พื้นที่รวม',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${totalSize.toStringAsFixed(2)} ไร่',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _provinces.map((province) {
                final isSelected = _selectedFilter == province;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(province),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = province;
                        _loadAreas();
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

  Widget _buildAreaCard(Map<String, dynamic> area) {
    final areaName = area['area_name'] ?? '';
    final location = area['location'] ?? '';
    final province = area['province'] ?? '';
    final sizeHectares = area['size_hectares'];
    final status = area['conservation_status'] ?? '';
    final description = area['description'] ?? '';
    final communityName = area['community_name'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAreaDetails(area),
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
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$location, $province',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
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
                        onPressed: () => _showAddAreaDialog(existingArea: area),
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDelete(area['id']),
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
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.square_foot, size: 14, color: Colors.blue.shade700),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                      ),
                      child: Text(
                        _conservationStatusMap[status] ?? status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  if (communityName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups, size: 14, color: Colors.purple.shade700),
                          const SizedBox(width: 4),
                          Text(
                            communityName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'protected':
        return Colors.green;
      case 'monitored':
        return Colors.blue;
      case 'threatened':
        return Colors.orange;
      case 'restored':
        return Colors.teal;
      // Legacy status colors
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

  void _showAreaDetails(Map<String, dynamic> area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(area['area_name'] ?? 'รายละเอียดพื้นที่'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('สถานที่', '${area['location']}, ${area['province']}'),
              if (area['size_hectares'] != null)
                _buildDetailRow('ขนาดพื้นที่', '${area['size_hectares']} ไร่'),
              if (area['conservation_status'] != null)
                _buildDetailRow('สถานะ', _conservationStatusMap[area['conservation_status']] ?? area['conservation_status']),
              if (area['mangrove_species'] != null)
                _buildDetailRow('พันธุ์ไม้', area['mangrove_species']),
              if (area['established_year'] != null)
                _buildDetailRow('ปีที่ก่อตั้ง', area['established_year'].toString()),
              if (area['managing_organization'] != null)
                _buildDetailRow('องค์กรดูแล', area['managing_organization']),
              if (area['community_name'] != null)
                _buildDetailRow('ชุมชน', area['community_name']),
              if (area['description'] != null && area['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'คำอธิบาย:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(area['description']),
              ],
              if (area['threats'] != null && area['threats'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'ภัยคุกคาม:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(area['threats']),
              ],
              if (area['conservation_activities'] != null && area['conservation_activities'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'กิจกรรมอนุรักษ์:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(area['conservation_activities']),
              ],
              if (area['latitude'] != null && area['longitude'] != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow('พิกัด', '${area['latitude']}, ${area['longitude']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddAreaDialog(existingArea: area);
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

  Widget _buildDetailRow(String label, String value) {
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

  void _showAddAreaDialog({Map<String, dynamic>? existingArea}) {
    final areaNameController = TextEditingController(text: existingArea?['area_name'] ?? '');
    final locationController = TextEditingController(text: existingArea?['location'] ?? '');
    final sizeController = TextEditingController(text: existingArea?['size_hectares']?.toString() ?? '');
    
    // Handle mangrove_species - convert array to comma-separated string
    String speciesText = '';
    if (existingArea?['mangrove_species'] != null) {
      final species = existingArea!['mangrove_species'];
      if (species is List) {
        speciesText = species.join(', ');
      } else if (species is String) {
        speciesText = species;
      }
    }
    final speciesController = TextEditingController(text: speciesText);
    
    final descriptionController = TextEditingController(text: existingArea?['description'] ?? '');
    final yearController = TextEditingController(text: existingArea?['established_year']?.toString() ?? '');
    final organizationController = TextEditingController(text: existingArea?['managing_organization'] ?? '');
    
    // Handle threats - convert array to comma-separated string
    String threatsText = '';
    if (existingArea?['threats'] != null) {
      final threats = existingArea!['threats'];
      if (threats is List) {
        threatsText = threats.join(', ');
      } else if (threats is String) {
        threatsText = threats;
      }
    }
    final threatsController = TextEditingController(text: threatsText);
    
    // Handle conservation_activities - convert array to comma-separated string
    String activitiesText = '';
    if (existingArea?['conservation_activities'] != null) {
      final activities = existingArea!['conservation_activities'];
      if (activities is List) {
        activitiesText = activities.join(', ');
      } else if (activities is String) {
        activitiesText = activities;
      }
    }
    final activitiesController = TextEditingController(text: activitiesText);

    String selectedProvince = existingArea?['province'] ?? 'ฉะเชิงเทรา';
    String selectedStatus = existingArea?['conservation_status'] ?? 'protected';

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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingArea == null ? 'เพิ่มพื้นที่ป่าชายเลน' : 'แก้ไขพื้นที่ป่าชายเลน'),
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
                          items: _provinces
                              .where((p) => p != 'ทั้งหมด')
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
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
                          items: _conservationStatusMap.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
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
                      prefixIcon: Icon(Icons.warning, color: Colors.red),
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
                      prefixIcon: Icon(Icons.volunteer_activism, color: Colors.green),
                      hintText: 'ระบุกิจกรรมอนุรักษ์ที่ดำเนินการ',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Location Picker
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
                        final location = await _showLocationPicker(
                          initialLat: selectedLat,
                          initialLon: selectedLon,
                        );
                        if (location != null) {
                          setDialogState(() {
                            selectedLat = location['lat'];
                            selectedLon = location['lon'];
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  selectedLat == null || selectedLon == null
                                      ? Icons.add_location_alt
                                      : Icons.check_circle,
                                  color: selectedLat == null || selectedLon == null
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
                                        selectedLat == null || selectedLon == null
                                            ? 'เลือกตำแหน่งบนแผนที่'
                                            : 'ตำแหน่งที่เลือก',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: selectedLat == null || selectedLon == null
                                              ? Colors.orange.shade700
                                              : Colors.green.shade700,
                                        ),
                                      ),
                                      if (selectedLat != null && selectedLon != null)
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (areaNameController.text.isEmpty ||
                    locationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณากรอกข้อมูลที่จำเป็น (ชื่อพื้นที่, สถานที่)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final areaData = {
                  'area_name': areaNameController.text,
                  'location': locationController.text,
                  'province': selectedProvince,
                  'size_hectares': sizeController.text.isNotEmpty ? double.tryParse(sizeController.text) : null,
                  'mangrove_species': speciesController.text.isNotEmpty ? speciesController.text : null,
                  'conservation_status': selectedStatus,
                  'latitude': selectedLat,
                  'longitude': selectedLon,
                  'description': descriptionController.text.isNotEmpty ? descriptionController.text : null,
                  'established_year': yearController.text.isNotEmpty ? int.tryParse(yearController.text) : null,
                  'managing_organization': organizationController.text.isNotEmpty ? organizationController.text : null,
                  'threats': threatsController.text.isNotEmpty ? threatsController.text : null,
                  'conservation_activities': activitiesController.text.isNotEmpty ? activitiesController.text : null,
                };

                Navigator.pop(context);

                if (existingArea == null) {
                  await _createArea(areaData);
                } else {
                  await _updateArea(existingArea['id'], areaData);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text(existingArea == null ? 'เพิ่ม' : 'บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, double>?> _showLocationPicker({
    double? initialLat,
    double? initialLon,
  }) async {
    double selectedLat = initialLat ?? _currentPosition?.latitude ?? 13.6904;
    double selectedLon = initialLon ?? _currentPosition?.longitude ?? 100.7503;

    return showDialog<Map<String, double>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
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

  Future<void> _createArea(Map<String, dynamic> areaData) async {
    try {
      final response = await _apiClient.createMangroveArea(areaData);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'เพิ่มพื้นที่สำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAreas();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'เกิดข้อผิดพลาด'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    }
  }

  Future<void> _updateArea(int id, Map<String, dynamic> areaData) async {
    try {
      final response = await _apiClient.updateMangroveArea(id, areaData);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'แก้ไขสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAreas();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'เกิดข้อผิดพลาด'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบพื้นที่นี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArea(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArea(int id) async {
    try {
      final response = await _apiClient.deleteMangroveArea(id);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'ลบสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAreas();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'เกิดข้อผิดพลาด'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    }
  }

  Widget _buildMapTab() {
    // Calculate center - use areas with location or default to Thailand center
    final areasWithLocation = _areas.where((a) => a['latitude'] != null && a['longitude'] != null).toList();
    
    double centerLat;
    double centerLon;
    double zoom;

    if (areasWithLocation.isEmpty) {
      // Default to Eastern Thailand (Chachoengsao area)
      centerLat = 13.6904;
      centerLon = 101.0779;
      zoom = 9.0;
    } else {
      // Calculate average position of all areas
      centerLat = areasWithLocation.fold(0.0, (sum, a) {
        final lat = a['latitude'];
        final latDouble = lat is num ? lat.toDouble() : double.tryParse(lat.toString()) ?? 0.0;
        return sum + latDouble;
      }) / areasWithLocation.length;
      
      centerLon = areasWithLocation.fold(0.0, (sum, a) {
        final lon = a['longitude'];
        final lonDouble = lon is num ? lon.toDouble() : double.tryParse(lon.toString()) ?? 0.0;
        return sum + lonDouble;
      }) / areasWithLocation.length;
      
      zoom = 10.0;
    }

    return Stack(
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
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.eastern_mangrove_app',
            ),
            if (areasWithLocation.isNotEmpty)
              MarkerLayer(
                markers: areasWithLocation.map((area) {
                  final lat = area['latitude'];
                  final lon = area['longitude'];
                  final latDouble = lat is num ? lat.toDouble() : double.tryParse(lat.toString()) ?? 0.0;
                  final lonDouble = lon is num ? lon.toDouble() : double.tryParse(lon.toString()) ?? 0.0;
                  
                  return Marker(
                    point: LatLng(latDouble, lonDouble),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showAreaDetails(area),
                      child: Icon(
                        Icons.eco,
                        color: _getStatusColor(area['conservation_status'] ?? ''),
                        size: 40,
                        shadows: const [
                          Shadow(color: Colors.white, blurRadius: 8),
                          Shadow(color: Colors.white, blurRadius: 4),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
        // Info overlay when no data
        if (_areas.isEmpty)
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
                      Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'ยังไม่มีข้อมูลพื้นที่ป่าชายเลน',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'กดปุ่ม + ด้านล่างเพื่อเพิ่มพื้นที่',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Info overlay when no location data
        if (_areas.isNotEmpty && areasWithLocation.isEmpty)
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
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
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
        // FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddAreaDialog(),
            backgroundColor: const Color(0xFF2E7D32),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    final provinceStats = <String, int>{};
    final statusStats = <String, int>{};
    double totalSize = 0;

    for (var area in _areas) {
      // Count by province
      final province = area['province'] ?? 'ไม่ระบุ';
      provinceStats[province] = (provinceStats[province] ?? 0) + 1;

      // Count by status
      final status = area['conservation_status'] ?? 'ไม่ระบุ';
      statusStats[status] = (statusStats[status] ?? 0) + 1;

      // Sum size
      if (area['size_hectares'] != null) {
        totalSize += double.tryParse(area['size_hectares'].toString()) ?? 0;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Stats
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: const Color(0xFF2E7D32), size: 28),
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
                  _buildStatRow('จำนวนพื้นที่ทั้งหมด', '${_areas.length} แห่ง'),
                  _buildStatRow('พื้นที่รวมทั้งหมด', '${totalSize.toStringAsFixed(2)} ไร่'),
                  _buildStatRow('พื้นที่เฉลี่ย', _areas.isEmpty ? '0 ไร่' : '${(totalSize / _areas.length).toStringAsFixed(2)} ไร่'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // By Province
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
                        Expanded(
                          child: Text(entry.key),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

          // By Status
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
                  final color = _getStatusColor(entry.key);
                  final label = _conservationStatusMap[entry.key] ?? entry.key;
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
                        Expanded(
                          child: Text(label),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
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
