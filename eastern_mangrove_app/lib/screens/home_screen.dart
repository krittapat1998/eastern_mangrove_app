import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'community/community_dashboard.dart';
import 'public/public_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Logo/Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Eastern Mangrove Communities',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ระบบจัดการข้อมูลชุมชนป่าชายเลนภาคตะวันออก',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF424242),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // User Type Selection Title
                const Text(
                  'เลือกประเภทผู้ใช้งาน',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // User Type Cards
                _buildUserTypeCard(
                  context,
                  icon: Icons.public,
                  title: 'ผู้ใช้ทั่วไป',
                  subtitle: 'ดูข้อมูลและสถิติป่าชายเลน',
                  onTap: () => _navigateToPublic(context),
                  color: const Color(0xFF4CAF50),
                ),
                
                const SizedBox(height: 20),
                
                _buildUserTypeCard(
                  context,
                  icon: Icons.groups,
                  title: 'ชุมชน',
                  subtitle: 'ลงทะเบียนและจัดการข้อมูลชุมชน',
                  onTap: () => _navigateToLogin(context, 'community'),
                  color: Colors.orange,
                ),
                
                const SizedBox(height: 20),
                
                _buildUserTypeCard(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'ผู้ดูแลระบบ (Admin)',
                  subtitle: 'จัดการข้อมูลพื้นที่และชุมชน',
                  onTap: () => _navigateToLogin(context, 'admin'),
                  color: const Color(0xFF2E7D32),
                ),
                
                const SizedBox(height: 40),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'สำหรับการอนุรักษ์และการจัดการ\nทรัพยากรป่าชายเลนอย่างยั่งยืน',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(userType: userType),
      ),
    );
  }

  void _navigateToPublic(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PublicDashboard(),
      ),
    );
  }
}