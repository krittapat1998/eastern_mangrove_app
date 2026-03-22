import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';

class PublicDashboard extends StatefulWidget {
  const PublicDashboard({super.key});

  @override
  State<PublicDashboard> createState() => _PublicDashboardState();
}

class _PublicDashboardState extends State<PublicDashboard>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _serviceSummary = [];
  List<Map<String, dynamic>> _serviceBreakdown = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Tab 2 map filter & GPS
  String _selectedMapFilter = 'ทั้งหมด';
  Position? _currentPosition;

  // Tab 3 expanded months
  final Set<String> _expandedMonths = {};

  static const Map<String, String> _conservationStatusMap = {
    'excellent': 'ดีเยี่ยม',
    'good': 'ดี',
    'moderate': 'ปานกลาง',
    'poor': 'เสื่อมโทรม',
    'protected': 'พื้นที่ปกป้อง',
    'monitored': 'พื้นที่เฝ้าระวัง',
    'threatened': 'พื้นที่เสี่ยง',
    'restored': 'พื้นที่ฟื้นฟู',
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentLocation());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _apiClient.getPublicStatistics(),
        _apiClient.getPublicMangroveAreas(),
        _apiClient.getPublicServiceSummary(),
        _apiClient.getPublicServiceBreakdown(),
      ]);
      if (mounted) {
        setState(() {
          if (results[0].success && results[0].data != null) {
            _statistics = results[0].data as Map<String, dynamic>;
          }
          if (results[1].success && results[1].data != null) {
            _areas = results[1].data as List<Map<String, dynamic>>;
          }
          if (results[2].success && results[2].data != null) {
            _serviceSummary = results[2].data as List<Map<String, dynamic>>;
          }
          if (results[3].success && results[3].data != null) {
            _serviceBreakdown = results[3].data as List<Map<String, dynamic>>;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'เกิดข้อผิดพลาด: $e';
        });
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'ข้อมูลป่าชายเลนภาคตะวันออก',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF4CAF50),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.forest), text: 'พื้นที่ป่าชายเลน'),
            Tab(icon: Icon(Icons.map), text: 'แผนที่'),
            Tab(icon: Icon(Icons.analytics), text: 'สรุปบริการ'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAreasTab(),
                    _buildMapTab(),
                    _buildServiceSummaryTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'เกิดข้อผิดพลาด',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAllData,
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

  // ─── TAB 1: พื้นที่ป่าชายเลน ────────────────────────────────────────────────

  Widget _buildAreasTab() {
    final filtered = _areas.where((a) {
      if (_searchQuery.isEmpty) return true;
      final name = (a['area_name'] ?? '').toString().toLowerCase();
      final province = (a['province'] ?? '').toString().toLowerCase();
      final org = (a['managing_organization'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || province.contains(q) || org.contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF2E7D32),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildAreasStatsHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ค้นหาพื้นที่, จังหวัด...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'พบ ${filtered.length} พื้นที่',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),
          filtered.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'ไม่พบพื้นที่ที่ตรงกัน',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildAreaCard(filtered[i]),
                    childCount: filtered.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildAreasStatsHeader() {
    final areasData =
        (_statistics['mangroveAreas'] as Map<String, dynamic>?) ?? {};
    final commData =
        (_statistics['communities'] as Map<String, dynamic>?) ?? {};
    final svcData =
        (_statistics['ecosystemServices'] as Map<String, dynamic>?) ?? {};

    final totalAreas = areasData['totalAreas'] ?? _areas.length;
    final totalHectares =
        (areasData['totalHectares'] ?? 0.0).toStringAsFixed(1);
    final totalCommunities = commData['total'] ?? 0;
    final totalValue =
        _formatNumber((svcData['totalValue'] ?? 0).toDouble());

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.forest, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'สถิติพื้นที่ป่าชายเลน',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                    '$totalAreas', 'พื้นที่', Icons.location_on),
              ),
              Expanded(
                child: _buildStatChip(
                    totalHectares, 'ไร่', Icons.straighten),
              ),
              Expanded(
                child: _buildStatChip(
                    '$totalCommunities', 'ชุมชน', Icons.groups),
              ),
              Expanded(
                child: _buildStatChip(
                    '฿$totalValue', 'มูลค่า 12 เดือน', Icons.attach_money,
                    small: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon,
      {bool small = false}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 12 : 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAreaCard(Map<String, dynamic> area) {
    final status = (area['conservation_status'] ?? '').toString().toLowerCase();
    final statusThai =
        _conservationStatusMap[status] ?? area['conservation_status'] ?? 'ไม่ระบุ';
    final statusColor = _getStatusColor(status);

    final species = area['mangrove_species'];
    String speciesText = '';
    if (species is List) {
      speciesText = (species as List).join(', ');
    } else if (species is String && species.isNotEmpty) {
      speciesText = species;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAreaDetail(area),
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
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.forest, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          area['area_name'] ?? 'ไม่ระบุชื่อ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                [
                                  area['province'],
                                  area['location'],
                                ]
                                    .where((s) =>
                                        s != null &&
                                        s.toString().isNotEmpty)
                                    .join(' • '),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      statusThai,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (area['size_hectares'] != null)
                    _buildInfoChip(
                        Icons.straighten,
                        '${area['size_hectares']} ไร่',
                        Colors.blue),
                  if (area['community_name'] != null) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                        Icons.groups, area['community_name'], Colors.orange),
                  ],
                ],
              ),
              if (speciesText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.eco,
                        size: 13, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        speciesText,
                        style: TextStyle(
                            fontSize: 12, color: Colors.green.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ดูรายละเอียด →',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAreaDetail(Map<String, dynamic> area) {
    final status = (area['conservation_status'] ?? '').toString().toLowerCase();
    final statusThai =
        _conservationStatusMap[status] ?? area['conservation_status'] ?? 'ไม่ระบุ';
    final statusColor = _getStatusColor(status);

    final species = area['mangrove_species'];
    String speciesText = '';
    if (species is List) {
      speciesText = (species as List).join(', ');
    } else if (species is String && species.isNotEmpty) {
      speciesText = species;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.forest,
                          color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            area['area_name'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              statusThai,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Google Maps button (when coordinates available)
                    if (area['latitude'] != null && area['longitude'] != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final lat = area['latitude'].toString();
                            final lon = area['longitude'].toString();
                            final name = Uri.encodeComponent(
                                area['area_name']?.toString() ?? '');
                            final uri = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lon&query_place_id=$name');
                            launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('เปิดใน Google Maps'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1976D2),
                            side: const BorderSide(
                                color: Color(0xFF1976D2), width: 1.5),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    _buildDetailSection('ที่ตั้ง', [
                      _detailRow('จังหวัด', area['province']),
                      _detailRow('สถานที่', area['location']),
                    ]),
                    if (area['size_hectares'] != null ||
                        area['established_year'] != null)
                      _buildDetailSection('ข้อมูลพื้นที่', [
                        if (area['size_hectares'] != null)
                          _detailRow('ขนาดพื้นที่',
                              '${area['size_hectares']} ไร่'),
                        if (area['established_year'] != null)
                          _detailRow(
                              'ปีที่จัดตั้ง', '${area['established_year']}'),
                        if (area['managing_organization'] != null)
                          _detailRow(
                              'หน่วยงาน', area['managing_organization']),
                      ]),
                    if (area['community_name'] != null)
                      _buildDetailSection('ชุมชนดูแล', [
                        _detailRow('ชื่อชุมชน', area['community_name']),
                        if (area['contact_person'] != null)
                          _detailRow(
                              'ผู้ติดต่อ', area['contact_person']),
                        if (area['phone_number'] != null)
                          _detailRow('โทรศัพท์', area['phone_number']),
                      ]),
                    if (speciesText.isNotEmpty ||
                        area['description'] != null)
                      _buildDetailSection('ข้อมูลนิเวศ', [
                        if (speciesText.isNotEmpty)
                          _detailRow('พันธุ์ไม้', speciesText),
                        if (area['description'] != null)
                          _detailRow('รายละเอียด', area['description']),
                      ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _detailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value.toString(),
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.teal.shade600;
      case 'good':
        return Colors.green.shade600;
      case 'moderate':
        return Colors.orange.shade600;
      case 'poor':
        return Colors.red.shade600;
      case 'protected':
        return Colors.blue.shade600;
      case 'monitored':
        return Colors.cyan.shade700;
      case 'threatened':
        return Colors.deepOrange.shade600;
      case 'restored':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // ─── TAB 2: แผนที่ (admin-style) ────────────────────────────────────────────

  Widget _buildMapTab() {
    // Apply conservation_status filter
    final filteredForMap = _selectedMapFilter == 'ทั้งหมด'
        ? _areas
        : _areas
            .where((a) => a['conservation_status'] == _selectedMapFilter)
            .toList();

    final areasWithLocation = filteredForMap
        .where((a) => a['latitude'] != null && a['longitude'] != null)
        .toList();

    double centerLat = 13.6904;
    double centerLon = 101.0779;
    double zoom = 9.0;

    if (areasWithLocation.isNotEmpty) {
      centerLat = areasWithLocation.fold(0.0, (sum, a) {
            final v = a['latitude'];
            return sum +
                (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
          }) /
          areasWithLocation.length;
      centerLon = areasWithLocation.fold(0.0, (sum, a) {
            final v = a['longitude'];
            return sum +
                (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
          }) /
          areasWithLocation.length;
      zoom = 10.0;
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'กรองตามสถานะ',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildMapFilterChips(),
            ],
          ),
        ),
        Expanded(
          child: Stack(
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.eastern_mangrove_app',
                  ),
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude),
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: const Icon(Icons.person_pin_circle,
                                color: Colors.white, size: 30),
                          ),
                        ),
                      ],
                    ),
                  if (areasWithLocation.isNotEmpty)
                    MarkerLayer(
                      markers: areasWithLocation.map((area) {
                        final lat = area['latitude'];
                        final lon = area['longitude'];
                        final latD = lat is num
                            ? lat.toDouble()
                            : double.tryParse(lat.toString()) ?? 0.0;
                        final lonD = lon is num
                            ? lon.toDouble()
                            : double.tryParse(lon.toString()) ?? 0.0;
                        return Marker(
                          point: LatLng(latD, lonD),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showAreaDetail(area),
                            child: Icon(
                              Icons.eco,
                              color: _getStatusColor(
                                  (area['conservation_status'] ?? '')
                                      .toString()
                                      .toLowerCase()),
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
              // Show overlay only when filter returns truly no areas
              if (filteredForMap.isEmpty)
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
                            Icon(Icons.map_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'ไม่พบพื้นที่ป่าชายเลน\nในหมวดหมู่นี้',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // When areas exist but none have coordinates
              if (filteredForMap.isNotEmpty && areasWithLocation.isEmpty)
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
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'ยังไม่มีพื้นที่ที่ระบุพิกัด\nข้อมูลพิกัดยังไม่ได้รับการบันทึก',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('ทั้งหมด'),
              selected: _selectedMapFilter == 'ทั้งหมด',
              onSelected: (_) =>
                  setState(() => _selectedMapFilter = 'ทั้งหมด'),
              backgroundColor: Colors.grey.shade200,
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: _selectedMapFilter == 'ทั้งหมด'
                    ? Colors.white
                    : Colors.black87,
                fontWeight: _selectedMapFilter == 'ทั้งหมด'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          ..._conservationStatusMap.entries.map((entry) {
            final isSelected = _selectedMapFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _selectedMapFilter = entry.key),
                backgroundColor: Colors.grey.shade200,
                selectedColor: const Color(0xFF2E7D32),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── TAB 3: สรุปการให้บริการ 12 เดือน ───────────────────────────────────────

  Widget _buildServiceSummaryTab() {
    int totalServices = 0;
    double totalVisitors = 0;
    double totalRevenue = 0;

    for (final row in _serviceSummary) {
      totalServices +=
          int.tryParse(row['service_count'].toString()) ?? 0;
      totalVisitors +=
          double.tryParse(row['total_visitors']?.toString() ?? '0') ?? 0;
      totalRevenue +=
          double.tryParse(row['total_revenue']?.toString() ?? '0') ?? 0;
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF2E7D32),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'สรุปการให้บริการ 12 เดือน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryStatItem(
                            '$totalServices',
                            'บริการทั้งหมด',
                            Icons.assignment),
                      ),
                      Expanded(
                        child: _buildSummaryStatItem(
                            _formatNumber(totalVisitors),
                            'ผู้รับประโยชน์',
                            Icons.people),
                      ),
                      Expanded(
                        child: _buildSummaryStatItem(
                            '฿${_formatNumber(totalRevenue)}',
                            'มูลค่ารวม',
                            Icons.attach_money),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month,
                          color: Colors.teal.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'รายละเอียดรายเดือน',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_serviceSummary.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(
                              'ยังไม่มีข้อมูลการให้บริการ',
                              style: TextStyle(
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text('เดือน',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00695C))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text('บริการ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('ผู้รับประโยชน์',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text('มูลค่า (บาท)',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._serviceSummary.map((row) => _buildMonthRow(row)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ข้อมูลสรุปการให้บริการระบบนิเวศป่าชายเลน รวบรวมจากชุมชนที่ได้รับการขึ้นทะเบียนทุกชุมชน ครอบคลุม 12 เดือนย้อนหลัง',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatItem(
      String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMonthRow(Map<String, dynamic> row) {
    final yearNum = int.tryParse(row['year']?.toString() ?? '0') ?? 0;
    final monthNum = int.tryParse(row['month']?.toString() ?? '0') ?? 0;
    final key = '$yearNum-$monthNum';
    final isExpanded = _expandedMonths.contains(key);
    final monthLabel = _getMonthThai(monthNum, yearNum);
    final services = row['service_count']?.toString() ?? '0';
    final visitors = _formatNumber(
        double.tryParse(row['total_visitors']?.toString() ?? '0') ?? 0);
    final revenue = _formatNumber(
        double.tryParse(row['total_revenue']?.toString() ?? '0') ?? 0);
    final isLatest = row == _serviceSummary.last;

    // Filter breakdown items for this month
    final breakdownItems = _serviceBreakdown
        .where((b) =>
            b['year']?.toString() == yearNum.toString() &&
            b['month']?.toString() == monthNum.toString())
        .toList();

    return Column(
      children: [
        GestureDetector(
          onTap: breakdownItems.isEmpty
              ? null
              : () => setState(() {
                    if (isExpanded) {
                      _expandedMonths.remove(key);
                    } else {
                      _expandedMonths.add(key);
                    }
                  }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isLatest ? Colors.teal.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isLatest
                  ? Border.all(color: Colors.teal.shade200, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      if (breakdownItems.isNotEmpty)
                        Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: Colors.teal.shade600,
                        ),
                      if (breakdownItems.isNotEmpty)
                        const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isLatest
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isLatest
                                ? Colors.teal.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    services,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    visitors,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    revenue,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && breakdownItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Column(
              children: breakdownItems
                  .map((item) => _buildBreakdownRow(item))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBreakdownRow(Map<String, dynamic> item) {
    final typeName =
        _translateServiceType(item['service_type']?.toString());
    final count = item['count']?.toString() ?? '0';
    final visitors = _formatNumber(
        double.tryParse(item['visitors']?.toString() ?? '0') ?? 0);
    final revenue = _formatNumber(
        double.tryParse(item['revenue']?.toString() ?? '0') ?? 0);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6, top: 1),
            decoration: BoxDecoration(
              color: Colors.teal.shade400,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              typeName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal.shade800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              count,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              visitors,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              revenue,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateServiceType(String? type) {
    switch (type?.toLowerCase()) {
      case 'tour_guide':
        return 'ไกด์นำเที่ยว';
      case 'seminar':
        return 'อบรมสัมมนา';
      case 'learning_camp':
        return 'ค่ายเรียนรู้';
      case 'firewood':
        return 'ฟืน/ไม้';
      case 'wood':
        return 'ไม้';
      case 'crab':
        return 'ปู';
      case 'shrimp':
        return 'กุ้ง';
      case 'fish':
        return 'ปลา';
      case 'shellfish':
        return 'หอย/สัตว์น้ำ';
      case 'medicinal_plants':
        return 'พืชสมุนไพร';
      case 'other_resource':
        return 'ทรัพยากรอื่นๆ';
      case 'ecotourism':
        return 'ท่องเที่ยวเชิงนิเวศ';
      case 'education':
        return 'สื่อการศึกษา';
      case 'recreation':
        return 'นันทนาการ';
      case 'homestay':
        return 'โฮมสเตย์';
      default:
        return type ?? 'อื่นๆ';
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} ล้าน';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} พัน';
    }
    return value.toStringAsFixed(0);
  }

  String _getMonthThai(int month, int year) {
    const months = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];
    if (month < 1 || month > 12) return '';
    return '${months[month]} ${year + 543}';
  }
}
