import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'community_registration_screen.dart';
import '../admin/admin_dashboard.dart';
import '../community/community_dashboard.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final String userType;
  
  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Color get _userTypeColor {
    return const Color(0xFF2E7D32); // ใช้เขียวเข้มสำหรับทุก userType
  }

  String get _userTypeTitle {
    switch (widget.userType) {
      case 'admin':
        return 'ผู้ดูแลระบบ';
      case 'community':
        return 'ชุมชน';
      default:
        return 'ผู้ใช้ทั่วไป';
    }
  }

  IconData get _userTypeIcon {
    switch (widget.userType) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'community':
        return Icons.groups;
      default:
        return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
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
                        _userTypeIcon,
                        size: 60,
                        color: _userTypeColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _userTypeColor,
                        ),
                      ),
                      Text(
                        _userTypeTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Login Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'ชื่อผู้ใช้',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _userTypeColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาป้อนชื่อผู้ใช้';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'รหัสผ่าน',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                  ? Icons.visibility_off 
                                  : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _userTypeColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาป้อนรหัสผ่าน';
                            }
                            if (value.length < 6) {
                              return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(),
                            child: Text(
                              'ลืมรหัสผ่าน?',
                              style: TextStyle(color: _userTypeColor),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Login Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _userTypeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'เข้าสู่ระบบ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        ),
                        
                        // Register Button (for community only)
                        if (widget.userType == 'community') ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => _navigateToRegister(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _userTypeColor,
                              side: BorderSide(color: _userTypeColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ลงทะเบียนชุมชนใหม่',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Back Button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'กลับหน้าหลัก',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (success) {
          // Navigate based on user type
          if (authProvider.isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
          } else if (authProvider.isCommunity) {
            if (authProvider.isCommunityApproved) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CommunityDashboard()),
              );
            } else {
              _showPendingApprovalDialog();
            }
          }
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'เข้าสู่ระบบไม่สำเร็จ'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityRegistrationScreen(),
      ),
    );
  }

  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pending, color: Colors.orange),
            SizedBox(width: 8),
            Text('รออนุมัติ'),
          ],
        ),
        content: const Text(
          'บัญชีของคุณอยู่ระหว่างการรอการอนุมัติจากผู้ดูแลระบบ\n'
          'กรุณารอการติดต่อกลับหรือติดต่อผู้ดูแลระบบโดยตรง',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home screen
            },
            icon: const Icon(Icons.home),
            label: const Text('กลับหน้าหลัก'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลืมรหัสผ่าน'),
        content: const Text('กรุณาติดต่อผู้ดูแลระบบสำหรับการรีเซ็ตรหัสผ่าน'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}