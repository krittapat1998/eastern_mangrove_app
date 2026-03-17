import 'package:flutter/material.dart';

class EconomicDataScreen extends StatefulWidget {
  const EconomicDataScreen({super.key});

  @override
  State<EconomicDataScreen> createState() => _EconomicDataScreenState();
}

class _EconomicDataScreenState extends State<EconomicDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _villageNameController = TextEditingController();
  final _subDistrictController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController();
  final _areaSizeController = TextEditingController();
  final _totalPopulationController = TextEditingController();
  final _resourceDependentController = TextEditingController();
  final _householdsController = TextEditingController();
  final _averageIncomeController = TextEditingController();

  String _selectedMainOccupation = '';
  String _selectedMainReligion = '';
  List<String> _selectedOccupations = [];

  // Existing Community Data (Demo)
  final List<CommunityEconomicData> _economicDataList = [
    CommunityEconomicData(
      id: 'ECO001',
      villageName: 'บ้านปลา',
      subDistrict: 'ธนาคารปู',
      district: 'วัดบน',
      province: 'ระเอง',
      areaSize: 250.5,
      totalPopulation: 324,
      resourceDependentPopulation: 180,
      households: 85,
      mainOccupation: 'ประมง',
      mainReligion: 'พุทธ',
      occupations: ['ประมง', 'เกษตรกรรม', 'ค้าขาย'],
      averageIncome: 18500,
      lastUpdated: DateTime(2024, 2, 28),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExistingData();
  }

  void _loadExistingData() {
    if (_economicDataList.isNotEmpty) {
      final data = _economicDataList.first;
      _villageNameController.text = data.villageName;
      _subDistrictController.text = data.subDistrict;
      _districtController.text = data.district;
      _provinceController.text = data.province;
      _areaSizeController.text = data.areaSize.toString();
      _totalPopulationController.text = data.totalPopulation.toString();
      _resourceDependentController.text = data.resourceDependentPopulation.toString();
      _householdsController.text = data.households.toString();
      _averageIncomeController.text = data.averageIncome.toString();
      _selectedMainOccupation = data.mainOccupation;
      _selectedMainReligion = data.mainReligion;
      _selectedOccupations = List.from(data.occupations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('ข้อมูลเศรษฐกิจสังคมชุมชน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'ข้อมูลชุมชน', icon: Icon(Icons.info)),
            Tab(text: 'สถิติและแผนภูมิ', icon: Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDataFormTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildDataFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Information Section
            _buildSectionCard(
              'ข้อมูลที่ตั้งและขนาด',
              Icons.location_on,
              Colors.blue,
              [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'ชื่อหมู่บ้าน *',
                        _villageNameController,
                        'เช่น บ้านปลา',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'ตำบล *',
                        _subDistrictController,
                        'เช่น ธนาคารปู',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'อำเภอ *',
                        _districtController,
                        'เช่น วัดบน',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        'จังหวัด *',
                        _provinceController.text,
                        ['ระเอง', 'สัตหีบ', 'ระยอง', 'จันทบุรี', 'ตราด'],
                        (value) => setState(() => _provinceController.text = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'ขนาดพื้นที่ชุมชน (ไร่)',
                  _areaSizeController,
                  'เช่น 250.5',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Population Information Section
            _buildSectionCard(
              'ข้อมูลประชากร',
              Icons.groups,
              Colors.orange,
              [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'จำนวนคนในชุมชน (คน)',
                        _totalPopulationController,
                        'เช่น 324',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'จำนวนครัวเรือน',
                        _householdsController,
                        'เช่น 85',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'จำนวนคนที่พึ่งพิงทรัพยากรป่าชายเลน (คน)',
                  _resourceDependentController,
                  'เช่น 180',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  'ศาสนาหลัก',
                  _selectedMainReligion,
                  ['พุทธ', 'อิสลาม', 'คริสต์', 'อื่นๆ'],
                  (value) => setState(() => _selectedMainReligion = value!),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Occupation Information Section
            _buildSectionCard(
              'ข้อมูลอาชีพและรายได้',
              Icons.work,
              Colors.teal,
              [
                _buildDropdownField(
                  'อาชีพหลัก',
                  _selectedMainOccupation,
                  ['ประมง', 'เกษตรกรรม', 'ท่องเที่ยว', 'ค้าขาย', 'รับจ้าง', 'อื่นๆ'],
                  (value) => setState(() => _selectedMainOccupation = value!),
                ),
                const SizedBox(height: 16),
                _buildMultiSelectField(),
                const SizedBox(height: 16),
                _buildTextField(
                  'รายได้เฉลี่ยต่อครัวเรือน (บาท/เดือน)',
                  _averageIncomeController,
                  'เช่น 18500',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'บันทึกข้อมูล',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_economicDataList.isEmpty) {
      return const Center(
        child: Text(
          'ยังไม่มีข้อมูลสำหรับแสดงสถิติ\nกรุณาบันทึกข้อมูลในแท็บแรก',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final data = _economicDataList.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'จำนวนประชากร',
                  '${data.totalPopulation} คน',
                  Icons.groups,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'พึ่งพิงทรัพยากร',
                  '${data.resourceDependentPopulation} คน',
                  Icons.eco,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'จำนวนครัวเรือน',
                  '${data.households} ครัวเรือน',
                  Icons.home,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'ขนาดพื้นที่',
                  '${data.areaSize} ไร่',
                  Icons.map,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Percentage Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'เปอร์เซ็นต์การพึ่งพิงทรัพยากร',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${((data.resourceDependentPopulation / data.totalPopulation) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${data.resourceDependentPopulation} จาก ${data.totalPopulation} คน',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Occupation Distribution
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
                  'การกระจายอาชีพในชุมชน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...data.occupations.map((occupation) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getOccupationColor(occupation),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(occupation),
                    ],
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Income Information
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
                  'ข้อมูลรายได้',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'รายได้เฉลี่ยต่อครัวเรือน',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${data.averageIncome.toStringAsFixed(0)} บาท/เดือน',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'รายได้รวมของชุมชนประมาณ ${(data.averageIncome * data.households).toStringAsFixed(0)} บาท/เดือน',
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'กรุณากรอก${label.replaceAll(' *', '')}';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value.isNotEmpty ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'อาชีพอื่นๆ ในชุมชน',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['ประมง', 'เกษตรกรรม', 'ท่องเที่ยว', 'ค้าขาย', 'รับจ้าง', 'อื่นๆ']
              .map((occupation) => FilterChip(
                    label: Text(occupation),
                    selected: _selectedOccupations.contains(occupation),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedOccupations.add(occupation);
                        } else {
                          _selectedOccupations.remove(occupation);
                        }
                      });
                    },
                    selectedColor: Colors.green.withOpacity(0.2),
                    checkmarkColor: Colors.green,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            textAlign: TextAlign.center,
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

  Color _getOccupationColor(String occupation) {
    switch (occupation) {
      case 'ประมง':
        return Colors.blue;
      case 'เกษตรกรรม':
        return Colors.green;
      case 'ท่องเที่ยว':
        return Colors.orange;
      case 'ค้าขาย':
        return Colors.purple;
      case 'รับจ้าง':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      // Update existing data or create new
      if (_economicDataList.isNotEmpty) {
        final data = _economicDataList.first;
        data.villageName = _villageNameController.text;
        data.subDistrict = _subDistrictController.text;
        data.district = _districtController.text;
        data.province = _provinceController.text;
        data.areaSize = double.tryParse(_areaSizeController.text) ?? 0;
        data.totalPopulation = int.tryParse(_totalPopulationController.text) ?? 0;
        data.resourceDependentPopulation = int.tryParse(_resourceDependentController.text) ?? 0;
        data.households = int.tryParse(_householdsController.text) ?? 0;
        data.mainOccupation = _selectedMainOccupation;
        data.mainReligion = _selectedMainReligion;
        data.occupations = List.from(_selectedOccupations);
        data.averageIncome = double.tryParse(_averageIncomeController.text) ?? 0;
        data.lastUpdated = DateTime.now();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลเศรษฐกิจสังคมสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to statistics tab to show updated data
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _villageNameController.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _areaSizeController.dispose();
    _totalPopulationController.dispose();
    _resourceDependentController.dispose();
    _householdsController.dispose();
    _averageIncomeController.dispose();
    super.dispose();
  }
}

class CommunityEconomicData {
  String villageName;
  String subDistrict;
  String district;
  String province;
  double areaSize;
  int totalPopulation;
  int resourceDependentPopulation;
  int households;
  String mainOccupation;
  String mainReligion;
  List<String> occupations;
  double averageIncome;
  DateTime lastUpdated;
  final String id;

  CommunityEconomicData({
    required this.id,
    required this.villageName,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.areaSize,
    required this.totalPopulation,
    required this.resourceDependentPopulation,
    required this.households,
    required this.mainOccupation,
    required this.mainReligion,
    required this.occupations,
    required this.averageIncome,
    required this.lastUpdated,
  });
}