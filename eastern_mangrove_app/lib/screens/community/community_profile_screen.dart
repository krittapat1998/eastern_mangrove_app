import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../data/thai_address_data.dart';

class CommunityProfileScreen extends StatefulWidget {
  const CommunityProfileScreen({super.key});

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isEditing = false;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;

  // Form Controllers - Basic Info
  final _communityNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Location Info
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubDistrict;
  String _postalCode = '';
  final _villageNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaSizeController = TextEditingController();
  
  // Contact Info
  final _contactPersonController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  final _socialMediaController = TextEditingController();
  
  // Community Info
  final _establishedYearController = TextEditingController();
  final _memberCountController = TextEditingController();
  final _totalPopulationController = TextEditingController();
  final _resourceDependentPopulationController = TextEditingController();
  final _householdsController = TextEditingController();
  final _mainOccupationController = TextEditingController();
  final _mainReligionController = TextEditingController();
  final _averageIncomeController = TextEditingController();
  
  // Mangrove Info
  final _mangroveSpeciesController = TextEditingController();
  final _conservationStatusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    // Basic Info
    _communityNameController.dispose();
    _descriptionController.dispose();
    // Location
    _villageNameController.dispose();
    _locationController.dispose();
    _areaSizeController.dispose();
    // Contact
    _contactPersonController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _websiteUrlController.dispose();
    _socialMediaController.dispose();
    // Community
    _establishedYearController.dispose();
    _memberCountController.dispose();
    _totalPopulationController.dispose();
    _resourceDependentPopulationController.dispose();
    _householdsController.dispose();
    _mainOccupationController.dispose();
    _mainReligionController.dispose();
    _averageIncomeController.dispose();
    // Mangrove
    _mangroveSpeciesController.dispose();
    _conservationStatusController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getCommunityProfileData();
      
      if (response.success && response.data != null) {
        final profile = response.data!;
        final communityData = profile['community'] ?? profile;
        
        setState(() {
          _profileData = communityData;
          _populateForm(communityData);
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

  void _populateForm(Map<String, dynamic> data) {
    // Helper to safely convert any value (including List) to String
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is List) return value.join(', ');
      return value.toString();
    }

    // Basic Info
    _communityNameController.text = safeString(data['name']);
    _descriptionController.text = safeString(data['description']);
    
    // Location
    final province = safeString(data['province']);
    final district = safeString(data['district']);
    final subDistrict = safeString(data['subDistrict']);
    _selectedProvince = ThaiAddressData.provinces.contains(province) ? province : null;
    _selectedDistrict = _selectedProvince != null &&
        ThaiAddressData.getDistricts(_selectedProvince!).contains(district)
        ? district : null;
    if (_selectedProvince != null && _selectedDistrict != null) {
      final subList = ThaiAddressData.getSubDistricts(_selectedProvince!, _selectedDistrict!);
      final match = subList.where((s) => s.name == subDistrict).toList();
      _selectedSubDistrict = match.isNotEmpty ? subDistrict : null;
      _postalCode = match.isNotEmpty ? match.first.postalCode : '';
    } else {
      _selectedSubDistrict = null;
      _postalCode = '';
    }
    _villageNameController.text = safeString(data['villageName']);
    _locationController.text = safeString(data['location']);
    _areaSizeController.text = data['areaSize']?.toString() ?? '';
    
    // Contact
    _contactPersonController.text = safeString(data['contactPerson']);
    _phoneNumberController.text = safeString(data['phoneNumber']);
    _emailController.text = safeString(data['email']);
    _websiteUrlController.text = safeString(data['websiteUrl']);
    _socialMediaController.text = safeString(data['socialMedia']);
    
    // Community
    _establishedYearController.text = data['establishedYear']?.toString() ?? '';
    _memberCountController.text = data['memberCount']?.toString() ?? '';
    _totalPopulationController.text = data['totalPopulation']?.toString() ?? '';
    _resourceDependentPopulationController.text = data['resourceDependentPopulation']?.toString() ?? '';
    _householdsController.text = data['households']?.toString() ?? '';
    _mainOccupationController.text = safeString(data['mainOccupation']);
    _mainReligionController.text = safeString(data['mainReligion']);
    _averageIncomeController.text = data['averageIncome']?.toString() ?? '';
    
    // Mangrove
    _mangroveSpeciesController.text = safeString(data['mangroveSpecies']);
    _conservationStatusController.text = safeString(data['conservationStatus']);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = {
        // Basic Info
        'name': _communityNameController.text,
        'description': _descriptionController.text,
        
        // Location
        'province': _selectedProvince ?? '',
        'district': _selectedDistrict ?? '',
        'subDistrict': _selectedSubDistrict ?? '',
        'villageName': _villageNameController.text,
        'location': _locationController.text,
        'areaSize': double.tryParse(_areaSizeController.text),
        
        // Contact
        'contactPerson': _contactPersonController.text,
        'phoneNumber': _phoneNumberController.text,
        'email': _emailController.text,
        'websiteUrl': _websiteUrlController.text,
        'socialMedia': _socialMediaController.text,
        
        // Community
        'establishedYear': int.tryParse(_establishedYearController.text),
        'memberCount': int.tryParse(_memberCountController.text),
        'totalPopulation': int.tryParse(_totalPopulationController.text),
        'resourceDependentPopulation': int.tryParse(_resourceDependentPopulationController.text),
        'households': int.tryParse(_householdsController.text),
        'mainOccupation': _mainOccupationController.text,
        'mainReligion': _mainReligionController.text,
        'averageIncome': double.tryParse(_averageIncomeController.text),
        
        // Mangrove
        'mangroveSpecies': _mangroveSpeciesController.text,
        'conservationStatus': _conservationStatusController.text,
      };

      print('🔄 Updating profile with data: $updateData');
      final response = await _apiClient.updateCommunityProfile(updateData);
      print('📡 Update response: success=${response.success}, error=${response.error}');
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัพเดตข้อมูลสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }
        setState(() {
          _isEditing = false;
        });
        await _loadProfile();
      } else {
        final errMsg = response.error ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่';
        print('❌ Update failed: $errMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบบัญชี', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีนี้?\n\nข้อมูลทั้งหมดจะถูกลบอย่างถาวรและไม่สามารถกู้คืนได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.deleteAccount();
      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบบัญชีสำเร็จ'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'เกิดข้อผิดพลาด'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('โปรไฟล์ชุมชน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'แก้ไขข้อมูล',
            )
          else if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  if (_profileData != null) {
                    _populateForm(_profileData!);
                  }
                });
              },
              tooltip: 'ยกเลิก',
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
              onPressed: _loadProfile,
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

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Basic Info
                  _buildSectionTitle('ข้อมูลพื้นฐาน', Icons.info),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _communityNameController,
                    label: 'ชื่อชุมชน',
                    icon: Icons.home,
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกชื่อชุมชน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'รายละเอียดชุมชน',
                    icon: Icons.description,
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  
                  // Section 2: Location Info
                  const SizedBox(height: 32),
                  _buildSectionTitle('ข้อมูลที่ตั้ง', Icons.place),
                  const SizedBox(height: 16),
                  _buildLocationFields(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _villageNameController,
                    label: 'ชื่อหมู่บ้าน',
                    icon: Icons.home_work,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'ที่อยู่เต็ม',
                    icon: Icons.place,
                    enabled: _isEditing,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _areaSizeController,
                    label: 'ขนาดพื้นที่ (ไร่)',
                    icon: Icons.landscape,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                  
                  // Section 3: Contact Info
                  const SizedBox(height: 32),
                  _buildSectionTitle('ข้อมูลติดต่อ', Icons.contact_page),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _contactPersonController,
                    label: 'ผู้ติดต่อ',
                    icon: Icons.person,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneNumberController,
                    label: 'เบอร์โทรศัพท์',
                    icon: Icons.phone,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[0-9\-]+$').hasMatch(value)) {
                          return 'กรุณากรอกเบอร์โทรศัพท์ที่ถูกต้อง';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'อีเมล',
                    icon: Icons.email,
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'กรุณากรอกอีเมลที่ถูกต้อง';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _websiteUrlController,
                    label: 'เว็บไซต์',
                    icon: Icons.language,
                    enabled: _isEditing,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _socialMediaController,
                    label: 'โซเชียลมีเดีย (Facebook, Line, etc.)',
                    icon: Icons.share,
                    enabled: _isEditing,
                    maxLines: 2,
                  ),
                  
                  // Section 4: Community Info
                  const SizedBox(height: 32),
                  _buildSectionTitle('ข้อมูลชุมชน', Icons.people),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _establishedYearController,
                          label: 'ปีที่ก่อตั้ง (พ.ศ.)',
                          icon: Icons.calendar_today,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _memberCountController,
                          label: 'จำนวนสมาชิก',
                          icon: Icons.groups,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _totalPopulationController,
                          label: 'จำนวนประชากรทั้งหมด',
                          icon: Icons.people_alt,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _householdsController,
                          label: 'จำนวนครัวเรือน',
                          icon: Icons.house,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _resourceDependentPopulationController,
                    label: 'ประชากรที่พึ่งพาทรัพยากร',
                    icon: Icons.nature_people,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _mainOccupationController,
                          label: 'อาชีพหลัก',
                          icon: Icons.work,
                          enabled: _isEditing,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _mainReligionController,
                          label: 'ศาสนาหลัก',
                          icon: Icons.temple_buddhist,
                          enabled: _isEditing,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _averageIncomeController,
                    label: 'รายได้เฉลี่ย (บาท/เดือน)',
                    icon: Icons.attach_money,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                  
                  // Section 5: Mangrove Info
                  const SizedBox(height: 32),
                  _buildSectionTitle('ข้อมูลป่าชายเลน', Icons.eco),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _mangroveSpeciesController,
                    label: 'ชนิดพันธุ์ไม้ป่าชายเลน',
                    icon: Icons.forest,
                    enabled: _isEditing,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _conservationStatusController,
                    label: 'สถานะการอนุรักษ์',
                    icon: Icons.park,
                    enabled: _isEditing,
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 32),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'บันทึกการเปลี่ยนแปลง',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _showDeleteAccountDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text(
                        'ลบบัญชี',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.account_circle,
              size: 60,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _communityNameController.text.isNotEmpty
                ? _communityNameController.text
                : 'ชุมชน',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (_locationController.text.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.place, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _locationController.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    if (!_isEditing) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyLocationField(
                  label: 'จังหวัด',
                  value: _selectedProvince ?? '',
                  icon: Icons.location_city,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyLocationField(
                  label: 'อำเภอ',
                  value: _selectedDistrict ?? '',
                  icon: Icons.location_on,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyLocationField(
                  label: 'ตำบล',
                  value: _selectedSubDistrict ?? '',
                  icon: Icons.my_location,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyLocationField(
                  label: 'รหัสไปรษณีย์',
                  value: _postalCode,
                  icon: Icons.markunread_mailbox,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Edit mode: cascading dropdowns
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: InputDecoration(
            labelText: 'จังหวัด',
            prefixIcon: const Icon(Icons.location_city, color: Color(0xFF2E7D32)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: ThaiAddressData.provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedProvince = value;
              _selectedDistrict = null;
              _selectedSubDistrict = null;
              _postalCode = '';
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedDistrict,
          decoration: InputDecoration(
            labelText: 'อำเภอ',
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _selectedProvince == null
              ? []
              : ThaiAddressData.getDistricts(_selectedProvince!)
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
          onChanged: _selectedProvince == null
              ? null
              : (value) {
                  setState(() {
                    _selectedDistrict = value;
                    _selectedSubDistrict = null;
                    _postalCode = '';
                  });
                },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedSubDistrict,
          decoration: InputDecoration(
            labelText: 'ตำบล',
            prefixIcon: const Icon(Icons.my_location, color: Color(0xFF2E7D32)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: (_selectedProvince == null || _selectedDistrict == null)
              ? []
              : ThaiAddressData.getSubDistricts(_selectedProvince!, _selectedDistrict!)
                  .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
                  .toList(),
          onChanged: (_selectedProvince == null || _selectedDistrict == null)
              ? null
              : (value) {
                  final subList = ThaiAddressData.getSubDistricts(
                      _selectedProvince!, _selectedDistrict!);
                  final selected = subList.firstWhere((s) => s.name == value);
                  setState(() {
                    _selectedSubDistrict = value;
                    _postalCode = selected.postalCode;
                  });
                },
        ),
        const SizedBox(height: 16),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: _postalCode),
          decoration: InputDecoration(
            labelText: 'รหัสไปรษณีย์',
            hintText: _postalCode.isEmpty ? 'กรอกอัตโนมัติเมื่อเลือกตำบล' : null,
            prefixIcon: const Icon(Icons.markunread_mailbox, color: Color(0xFF2E7D32)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyLocationField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      isEmpty: value.isEmpty,
      child: Text(
        value,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? const Color(0xFF2E7D32) : Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: enabled ? const Color(0xFF2E7D32) : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey.shade600,
      ),
    );
  }
}
