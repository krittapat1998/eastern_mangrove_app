import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class QuarterlyReportScreen extends StatefulWidget {
  const QuarterlyReportScreen({super.key});

  @override
  State<QuarterlyReportScreen> createState() => _QuarterlyReportScreenState();
}

class _QuarterlyReportScreenState extends State<QuarterlyReportScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;
  
  Map<String, List<Map<String, dynamic>>> _quarterlyData = {};
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedYear = DateTime.now().year;
  
  final List<int> _availableYears = List.generate(
    5, 
    (index) => DateTime.now().year - index
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadQuarterlyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getQuarterName(int quarter) {
    switch (quarter) {
      case 1: return 'ไตรมาสที่ 1 (ม.ค.-มี.ค.)';
      case 2: return 'ไตรมาสที่ 2 (เม.ย.-มิ.ย.)';
      case 3: return 'ไตรมาสที่ 3 (ก.ค.-ก.ย.)';
      case 4: return 'ไตรมาสที่ 4 (ต.ค.-ธ.ค.)';
      default: return 'ไตรมาสที่ $quarter';
    }
  }

  int _getQuarterFromMonth(int month) {
    if (month >= 1 && month <= 3) return 1;
    if (month >= 4 && month <= 6) return 2;
    if (month >= 7 && month <= 9) return 3;
    return 4;
  }

  // Translate category from English to Thai
  String _translateCategory(String? category) {
    if (category == null) return 'อื่นๆ';
    switch (category.toLowerCase()) {
      case 'resource':
        return 'ทรัพยากร';
      case 'activity':
        return 'กิจกรรม';
      case 'provision':
      case 'provisioning':
        return 'การจัดหา';
      case 'regulation':
      case 'regulating':
        return 'การควบคุม';
      case 'culture':
      case 'cultural':
        return 'วัฒนธรรม';
      default:
        return category;
    }
  }

  // Translate service type from English to Thai
  String _translateServiceType(String? serviceType) {
    if (serviceType == null) return 'ไม่ระบุ';
    switch (serviceType.toLowerCase()) {
      case 'fish':
        return 'ปลา';
      case 'shellfish':
        return 'หอย/สัตว์น้ำ';
      case 'crab':
        return 'ปู';
      case 'shrimp':
        return 'กุ้ง';
      case 'wood':
        return 'ไม้';
      case 'firewood':
        return 'ไม้ฟืน';
      case 'medicinal_plants':
        return 'พืชสมุนไพร';
      case 'other_resource':
        return 'ทรัพยากรอื่นๆ';
      case 'tour_guide':
        return 'ไกด์นำเที่ยว';
      case 'homestay':
        return 'โฮมสเตย์';
      case 'seminar':
        return 'การสัมมนา';
      case 'workshop':
        return 'การอบรม';
      case 'learning_camp':
        return 'ค่ายการเรียนรู้';
      case 'other_activity':
        return 'กิจกรรมอื่นๆ';
      case 'ecotourism':
        return 'ท่องเที่ยวเชิงนิเวศ';
      case 'education':
        return 'การศึกษา';
      case 'provisioning':
        return 'การจัดหาทรัพยากร';
      case 'regulating':
        return 'การควบคุมสภาพแวดล้อม';
      case 'cultural':
        return 'วัฒนธรรม';
      case 'recreation':
        return 'นันทนาการ';
      case 'other':
        return 'อื่นๆ';
      default:
        return serviceType;
    }
  }

  // Translate unit from English to Thai
  String _translateUnit(String? unit) {
    if (unit == null || unit.isEmpty) return '';
    switch (unit.toLowerCase()) {
      case 'kg':
        return 'กก.';
      case 'ton':
        return 'ตัน';
      case 'piece':
        return 'ชิ้น';
      case 'bundle':
        return 'มัด';
      case 'person':
        return 'คน';
      case 'group':
        return 'กลุ่ม';
      case 'trip':
        return 'ครั้ง';
      case 'day':
        return 'วัน';
      case 'night':
        return 'คืน';
      default:
        return unit;
    }
  }

  Future<void> _loadQuarterlyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getEcosystemServices();
      
      if (response.success && response.data != null) {
        // Group data by quarters
        Map<String, List<Map<String, dynamic>>> grouped = {
          'Q1': [],
          'Q2': [],
          'Q3': [],
          'Q4': [],
        };

        for (var service in response.data!) {
          final year = service['year'] ?? 0;
          final month = service['month'] ?? 0;
          
          if (year == _selectedYear && month > 0) {
            final quarter = _getQuarterFromMonth(month);
            grouped['Q$quarter']!.add(service);
          }
        }

        setState(() {
          _quarterlyData = grouped;
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
        title: const Text('รายงานรายไตรมาส'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // Year selector dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<int>(
              value: _selectedYear,
              dropdownColor: const Color(0xFF2E7D32),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: _availableYears.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text('ปี $year', style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (int? newYear) {
                if (newYear != null) {
                  setState(() {
                    _selectedYear = newYear;
                  });
                  _loadQuarterlyData();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuarterlyData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'ไตรมาส 1'),
            Tab(text: 'ไตรมาส 2'),
            Tab(text: 'ไตรมาส 3'),
            Tab(text: 'ไตรมาส 4'),
          ],
        ),
      ),
      body: _buildBody(),
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
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuarterlyData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildQuarterView(1, _quarterlyData['Q1'] ?? []),
        _buildQuarterView(2, _quarterlyData['Q2'] ?? []),
        _buildQuarterView(3, _quarterlyData['Q3'] ?? []),
        _buildQuarterView(4, _quarterlyData['Q4'] ?? []),
      ],
    );
  }

  Widget _buildQuarterView(int quarter, List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'ไม่มีข้อมูลสำหรับ${_getQuarterName(quarter)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate totals
    double totalEconomicValue = 0;
    int totalBeneficiaries = 0;
    Map<String, double> categoryTotals = {};
    Map<String, int> serviceTypeCounts = {};

    for (var service in data) {
      final economicValue = _parseDouble(service['economic_value']);
      final beneficiaries = _parseInt(service['beneficiaries_count']);
      final category = _translateCategory(service['category']?.toString());
      final serviceType = _translateServiceType(service['service_type']?.toString());

      totalEconomicValue += economicValue;
      totalBeneficiaries += beneficiaries;
      
      categoryTotals[category] = (categoryTotals[category] ?? 0) + economicValue;
      serviceTypeCounts[serviceType] = (serviceTypeCounts[serviceType] ?? 0) + 1;
    }

    return RefreshIndicator(
      onRefresh: _loadQuarterlyData,
      color: const Color(0xFF2E7D32),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _buildSummaryCard(
              quarter,
              totalEconomicValue,
              totalBeneficiaries,
              data.length,
            ),
            const SizedBox(height: 16),

            // Category breakdown
            _buildCategoryBreakdown(categoryTotals),
            const SizedBox(height: 16),

            // Service type distribution
            _buildServiceTypeDistribution(serviceTypeCounts),
            const SizedBox(height: 16),

            // Detailed list
            _buildDetailedList(data),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    int quarter,
    double totalValue,
    int totalBeneficiaries,
    int itemCount,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getQuarterName(quarter),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white54, height: 24),
            _buildSummaryRow(
              'มูลค่าเศรษฐกิจรวม',
              '${_formatCurrency(totalValue)} บาท',
              Icons.attach_money,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'จำนวนผู้รับผลประโยชน์',
              '${_formatNumber(totalBeneficiaries)} คน',
              Icons.people,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'จำนวนบริการทั้งหมด',
              '$itemCount รายการ',
              Icons.list_alt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> categoryTotals) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'แยกตามหมวดหมู่',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...categoryTotals.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      '${_formatCurrency(entry.value)} บาท',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeDistribution(Map<String, int> serviceTypeCounts) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'จำนวนบริการแยกตามประเภท',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...serviceTypeCounts.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value} รายการ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedList(List<Map<String, dynamic>> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'รายละเอียดทั้งหมด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...data.map((service) => _buildServiceItem(service)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final serviceName = service['service_name']?.toString() ?? 'ไม่ระบุชื่อ';
    final category = _translateCategory(service['category']?.toString());
    final economicValue = _parseDouble(service['economic_value']);
    final quantity = _parseDouble(service['quantity']);
    final unit = _translateUnit(service['unit']?.toString());
    final month = _parseInt(service['month']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getMonthName(month),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.category, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                category,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          if (quantity > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_formatNumber(quantity)} $unit',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${_formatCurrency(economicValue)} บาท',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    if (month >= 1 && month <= 12) {
      return months[month];
    }
    return '';
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)} ล้าน';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} พัน';
    }
    return value.toStringAsFixed(0);
  }

  String _formatNumber(dynamic value) {
    final num = value is int ? value : _parseInt(value);
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
