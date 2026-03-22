import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class EconomicDataScreenNew extends StatefulWidget {
  const EconomicDataScreenNew({super.key});

  @override
  State<EconomicDataScreenNew> createState() => _EconomicDataScreenNewState();
}

class _EconomicDataScreenNewState extends State<EconomicDataScreenNew> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _communityData;

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

  @override
  void initState() {
    super.initState();
    _loadCommunityProfile();
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

  // Helper function to safely parse int
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper function to parse location string (e.g., "ตำบลบางปู อำเภอเมือง จังหวัดสมุทรปราการ")
  Map<String, String> _parseLocation(String location) {
    final result = <String, String>{};
    
    // Parse sub-district (ตำบล)
    final subDistrictMatch = RegExp(r'ตำบล([^\s]+)').firstMatch(location);
    if (subDistrictMatch != null) {
      result['subDistrict'] = subDistrictMatch.group(1) ?? '';
    }
    
    // Parse district (อำเภอ)
    final districtMatch = RegExp(r'อำเภอ([^\s]+)').firstMatch(location);
    if (districtMatch != null) {
      result['district'] = districtMatch.group(1) ?? '';
    }
    
    // Parse province (จังหวัด)
    final provinceMatch = RegExp(r'จังหวัด([^\s]+)').firstMatch(location);
    if (provinceMatch != null) {
      result['province'] = provinceMatch.group(1) ?? '';
    }
    
    return result;
  }

  // Helper function to extract village name from community name
  // e.g., "ชุมชนอนุรักษ์ป่าชายเลนบางปู" -> "บ้านบางปู"
  String _extractVillageName(String communityName) {
    // Try to extract the last word which is usually the location name
    final patterns = [
      RegExp(r'บ้าน([ก-๙]+)$'),  // "บ้านXXX"
      RegExp(r'ชายเลน([ก-๙]+)$'),  // "ป่าชายเลนXXX"
      RegExp(r'เลน([ก-๙]+)$'),  // "เลนXXX"
      RegExp(r'([ก-๙]+)$'),  // Last Thai word
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(communityName);
      if (match != null) {
        String extracted = match.group(1) ?? '';
        // If we extracted from "ป่าชายเลนXXX" or "เลนXXX", prefix with "บ้าน"
        if (pattern.pattern.contains('เลน') && !extracted.startsWith('บ้าน')) {
          return 'บ้าน$extracted';
        }
        // If it's just the last word and doesn't start with บ้าน, add it
        if (!extracted.startsWith('บ้าน')) {
          return 'บ้าน$extracted';
        }
        return extracted;
      }
    }
    return '';
  }

  Future<void> _loadCommunityProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getCommunityProfileData();
      
      // Debug: Print response to see what data we're getting
      print('📊 API Response Success: ${response.success}');
      print('📊 API Response Data: ${response.data}');
      
      if (response.success && response.data != null) {
        final community = response.data!['community'];
        print('📊 Community Data: $community');
        
        setState(() {
          _communityData = community;
          
          // Fill form with existing data (don't show 0, leave empty instead)
          _villageNameController.text = community['villageName']?.toString() ?? '';
          _subDistrictController.text = community['subDistrict']?.toString() ?? '';
          _districtController.text = community['district']?.toString() ?? '';
          _provinceController.text = community['province']?.toString() ?? '';
          
          // If village name is empty, try to extract from community name
          if (_villageNameController.text.isEmpty && community['name'] != null) {
            final extractedVillage = _extractVillageName(community['name'].toString());
            if (extractedVillage.isNotEmpty) {
              _villageNameController.text = extractedVillage;
            }
          }
          
          // If new fields are empty, try to parse from old 'location' field
          if (_subDistrictController.text.isEmpty && 
              _districtController.text.isEmpty && 
              _provinceController.text.isEmpty &&
              community['location'] != null) {
            final locationParts = _parseLocation(community['location'].toString());
            if (locationParts.isNotEmpty) {
              _subDistrictController.text = locationParts['subDistrict'] ?? '';
              _districtController.text = locationParts['district'] ?? '';
              _provinceController.text = locationParts['province'] ?? '';
            }
          }
          
          // Only show numbers if they're greater than 0
          final areaSize = _parseDouble(community['areaSize']);
          _areaSizeController.text = areaSize > 0 ? areaSize.toString() : '';
          
          final totalPopulation = _parseInt(community['totalPopulation']);
          _totalPopulationController.text = totalPopulation > 0 ? totalPopulation.toString() : '';
          
          final resourceDependent = _parseInt(community['resourceDependentPopulation']);
          _resourceDependentController.text = resourceDependent > 0 ? resourceDependent.toString() : '';
          
          final households = _parseInt(community['households']);
          _householdsController.text = households > 0 ? households.toString() : '';
          
          final avgIncome = _parseDouble(community['averageIncome']);
          _averageIncomeController.text = avgIncome > 0 ? avgIncome.toString() : '';
          
          _selectedMainOccupation = community['mainOccupation']?.toString() ?? '';
          _selectedMainReligion = community['mainReligion']?.toString() ?? '';
          
          if (community['occupations'] != null && community['occupations'] is List) {
            _selectedOccupations = List<String>.from(community['occupations']);
          }
          
          _isLoading = false;
          
          // Show info if data is still empty after parsing
          if (_villageNameController.text.isEmpty && 
              _totalPopulationController.text.isEmpty &&
              _subDistrictController.text.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('พบข้อมูลบางส่วน กรุณากรอกข้อมูลเพิ่มเติม'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Load community profile error: $e');
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = {
        'villageName': _villageNameController.text.trim(),
        'subDistrict': _subDistrictController.text.trim(),
        'district': _districtController.text.trim(),
        'province': _provinceController.text.trim(),
        'areaSize': double.tryParse(_areaSizeController.text.trim()) ?? 0.0,
        'totalPopulation': int.tryParse(_totalPopulationController.text.trim()) ?? 0,
        'resourceDependentPopulation': int.tryParse(_resourceDependentController.text.trim()) ?? 0,
        'households': int.tryParse(_householdsController.text.trim()) ?? 0,
        'mainOccupation': _selectedMainOccupation,
        'mainReligion': _selectedMainReligion,
        'occupations': _selectedOccupations,
        'averageIncome': double.tryParse(_averageIncomeController.text.trim()) ?? 0.0,
      };

      final response = await _apiClient.updateCommunityProfile(profileData);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกข้อมูลสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadCommunityProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('ข้อมูลเศรษฐกิจสังคมชุมชน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCommunityProfile,
          ),
        ],
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
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCommunityProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

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
                        'เช่น บ้านบางปู',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'ตำบล *',
                        _subDistrictController,
                        'เช่น แหลมฉบัง',
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
                        'เช่น ศรีราชา',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        'จังหวัด *',
                        _provinceController.text,
                        ['ชลบุรี', 'ระยอง', 'จันทบุรี', 'ตราด', 'ฉะเชิงเทรา', 'ปราจีนบุรี', 'สระแก้ว'],
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
                onPressed: _isLoading ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
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

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
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
      padding: const EdgeInsets.all(20),
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
                child: Icon(icon, color: color, size: 24),
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
          const SizedBox(height: 20),
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
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelectField() {
    final occupations = ['ประมง', 'เกษตรกรรม', 'ท่องเที่ยว', 'ค้าขาย', 'รับจ้าง', 'อื่นๆ'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'อาชีพที่มีในชุมชน (เลือกได้มากกว่า 1)',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: occupations.map((occupation) {
            final isSelected = _selectedOccupations.contains(occupation);
            return FilterChip(
              label: Text(occupation),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedOccupations.add(occupation);
                  } else {
                    _selectedOccupations.remove(occupation);
                  }
                });
              },
              selectedColor: const Color(0xFF2E7D32).withOpacity(0.3),
              checkmarkColor: const Color(0xFF2E7D32),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
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
