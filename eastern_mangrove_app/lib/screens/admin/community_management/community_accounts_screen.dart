import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/api_client.dart';

class CommunityAccountsScreen extends StatefulWidget {
  const CommunityAccountsScreen({super.key});

  @override
  State<CommunityAccountsScreen> createState() => _CommunityAccountsScreenState();
}

class _CommunityAccountsScreenState extends State<CommunityAccountsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _communities = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);
    
    try {
      final status = _selectedStatus == 'all' ? null : _selectedStatus;
      final search = _searchQuery.isEmpty ? null : _searchQuery;
      
      print('🔍 กำลังโหลดชุมชน...');
      print('   - Status filter: $status');
      print('   - Search: $search');
      print('   - Page: $_currentPage, Limit: $_limit');
      
      final response = await _apiClient.getAllCommunities(
        status: status,
        search: search,
        page: _currentPage,
        limit: _limit,
      );
      
      print('📦 API Response:');
      print('   - Success: ${response.success}');
      print('   - Message: ${response.message}');
      print('   - Error: ${response.error}');
      print('   - Data keys: ${response.data?.keys}');
      
      if (response.success && mounted) {
        // API returns: { success: true, data: [...] }
        // Not: { communities: [...], totalPages: 1 }
        final responseData = response.data;
        final communities = responseData?['data'] as List? ?? [];
        final totalPages = responseData?['totalPages'] as int? ?? 1;
        
        // DEBUG: แสดงโครงสร้างข้อมูลชุมชนแรก
        if (communities.isNotEmpty) {
          print('📋 ตัวอย่างข้อมูลชุมชนแรก:');
          final firstCommunity = communities[0];
          print('   Keys: ${(firstCommunity as Map).keys.toList()}');
          print('   community_id: ${firstCommunity['community_id']}');
          print('   id: ${firstCommunity['id']}');
          print('   user_id: ${firstCommunity['user_id']}');
          print('   community_name: ${firstCommunity['community_name']}');
        }
        
        setState(() {
          _communities = communities;
          _totalPages = totalPages;
          _isLoading = false;
        });
        print('✅ โหลดชุมชนสำเร็จ: ${_communities.length} รายการ');
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          print('❌ โหลดชุมชนล้มเหลว: ${response.message}');
          print('   Response error: ${response.error}');
          
          final errorMsg = response.error ?? response.message;
          final displayMsg = errorMsg.contains('Token') 
              ? 'กรุณาเข้าสู่ระบบใหม่ (เซสชันหมดอายุ)'
              : 'ไม่สามารถโหลดข้อมูล: $errorMsg';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ปิด',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('💥 Exception ใน _loadCommunities: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ปิด',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('จัดการบัญชีชุมชน'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCommunityDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อชุมชนหรือผู้ติดต่อ',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    });
                    _loadCommunities();
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('all', 'ทั้งหมด'),
                      _buildStatusChip('approved', 'ใช้งานได้'),
                      _buildStatusChip('pending', 'รออนุมัติ'),
                      _buildStatusChip('rejected', 'ถูกปฏิเสธ'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('ทั้งหมด', _communities.length.toString(), Colors.blue),
                _buildStatItem('ใช้งานได้', _getApprovedCount().toString(), Colors.green),
                _buildStatItem('รออนุมัติ', _getPendingCount().toString(), Colors.orange),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Communities List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _communities.isEmpty
                    ? const Center(child: Text('ไม่พบข้อมูลชุมชน'))
                    : RefreshIndicator(
                        onRefresh: _loadCommunities,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _communities.length,
                          itemBuilder: (context, index) {
                            final community = _communities[index];
                            return _buildCommunityCard(community);
                          },
                        ),
                      ),
          ),
          
          // Pagination
          if (_totalPages > 1)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadCommunities();
                          }
                        : null,
                  ),
                  Text('$_currentPage / $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadCommunities();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = value;
            _currentPage = 1;
          });
          _loadCommunities();
        },
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityCard(dynamic community) {
    final String status = community['registration_status'] ?? 'pending';
    final bool isUserActive = community['user_active'] == true;
    
    // API ส่งมาด้วย 'id' ไม่ใช่ 'community_id'
    final int? communityId = community['id'];
    final String communityName = community['community_name'] ?? 'ไม่ระบุชื่อ';
    
    // Debug log เพื่อตรวจสอบข้อมูล
    print('📋 Card data - ID: $communityId, Name: $communityName, Active: $isUserActive');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          print('🖱️ คลิกดูรายละเอียด: $communityName');
          _showCommunityDetails(community);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Title, Status, and Menu
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          communityName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'รหัส: ${communityId ?? "-"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF95A5A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Registration Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status == 'approved' ? Icons.verified : 
                              status == 'pending' ? Icons.pending :
                              Icons.cancel,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusText(status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // User Active Status Badge
                      if (!isUserActive) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.block,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'ระงับ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Overflow menu for ALL actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF2C3E50), size: 24),
                    tooltip: 'จัดการชุมชน',
                    onSelected: (value) {
                      if (value == 'edit') {
                        print('🖱️ เมนู: แก้ไข $communityName');
                        if (communityId != null) _showEditCommunityDialog(community);
                      } else if (value == 'toggle') {
                        print('🖱️ เมนู: ${isUserActive ? "ระงับ" : "เปิดใช้"} $communityName');
                        if (communityId != null) _toggleUserStatus(community, !isUserActive);
                      } else if (value == 'delete') {
                        print('🖱️ เมนู: ลบ $communityName');
                        if (communityId != null) _deleteCommunity(community);
                      } else if (value == 'reset') {
                        print('🖱️ เมนู: รีเซ็ตรหัส $communityName');
                        _showResetPasswordDialog(community);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        enabled: communityId != null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit, 
                              size: 20, 
                              color: communityId != null ? const Color(0xFF27AE60) : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'แก้ไขข้อมูล',
                              style: TextStyle(
                                color: communityId != null ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Only show toggle for approved communities
                      if (status == 'approved')
                        PopupMenuItem(
                          value: 'toggle',
                          enabled: communityId != null,
                          child: Row(
                            children: [
                              Icon(
                                isUserActive ? Icons.block : Icons.check_circle,
                                size: 20,
                                color: communityId != null 
                                  ? (isUserActive ? const Color(0xFFE67E22) : const Color(0xFF3498DB))
                                  : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isUserActive ? 'ระงับการใช้งาน' : 'เปิดใช้งาน',
                                style: TextStyle(
                                  color: communityId != null ? Colors.black87 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.lock_reset, size: 20, color: Color(0xFF95A5A6)),
                            SizedBox(width: 12),
                            Text('รีเซ็ตรหัสผ่าน'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        enabled: communityId != null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_forever,
                              size: 20,
                              color: communityId != null ? const Color(0xFFE74C3C) : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ลบบัญชีชุมชน',
                              style: TextStyle(
                                color: communityId != null ? const Color(0xFFE74C3C) : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            
            const Divider(height: 24, thickness: 1, color: Color(0xFFECF0F1)),
            
            // Community Details
            if (community['location'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Color(0xFF3498DB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      community['location'],
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            Row(
              children: [
                if (community['contact_person'] != null) ...[
                  const Icon(Icons.person, size: 18, color: Color(0xFF27AE60)),
                  const SizedBox(width: 8),
                  Text(
                    community['contact_person'],
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 13,
                    ),
                  ),
                ],
                if (community['contact_person'] != null && community['phone_number'] != null)
                  const SizedBox(width: 16),
                if (community['phone_number'] != null) ...[
                  const Icon(Icons.phone, size: 18, color: Color(0xFF9B59B6)),
                  const SizedBox(width: 8),
                  Text(
                    community['phone_number'],
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            
            if (community['email'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email, size: 18, color: Color(0xFFE67E22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      community['email'],
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            if (community['created_at'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Color(0xFF95A5A6)),
                  const SizedBox(width: 8),
                  Text(
                    'ลงทะเบียน: ${_formatDate(community['created_at'])}',
                    style: const TextStyle(
                      color: Color(0xFF95A5A6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            
            // Rejection Reason (if rejected)
            if (status == 'rejected' && community['rejection_reason'] != null && (community['rejection_reason'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'เหตุผลที่ปฏิเสธ:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      community['rejection_reason'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Hint text
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.touch_app, size: 14, color: Color(0xFF95A5A6)),
                const SizedBox(width: 6),
                const Text(
                  'คลิกเพื่อดูรายละเอียด • เมนู',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF95A5A6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_vert, size: 14, color: Color(0xFF95A5A6)),
                const SizedBox(width: 4),
                const Text(
                  'เพื่อจัดการ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF95A5A6),
                    fontStyle: FontStyle.italic,
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

  int _getApprovedCount() {
    return _communities.where((c) => c['registration_status'] == 'approved').length;
  }

  int _getPendingCount() {
    return _communities.where((c) => c['registration_status'] == 'pending').length;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'pending':
        return 'รออนุมัติ';
      case 'rejected':
        return 'ถูกปฏิเสธ';
      default:
        return '';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showCommunityDetails(dynamic community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(community['community_name'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('รหัส', community['id']?.toString()),
              _buildDetailRow('ชื่อชุมชน', community['community_name']),
              _buildDetailRow('ที่อยู่', community['location']),
              _buildDetailRow('ผู้ติดต่อ', community['contact_person']),
              _buildDetailRow('เบอร์โทร', community['phone_number']),
              _buildDetailRow('อีเมล', community['email']),
              _buildDetailRow('คำอธิบาย', community['description']),
              _buildDetailRow('ปีที่ก่อตั้ง', community['established_year']?.toString()),
              _buildDetailRow('จำนวนสมาชิก', community['member_count']?.toString()),
              _buildDetailRow('สถานะการลงทะเบียน', _getStatusText(community['registration_status'] ?? '')),
              _buildDetailRow('สถานะการใช้งาน', community['user_active'] == true ? 'ใช้งาน' : 'ระงับการใช้งาน'),
              _buildDetailRow('วันที่ลงทะเบียน', _formatDate(community['created_at'])),
              if (community['approved_at'] != null)
                _buildDetailRow('วันที่อนุมัติ', _formatDate(community['approved_at'])),
              if (community['rejection_reason'] != null)
                _buildDetailRow('เหตุผลที่ปฏิเสธ', community['rejection_reason']),
            ],
          ),
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

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(dynamic community) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final int? userId = community['user_id'];
    
    // Check if user_id exists
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ข้อผิดพลาด: ไม่พบข้อมูลผู้ใช้'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รีเซ็ตรหัสผ่าน'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('รีเซ็ตรหัสผ่านสำหรับ: ${community['community_name']}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่านใหม่',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสผ่าน';
                  }
                  if (value.length < 8) {
                    return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'รหัสผ่านไม่ตรงกัน';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _resetPassword(userId, passwordController.text, community['community_name']);
              }
            },
            child: const Text('รีเซ็ตรหัสผ่าน'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(int userId, String newPassword, String? communityName) async {
    try {
      print('🔐 กำลังรีเซ็ตรหัสผ่าน userId: $userId');
      final response = await _apiClient.resetUserPassword(userId, newPassword);
      
      print('📦 Reset Response: success=${response.success}, message=${response.message}');
      
      if (response.success && mounted) {
        print('✅ รีเซ็ตรหัสผ่านสำเร็จ!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('รีเซ็ตรหัสผ่านสำหรับ ${communityName ?? "ชุมชน"} เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'ปิด',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        print('❌ รีเซ็ตรหัสผ่านล้มเหลว: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('รีเซ็ตรหัสผ่านล้มเหลว: ${response.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ปิด',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Exception ใน _resetPassword: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ปิด',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showAddCommunityDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final contactPersonController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final descriptionController = TextEditingController();
    final establishedYearController = TextEditingController();
    final memberCountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isChecking = false;
          
          return AlertDialog(
            title: const Text('เพิ่มบัญชีชุมชน'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อชุมชน *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อชุมชน' : null,
                      enabled: !isChecking,
                    ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่ *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกที่อยู่' : null,
                  enabled: !isChecking,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'ผู้ติดต่อ *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกผู้ติดต่อ' : null,
                  enabled: !isChecking,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์ *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
                  enabled: !isChecking,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) return 'รูปแบบอีเมลไม่ถูกต้อง เช่น example@email.com';
                    return null;
                  },
                  enabled: !isChecking,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอกรหัสผ่าน';
                    if (value!.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                    return null;
                  },
                  enabled: !isChecking,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'คำอธิบาย',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !isChecking,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: establishedYearController,
                  decoration: const InputDecoration(
                    labelText: 'ปีที่ก่อตั้ง',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isChecking,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: memberCountController,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนสมาชิก',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isChecking,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isChecking ? null : () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: isChecking ? null : () async {
              if (formKey.currentState!.validate()) {
                // Show loading
                setState(() => isChecking = true);
                
                try {
                  // Check for duplicate first
                  print('🔍 Checking duplicate...');
                  final checkResponse = await _apiClient.checkDuplicateCommunity(
                    communityName: nameController.text,
                    email: emailController.text,
                  );
                  
                  setState(() => isChecking = false);
                  
                  if (!checkResponse.success) {
                    // API error - show alert
                    if (mounted) {
                      final errMsg = checkResponse.error ?? '';
                      final isTokenError = errMsg.contains('Token') || errMsg.contains('token') || errMsg.contains('Unauthorized') || errMsg.contains('expired') || errMsg.contains('login');
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(isTokenError ? Icons.lock_outline : Icons.error_outline, color: isTokenError ? Colors.orange : Colors.red),
                              const SizedBox(width: 8),
                              Text(isTokenError ? 'เซสชันหมดอายุ' : 'เกิดข้อผิดพลาด'),
                            ],
                          ),
                          content: Text(isTokenError
                              ? 'กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่\n(เซสชันหมดอายุ)'
                              : (checkResponse.error ?? 'เกิดข้อผิดพลาดในการตรวจสอบข้อมูล')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ตกลง'),
                            ),
                          ],
                        ),
                      );
                    }
                    return;
                  }
                  
                  // Check if duplicate
                  final isDuplicate = checkResponse.data?['isDuplicate'] ?? false;
                  if (isDuplicate) {
                    if (mounted) {
                      final message = checkResponse.data?['message'] ?? 'ข้อมูลซ้ำกัน';
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('ข้อมูลซ้ำกัน'),
                            ],
                          ),
                          content: Text(
                            '$message\n\nกรุณาเปลี่ยนชื่อชุมชนหรืออีเมล',
                            style: const TextStyle(fontSize: 16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ตกลง'),
                            ),
                          ],
                        ),
                      );
                    }
                    return;
                  }
                  
                  // No duplicate, proceed to create
                  Navigator.pop(context);
                  
                  await _addCommunity(
                    nameController.text,
                    locationController.text,
                    contactPersonController.text,
                    phoneController.text,
                    emailController.text,
                    passwordController.text,
                    descriptionController.text.isEmpty ? null : descriptionController.text,
                    establishedYearController.text.isEmpty ? null : int.tryParse(establishedYearController.text),
                    memberCountController.text.isEmpty ? null : int.tryParse(memberCountController.text),
                  );
                } catch (e) {
                  print('💥 Error in duplicate check: $e');
                  setState(() => isChecking = false);
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('เกิดข้อผิดพลาด'),
                          ],
                        ),
                        content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('ตกลง'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              }
            },
            child: isChecking 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('เพิ่มชุมชน'),
          ),
        ],
      );
        },
      ),
    );
  }

  Future<void> _addCommunity(
    String name,
    String location,
    String contactPerson,
    String phone,
    String email,
    String password,
    String? description,
    int? establishedYear,
    int? memberCount,
  ) async {
    try {
      print('➕ กำลังเพิ่มชุมชน:');
      print('   - ชื่อ: $name');
      print('   - อีเมล: $email');
      print('   - เบอร์โทร: $phone');
      print('   - ที่อยู่: $location');
      print('   - ผู้ติดต่อ: $contactPerson');
      
      final response = await _apiClient.createCommunity(
        communityName: name,
        location: location,
        contactPerson: contactPerson,
        phoneNumber: phone,
        email: email,
        password: password,
        description: description,
        establishedYear: establishedYear,
        memberCount: memberCount,
      );
      
      print('📦 Create Response:');
      print('   - success: ${response.success}');
      print('   - message: ${response.message}');
      print('   - error: ${response.error}');
      
      if (response.success && mounted) {
        print('✅ เพิ่มชุมชนสำเร็จ: $name');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เพิ่มชุมชน "$name" เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadCommunities(); // Reload list
      } else {
        if (mounted) {
          print('❌ เพิ่มชุมชนล้มเหลว: ${response.message}');
          print('   Response error: ${response.error}');
          
          final errorMsg = response.error ?? response.message ?? 'Unknown error';
          
          String displayMsg;
          if (errorMsg.contains('Token') || errorMsg.contains('Unauthorized') || errorMsg.contains('401')) {
            displayMsg = '🔒 กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่\n(เซสชันหมดอายุ)';
          } else if (errorMsg.contains('มีชุมชนที่ใช้ชื่อหรืออีเมลนี้อยู่แล้ว') || errorMsg.contains('Duplicate')) {
            displayMsg = '⚠️ ชื่อชุมชนหรืออีเมลนี้ถูกใช้แล้ว\nกรุณาเปลี่ยนใหม่';
          } else if (errorMsg.contains('Connection') || errorMsg.contains('Network') || errorMsg.contains('Failed host lookup')) {
            displayMsg = '📡 ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์\nกรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
          } else if (errorMsg.contains('SocketException')) {
            displayMsg = '🔌 ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์\nกรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
          } else {
            displayMsg = '❌ เกิดข้อผิดพลาด:\n$errorMsg';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'ปิด',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('💥 Exception ใน _addCommunity: $e');
        print('💥 Exception type: ${e.runtimeType}');
        
        String displayMsg;
        if (e.toString().contains('SocketException')) {
          displayMsg = '🔌 ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์\n\nกรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
        } else if (e.toString().contains('FormatException')) {
          displayMsg = '⚠️ รูปแบบข้อมูลไม่ถูกต้อง\nกรุณาติดต่อผู้ดูแลระบบ';
        } else {
          displayMsg = '❌ เกิดข้อผิดพลาด:\n${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'ปิด',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showEditCommunityDialog(dynamic community) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: community['community_name']);
    final locationController = TextEditingController(text: community['location']);
    final contactPersonController = TextEditingController(text: community['contact_person']);
    final phoneController = TextEditingController(text: community['phone_number']);
    final emailController = TextEditingController(text: community['email']);
    final descriptionController = TextEditingController(text: community['description'] ?? '');
    final establishedYearController = TextEditingController(
      text: community['established_year']?.toString() ?? '',
    );
    final memberCountController = TextEditingController(
      text: community['member_count']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขข้อมูลชุมชน'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อชุมชน *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อชุมชน' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่ *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกที่อยู่' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'ผู้ติดต่อ *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกผู้ติดต่อ' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์ *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) return 'รูปแบบอีเมลไม่ถูกต้อง เช่น example@email.com';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'คำอธิบาย',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: establishedYearController,
                  decoration: const InputDecoration(
                    labelText: 'ปีที่ก่อตั้ง',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: memberCountController,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนสมาชิก',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                final communityId = community['id'];
                await _updateCommunity(
                  communityId,
                  nameController.text,
                  locationController.text,
                  contactPersonController.text,
                  phoneController.text,
                  emailController.text,
                  descriptionController.text.isEmpty ? null : descriptionController.text,
                  establishedYearController.text.isEmpty ? null : int.tryParse(establishedYearController.text),
                  memberCountController.text.isEmpty ? null : int.tryParse(memberCountController.text),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCommunity(
    int? communityId,
    String name,
    String location,
    String contactPerson,
    String phone,
    String email,
    String? description,
    int? establishedYear,
    int? memberCount,
  ) async {
    if (communityId == null) {
      print('❌ ERROR: communityId เป็น null!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ข้อผิดพลาด: ไม่พบรหัสชุมชน'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    try {
      print('🔧 กำลังแก้ไขชุมชน ID: $communityId');
      print('   - ชื่อ: $name');
      print('   - ที่อยู่: $location');
      
      final response = await _apiClient.updateCommunity(
        communityId, // Now guaranteed to be non-null
        communityName: name,
        location: location,
        contactPerson: contactPerson,
        phoneNumber: phone,
        email: email,
        description: description,
        establishedYear: establishedYear,
        memberCount: memberCount,
      );
      
      print('📦 Update Response: success=${response.success}, message=${response.message}');
      
      if (response.success && mounted) {
        print('✅ แก้ไขสำเร็จ!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadCommunities(); // Reload list
      } else {
        print('❌ แก้ไขล้มเหลว: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ปิด',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Exception ใน _updateCommunity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ปิด',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(dynamic community, bool activate) async {
    final action = activate ? 'เปิดใช้งาน' : 'ระงับการใช้งาน';
    final String communityName = community['community_name'] ?? 'ไม่ระบุชื่อ';
    final int? communityId = community['id'];  // ใช้ id แทน user_id
    
    // Debug logging
    print('🔄 กำลัง$action ชุมชน: $communityName');
    print('   - Community ID: $communityId');
    print('   - activate: $activate');
    
    if (communityId == null) {
      print('❌ ERROR: ไม่พบ ID ในข้อมูล!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ข้อผิดพลาด: ไม่พบรหัส'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการ$action $communityName หรือไม่?'),
            const SizedBox(height: 8),
            Text(
              activate 
                ? 'ผู้ใช้จะสามารถเข้าสู่ระบบและใช้งานได้'
                : 'ผู้ใช้จะไม่สามารถเข้าสู่ระบบได้ชั่วคราว',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: activate ? Colors.green : Colors.red,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('🔄 เรียก API toggleUserStatus với communityId: $communityId');
        
        final response = await _apiClient.toggleUserStatus(
          communityId,  // ใช้ community id
          reason: activate ? 'เปิดใช้งานโดย Admin' : 'ระงับการใช้งานโดย Admin',
        );
        
        print('📦 Toggle Response: success=${response.success}, message=${response.message}');
        
        if (response.success && mounted) {
          print('✅ ${action}สำเร็จ!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          _loadCommunities(); // Reload list
        } else {
          print('❌ ${action}ล้มเหลว: ${response.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'ปิด',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('💥 Exception ใน _toggleUserStatus: $e');
        print('Stack trace: ${StackTrace.current}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ปิด',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } else {
      print('❌ ผู้ใช้ยกเลิก action');
    }
  }

  Future<void> _deleteCommunity(dynamic community) async {
    final String communityName = community['community_name'] ?? 'ไม่ระบุชื่อ';
    final int? communityId = community['id'];
    
    // Debug logging
    print('🗑️ กำลังลบชุมชน: $communityName');
    print('   - id: ${community['id']}');
    print('   - communityId ที่ใช้: $communityId');
    print('   - All keys: ${(community as Map).keys.toList()}');
    
    if (communityId == null) {
      print('❌ ERROR: ไม่พบ id ในข้อมูล!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ข้อผิดพลาด: ไม่พบรหัสชุมชน'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบบัญชีชุมชน?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการลบ $communityName หรือไม่?'),
            const SizedBox(height: 8),
            const Text(
              'การลบบัญชีจะลบข้อมูลทั้งหมดของชุมชนนี้',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'และไม่สามารถกู้คืนได้!',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('ยืนยันการลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('🗑️ เรียก API deleteCommunity với communityId: $communityId');
        
        final response = await _apiClient.deleteCommunity(communityId);
        
        print('📦 Delete Response: success=${response.success}, message=${response.message}');
        
        if (response.success && mounted) {
          print('✅ ลบสำเร็จ!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          _loadCommunities(); // Reload list
        } else {
          print('❌ ลบล้มเหลว: ${response.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ลบล้มเหลว: ${response.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'ปิด',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('💥 Exception ใน _deleteCommunity: $e');
        print('Stack trace: ${StackTrace.current}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ปิด',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } else {
      print('❌ ผู้ใช้ยกเลิกการลบ');
    }
  }
}
