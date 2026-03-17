import 'package:flutter/material.dart';
import '../../../../services/api_client.dart';

class MangroveTestScreen extends StatefulWidget {
  const MangroveTestScreen({super.key});

  @override
  State<MangroveTestScreen> createState() => _MangroveTestScreenState();
}

class _MangroveTestScreenState extends State<MangroveTestScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String _status = 'เริ่มต้น';
  List<Map<String, dynamic>> _areas = [];

  @override
  void initState() {
    super.initState();
    print('🟢 MangroveTestScreen initState');
    _testLoad();
  }

  Future<void> _testLoad() async {
    print('🔵 Starting test load');
    setState(() {
      _isLoading = true;
      _status = 'กำลังโหลด...';
    });

    try {
      print('🔵 Calling getMangroveAreas...');
      final response = await _apiClient.getMangroveAreas();
      
      print('🔵 Response received');
      print('   - success: ${response.success}');
      print('   - message: ${response.message}');
      print('   - error: ${response.error}');
      print('   - data length: ${response.data?.length}');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _areas = response.data!;
            _status = 'โหลดสำเร็จ: ${_areas.length} พื้นที่';
            print('✅ Success: ${_areas.length} areas');
          } else {
            _status = 'Error: ${response.error ?? response.message ?? "Unknown"}';
            print('❌ Error: $_status');
          }
        });
      }
    } catch (e, stack) {
      print('❌ Exception: $e');
      print('Stack: $stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = 'Exception: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบ Mangrove API'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สถานะ:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('โหลดใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: _areas.isEmpty
                    ? const Center(
                        child: Text(
                          'ยังไม่มีข้อมูล',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _areas.length,
                        itemBuilder: (context, index) {
                          final area = _areas[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2E7D32),
                              child: Text('${index + 1}'),
                            ),
                            title: Text(area['area_name'] ?? 'No name'),
                            subtitle: Text(
                              '${area['province'] ?? ''} - ${area['size_hectares'] ?? ''} ไร่',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                area['conservation_status'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
