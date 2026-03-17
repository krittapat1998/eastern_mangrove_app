import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/api_client.dart';

class RegistrationApprovalScreen extends StatefulWidget {
  const RegistrationApprovalScreen({super.key});

  @override
  State<RegistrationApprovalScreen> createState() => _RegistrationApprovalScreenState();
}

class _RegistrationApprovalScreenState extends State<RegistrationApprovalScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingCommunities = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingCommunities();
  }

  Future<void> _loadPendingCommunities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _apiClient.getPendingCommunities();

    setState(() {
      _isLoading = false;
      if (response.success) {
        _pendingCommunities = response.data ?? [];
      } else {
        _error = response.error;
      }
    });
  }

  Future<void> _approveCommunity(Map<String, dynamic> community) async {
    final int communityId = community['id'];
    final String communityName = community['community_name'] ?? 'ไม่ระบุชื่อ';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการอนุมัติ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการอนุมัติการลงทะเบียนของ'),
            const SizedBox(height: 8),
            Text(
              communityName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text('หรือไม่?'),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('อนุมัติ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Call API
    final response = await _apiClient.approveCommunity(communityId);

    // Hide loading
    if (!mounted) return;
    Navigator.pop(context);

    // Show result
    if (!mounted) return;
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'อนุมัติคำขอเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPendingCommunities(); // Reload list
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('เกิดข้อผิดพลาด'),
          content: Text(response.error ?? 'ไม่สามารถอนุมัติคำขอได้'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _rejectCommunity(Map<String, dynamic> community) async {
    final int communityId = community['id'];
    final String communityName = community['community_name'] ?? 'ไม่ระบุชื่อ';
    final TextEditingController reasonController = TextEditingController();

    // Show reason dialog
    final String? reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธคำขอลงทะเบียน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชุมชน: $communityName'),
            const SizedBox(height: 16),
            const Text(
              'กรุณาระบุเหตุผลในการปฏิเสธ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'เหตุผล...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาระบุเหตุผล'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ปฏิเสธ'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Call API
    final response = await _apiClient.rejectCommunity(communityId, reason: reason);

    // Hide loading
    if (!mounted) return;
    Navigator.pop(context);

    // Show result
    if (!mounted) return;
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'ปฏิเสธคำขอเรียบร้อยแล้ว'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadPendingCommunities(); // Reload list
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('เกิดข้อผิดพลาด'),
          content: Text(response.error ?? 'ไม่สามารถปฏิเสธคำขอได้'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('อนุมัติการลงทะเบียนชุมชน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingCommunities,
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
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingCommunities,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : _pendingCommunities.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            'ไม่มีคำขอรออนุมัติ',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingCommunities,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingCommunities.length,
                        itemBuilder: (context, index) {
                          final community = _pendingCommunities[index];
                          return _buildCommunityCard(community);
                        },
                      ),
                    ),
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community) {
    final String communityName = community['community_name'] ?? 'ไม่ระบุชื่อ';
    final String location = community['location'] ?? '-';
    final String contactPerson = community['contact_person'] ?? '-';
    final String phoneNumber = community['phone_number'] ?? '-';
    final String email = community['email'] ?? '-';
    final String? description = community['description'];
    final String createdAt = community['created_at'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(community['created_at']))
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        communityName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ส่งคำขอเมื่อ: $createdAt',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Community Details
            _buildDetailRow(Icons.location_on, 'ที่ตั้ง', location),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.person, 'ผู้ติดต่อ', contactPerson),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.phone, 'เบอร์โทร', phoneNumber),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.email, 'อีเมล', email),

            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'รายละเอียด:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectCommunity(community),
                    icon: const Icon(Icons.close),
                    label: const Text('ปฏิเสธ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveCommunity(community),
                    icon: const Icon(Icons.check),
                    label: const Text('อนุมัติ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
