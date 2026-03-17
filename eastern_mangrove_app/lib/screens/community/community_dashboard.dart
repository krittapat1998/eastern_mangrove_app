import 'package:flutter/material.dart';
import 'economic_data_screen_new.dart';
import 'ecosystem_service_screen.dart';
import 'pollution_report_screen.dart';
import 'quarterly_report_screen.dart';
import 'ecosystem_services_new_screen.dart';
import 'ecosystem_services_improved_screen.dart';
import 'pollution_reports_new_screen.dart';
import 'community_profile_screen.dart';
import '../../services/api_client.dart';

class CommunityDashboard extends StatefulWidget {
  const CommunityDashboard({super.key});

  @override
  State<CommunityDashboard> createState() => _CommunityDashboardState();
}

class _CommunityDashboardState extends State<CommunityDashboard> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  
  // Data from API
  String _communityName = 'ชุมชน';
  String _locationInfo = 'กำลังโหลด...';
  String _villageName = '';
  String _subDistrict = '';
  String _areaSize = '';
  String _registrationStatus = '';
  String? _rejectionReason;
  int _pollutionReportsCount = 0;
  int _ecosystemServicesCount = 0;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    print('🏠 Dashboard: Starting to load data...');
    try {
      // Fetch community profile (using ProfileData for raw Map)
      print('📞 Dashboard: Calling getCommunityProfileData...');
      final profileResponse = await _apiClient.getCommunityProfileData();
      print('✅ Dashboard: Profile response: success=${profileResponse.success}, data=${profileResponse.data}');
      
      // Fetch pollution reports
      print('📞 Dashboard: Calling getPollutionReportsNew...');
      final pollutionResponse = await _apiClient.getPollutionReportsNew();
      print('✅ Dashboard: Pollution response: success=${pollutionResponse.success}, count=${pollutionResponse.data?.length ?? 0}');
      
      // Fetch ecosystem services
      print('📞 Dashboard: Calling getEcosystemServices...');
      final ecosystemResponse = await _apiClient.getEcosystemServices();
      print('✅ Dashboard: Ecosystem response: success=${ecosystemResponse.success}, count=${ecosystemResponse.data?.length ?? 0}');

      if (mounted) {
        setState(() {
          // Parse community profile
          if (profileResponse.success && profileResponse.data != null) {
            final profile = profileResponse.data!;
            // Check if data is nested under 'community' key
            final communityData = profile['community'] ?? profile;
            _communityName = communityData['name'] ?? communityData['community_name'] ?? 'ชุมชน';
            
            // Extract registration status and rejection reason
            _registrationStatus = communityData['registrationStatus'] ?? '';
            _rejectionReason = communityData['rejectionReason'];
            
            // Extract detailed location fields
            _villageName = communityData['villageName'] ?? '';
            _subDistrict = communityData['subDistrict'] ?? '';
            final district = communityData['district'] ?? '';
            final province = communityData['province'] ?? '';
            _areaSize = communityData['areaSize']?.toString() ?? '';
            
            // Build location info for display
            List<String> locationParts = [];
            if (province.isNotEmpty) locationParts.add(province);
            if (district.isNotEmpty) locationParts.add(district);
            
            if (locationParts.isNotEmpty) {
              _locationInfo = locationParts.join(' • ');
            } else {
              final location = communityData['location'] ?? '';
              _locationInfo = location.isNotEmpty ? location : 'ไม่มีข้อมูลที่อยู่';
            }
            
            print('🏘️ Dashboard: Community name: $_communityName');
            print('📍 Dashboard: Village: $_villageName, Sub-district: $_subDistrict');
            print('🗺️ Dashboard: Location: $_locationInfo, Area: $_areaSize');
            print('📋 Dashboard: Status: $_registrationStatus, Rejection: $_rejectionReason');
          } else {
            print('⚠️ Dashboard: Profile data not available');
            _communityName = 'ชุมชน';
            _locationInfo = 'ไม่มีข้อมูล';
            _villageName = '';
            _subDistrict = '';
            _areaSize = '';
            _registrationStatus = '';
            _rejectionReason = null;
          }

          // Count pollution reports
          if (pollutionResponse.success && pollutionResponse.data != null) {
            final reports = pollutionResponse.data!;
            _pollutionReportsCount = reports.length;
            print('📊 Dashboard: Pollution reports count: $_pollutionReportsCount');
            
            // Build recent activities from pollution reports
            for (var report in reports) {
              final createdAt = report['created_at'];
              DateTime? timestamp;
              try {
                timestamp = createdAt is String ? DateTime.parse(createdAt) : null;
              } catch (e) {
                print('⚠️ Failed to parse timestamp: $createdAt');
              }
              
              if (timestamp != null) {
                _recentActivities.add({
                  'icon': Icons.report_problem,
                  'color': Colors.red,
                  'title': 'รายงานมลพิษใหม่',
                  'description': 'มีรายงานมลพิษ ${report['report_type'] ?? 'ทั่วไป'}',
                  'time': _formatTimestamp(createdAt),
                  'timestamp': timestamp,
                });
              }
            }
            print('🔴 Dashboard: Added ${reports.length} pollution activities');
          } else {
            print('⚠️ Dashboard: Pollution reports not available');
          }

          // Count ecosystem services
          if (ecosystemResponse.success && ecosystemResponse.data != null) {
            final services = ecosystemResponse.data!;
            _ecosystemServicesCount = services.length;
            print('📊 Dashboard: Ecosystem services count: $_ecosystemServicesCount');
            
            // Add to recent activities
            for (var service in services) {
              final createdAt = service['created_at'];
              DateTime? timestamp;
              try {
                timestamp = createdAt is String ? DateTime.parse(createdAt) : null;
              } catch (e) {
                print('⚠️ Failed to parse timestamp: $createdAt');
              }
              
              if (timestamp != null) {
                _recentActivities.add({
                  'icon': Icons.eco,
                  'color': Colors.green,
                  'title': 'บริการนิเวศ',
                  'description': 'บริการนิเวศ ${service['service_name'] ?? service['service_type'] ?? 'ทั่วไป'}',
                  'time': _formatTimestamp(createdAt),
                  'timestamp': timestamp,
                });
              }
            }
            print('🟢 Dashboard: Added ${services.length} ecosystem activities');
          } else {
            print('⚠️ Dashboard: Ecosystem services not available');
          }
          
          // Sort activities by timestamp (newest first) and limit to 5
          _recentActivities.sort((a, b) {
            final aTime = a['timestamp'] as DateTime?;
            final bTime = b['timestamp'] as DateTime?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // Descending order
          });
          
          // Limit to 5 most recent activities
          if (_recentActivities.length > 5) {
            _recentActivities = _recentActivities.sublist(0, 5);
          }
          
          print('📋 Dashboard: Recent activities count (after sorting & limiting): ${_recentActivities.length}');
          
          _isLoading = false;
          print('✅ Dashboard: Loading complete!');
        });
      }
    } catch (e, stackTrace) {
      print('❌ Dashboard Error loading data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'ไม่ทราบเวลา';
    
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'ไม่ทราบเวลา';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'เมื่อสักครู่';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} นาทีที่แล้ว';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} ชั่วโมงที่แล้ว';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} วันที่แล้ว';
      } else {
        return '${(difference.inDays / 7).floor()} สัปดาห์ที่แล้ว';
      }
    } catch (e) {
      return 'ไม่ทราบเวลา';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('ชุมชนป่าชายเลน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('โปรไฟล์ชุมชน'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('ออกจากระบบ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                _navigateToProfile();
              } else if (value == 'logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner (Rejected or Pending)
            if (_registrationStatus == 'rejected')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'การลงทะเบียนของคุณถูกปฏิเสธ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_rejectionReason != null && _rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เหตุผลที่ปฏิเสธ:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _rejectionReason!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'กรุณาติดต่อผู้ดูแลระบบเพื่อขอข้อมูลเพิ่มเติมหรือลงทะเบียนใหม่',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_registrationStatus == 'pending')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รอการอนุมัติ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'การลงทะเบียนของคุณอยู่ระหว่างการพิจารณาจากผู้ดูแลระบบ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สวัสดี, $_communityName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'จัดการข้อมูลชุมชนและป่าชายเลน',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location info with icon
                  if (_locationInfo.isNotEmpty && _locationInfo != 'ไม่มีข้อมูล')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _locationInfo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Village and Sub-district
                  if (_villageName.isNotEmpty || _subDistrict.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.home, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              [
                                if (_villageName.isNotEmpty) 'หมู่บ้าน$_villageName',
                                if (_subDistrict.isNotEmpty) 'ตำบล$_subDistrict',
                              ].join(' • '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Area size
                  if (_areaSize.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.landscape, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'ขนาดพื้นที่: $_areaSize ไร่',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Stats - Only 2 cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'รายงานมลพิษ',
                    '$_pollutionReportsCount รายการ',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'บริการนิเวศ',
                    '$_ecosystemServicesCount รายการ',
                    Icons.eco,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Main Functions
            const Text(
              'เมนูหลัก',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Function Cards
            _buildFunctionCard(
              context,
              icon: Icons.groups,
              title: 'จัดการข้อมูลชุมชนและประชากร',
              subtitle: 'อาชีพหลัก, ขนาดพื้นที่, จำนวนคน, ศาสนา, ฯลฯ',
              color: const Color(0xFF2E7D32),
              onTap: () => _navigateToEconomicData(),
            ),
            
            const SizedBox(height: 16),
            
            _buildFunctionCard(
              context,
              icon: Icons.assessment,
              title: 'รายงานรายไตรมาส',
              subtitle: 'สรุปมูลค่าเศรษฐกิจและบริการนิเวศรายไตรมาส',
              color: Colors.teal,
              onTap: () => _navigateToQuarterlyIncome(),
            ),
            
            const SizedBox(height: 16),
            
            _buildFunctionCard(
              context,
              icon: Icons.eco,
              title: 'จัดการข้อมูลบริการทางนิเวศ',
              subtitle: 'ทรัพยากรที่ใช้ประโยชน์, การท่องเที่ยว, มูลค่าเศรษฐกิจ',
              color: const Color(0xFF4CAF50),
              onTap: () => _navigateToEcosystemService(),
            ),
            
            const SizedBox(height: 16),
            
            _buildFunctionCard(
              context,
              icon: Icons.warning,
              title: 'รายงานแหล่งมลพิษ',
              subtitle: 'บันทึกและรายงานแหล่งมลพิษที่ส่งผลต่อป่าชายเลน',
              color: Colors.red,
              onTap: () => _navigateToPollutionReport(),
            ),
            
            const SizedBox(height: 32),
            
            // Recent Activities
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
                  const Text(
                    'กิจกรรมล่าสุด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_recentActivities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'ยังไม่มีกิจกรรมล่าสุด',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._recentActivities.map((activity) {
                      return _buildActivityItem(
                        activity['title'] ?? 'กิจกรรม',
                        activity['time'] ?? 'ไม่ทราบเวลา',
                        activity['icon'] ?? Icons.info,
                        activity['color'] ?? Colors.grey,
                      );
                    }).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tips Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'เคล็ดลับการใช้งาน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💡 บันทึกข้อมูลเป็นประจำเพื่อความแม่นยำ\n'
                    '🌱 รายงานผลการอนุรักษ์เป็นรายเดือน\n'
                    '📊 ใช้ข้อมูลเพื่อวางแผนการจัดการทรัพยากร',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF424242),
                      height: 1.4,
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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

  Widget _buildFunctionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF757575)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
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
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEconomicData() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EconomicDataScreenNew(),
      ),
    );
  }

  void _navigateToQuarterlyIncome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuarterlyReportScreen(),
      ),
    );
  }

  void _navigateToEcosystemService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EcosystemServicesImprovedScreen(), // ใช้หน้าใหม่ที่ปรับปรุงแล้ว
      ),
    ).then((_) => _loadDashboardData()); // Reload data when returning
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityProfileScreen(),
      ),
    ).then((_) => _loadDashboardData()); // Reload data when returning
  }

  void _navigateToPollutionReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PollutionReportsNewScreen(), // ใช้หน้าใหม่ที่ต่อ API
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }
}