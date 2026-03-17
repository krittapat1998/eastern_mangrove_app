import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';

class PollutionReportsNewScreen extends StatefulWidget {
  const PollutionReportsNewScreen({super.key});

  @override
  State<PollutionReportsNewScreen> createState() => _PollutionReportsNewScreenState();
}

class _PollutionReportsNewScreenState extends State<PollutionReportsNewScreen> 
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'ทั้งหมด';
  Position? _currentPosition;

  final Map<String, String> _reportTypes = {
    'ทั้งหมด': 'all',
    'มลพิษทางน้ำ': 'water',
    'มลพิษทางอากาศ': 'air',
    'ขยะชุมชน': 'community_waste',
    'ขยะอุตสาหกรรม': 'industrial_waste',
  };

  final Map<String, String> _severityLevels = {
    'low': 'ต่ำ',
    'medium': 'ปานกลาง',
    'high': 'สูง',
    'critical': 'วิกฤต',
  };

  final Map<String, String> _statusMap = {
    'pending': 'รอดำเนินการ',
    'investigating': 'กำลังตรวจสอบ',
    'monitoring': 'กำลังติดตาม',
    'resolved': 'แก้ไขแล้ว',
    'closed': 'ปิดเรื่อง',
  };

  // Reverse mapping: Database format -> Frontend format
  final Map<String, String> _dbToFrontendTypeMap = {
    'Water Pollution': 'water',
    'Air Pollution': 'air',
    'Community Waste': 'community_waste',
    'Industrial Waste': 'industrial_waste',
  };

  // For display: Database format -> Thai name
  final Map<String, String> _dbTypeToThaiMap = {
    'Water Pollution': 'มลพิษทางน้ำ',
    'Air Pollution': 'มลพิษทางอากาศ',
    'Community Waste': 'ขยะชุมชน',
    'Industrial Waste': 'ขยะอุตสาหกรรม',
  };

  // Frontend to Database mapping
  final Map<String, String> _frontendToDbTypeMap = {
    'water': 'Water Pollution',
    'air': 'Air Pollution',
    'community_waste': 'Community Waste',
    'industrial_waste': 'Industrial Waste',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
    // Load location after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
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
      // Silent fail - will use default location
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getPollutionReportsNew();
      
      print('📍 Pollution Reports Response: ${response.success}');
      print('📍 Data count: ${response.data?.length ?? 0}');
      if (response.data != null && response.data!.isNotEmpty) {
        print('📍 First report sample: ${response.data![0]}');
        print('📍 Latitude: ${response.data![0]['latitude']}');
        print('📍 Longitude: ${response.data![0]['longitude']}');
      }
      
      if (response.success && response.data != null) {
        setState(() {
          _reports = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Load reports error: $e');
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredReports {
    if (_selectedFilter == 'ทั้งหมด') {
      return _reports;
    }
    // Filter by Thai pollution type directly (API already returns Thai format)
    return _reports.where((r) => r['report_type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('รายงานมลพิษป่าชายเลน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF4CAF50),
          tabs: const [
            Tab(text: 'รายงานมลพิษ', icon: Icon(Icons.list_alt)),
            Tab(text: 'แผนที่มลพิษ', icon: Icon(Icons.map)),
            Tab(text: 'สถิติ', icon: Icon(Icons.bar_chart)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildMapTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
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
                onPressed: () => _showAddReportDialog(),
                backgroundColor: const Color(0xFF2E7D32),
                child: const Icon(Icons.add, size: 24),
              ),
            ),
          ),
        ],
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
              onPressed: _loadReports,
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

    return Stack(
      children: [
        Column(
          children: [
            _buildSummaryAndFilter(),
            Expanded(
              child: _filteredReports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'ยังไม่มีรายงานมลพิษ\nกดปุ่ม + เพื่อเพิ่มรายงาน',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = _filteredReports[index];
                        return _buildReportCard(report);
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: () => _showAddReportDialog(),
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.add, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryAndFilter() {
    final highSeverity = _filteredReports.where((r) => r['severity_level'] == 'high' || r['severity_level'] == 'critical').length;
    final pending = _filteredReports.where((r) => r['status'] == 'reported' || r['status'] == 'investigating').length;

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
                  'รายงานทั้งหมด',
                  '${_filteredReports.length}',
                  Icons.report_problem,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'ความรุนแรงสูง',
                  '$highSeverity',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'รอดำเนินการ',
                  '$pending',
                  Icons.pending_actions,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _reportTypes.keys.map((type) {
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

  Widget _buildReportCard(Map<String, dynamic> report) {
    final reportType = report['report_type'] ?? '';
    final description = report['description'] ?? '';
    final severity = report['severity_level'] ?? '';
    final status = report['status'] ?? '';
    final dateReported = report['report_date'] != null
        ? DateTime.parse(report['report_date'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getSeverityColor(severity).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning,
                          size: 14,
                          color: _getSeverityColor(severity),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _severityLevels[severity] ?? severity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(severity),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _dbTypeToThaiMap[reportType] ?? reportType,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showAddReportDialog(existingReport: report),
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDelete(report['id']),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                    ),
                    child: Text(
                      _statusMap[status] ?? status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (dateReported != null)
                    Text(
                      _formatDate(dateReported),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'reported':
        return Colors.blue;
      case 'investigating':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year + 543}';
  }

  void _showReportDetails(Map<String, dynamic> report) {
    // Get Thai name for report type from database format
    final reportType = report['report_type'];
    final reportTypeThai = _dbTypeToThaiMap[reportType] ?? reportType ?? 'ไม่ระบุ';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reportTypeThai),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ความรุนแรง', _severityLevels[report['severity_level']] ?? '-'),
              _buildDetailRow('สถานะ', _statusMap[report['status']] ?? '-'),
              const SizedBox(height: 16),
              const Text(
                'คำอธิบาย:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(report['description'] ?? '-'),
              if (report['pollution_source'] != null && report['pollution_source'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'แหล่งที่มา:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(report['pollution_source']),
              ],
              if (report['latitude'] != null && report['longitude'] != null) ...[
                const SizedBox(height: 16),
                _buildDetailRow('ตำแหน่ง', '${report['latitude']}, ${report['longitude']}'),
              ],
              if (report['report_date'] != null)
                _buildDetailRow('วันที่รายงาน', _formatDate(DateTime.parse(report['report_date']))),
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
              _showAddReportDialog(existingReport: report);
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

  void _showAddReportDialog({Map<String, dynamic>? existingReport}) {
    // Convert database format to frontend format for editing
    String selectedType = 'water'; // default
    if (existingReport != null && existingReport['report_type'] != null) {
      // Try to map from database format (e.g., "Water Pollution") to frontend format (e.g., "water")
      selectedType = _dbToFrontendTypeMap[existingReport['report_type']] ?? 'water';
    }
    
    String selectedSeverity = existingReport?['severity_level'] ?? 'medium';
    String selectedStatus = existingReport?['status'] ?? 'pending';
    
    // Parse latitude and longitude properly
    double? selectedLat;
    double? selectedLon;
    
    if (existingReport != null) {
      if (existingReport['latitude'] != null) {
        selectedLat = existingReport['latitude'] is String 
            ? double.tryParse(existingReport['latitude']) 
            : existingReport['latitude']?.toDouble();
      }
      if (existingReport['longitude'] != null) {
        selectedLon = existingReport['longitude'] is String 
            ? double.tryParse(existingReport['longitude']) 
            : existingReport['longitude']?.toDouble();
      }
    }
    
    final descriptionController = TextEditingController(
      text: existingReport?['description'] ?? '',
    );
    final sourceController = TextEditingController(
      text: existingReport?['pollution_source'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingReport == null ? 'เพิ่มรายงานมลพิษ' : 'แก้ไขรายงานมลพิษ'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'ประเภทมลพิษ *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _reportTypes.entries
                        .where((e) => e.key != 'ทั้งหมด')
                        .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'ความรุนแรง *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                    items: _severityLevels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedSeverity = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'สถานะ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: _statusMap.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'คำอธิบาย *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sourceController,
                    decoration: const InputDecoration(
                      labelText: 'แหล่งที่มาของมลพิษ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.source),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location Picker Button (REQUIRED)
                  Card(
                    elevation: 2,
                    color: selectedLat == null || selectedLon == null
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: selectedLat == null || selectedLon == null
                            ? Colors.red.shade300
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
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: selectedLat != null && selectedLon != null
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'ตำแหน่งมลพิษ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        ' *',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      if (selectedLat == null || selectedLon == null)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            '(บังคับ)',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedLat != null && selectedLon != null
                                        ? 'พิกัด: ${selectedLat!.toStringAsFixed(6)}, ${selectedLon!.toStringAsFixed(6)}'
                                        : 'แตะเพื่อเลือกตำแหน่งบนแผนที่',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Use Current Location Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final location = await _getCurrentLocation();
                        if (location != null) {
                          setDialogState(() {
                            selectedLat = location['lat'];
                            selectedLon = location['lon'];
                          });
                          if (context.mounted) {
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
                // Validation: Description
                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณากรอกคำอธิบาย'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Validation: Location (REQUIRED)
                if (selectedLat == null || selectedLon == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ กรุณาเลือกตำแหน่งมลพิษ\nกดที่การ์ด "ตำแหน่งมลพิษ" หรือใช้ "ใช้ตำแหน่งปัจจุบัน"'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                    ),
                  );
                  return;
                }

                // Convert frontend format to database format
                final dbReportType = _frontendToDbTypeMap[selectedType] ?? selectedType;
                
                final dataMap = {
                  'reportType': dbReportType,
                  'severityLevel': selectedSeverity,
                  'status': selectedStatus,
                  'description': descriptionController.text.trim(),
                  'pollutionSource': sourceController.text.trim().isNotEmpty 
                      ? sourceController.text.trim() 
                      : 'ไม่ระบุ',
                  'latitude': selectedLat,
                  'longitude': selectedLon,
                  'reportDate': DateTime.now().toIso8601String(),
                  'photos': existingReport?['photos'] ?? [],
                };

                Navigator.pop(context);

                if (existingReport == null) {
                  await _createReport(dataMap);
                } else {
                  // Ensure id is properly parsed as int
                  final int reportId = existingReport['id'] is int 
                      ? existingReport['id'] 
                      : int.parse(existingReport['id'].toString());
                  await _updateReport(reportId, dataMap);
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

  // Request location permission
  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเปิดบริการตำแหน่ง (GPS) ในการตั้งค่า'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ต้องการสิทธิ์การเข้าถึงตำแหน่งเพื่อระบุตำแหน่งมลพิษ'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สิทธิ์การเข้าถึงตำแหน่งถูกปิดอย่างถาวร กรุณาเปิดในการตั้งค่า'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }

    return true;
  }

  // Get current GPS location
  Future<Map<String, double>?> _getCurrentLocation() async {
    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กำลังรับตำแหน่งปัจจุบัน...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return {
        'lat': position.latitude,
        'lon': position.longitude,
      };
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถรับตำแหน่งได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<Map<String, double>?> _showLocationPicker({
    double? initialLat,
    double? initialLon,
  }) async {
    // Default to Bangkok area if no initial location
    final centerLat = initialLat ?? 13.7563;
    final centerLon = initialLon ?? 100.5018;
    
    LatLng? selectedLocation = initialLat != null && initialLon != null
        ? LatLng(initialLat, initialLon)
        : null;

    return showDialog<Map<String, double>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setMapState) => AlertDialog(
          title: const Text('เลือกตำแหน่งมลพิษ'),
          content: SizedBox(
            width: 500,
            height: 500,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedLocation != null
                              ? 'พิกัดที่เลือก: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}'
                              : 'แตะบนแผนที่เพื่อเลือกตำแหน่ง',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(centerLat, centerLon),
                      initialZoom: 13.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      onTap: (tapPosition, point) {
                        setMapState(() {
                          selectedLocation = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.eastern_mangrove_app',
                      ),
                      if (selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selectedLocation!,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: selectedLocation != null
                  ? () {
                      Navigator.pop(context, {
                        'lat': selectedLocation!.latitude,
                        'lon': selectedLocation!.longitude,
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันตำแหน่ง'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createReport(Map<String, dynamic> dataMap) async {
    try {
      print('➕ Creating new report');
      print('📦 Data: $dataMap');
      
      final response = await _apiClient.createPollutionReport(dataMap);
      
      print('📬 Response: success=${response.success}, message=${response.message}');
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกรายงานมลพิษสำเร็จ'), backgroundColor: Colors.green),
          );
          _loadReports();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.message}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Create error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateReport(int id, Map<String, dynamic> dataMap) async {
    try {
      print('🔄 Updating report ID: $id');
      print('📦 Data: $dataMap');
      
      final response = await _apiClient.updatePollutionReport(id, dataMap);
      
      print('📬 Response: success=${response.success}, message=${response.message}');
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัพเดทรายงานมลพิษสำเร็จ'), backgroundColor: Colors.green),
          );
          _loadReports();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.message}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Update error: $e');
      print('Stack trace: $stackTrace');
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
        content: const Text('คุณต้องการลบรายงานมลพิษนี้ใช่หรือไม่?'),
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
      await _deleteReport(id);
    }
  }

  Future<void> _deleteReport(int id) async {
    try {
      final response = await _apiClient.deletePollutionReport(id);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบรายงานมลพิษสำเร็จ'), backgroundColor: Colors.green),
          );
          _loadReports();
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

  // Helper method to build stat item with progress bar
  Widget _buildStatItem({
    required String label,
    required int count,
    required int total,
    required Color color,
    IconData? icon,
  }) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    final progress = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$count เรื่อง',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Get icon for marker based on report type (แยก icon ให้ชัดเจน)
  IconData _getMarkerIcon(String reportType) {
    switch (reportType) {
      case 'มลพิษทางน้ำ':
        return Icons.water_drop; // 💧 มลพิษทางน้ำ
      case 'มลพิษทางอากาศ':
        return Icons.air; // 🌬️ มลพิษทางอากาศ
      case 'ขยะชุมชน':
        return Icons.delete; // 🗑️ ขยะชุมชน
      case 'ขยะอุตสาหกรรม':
        return Icons.factory; // 🏭 ขยะอุตสาหกรรม
      default:
        return Icons.report_problem; // ⚠️ เครื่องหมายอื่นๆ
    }
  }

  Widget _buildMapTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return const Center(
        child: Text('ไม่มีข้อมูลรายงานมลพิษ', style: TextStyle(fontSize: 18)),
      );
    }

    // Use filtered reports for map (same as Tab 1)
    final displayReports = _filteredReports;
    
    print('📍 Total reports for map: ${displayReports.length}');
    
    // Filter reports that have valid coordinates
    final reportsWithLocation = displayReports.where((report) {
      final lat = report['latitude'];
      final lng = report['longitude'];
      
      print('📍 Checking report: lat=$lat (${lat.runtimeType}), lng=$lng (${lng.runtimeType})');
      
      if (lat == null || lng == null) return false;
      
      // Handle both String and num types
      double? latNum;
      double? lngNum;
      
      if (lat is num) {
        latNum = lat.toDouble();
      } else if (lat is String) {
        latNum = double.tryParse(lat);
      }
      
      if (lng is num) {
        lngNum = lng.toDouble();
      } else if (lng is String) {
        lngNum = double.tryParse(lng);
      }
      
      return latNum != null && lngNum != null && 
             latNum != 0 && lngNum != 0;
    }).toList();

    print('📍 Reports with valid location: ${reportsWithLocation.length}');

    // Calculate center: use average of markers if available, otherwise use user location
    double centerLat;
    double centerLng;
    
    if (reportsWithLocation.isNotEmpty) {
      // Calculate center from markers
      double avgLat = 0;
      double avgLng = 0;
      
      for (final report in reportsWithLocation) {
        final latRaw = report['latitude'];
        final lngRaw = report['longitude'];
        
        final lat = (latRaw is num) ? latRaw.toDouble() : double.parse(latRaw.toString());
        final lng = (lngRaw is num) ? lngRaw.toDouble() : double.parse(lngRaw.toString());
        
        avgLat += lat;
        avgLng += lng;
      }
      
      centerLat = avgLat / reportsWithLocation.length;
      centerLng = avgLng / reportsWithLocation.length;
    } else if (_currentPosition != null) {
      // Use user location if no reports
      centerLat = _currentPosition!.latitude;
      centerLng = _currentPosition!.longitude;
    } else {
      // Default to Bangkok coordinates
      centerLat = 13.7563;
      centerLng = 100.5018;
    }

    print('🗺️ Map center: $centerLat, $centerLng');
    print('🗺️ Total markers to create: ${reportsWithLocation.length}');

    return Stack(
      children: [
        Column(
          children: [
            _buildSummaryAndFilter(),
            Expanded(
              child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: 14.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.eastern_mangrove_app',
            ),
            // User Location Marker Layer
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_pin_circle,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            // Pollution Reports Marker Layer
            MarkerLayer(
              markers: reportsWithLocation.map((report) {
                print('🗺️ Creating marker for report: ${report['id']}');
                // Handle both String and num for coordinates
                final latRaw = report['latitude'];
                final lngRaw = report['longitude'];
                
                final lat = (latRaw is num) ? latRaw.toDouble() : double.parse(latRaw.toString());
                final lng = (lngRaw is num) ? lngRaw.toDouble() : double.parse(lngRaw.toString());
                
                final severity = report['severity_level'] ?? 'unknown';
                final reportType = report['report_type'] ?? 'unknown';
                
                print('🎯 Report ${report['id']}: type=$reportType, severity=$severity');
                
                // Determine marker color based on severity
                Color markerColor;
                switch (severity.toLowerCase()) {
                  case 'low':
                  case 'ต่ำ':
                    markerColor = Colors.green;
                    break;
                  case 'medium':
                  case 'ปานกลาง':
                    markerColor = Colors.orange;
                    break;
                  case 'high':
                  case 'สูง':
                    markerColor = Colors.deepOrange;
                    break;
                  case 'critical':
                  case 'วิกฤต':
                    markerColor = Colors.red;
                    break;
                  default:
                    markerColor = Colors.blue;
                }

                // Get icon based on report type
                final markerIcon = _getMarkerIcon(reportType);

                return Marker(
                  point: LatLng(lat, lng),
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () => _showMarkerInfo(report),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Location pin background (สีอ่อนตามความรุนแรง)
                        Icon(
                          Icons.location_on,
                          size: 80,
                          color: markerColor.withOpacity(0.5),
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black45,
                              offset: Offset(1, 2),
                            ),
                          ],
                        ),
                        // White circle background with icon in severity color
                        Positioned(
                          top: 10,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                markerIcon, // Icon แต่ละแบบต่างกัน
                                size: 28,
                                color: markerColor, // สีตามความรุนแรง
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
            ),
          ],
        ),
        // Floating buttons (my_location left, add right - same size)
        Positioned(
          bottom: 16,
          left: 16,
          child: SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: _moveToCurrentLocation,
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.my_location, size: 24, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: () => _showAddReportDialog(),
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.add, size: 24, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _moveToCurrentLocation() async {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14.0,
      );
    } else {
      // Try to get current location
      final location = await _getCurrentLocation();
      if (location != null && mounted) {
        _mapController.move(
          LatLng(location['lat']!, location['lon']!),
          14.0,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถรับตำแหน่งปัจจุบันได้'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showMarkerInfo(Map<String, dynamic> report) {
    // Get report type in Thai from database format
    final reportType = report['report_type'];
    final reportTypeThai = _dbTypeToThaiMap[reportType] ?? reportType ?? 'ไม่ระบุ';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            reportTypeThai,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('ประเภท', reportTypeThai),
                const SizedBox(height: 8),
                _buildInfoRow('ระดับความรุนแรง', _severityLevels[report['severity_level']] ?? report['severity_level'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow('สถานะ', _statusMap[report['status']] ?? report['status'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow('แหล่งมลพิษ', report['pollution_source'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow('รายละเอียด', report['description'] ?? '-'),
                const SizedBox(height: 8),
                _buildInfoRow('พิกัด', '${report['latitude']}, ${report['longitude']}'),
                if (report['report_date'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('วันที่รายงาน', _formatDate(DateTime.parse(report['report_date']))),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _openInGoogleMaps(
                  report['latitude'],
                  report['longitude'],
                  report['description'] ?? 'ตำแหน่งมลพิษ',
                );
              },
              icon: const Icon(Icons.navigation),
              label: const Text('นำทาง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันเปิด Google Maps สำหรับนำทาง
  Future<void> _openInGoogleMaps(dynamic lat, dynamic lon, String label) async {
    if (lat == null || lon == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ ไม่พบข้อมูลตำแหน่ง'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final double latitude = (lat is num) ? lat.toDouble() : double.parse(lat.toString());
    final double longitude = (lon is num) ? lon.toDouble() : double.parse(lon.toString());
    
    // สร้าง URL สำหรับ Google Maps
    // รูปแบบ: https://www.google.com/maps/dir/?api=1&destination=lat,lng&travelmode=driving
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
    
    // สำหรับเปิดใน Google Maps app โดยตรง (iOS และ Android)
    final String googleMapsAppUrl = 'geo:$latitude,$longitude?q=$latitude,$longitude($label)';
    
    try {
      // ลองเปิด Google Maps app ก่อน
      final Uri geoUri = Uri.parse(googleMapsAppUrl);
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        // ถ้าไม่สำเร็จ ให้เปิดใน browser
        final Uri webUri = Uri.parse(googleMapsUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'ไม่สามารถเปิด Google Maps ได้';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิด Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('ไม่มีข้อมูลสถิติ', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    // Calculate statistics using snake_case from database
    final totalReports = _reports.length;
    final byType = <String, int>{};
    final bySeverity = <String, int>{};
    final byStatus = <String, int>{};

    for (var report in _reports) {
      final type = report['report_type'] ?? 'unknown';
      final severity = report['severity_level'] ?? 'unknown';
      final status = report['status'] ?? 'unknown';

      byType[type] = (byType[type] ?? 0) + 1;
      bySeverity[severity] = (bySeverity[severity] ?? 0) + 1;
      byStatus[status] = (byStatus[status] ?? 0) + 1;
    }

    // Map database values to Thai display names (updated for new 4 types)
    final Map<String, String> typeToThaiMap = {
      'Water Pollution': 'มลพิษทางน้ำ',
      'Air Pollution': 'มลพิษทางอากาศ',
      'Community Waste': 'ขยะชุมชน',
      'Industrial Waste': 'ขยะอุตสาหกรรม',
      // Identity mappings for Thai names (in case data is already in Thai)
      'มลพิษทางน้ำ': 'มลพิษทางน้ำ',
      'มลพิษทางอากาศ': 'มลพิษทางอากาศ',
      'ขยะชุมชน': 'ขยะชุมชน',
      'ขยะอุตสาหกรรม': 'ขยะอุตสาหกรรม',
    };

    final Map<String, String> severityToThaiMap = {
      'low': 'ต่ำ',
      'medium': 'ปานกลาง',
      'high': 'สูง',
      'critical': 'วิกฤต',
    };

    final Map<String, String> statusToThaiMap = {
      'pending': 'รอดำเนินการ',
      'investigating': 'กำลังตรวจสอบ',
      'monitoring': 'กำลังติดตาม',
      'resolved': 'แก้ไขแล้ว',
      'closed': 'ปิดเรื่อง',
    };

    // Get recent reports (max 5)
    final recentReports = _reports.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Card with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(
                  Icons.assessment,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'รายงานมลพิษทั้งหมด',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalReports',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 56,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'เรื่อง',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // By Type Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'แยกตามประเภทมลพิษ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ...byType.entries.map((entry) {
                    Color color;
                    IconData icon;
                    final type = entry.key;
                    
                    // ใช้ switch-case แบบเดียวกับส่วนอื่นๆ
                    switch (type) {
                      case 'มลพิษทางน้ำ':
                        color = Colors.blue.shade600;
                        icon = Icons.water_drop;
                        break;
                      case 'มลพิษทางอากาศ':
                        color = Colors.grey.shade600;
                        icon = Icons.air;
                        break;
                      case 'ขยะชุมชน':
                        color = Colors.brown.shade600;
                        icon = Icons.delete;
                        break;
                      case 'ขยะอุตสาหกรรม':
                        color = Colors.orange.shade700;
                        icon = Icons.factory;
                        break;
                      default:
                        color = Colors.teal.shade600;
                        icon = Icons.report_problem;
                    }
                    
                    return _buildStatItem(
                      label: typeToThaiMap[entry.key] ?? entry.key,
                      count: entry.value,
                      total: totalReports,
                      color: color,
                      icon: icon,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // By Severity Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'แยกตามระดับความรุนแรง',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ...bySeverity.entries.map((entry) {
                    Color color;
                    IconData icon;
                    switch (entry.key.toLowerCase()) {
                      case 'low':
                        color = Colors.green;
                        icon = Icons.check_circle;
                        break;
                      case 'medium':
                        color = Colors.orange;
                        icon = Icons.warning_amber;
                        break;
                      case 'high':
                        color = Colors.deepOrange;
                        icon = Icons.error;
                        break;
                      case 'critical':
                        color = Colors.red;
                        icon = Icons.dangerous;
                        break;
                      default:
                        color = Colors.grey;
                        icon = Icons.help;
                    }
                    
                    return _buildStatItem(
                      label: severityToThaiMap[entry.key] ?? entry.key,
                      count: entry.value,
                      total: totalReports,
                      color: color,
                      icon: icon,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // By Status Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.task_alt,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'แยกตามสถานะการแก้ไข',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ...byStatus.entries.map((entry) {
                    Color color;
                    IconData icon;
                    switch (entry.key.toLowerCase()) {
                      case 'pending':
                        color = Colors.orange;
                        icon = Icons.pending;
                        break;
                      case 'investigating':
                        color = Colors.blue;
                        icon = Icons.search;
                        break;
                      case 'monitoring':
                        color = Colors.purple;
                        icon = Icons.visibility;
                        break;
                      case 'resolved':
                        color = Colors.green;
                        icon = Icons.check_circle;
                        break;
                      case 'closed':
                        color = Colors.grey;
                        icon = Icons.archive;
                        break;
                      default:
                        color = Colors.grey;
                        icon = Icons.help;
                    }
                    
                    return _buildStatItem(
                      label: statusToThaiMap[entry.key] ?? entry.key,
                      count: entry.value,
                      total: totalReports,
                      color: color,
                      icon: icon,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Activities Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history,
                          color: Colors.indigo.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'รายงานล่าสุด',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (recentReports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'ยังไม่มีรายงาน',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...recentReports.map((report) {
                      final severity = report['severity_level'] ?? 'unknown';
                      Color severityColor;
                      IconData severityIcon;
                      switch (severity.toLowerCase()) {
                        case 'low':
                          severityColor = Colors.green;
                          severityIcon = Icons.check_circle;
                          break;
                        case 'medium':
                          severityColor = Colors.orange;
                          severityIcon = Icons.warning_amber;
                          break;
                        case 'high':
                          severityColor = Colors.deepOrange;
                          severityIcon = Icons.error;
                          break;
                        case 'critical':
                          severityColor = Colors.red;
                          severityIcon = Icons.dangerous;
                          break;
                        default:
                          severityColor = Colors.grey;
                          severityIcon = Icons.help;
                      }

                      String dateStr = '';
                      if (report['report_date'] != null) {
                        try {
                          final date = DateTime.parse(report['report_date']);
                          dateStr = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        } catch (e) {
                          dateStr = report['report_date'];
                        }
                      }

                      final type = typeToThaiMap[report['report_type']] ?? report['report_type'] ?? 'ไม่ระบุ';
                      final severityText = severityToThaiMap[severity] ?? severity;
                      final location = report['pollution_source'] ?? 'ไม่ระบุ';
                      final description = report['description'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: severityColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: severityColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                severityIcon,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (description.isNotEmpty)
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: severityColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          severityText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: severityColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
