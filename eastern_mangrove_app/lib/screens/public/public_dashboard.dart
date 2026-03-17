import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PublicDashboard extends StatefulWidget {
  const PublicDashboard({super.key});

  @override
  State<PublicDashboard> createState() => _PublicDashboardState();
}

class _PublicDashboardState extends State<PublicDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  
  // Center point on Eastern Thailand mangrove areas
  final LatLng _mapCenter = const LatLng(12.5500, 101.6000);

  // Sample data for mangrove locations
  final List<MangroveLocation> _mangroveLocations = [
    MangroveLocation(
      name: 'ป่าชายเลนวังก์แก้ว',
      coordinates: const LatLng(12.6789, 101.5432),
      area: '250 ไร่',
      status: 'ดี',
      description: 'ป่าชายเลนที่มีความหลากหลายทางชีวภาพสูง',
    ),
    MangroveLocation(
      name: 'ป่าชายเลนปากคลองใหญ่', 
      coordinates: const LatLng(12.6543, 101.5678),
      area: '180 ไร่',
      status: 'ปานกลาง',
      description: 'ป่าชายเลนที่กำลังฟื้นฟูระบบนิเวศ',
    ),
    MangroveLocation(
      name: 'ป่าชายเลนเทพา',
      coordinates: const LatLng(12.6234, 101.5891),
      area: '320 ไร่', 
      status: 'ดี',
      description: 'ป่าชายเลนที่อุดมสมบูรณ์ เหมาะกับการศึกษาธรรมชาติ',
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
            Tab(icon: Icon(Icons.eco), text: 'ข้อมูลป่าชายเลน'),
            Tab(icon: Icon(Icons.map), text: 'แผนที่'),
            Tab(icon: Icon(Icons.analytics), text: 'สรุปการให้บริการ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMapTab(),
          _buildServiceSummaryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.eco,
                  size: 50,
                  color: Colors.white,
                ),
                SizedBox(height: 15),
                Text(
                  'ยินดีต้อนรับสู่ระบบข้อมูลป่าชายเลน',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ศูนย์รวมข้อมูลและการอนุรักษ์ป่าชายเลนภาคตะวันออก',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'พื้นที่ป่าชายเลน',
                  '750 ไร่',
                  Icons.forest,
                  Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'ชุมชนที่เข้าร่วม',
                  '15 ชุมชน',
                  Icons.groups,
                  Colors.blue.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'สิ่งมีชีวิตพบ',
                  '85 ชนิด',
                  Icons.pets,
                  Colors.orange.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'โครงการอนุรักษ์',
                  '23 โครงการ',
                  Icons.campaign,
                  Colors.purple.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Recent News Section
          Container(
            padding: const EdgeInsets.all(20),
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
                    Icon(Icons.newspaper, color: Colors.green.shade600),
                    const SizedBox(width: 10),
                    const Text(
                      'ข่าวสารล่าสุด',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildNewsItem(
                  'โครงการปลูกป่าชายเลนเทพา เสร็จสิ้นแล้ว 80%',
                  '2 วันที่แล้ว',
                  Icons.eco,
                ),
                _buildNewsItem(
                  'การอบรมการใช้ประโยชน์จากป่าชายเลนอย่างยั่งยืน',
                  '5 วันที่แล้ว',
                  Icons.school,
                ),
                _buildNewsItem(
                  'พบสัตว์ป่าใหม่ในพื้นที่ป่าชายเลนวังก์แก้ว',
                  '1 สัปดาห์ที่แล้ว',
                  Icons.pets,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 30,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(String title, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return Column(
      children: [
        // Map Info Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'แผนที่แสดงตำแหน่งป่าชายเลนในภาคตะวันออก',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Map
        Expanded(
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
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 10.0,
                  minZoom: 8.0,
                  maxZoom: 16.0,
                ),
                children: [
                  // OpenStreetMap Tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.eastern_mangrove_app',
                  ),
                  
                  // Mangrove Location Markers
                  MarkerLayer(
                    markers: _mangroveLocations.map((location) {
                      return Marker(
                        point: location.coordinates,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showLocationDetails(location),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getStatusColor(location.status),
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
                                Icons.forest,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  // Attribution
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Legend
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สถานะป่าชายเลน:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('ดี', Colors.green.shade600),
                  _buildLegendItem('ปานกลาง', Colors.orange.shade600),
                  _buildLegendItem('ต้องปรับปรุง', Colors.red.shade600),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ดี':
        return Colors.green.shade600;
      case 'ปานกลาง':
        return Colors.orange.shade600;
      case 'ต้องปรับปรุง':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showLocationDetails(MangroveLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.forest, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(location.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('พื้นที่:', location.area),
            _buildDetailRow('สถานะ:', location.status),
            const SizedBox(height: 10),
            Text(
              location.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildServiceSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.analytics,
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'สรุปการให้บริการ 12 เดือน',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ข้อมูลการให้บริการพื้นที่ป่าชายเลนรอบปี 2025-2026',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Annual Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'จำนวนผู้มาเยือน',
                  '24,580 คน',
                  '+18%',
                  Icons.people,
                  Colors.blue.shade600,
                  Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'รายได้การท่องเที่ยว',
                  '1.2M บาท',
                  '+25%',
                  Icons.attach_money,
                  Colors.green.shade600,
                  Colors.green.shade50,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'กิจกรรมที่จัด',
                  '48 กิจกรรม',
                  '+12%',
                  Icons.event,
                  Colors.purple.shade600,
                  Colors.purple.shade50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'โครงการอนุรักษ์',
                  '15 โครงการ',
                  '+7%',
                  Icons.eco,
                  Colors.orange.shade600,
                  Colors.orange.shade50,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Monthly Breakdown
          Container(
            padding: const EdgeInsets.all(20),
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
                    Icon(Icons.calendar_month, color: Colors.teal.shade600),
                    const SizedBox(width: 10),
                    const Text(
                      'สถิติ 6 เดือนล่าสุด',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Monthly Data List
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final months = [
                        'ก.ย. 2025', 'ต.ค.', 'พ.ย.', 'ธ.ค.', 'ม.ค. 2026', 'ก.พ.'
                      ];
                      final visitors = [2340, 2150, 1890, 2070, 2580, 2420];
                      final revenues = [180, 165, 145, 160, 195, 185];
                      
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: index == 5 ? const Color(0xFF4CAF50) : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: index == 5 ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                            width: index == 5 ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              months[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: index == 5 ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Visitors
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.people, size: 12, color: Colors.white),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${visitors[index]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 6),
                            
                            // Revenue
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.attach_money, size: 12, color: Colors.white),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${revenues[index]}K',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Service Highlights
          Container(
            padding: const EdgeInsets.all(20),
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
                    Icon(Icons.star, color: Colors.yellow.shade700),
                    const SizedBox(width: 10),
                    const Text(
                      'ไฮไลท์การให้บริการ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                _buildHighlightItem(
                  'โครงการศึกษาธรรมชาติป่าชายเลนสำหรับนักเรียน',
                  '2,450 คน เข้าร่วม',
                  Icons.school,
                  Colors.blue.shade600,
                ),
                _buildHighlightItem(
                  'กิจกรรมปลูกป่าชายเลนร่วมกับชุมชน',
                  '850 ต้น ปลูกสำเร็จ',
                  Icons.nature,
                  Colors.green.shade600,
                ),
                _buildHighlightItem(
                  'ฝึกอบรมไกด์ท้องถิ่นและการท่องเที่ยวชุมชน',
                  '120 คน ผ่านการอบรม',
                  Icons.groups,
                  Colors.orange.shade600,
                ),
                _buildHighlightItem(
                  'โครงการวิจัยและติดตามระบบนิเวศ',
                  '15 งานวิจัย เสร็จสิ้น',
                  Icons.science,
                  Colors.purple.shade600,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Satisfaction Rating
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sentiment_very_satisfied, color: Colors.green.shade600),
                    const SizedBox(width: 10),
                    Text(
                      'ความพึงพอใจผู้มาเยือน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '4.7/5.0',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const Text(
                            'คะแนนเฉลี่ย',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '92%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const Text(
                            'แนะนำผู้อื่น',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
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
  }

  Widget _buildSummaryCard(String title, String value, String change, 
      IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
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
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

class MangroveLocation {
  final String name;
  final LatLng coordinates;
  final String area;
  final String status;
  final String description;

  MangroveLocation({
    required this.name,
    required this.coordinates,
    required this.area,
    required this.status,
    required this.description,
  });
}