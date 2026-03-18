import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/api_client.dart';
import 'widgets/area_card.dart';
import 'widgets/area_details_dialog.dart';
import 'widgets/add_area_dialog.dart';
import 'widgets/map_tab.dart';

class MangroveManagementScreen extends StatefulWidget {
  const MangroveManagementScreen({super.key});

  @override
  State<MangroveManagementScreen> createState() =>
      _MangroveManagementScreenState();
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
      if (!hasPermission) return;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) setState(() => _currentPosition = position);
    } catch (_) {}
  }

  Future<bool> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, double>?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กรุณาเปิดบริการตำแหน่ง (GPS) ในการตั้งค่า'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ต้องการสิทธิ์การเข้าถึงตำแหน่ง'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
      return {'lat': position.latitude, 'lon': position.longitude};
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

  Future<void> _loadAreas() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await _apiClient.getMangroveAreas(province: null);
      if (!mounted) return;
      if (response.success) {
        setState(() { _areas = response.data ?? []; _isLoading = false; });
      } else {
        setState(() {
          _errorMessage = response.error ?? response.message ?? 'ไม่สามารถโหลดข้อมูลได้';
          _isLoading = false;
          _areas = [];
        });
      }
    } catch (e) {
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
    if (_selectedFilter == 'ทั้งหมด') return _areas;
    return _areas.where((a) => a['conservation_status'] == _selectedFilter).toList();
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
            onPressed: () { Navigator.pop(context); _deleteArea(id); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? (response.success ? 'ลบสำเร็จ' : 'เกิดข้อผิดพลาด')),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadAreas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAreas),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAreasTab(),
          MangroveMapTab(
            filteredAreas: _filteredAreas,
            currentPosition: _currentPosition,
            buildFilterChips: _buildFilterChips,
            onAreaTap: (area) => showMangroveAreaDetailsDialog(
              context, area,
              conservationStatusMap: _conservationStatusMap,
              onEdit: (a) => showMangroveAddAreaDialog(
                context, existingArea: a,
                provinces: _provinces,
                conservationStatusMap: _conservationStatusMap,
                apiClient: _apiClient,
                currentPosition: _currentPosition,
                getCurrentLocation: _getCurrentLocation,
                onSuccess: _loadAreas,
              ),
            ),
            onAddPressed: () => showMangroveAddAreaDialog(
              context,
              provinces: _provinces,
              conservationStatusMap: _conservationStatusMap,
              apiClient: _apiClient,
              currentPosition: _currentPosition,
              getCurrentLocation: _getCurrentLocation,
              onSuccess: _loadAreas,
            ),
          ),
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
            bottom: 16, right: 16,
            child: FloatingActionButton(
              onPressed: () => showMangroveAddAreaDialog(
                context,
                provinces: _provinces,
                conservationStatusMap: _conservationStatusMap,
                apiClient: _apiClient,
                currentPosition: _currentPosition,
                getCurrentLocation: _getCurrentLocation,
                onSuccess: _loadAreas,
              ),
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.add),
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
                  Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
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
            bottom: 16, right: 16,
            child: FloatingActionButton(
              onPressed: () => showMangroveAddAreaDialog(
                context,
                provinces: _provinces,
                conservationStatusMap: _conservationStatusMap,
                apiClient: _apiClient,
                currentPosition: _currentPosition,
                getCurrentLocation: _getCurrentLocation,
                onSuccess: _loadAreas,
              ),
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
                        return MangroveAreaCard(
                          area: area,
                          conservationStatusMap: _conservationStatusMap,
                          onTap: () => showMangroveAreaDetailsDialog(
                            context, area,
                            conservationStatusMap: _conservationStatusMap,
                            onEdit: (a) => showMangroveAddAreaDialog(
                              context, existingArea: a,
                              provinces: _provinces,
                              conservationStatusMap: _conservationStatusMap,
                              apiClient: _apiClient,
                              currentPosition: _currentPosition,
                              getCurrentLocation: _getCurrentLocation,
                              onSuccess: _loadAreas,
                            ),
                          ),
                          onEdit: (a) => showMangroveAddAreaDialog(
                            context, existingArea: a,
                            provinces: _provinces,
                            conservationStatusMap: _conservationStatusMap,
                            apiClient: _apiClient,
                            currentPosition: _currentPosition,
                            getCurrentLocation: _getCurrentLocation,
                            onSuccess: _loadAreas,
                          ),
                          onDelete: _confirmDelete,
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton(
            onPressed: () => showMangroveAddAreaDialog(
              context,
              provinces: _provinces,
              conservationStatusMap: _conservationStatusMap,
              apiClient: _apiClient,
              currentPosition: _currentPosition,
              getCurrentLocation: _getCurrentLocation,
              onSuccess: _loadAreas,
            ),
            backgroundColor: const Color(0xFF2E7D32),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('ทั้งหมด'),
              selected: _selectedFilter == 'ทั้งหมด',
              onSelected: (_) => setState(() => _selectedFilter = 'ทั้งหมด'),
              backgroundColor: Colors.grey.shade200,
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: _selectedFilter == 'ทั้งหมด' ? Colors.white : Colors.black87,
                fontWeight: _selectedFilter == 'ทั้งหมด' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          ..._conservationStatusMap.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFilter = entry.key),
                backgroundColor: Colors.grey.shade200,
                selectedColor: const Color(0xFF2E7D32),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryAndFilter() {
    final totalSize = _filteredAreas.fold<double>(
      0,
      (sum, area) => sum + (area['size_hectares'] != null ? double.tryParse(area['size_hectares'].toString()) ?? 0 : 0),
    );
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'พื้นที่ป่าทั้งหมด',
                  '${_filteredAreas.length} แห่ง',
                  Icons.eco,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'พื้นที่รวม',
                  '${totalSize.toStringAsFixed(1)} ไร่',
                  Icons.terrain,
                  Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'กรองตามสถานะ',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          _buildFilterChips(),
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
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
