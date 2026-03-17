import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../models/models.dart';

class QuarterlyIncomeScreen extends StatefulWidget {
  const QuarterlyIncomeScreen({super.key});

  @override
  State<QuarterlyIncomeScreen> createState() => _QuarterlyIncomeScreenState();
}

class _QuarterlyIncomeScreenState extends State<QuarterlyIncomeScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _economicData = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEconomicData();
  }

  // Helper function to safely parse double from API response
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _loadEconomicData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getEconomicDataNew();
      
      if (response.success && response.data != null) {
        setState(() {
          _economicData = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('ข้อมูลรายได้รายไตรมาส'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEconomicData,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIncomeDialog(),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEconomicData,
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

    if (_economicData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'ยังไม่มีข้อมูลรายได้\nกดปุ่ม + เพื่อเพิ่มข้อมูล',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCards(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _economicData.length,
            itemBuilder: (context, index) {
              final data = _economicData[index];
              return _buildIncomeCard(data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final totalIncome = _economicData.fold<double>(
      0,
      (sum, item) => sum + _parseDouble(item['total_income']),
    );

    final avgIncome = _economicData.isNotEmpty
        ? totalIncome / _economicData.length
        : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'รายได้รวม',
              '${_formatNumber(totalIncome)} บาท',
              Icons.monetization_on,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'รายการทั้งหมด',
              '${_economicData.length} รายการ',
              Icons.list_alt,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'เฉลี่ยต่อไตรมาส',
              '${_formatNumber(avgIncome.toDouble())} บาท',
              Icons.trending_up,
              Colors.orange,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(Map<String, dynamic> data) {
    final year = data['year'];
    final quarter = data['quarter'];
    final fishery = _parseDouble(data['income_fishery']);
    final tourism = _parseDouble(data['income_tourism']);
    final agriculture = _parseDouble(data['income_agriculture']);
    final others = _parseDouble(data['income_others']);
    final total = _parseDouble(data['total_income']);
    final employment = data['employment_count'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showIncomeDetails(data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Q$quarter/$year',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditIncomeDialog(data),
                        color: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDelete(data['id']),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildIncomeRow('ประมง', fishery, Icons.set_meal, Colors.blue),
              _buildIncomeRow('ท่องเที่ยว', tourism, Icons.beach_access, Colors.orange),
              _buildIncomeRow('เกษตร', agriculture, Icons.agriculture, Colors.green),
              _buildIncomeRow('อื่นๆ', others, Icons.more_horiz, Colors.grey),
              const Divider(),
              _buildIncomeRow(
                'รวมทั้งหมด',
                total,
                Icons.monetization_on,
                const Color(0xFF2E7D32),
                isBold: true,
              ),
              if (employment != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'จำนวนผู้มีงานทำ: $employment คน',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeRow(String label, double amount, IconData icon, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? color : Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            '${_formatNumber(amount)} บาท',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showIncomeDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รายละเอียดรายได้ Q${data['quarter']}/${data['year']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('รายได้จากประมง', data['income_fishery']),
              _buildDetailRow('รายได้จากท่องเที่ยว', data['income_tourism']),
              _buildDetailRow('รายได้จากเกษตร', data['income_agriculture']),
              _buildDetailRow('รายได้อื่นๆ', data['income_others']),
              const Divider(),
              _buildDetailRow('รวมทั้งหมด', data['total_income'], isBold: true),
              if (data['employment_count'] != null)
                _buildDetailRow('จำนวนผู้มีงานทำ', '${data['employment_count']} คน'),
              if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'หมายเหตุ:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(data['notes']),
              ],
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

  Widget _buildDetailRow(String label, dynamic value, {bool isBold = false}) {
    String valueText;
    if (value is num) {
      valueText = '${_formatNumber(value.toDouble())} บาท';
    } else {
      valueText = value?.toString() ?? '-';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? const Color(0xFF2E7D32) : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog() {
    _showIncomeFormDialog(null);
  }

  void _showEditIncomeDialog(Map<String, dynamic> data) {
    _showIncomeFormDialog(data);
  }

  void _showIncomeFormDialog(Map<String, dynamic>? existingData) {
    final yearController = TextEditingController(
      text: existingData?['year']?.toString() ?? DateTime.now().year.toString(),
    );
    final quarterController = TextEditingController(
      text: existingData?['quarter']?.toString() ?? '1',
    );
    
    // Helper to show empty string for 0 values
    String _valueOrEmpty(dynamic value) {
      if (value == null) return '';
      final num = _parseDouble(value);
      return num > 0 ? num.toString() : '';
    }
    
    final fisheryController = TextEditingController(
      text: _valueOrEmpty(existingData?['income_fishery']),
    );
    final tourismController = TextEditingController(
      text: _valueOrEmpty(existingData?['income_tourism']),
    );
    final agricultureController = TextEditingController(
      text: _valueOrEmpty(existingData?['income_agriculture']),
    );
    final othersController = TextEditingController(
      text: _valueOrEmpty(existingData?['income_others']),
    );
    final employmentController = TextEditingController(
      text: existingData?['employment_count'] != null && existingData!['employment_count'] > 0
          ? existingData['employment_count'].toString()
          : '',
    );
    final notesController = TextEditingController(
      text: existingData?['notes']?.toString() ?? '',
    );

    // Get existing quarters for validation
    String _getExistingQuarters() {
      if (_economicData.isEmpty) return 'ยังไม่มีข้อมูล';
      final quarters = _economicData.map((d) => 'Q${d['quarter']}/${d['year']}').toList();
      return quarters.join(', ');
    }

    bool _isDuplicate(String year, String quarter) {
      if (existingData != null) return false; // Allow editing same quarter
      final y = int.tryParse(year) ?? 0;
      final q = int.tryParse(quarter) ?? 0;
      return _economicData.any((d) => d['year'] == y && d['quarter'] == q);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingData == null ? 'เพิ่มข้อมูลรายได้' : 'แก้ไขข้อมูลรายได้'),
          content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show existing quarters info
              if (existingData == null && _economicData.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ไตรมาสที่มีข้อมูลแล้ว: ${_getExistingQuarters()}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Duplicate warning
              if (_isDuplicate(yearController.text, quarterController.text)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ไตรมาสนี้มีข้อมูลแล้ว กรุณาเลือกไตรมาสอื่น',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: yearController,
                      decoration: const InputDecoration(
                        labelText: 'ปี พ.ศ.',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: quarterController,
                      decoration: const InputDecoration(
                        labelText: 'ไตรมาส (1-4)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fisheryController,
                decoration: const InputDecoration(
                  labelText: 'รายได้จากประมง (บาท)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.set_meal),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tourismController,
                decoration: const InputDecoration(
                  labelText: 'รายได้จากท่องเที่ยว (บาท)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.beach_access),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: agricultureController,
                decoration: const InputDecoration(
                  labelText: 'รายได้จากเกษตร (บาท)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: othersController,
                decoration: const InputDecoration(
                  labelText: 'รายได้อื่นๆ (บาท)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.more_horiz),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: employmentController,
                decoration: const InputDecoration(
                  labelText: 'จำนวนผู้มีงานทำ (คน)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
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
            onPressed: _isDuplicate(yearController.text, quarterController.text) 
              ? null 
              : () async {
              final dataMap = {
                'year': int.tryParse(yearController.text) ?? DateTime.now().year,
                'quarter': int.tryParse(quarterController.text) ?? 1,
                'incomeFishery': double.tryParse(fisheryController.text) ?? 0.0,
                'incomeTourism': double.tryParse(tourismController.text) ?? 0.0,
                'incomeAgriculture': double.tryParse(agricultureController.text) ?? 0.0,
                'incomeOthers': double.tryParse(othersController.text) ?? 0.0,
                'employmentCount': int.tryParse(employmentController.text) ?? 0,
                'notes': notesController.text.isNotEmpty ? notesController.text : null,
              };

              Navigator.pop(context);

              if (existingData == null) {
                await _createIncome(dataMap);
              } else {
                await _updateIncome(existingData['id'], dataMap);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _createIncome(Map<String, dynamic> dataMap) async {
    try {
      final response = await _apiClient.createEconomicData(dataMap);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกข้อมูลรายได้สำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadEconomicData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${response.message}'),
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
    }
  }

  Future<void> _updateIncome(int id, Map<String, dynamic> dataMap) async {
    try {
      final response = await _apiClient.updateEconomicData(id, dataMap);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัพเดทข้อมูลรายได้สำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadEconomicData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${response.message}'),
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
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบข้อมูลรายได้นี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteIncome(id);
    }
  }

  Future<void> _deleteIncome(int id) async {
    try {
      final response = await _apiClient.deleteEconomicData(id);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบข้อมูลรายได้สำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          _loadEconomicData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${response.message}'),
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
    }
  }
}
