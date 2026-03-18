import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'mangrove_management/mangrove_management_screen.dart';
import 'community_management/community_accounts_screen.dart';
import 'registration/registration_approval_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardStats;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }
  
  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final response = await _apiClient.getAdminDashboardStats();
    
    setState(() {
      _isLoading = false;
      if (response.success) {
        _dashboardStats = response.data;
      } else {
        _error = response.error;
      }
    });
  }
  
  int _getStat(String path) {
    if (_dashboardStats == null) return 0;
    
    final parts = path.split('.');
    dynamic current = _dashboardStats;
    
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return 0;
      }
    }
    
    return current is int ? current : 0;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ผู้ดูแลระบบ'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('โปรไฟล์'),
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
              if (value == 'logout') {
                _logout();
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'เกิดข้อผิดพลาด',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardStats,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ยินดีต้อนรับ, ผู้ดูแลระบบ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'จัดการระบบชุมชนป่าชายเลนภาคตะวันออก',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Statistics Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'ชุมชนทั้งหมด',
                                '${_getStat('communities.total')}',
                                Icons.groups,
                                const Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'พื้นที่ป่าทั้งหมด',
                                '${_getStat('mangroveAreas.total')}',
                                Icons.eco,
                                const Color(0xFF388E3C),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard(
                            'รายงานมลพิษ',
                            '${_getStat('pollutionReports.total')}',
                            Icons.warning,
                            Colors.orange,
                          ),
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

                        // Admin Function Cards
                        _buildFunctionCard(
                          context,
                          icon: Icons.approval,
                          title: 'อนุมัติการลงทะเบียนชุมชน',
                          subtitle: 'ตรวจสอบและอนุมัติคำขอลงทะเบียนของชุมชนใหม่',
                          badge: _getStat('communities.pending') > 0 ? '${_getStat('communities.pending')}' : null,
                          color: const Color(0xFF2E7D32),
                          onTap: () => _navigateToRegistrationApproval(),
                        ),

                        const SizedBox(height: 16),

                        _buildFunctionCard(
                          context,
                          icon: Icons.groups,
                          title: 'จัดการบัญชีชุมชน',
                          subtitle: 'เพิ่ม แก้ไข ลบ และจัดการบัญชีผู้ใช้ชุมชน',
                          color: const Color(0xFF4CAF50),
                          onTap: () => _navigateToCommunityAccounts(),
                        ),

                        const SizedBox(height: 16),

                        _buildFunctionCard(
                          context,
                          icon: Icons.eco,
                          title: 'จัดการข้อมูลพื้นที่ป่าชายเลน',
                          subtitle: 'เพิ่ม แก้ไข ลบข้อมูลพื้นที่ป่าชายเลนเบื้องต้น',
                          color: const Color(0xFF2E7D32),
                          onTap: () => _navigateToMangroveManagement(),
                        ),
                      ],
                    ),
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
              fontSize: 24,
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
    String? badge,
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
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  if (badge != null && badge != '0')
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
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

  void _navigateToMangroveManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MangroveManagementScreen(),
      ),
    );
  }

  void _navigateToCommunityAccounts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityAccountsScreen(),
      ),
    );
  }

  void _navigateToRegistrationApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrationApprovalScreen(),
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