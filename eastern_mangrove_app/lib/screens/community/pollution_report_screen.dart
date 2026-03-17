import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// DraggableMarker Widget for editable markers
class DraggableMarker extends StatefulWidget {
  final PollutionReport report;
  final int index;
  final Function(int, LatLng) onDragEnd;
  final Widget child;

  const DraggableMarker({
    super.key,
    required this.report,
    required this.index,
    required this.onDragEnd,
    required this.child,
  });

  @override
  State<DraggableMarker> createState() => _DraggableMarkerState();
}

class _DraggableMarkerState extends State<DraggableMarker> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: widget.index,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      hapticFeedbackOnStart: true,
      onDragStarted: () {
        setState(() {
          _isDragging = true;
        });
      },
      onDragEnd: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade600, width: 2),
        ),
        child: Icon(
          Icons.open_with,
          color: Colors.grey.shade700,
          size: 20,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          // Handle tap for details if not dragging
          if (!_isDragging) {
            // Handle marker tap
          }
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.yellow.shade600, 
              width: 2
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class PollutionReportScreen extends StatefulWidget {
  const PollutionReportScreen({super.key});

  @override
  State<PollutionReportScreen> createState() => _PollutionReportScreenState();
}

class _PollutionReportScreenState extends State<PollutionReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _mapZoom = 1.5; // Map zoom level
  
  // Flutter Map Controllers
  final MapController _mapController = MapController();
  String _selectedPollutionFilter = 'ทั้งหมด';
  bool _isAddingMarker = false;
  bool _isEditingMarker = false;
  LatLng? _tempMarker;
  PollutionReport? _editingReport;
  int? _editingIndex;
  
  // Center point on Eastern Thailand mangrove areas
  final LatLng _mapCenter = const LatLng(12.5500, 101.6000);

  // Sample pollution data
  final List<PollutionReport> _pollutionReports = [
    PollutionReport(
      id: 'P001',
      title: 'น้ำเสียจากโรงงานแปรรูปอาหาร',
      pollutionType: 'มลพิษทางน้ำ',
      severityLevel: 'สูง',
      location: 'บ้านปากคลอง ตำบลเทพา',
      coordinates: '12.6789, 101.5432',
      description: 'พบน้ำเสียสีเข้มไฝล ออกจากโรงงานลงสู่คลองที่ไหลผ่านป่าชายเลน กลิ่นเหม็นรุนแรง',
      reportDate: DateTime(2024, 2, 28),
      status: 'รอการแก้ไข',
      reporterName: 'นายสมชาย ใจดี',
      contactNumber: '081-234-5678',
    ),
    PollutionReport(
      id: 'P002',
      title: 'ขยะพลาสติกริมหาด',
      pollutionType: 'ขยะชุมชน',
      severityLevel: 'กลาง',
      location: 'หาดปากน้ำ ตำบลวังก์แก้ว',
      coordinates: '12.6543, 101.5678', 
      description: 'พบขยะพลาสติก ขวดน้ำ ถุงพลาสติกจำนวนมากทับถมริมหาดใกล้ป่าชายเลน',
      reportDate: DateTime(2024, 2, 25),
      status: 'แก้ไขแล้ว',
      reporterName: 'นางสาวมาลี สวยงาม',
      contactNumber: '085-678-9012',
    ),
    PollutionReport(
      id: 'P003',
      title: 'ควันจากโรงงานอุตสาหกรรม',
      pollutionType: 'มลพิษทางอากาศ',
      severityLevel: 'กลาง',
      location: 'หมู่บ้านปลาป่น ตำบลคลองใหญ่',
      coordinates: '12.6234, 101.5891',
      description: 'พบควันสีเทาจากโรงงานอุตสาหกรรมปล่อยออกมาในปริมาณมาก ส่งกลิ่นไม่พึงประสงค์และอาจส่งผลต่อระบบนิเวศป่าชายเลน',
      reportDate: DateTime(2024, 2, 20),
      status: 'กำลังแก้ไข',
      reporterName: 'นายวิชัย อนุรักษ์',
      contactNumber: '089-345-6789',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('จัดการข้อมูลแหล่งมลพิษ'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF4CAF50),
          tabs: const [
            Tab(text: 'รายงานมลพิษ', icon: Icon(Icons.report_problem)),
            Tab(text: 'แผนที่มลพิษ', icon: Icon(Icons.map)),
            Tab(text: 'สถิติ', icon: Icon(Icons.analytics)),
          ],
        ),
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
    // Filter pollution reports based on selected filter
    final filteredReportsTab1 = _selectedPollutionFilter == 'ทั้งหมด'
        ? _pollutionReports
        : _pollutionReports.where((r) => r.pollutionType == _selectedPollutionFilter).toList();

    return Column(
      children: [
        // Summary Cards
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'รายงานทั้งหมด',
                  '${_pollutionReports.length} เรื่อง',
                  Icons.report,
                  Colors.red.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'ความรุนแรงสูง',
                  '${_pollutionReports.where((r) => r.severityLevel == 'สูง').length} เรื่อง',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'รอการแก้ไข',
                  '${_pollutionReports.where((r) => r.status == 'รอการแก้ไข').length} เรื่อง',
                  Icons.pending,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),

        // Filter dropdown
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'กรองตามประเภทมลพิษ',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _selectedPollutionFilter,
            items: [
              const DropdownMenuItem(value: 'ทั้งหมด', child: Text('ทั้งหมด')),
              ...['มลพิษทางน้ำ', 'มลพิษทางอากาศ', 'ขยะชุมชน', 'ขยะอุตสาหกรรม'].map(
                (type) => DropdownMenuItem(value: type, child: Text(type)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPollutionFilter = value!;
              });
            },
          ),
        ),

        // Add Report Button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddReportDialog(),
              icon: const Icon(Icons.add),
              label: const Text('รายงานมลพิษใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        // Reports List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredReportsTab1.length,
            itemBuilder: (context, index) {
              final report = filteredReportsTab1[index];
              return _buildReportCard(report, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    // Filter pollution reports based on selected filter
    final filteredReports = _selectedPollutionFilter == 'ทั้งหมด'
        ? _pollutionReports
        : _pollutionReports.where((r) => r.pollutionType == _selectedPollutionFilter).toList();

    return Column(
      children: [
        // Map Controls
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // First Row - Filter
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'กรองตามประเภทมลพิษ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _selectedPollutionFilter,
                      items: [
                        const DropdownMenuItem(value: 'ทั้งหมด', child: Text('ทั้งหมด')),
                        ...['มลพิษทางน้ำ', 'มลพิษทางอากาศ', 'ขยะชุมชน', 'ขยะอุตสาหกรรม'].map(
                          (type) => DropdownMenuItem(value: type, child: Text(type)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPollutionFilter = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second Row - Action Buttons
              Row(
                children: [
                  // Add Marker Toggle
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isAddingMarker = !_isAddingMarker;
                          _isEditingMarker = false;
                          _tempMarker = null;
                          _editingReport = null;
                          _editingIndex = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isAddingMarker 
                              ? 'คลิกที่แผนที่เพื่อเพิ่มจุดมลพิษใหม่' 
                              : 'ปิดโหมดเพิ่มจุดมลพิษ'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(_isAddingMarker ? Icons.close : Icons.add_location),
                      label: Text(_isAddingMarker ? 'ยกเลิก' : 'เพิ่มจุด'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAddingMarker ? Colors.red.shade400 : Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit Mode Toggle
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditingMarker = !_isEditingMarker;
                          _isAddingMarker = false;
                          _tempMarker = null;
                          _editingReport = null;
                          _editingIndex = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isEditingMarker 
                              ? 'ลากจุดมลพิษเพื่อย้ายตำแหน่ง'
                              : 'ปิดโหมดแก้ไขตำแหน่ง'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(_isEditingMarker ? Icons.check : Icons.edit_location),
                      label: Text(_isEditingMarker ? 'เสร็จ' : 'แก้ไข'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditingMarker ? Colors.orange.shade600 : Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Map Legend
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Text(
                      'คำอธิบาย: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildLegendItem('สูง', Colors.red.shade700),
                    const SizedBox(width: 16),
                    _buildLegendItem('กลาง', Colors.orange),
                    const SizedBox(width: 16),
                    _buildLegendItem('ต่ำ', Colors.yellow.shade700),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Flutter Map
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  DragTarget<int>(
                    onWillAcceptWithDetails: (details) => _isEditingMarker,
                    onAcceptWithDetails: (details) {
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(details.offset);
                      
                      // Get map camera
                      final camera = _mapController.camera;
                      final bounds = camera.visibleBounds;
                      final mapSize = renderBox.size;
                      
                      // Calculate lat/lng from pixel position with proper bounds
                      final lat = bounds.north - 
                          (localPosition.dy / mapSize.height) * (bounds.north - bounds.south);
                      final lng = bounds.west + 
                          (localPosition.dx / mapSize.width) * (bounds.east - bounds.west);
                      
                      // Update marker position
                      _onMarkerDragEnd(details.data, LatLng(lat, lng));
                    },
                    builder: (context, candidateData, rejectedData) {
                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter,
                          initialZoom: 10.0,
                          minZoom: 8.0,
                          maxZoom: 18.0,
                          onTap: _isAddingMarker ? _onMapTapped : null,
                          interactionOptions: InteractionOptions(
                            enableMultiFingerGestureRace: true,
                            flags: _isEditingMarker 
                                ? InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom
                                : InteractiveFlag.all,
                          ),
                        ),
                children: [
                  // OpenStreetMap Tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.eastern_mangrove_app',
                  ),
                  
                  // Pollution Markers
                  MarkerLayer(
                    markers: [
                      // Existing pollution markers
                      ...filteredReports.asMap().entries.map((entry) {
                        final index = entry.key;
                        final report = entry.value;
                        final coords = report.coordinates.split(', ');
                        final lat = double.parse(coords[0]);
                        final lng = double.parse(coords[1]);
                        final actualIndex = _pollutionReports.indexOf(report);
                        
                        return Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: _isEditingMarker 
                              ? DraggableMarker(
                                  report: report,
                                  index: actualIndex,
                                  onDragEnd: _onMarkerDragEnd,
                                  child: _buildMarkerIcon(report),
                                )
                              : GestureDetector(
                                  onTap: () => _showMapMarkerDialog(report),
                                  onLongPress: () => _showEditMarkerOptions(report),
                                  child: _buildMarkerIcon(report),
                                ),
                        );
                      }),
                      
                      // Temporary marker when adding
                      if (_tempMarker != null)
                        Marker(
                          point: _tempMarker!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ), 
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // Rich Attributions
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Map Controls & Location List
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Zoom Controls
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        },
                        icon: const Icon(Icons.zoom_in),
                        iconSize: 20,
                      ),
                      Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      IconButton(
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        },
                        icon: const Icon(Icons.zoom_out),
                        iconSize: 20,
                      ),
                      Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      IconButton(
                        onPressed: () {
                          _mapController.move(_mapCenter, 10.0);
                        },
                        icon: const Icon(Icons.home),
                        iconSize: 20,
                        tooltip: 'กลับสู่ตำแหน่งเริ่มต้น',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Location Details List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                            Text(
                              'รายการพิกัดมลพิษ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${filteredReports.length} จุด',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredReports.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              final distance = _calculateDistance(report.coordinates);
                              
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getSeverityColor(report.severityLevel),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getPollutionIcon(report.pollutionType),
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  report.location,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${report.pollutionType} • ${report.severityLevel}',
                                      style: TextStyle(
                                        color: _getSeverityColor(report.severityLevel),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'ระยะห่าง: ${distance.toStringAsFixed(1)} กม.',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF757575),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _focusOnMarker(report),
                                      icon: const Icon(Icons.center_focus_strong),
                                      iconSize: 16,
                                      tooltip: 'โฟกัสที่ตำแหน่ง',
                                    ),
                                    IconButton(
                                      onPressed: () => _showMapMarkerDialog(report),
                                      icon: const Icon(Icons.info_outline),
                                      iconSize: 16,
                                      tooltip: 'ดูรายละเอียด',
                                    ),
                                  ],
                                ),
                                onTap: () => _focusOnMarker(report),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    final typeStats = <String, int>{};
    final severityStats = <String, int>{};
    final statusStats = <String, int>{};

    for (final report in _pollutionReports) {
      typeStats[report.pollutionType] = (typeStats[report.pollutionType] ?? 0) + 1;
      severityStats[report.severityLevel] = (severityStats[report.severityLevel] ?? 0) + 1;
      statusStats[report.status] = (statusStats[report.status] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total Reports Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'รายงานมลพิษทั้งหมด',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_pollutionReports.length} เรื่อง',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เดือน ${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Statistics Cards
          _buildStatSection('ประเภทมลพิษ', typeStats, [
            Colors.red, Colors.orange, Colors.brown, Colors.purple
          ]),

          const SizedBox(height: 20),

          _buildStatSection('ระดับความรุนแรง', severityStats, [
            Colors.red.shade700, Colors.orange, Colors.yellow.shade700
          ]),

          const SizedBox(height: 20),

          _buildStatSection('สถานะการแก้ไข', statusStats, [
            Colors.green, Colors.blue, Colors.grey
          ]),

          const SizedBox(height: 20),

          // Recent Activity
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.history, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'กิจกรรมล่าสุด',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...(_pollutionReports.take(3).map((report) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getSeverityColor(report.severityLevel),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'รายงาน ${report.pollutionType} ที่ ${report.location}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${report.reportDate.day}/${report.reportDate.month}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(PollutionReport report, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(report.severityLevel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPollutionIcon(report.pollutionType),
                    color: _getSeverityColor(report.severityLevel),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${report.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('ดูรายละเอียด'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('แก้ไข'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('ลบ'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'view') {
                      _showReportDetails(report);
                    } else if (value == 'edit') {
                      _showEditReportDialog(report, index);
                    } else if (value == 'delete') {
                      _deleteReport(index);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'ประเภท:',
                    report.pollutionType,
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'ความรุนแรง:',
                    report.severityLevel,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildInfoRow(
              'สถานที่:',
              report.location,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'ผู้รายงาน:',
                    report.reporterName,
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'วันที่:',
                    '${report.reportDate.day}/${report.reportDate.month}/${report.reportDate.year}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424242),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, Map<String, int> stats, List<Color> colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: stats.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final stat = entry.value;
              final color = colors[index % colors.length];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                    Expanded(child: Text(stat.key)),
                    Text(
                      '${stat.value} เรื่อง',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'สูง': return Colors.red.shade700;
      case 'กลาง': return Colors.orange;
      case 'ต่ำ': return Colors.yellow.shade700;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'แก้ไขแล้ว': return Colors.green;
      case 'กำลังแก้ไข': return Colors.blue;
      case 'รอการแก้ไข': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _getPollutionIcon(String type) {
    switch (type) {
      case 'มลพิษทางน้ำ': return Icons.water_drop;
      case 'มลพิษทางอากาศ': return Icons.air;
      case 'ขยะชุมชน': return Icons.delete;
      case 'ขยะอุตสาหกรรม': return Icons.factory;
      default: return Icons.warning;
    }
  }

  void _showAddReportDialog() {
    _showReportDialog();
  }

  void _showEditReportDialog(PollutionReport report, int index) {
    _showReportDialog(report: report, index: index);
  }

  void _showReportDialog({PollutionReport? report, int? index}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: report?.title ?? '');
    final locationController = TextEditingController(text: report?.location ?? '');
    final coordinatesController = TextEditingController(text: report?.coordinates ?? '');
    final descriptionController = TextEditingController(text: report?.description ?? '');
    final reporterNameController = TextEditingController(text: report?.reporterName ?? '');
    final contactController = TextEditingController(text: report?.contactNumber ?? '');
    
    String selectedPollutionType = report?.pollutionType ?? 'มลพิษทางน้ำ';
    String selectedSeverity = report?.severityLevel ?? 'กลาง';
    String selectedStatus = report?.status ?? 'รอการแก้ไข';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report == null ? 'รายงานมลพิษใหม่' : 'แก้ไขข้อมูลมลพิษ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Title
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'หัวข้อรายงาน *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty 
                            ? 'กรุณาป้อนหัวข้อรายงาน' : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Pollution Type
                        StatefulBuilder(
                          builder: (context, setDialogState) => DropdownButtonFormField<String>(
                            value: selectedPollutionType,
                            decoration: const InputDecoration(
                              labelText: 'ประเภทมลพิษ *',
                              border: OutlineInputBorder(),
                            ),
                            items: ['มลพิษทางน้ำ', 'มลพิษทางอากาศ', 'ขยะชุมชน', 'ขยะอุตสาหกรรม']
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (value) => setDialogState(() {
                              selectedPollutionType = value!;
                            }),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            // Severity
                            Expanded(
                              child: StatefulBuilder(
                                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                                  value: selectedSeverity,
                                  decoration: const InputDecoration(
                                    labelText: 'ระดับความรุนแรง *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['สูง', 'กลาง', 'ต่ำ']
                                      .map((severity) => DropdownMenuItem(value: severity, child: Text(severity)))
                                      .toList(),
                                  onChanged: (value) => setDialogState(() {
                                    selectedSeverity = value!;
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Status
                            Expanded(
                              child: StatefulBuilder(
                                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  decoration: const InputDecoration(
                                    labelText: 'สถานะ *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['รอการแก้ไข', 'กำลังแก้ไข', 'แก้ไขแล้ว']
                                      .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                                      .toList(),
                                  onChanged: (value) => setDialogState(() {
                                    selectedStatus = value!;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Location
                        TextFormField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'สถานที่ *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty 
                            ? 'กรุณาป้อนสถานที่' : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Coordinates
                        TextFormField(
                          controller: coordinatesController,
                          decoration: const InputDecoration(
                            labelText: 'พิกัด (ละติจูด, ลองจิจูด)',
                            border: OutlineInputBorder(),
                            hintText: 'เช่น 12.6789, 101.5432',
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'รายละเอียด *',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => value == null || value.isEmpty 
                            ? 'กรุณาป้อนรายละเอียด' : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            // Reporter Name
                            Expanded(
                              child: TextFormField(
                                controller: reporterNameController,
                                decoration: const InputDecoration(
                                  labelText: 'ชื่อผู้รายงาน *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value == null || value.isEmpty 
                                  ? 'กรุณาป้อนชื่อผู้รายงาน' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Contact
                            Expanded(
                              child: TextFormField(
                                controller: contactController,
                                decoration: const InputDecoration(
                                  labelText: 'เบอร์ติดต่อ',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newReport = PollutionReport(
                            id: report?.id ?? 'P${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text,
                            pollutionType: selectedPollutionType,
                            severityLevel: selectedSeverity,
                            location: locationController.text,
                            coordinates: coordinatesController.text,
                            description: descriptionController.text,
                            reportDate: DateTime.now(),
                            status: selectedStatus,
                            reporterName: reporterNameController.text,
                            contactNumber: contactController.text,
                          );

                          setState(() {
                            if (index != null) {
                              _pollutionReports[index] = newReport;
                            } else {
                              _pollutionReports.add(newReport);
                            }
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(report == null 
                                ? 'บันทึกข้อมูลมลพิษสำเร็จ' 
                                : 'แก้ไขข้อมูลมลพิษสำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(report == null ? 'บันทึก' : 'แก้ไข'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDetails(PollutionReport report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(report.severityLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPollutionIcon(report.pollutionType),
                      color: _getSeverityColor(report.severityLevel),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildDetailRow('ประเภทมลพิษ:', report.pollutionType),
              _buildDetailRow('ระดับความรุนแรง:', report.severityLevel),
              _buildDetailRow('สถานที่:', report.location),
              if (report.coordinates.isNotEmpty)
                _buildDetailRow('พิกัด:', report.coordinates),
              _buildDetailRow('ผู้รายงาน:', report.reporterName),
              if (report.contactNumber.isNotEmpty)
                _buildDetailRow('เบอร์ติดต่อ:', report.contactNumber),
              _buildDetailRow('วันที่รายงาน:', 
                '${report.reportDate.day}/${report.reportDate.month}/${report.reportDate.year}'),

              const SizedBox(height: 16),

              const Text(
                'รายละเอียด:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.description,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ปิด'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteReport(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบรายงานมลพิษนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pollutionReports.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ลบรายงานมลพิษแล้ว'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerIcon(PollutionReport report) {
    return Container(
      decoration: BoxDecoration(
        color: _getSeverityColor(report.severityLevel),
        shape: BoxShape.circle,
        border: Border.all(
          color: _isEditingMarker ? Colors.yellow : Colors.white, 
          width: _isEditingMarker ? 3 : 2
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getPollutionIcon(report.pollutionType),
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  void _onMarkerDragEnd(int index, LatLng newPosition) {
    if (index >= 0 && index < _pollutionReports.length) {
      final report = _pollutionReports[index];
      final updatedReport = PollutionReport(
        id: report.id,
        title: report.title,
        pollutionType: report.pollutionType,
        severityLevel: report.severityLevel,
        location: report.location + ' (ย้ายตำแหน่ง)', // เพิ่มหมายเหตุว่าย้ายแล้ว
        coordinates: '${newPosition.latitude.toStringAsFixed(5)}, ${newPosition.longitude.toStringAsFixed(5)}',
        description: report.description,
        reportDate: report.reportDate,
        status: report.status,
        reporterName: report.reporterName,
        contactNumber: report.contactNumber,
      );

      setState(() {
        _pollutionReports[index] = updatedReport;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ย้ายจุดมลพิษ "${report.title}" สำเร็จ'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'เปลี่ยนข้อมูล',
            onPressed: () => _showEditReportDialog(updatedReport, index),
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  void _updateReportInAllTabs(int index, PollutionReport updatedReport) {
    setState(() {
      if (index >= 0 && index < _pollutionReports.length) {
        _pollutionReports[index] = updatedReport;
      }
    });
  }

  void _deleteReportFromAllTabs(int index) {
    setState(() {
      if (index >= 0 && index < _pollutionReports.length) {
        _pollutionReports.removeAt(index);
      }
    });
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(String coordinates) {
    // Mock distance calculation from center point (12.65, 101.55)
    final coords = coordinates.split(', ');
    final lat = double.parse(coords[0]);
    final lng = double.parse(coords[1]);
    
    // Simple distance formula (mock)
    final centerLat = 12.65;
    final centerLng = 101.55;
    
    final distance = ((lat - centerLat) * (lat - centerLat) + 
                     (lng - centerLng) * (lng - centerLng)) * 111; // Convert to km
    
    return distance.abs();
  }

  void _showMapMarkerDialog(PollutionReport report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(report.severityLevel),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPollutionIcon(report.pollutionType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          report.pollutionType + ' • ' + report.severityLevel,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getSeverityColor(report.severityLevel),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Location Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report.location,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'พิกัด: ${report.coordinates}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.straighten, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'ระยะทาง: ${_calculateDistance(report.coordinates).toStringAsFixed(1)} กม.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'รายละเอียด:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.description,
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ปิด'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showReportDetails(report);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ดูเพิ่มเติม'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    if (_isAddingMarker) {
      setState(() {
        _tempMarker = point;
      });
      
      // Show confirmation dialog for new pollution point
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('เพิ่มจุดมลพิษใหม่'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('พิกัด: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'),
              const SizedBox(height: 12),
              const Text('คุณต้องการเพิ่มจุดมลพิษใหม่ที่ตำแหน่งนี้หรือไม่?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _tempMarker = null;
                });
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddPollutionDialog(point);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      );
    }
  }

  void _focusOnMarker(PollutionReport report) {
    final coords = report.coordinates.split(', ');
    final lat = double.parse(coords[0]);
    final lng = double.parse(coords[1]);
    
    _mapController.move(LatLng(lat, lng), 15.0);
  }

  void _showEditMarkerOptions(PollutionReport report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'จัดการจุดมลพิษ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('ดูรายละเอียด'),
              onTap: () {
                Navigator.pop(context);
                _showReportDetails(report);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('แก้ไขข้อมูল'),
              onTap: () {
                Navigator.pop(context);
                final index = _pollutionReports.indexOf(report);
                _showEditReportDialog(report, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('ลบจุดมลพิษ'),
              onTap: () {
                Navigator.pop(context);
                final index = _pollutionReports.indexOf(report);
                _deleteReport(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPollutionDialog(LatLng point) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    final reporterNameController = TextEditingController();
    final contactController = TextEditingController();
    
    String selectedPollutionType = 'มลพิษทางน้ำ';
    String selectedSeverity = 'กลาง';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เพิ่มรายงานมลพิษใหม่',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'พิกัด: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'หัวข้อรายงาน *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty 
                            ? 'กรุณาป้อนหัวข้อรายงาน' : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: StatefulBuilder(
                                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                                  value: selectedPollutionType,
                                  decoration: const InputDecoration(
                                    labelText: 'ประเภทมลพิษ *',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: ['มลพิษทางน้ำ', 'มลพิษทางอากาศ', 'ขยะชุมชน', 'ขยะอุตสาหกรรม']
                                      .map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 12))))
                                      .toList(),
                                  onChanged: (value) => setDialogState(() {
                                    selectedPollutionType = value!;
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatefulBuilder(
                                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                                  value: selectedSeverity,
                                  decoration: const InputDecoration(
                                    labelText: 'ความรุนแรง *',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: ['สูง', 'กลาง', 'ต่ำ']
                                      .map((severity) => DropdownMenuItem(value: severity, child: Text(severity, style: const TextStyle(fontSize: 12))))
                                      .toList(),
                                  onChanged: (value) => setDialogState(() {
                                    selectedSeverity = value!;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อสถานที่ *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty 
                            ? 'กรุณาป้อนชื่อสถานที่' : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'รายละเอียด *',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => value == null || value.isEmpty 
                            ? 'กรุณาป้อนรายละเอียด' : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: reporterNameController,
                                decoration: const InputDecoration(
                                  labelText: 'ชื่อผู้รายงาน *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value == null || value.isEmpty 
                                  ? 'กรุณาป้อนชื่อผู้รายงาน' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: contactController,
                                decoration: const InputDecoration(
                                  labelText: 'เบอร์ติดต่อ',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempMarker = null;
                          _isAddingMarker = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newReport = PollutionReport(
                            id: 'P${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text,
                            pollutionType: selectedPollutionType,
                            severityLevel: selectedSeverity,
                            location: locationController.text,
                            coordinates: '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                            description: descriptionController.text,
                            reportDate: DateTime.now(),
                            status: 'รอการแก้ไข',
                            reporterName: reporterNameController.text,
                            contactNumber: contactController.text,
                          );

                          setState(() {
                            _pollutionReports.add(newReport);
                            _tempMarker = null;
                            _isAddingMarker = false;
                            _isEditingMarker = false;
                            _editingReport = null;
                            _editingIndex = null;
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('เพิ่มจุดมลพิษใหม่สำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('บันทึก'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

// Data Model
class PollutionReport {
  final String id;
  final String title;
  final String pollutionType;
  final String severityLevel;
  final String location;
  final String coordinates;
  final String description;
  final DateTime reportDate;
  final String status;
  final String reporterName;
  final String contactNumber;

  PollutionReport({
    required this.id,
    required this.title,
    required this.pollutionType,
    required this.severityLevel,
    required this.location,
    required this.coordinates,
    required this.description,
    required this.reportDate,
    required this.status,
    required this.reporterName,
    required this.contactNumber,
  });
}