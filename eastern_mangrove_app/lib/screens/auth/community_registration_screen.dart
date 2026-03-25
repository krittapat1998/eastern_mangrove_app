import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../models/models.dart';
import '../../data/thai_address_data.dart';

class CommunityRegistrationScreen extends StatefulWidget {
  const CommunityRegistrationScreen({super.key});

  @override
  State<CommunityRegistrationScreen> createState() => _CommunityRegistrationScreenState();
}

class _CommunityRegistrationScreenState extends State<CommunityRegistrationScreen> {
  final _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  
  // Form Controllers
  final _communityNameController = TextEditingController();
  final _villageNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Address dropdowns
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubDistrict;
  String _postalCode = '';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'ลงทะเบียนชุมชนใหม่',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          for (int i = 0; i < 2; i++) ...[
                            _buildStepIndicator(i),
                            if (i < 1) _buildStepConnector(i),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
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
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentStep = index),
                      children: [
                        _buildStep1(), // ข้อมูลชุมชน
                        _buildStep2(), // ข้อมูลติดต่อและบัญชี
                      ],
                    ),
                  ),
                ),
              ),
              
              // Navigation Buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _previousStep(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('ย้อนกลับ'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _nextStep(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
                          : Text(_currentStep == 1 ? 'ส่งคำขอ' : 'ถัดไป'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex) {
    final isActive = stepIndex <= _currentStep;
    final isCompleted = stepIndex < _currentStep;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? Colors.orange : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Center(
        child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : Text(
              '${stepIndex + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isActive = stepIndex < _currentStep;
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.orange : Colors.orange.withOpacity(0.3),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลชุมชน',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'กรุณากรอกข้อมูลพื้นฐานของชุมชน',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 24),
          
          // Community Name
          TextFormField(
            controller: _communityNameController,
            decoration: InputDecoration(
              labelText: 'ชื่อชุมชน *',
              hintText: 'เช่น ชุมชนบ้านปลา',
              prefixIcon: const Icon(Icons.groups),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อนชื่อชุมชน';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Village Name
          TextFormField(
            controller: _villageNameController,
            decoration: InputDecoration(
              labelText: 'ชื่อหมู่บ้าน/พื้นที่ *',
              hintText: 'เช่น บ้านปลา ธนาคารปู',
              prefixIcon: const Icon(Icons.home),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อนชื่อหมู่บ้าน';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Province dropdown
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            decoration: InputDecoration(
              labelText: 'จังหวัด *',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
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
            validator: (value) =>
                value == null ? 'กรุณาเลือกจังหวัด' : null,
          ),

          const SizedBox(height: 20),

          // District dropdown
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: InputDecoration(
              labelText: 'อำเภอ *',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
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
            validator: (value) =>
                value == null ? 'กรุณาเลือกอำเภอ' : null,
          ),

          const SizedBox(height: 20),

          // Sub-district dropdown
          DropdownButtonFormField<String>(
            value: _selectedSubDistrict,
            decoration: InputDecoration(
              labelText: 'ตำบล *',
              prefixIcon: const Icon(Icons.place),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            items: (_selectedProvince == null || _selectedDistrict == null)
                ? []
                : ThaiAddressData.getSubDistricts(
                        _selectedProvince!, _selectedDistrict!)
                    .map((s) =>
                        DropdownMenuItem(value: s.name, child: Text(s.name)))
                    .toList(),
            onChanged: (_selectedProvince == null || _selectedDistrict == null)
                ? null
                : (value) {
                    final subList = ThaiAddressData.getSubDistricts(
                        _selectedProvince!, _selectedDistrict!);
                    final selected =
                        subList.firstWhere((s) => s.name == value);
                    setState(() {
                      _selectedSubDistrict = value;
                      _postalCode = selected.postalCode;
                    });
                  },
            validator: (value) =>
                value == null ? 'กรุณาเลือกตำบล' : null,
          ),

          const SizedBox(height: 20),

          // Postal code (auto-filled)
          TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'รหัสไปรษณีย์',
              hintText: _postalCode.isEmpty ? 'กรอกอัตโนมัติเมื่อเลือกตำบล' : _postalCode,
              prefixIcon: const Icon(Icons.markunread_mailbox),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            controller: TextEditingController(text: _postalCode),
          ),
          
          const SizedBox(height: 20),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'คำอธิบายเพิ่มเติมเกี่ยวกับชุมชน',
              hintText: 'เช่น กิจกรรมหลักของชุมชน, ความสำคัญของป่าชายเลน',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลติดต่อและบัญชี',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ข้อมูลผู้ติดต่อและสำหรับเข้าสู่ระบบ',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 24),
          
          // Contact Person
          TextFormField(
            controller: _contactPersonController,
            decoration: InputDecoration(
              labelText: 'ชื่อผู้ติดต่อ *',
              hintText: 'เช่น นายสมชาย ใจดี',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อนชื่อผู้ติดต่อ';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Phone
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'เบอร์โทรศัพท์ *',
              hintText: 'เช่น 081-234-5678',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อนเบอร์โทรศัพท์';
              }
              if (value.length < 10) {
                return 'เบอร์โทรศัพท์ไม่ถูกต้อง';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'อีเมล *',
              hintText: 'เช่น community@email.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อนอีเมล';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'รูปแบบอีเมลไม่ถูกต้อง เช่น example@email.com';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 32),
          
          // Separator
          const Divider(),
          const SizedBox(height: 20),
          
          const Text(
            'ข้อมูลบัญชีผู้ใช้',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Username
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'ชื่อผู้ใช้ *',
              hintText: 'เช่น community_banpla',
              prefixIcon: const Icon(Icons.account_circle),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อนชื่อผู้ใช้';
              }
              if (value.length < 4) {
                return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 4 ตัวอักษร';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'รหัสผ่าน *',
              hintText: 'อย่างน้อย 8 ตัวอักษร',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาป้อนรหัสผ่าน';
              }
              if (value.length < 8) {
                return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'ยืนยันรหัสผ่าน *',
              hintText: 'กรอกรหัสผ่านอีกครั้ง',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณายืนยันรหัสผ่าน';
              }
              if (value != _passwordController.text) {
                return 'รหัสผ่านไม่ตรงกัน';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    print('📝 _nextStep called, current step: $_currentStep');
    
    if (_currentStep == 0) {
      // Validate Step 1
      print('📋 Validating Step 1...');
      if (_communityNameController.text.isEmpty ||
          _villageNameController.text.isEmpty ||
          _selectedProvince == null ||
          _selectedDistrict == null ||
          _selectedSubDistrict == null) {
        print('❌ Step 1 validation failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      print('✅ Step 1 validation passed, moving to next page');
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 1) {
      // Validate Step 2 then submit
      print('📋 Validating Step 2...');
      if (!_formKey.currentState!.validate()) {
        print('❌ Step 2 validation failed');
        return;
      }
      print('✅ Step 2 validation passed, submitting...');
      _submitRegistration();
    }
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitRegistration() async {
    print('🚀 _submitRegistration started...');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Build location string from village, subdistrict, district, province
      final location = [
        _villageNameController.text.trim(),
        'ตำบล${_selectedSubDistrict ?? ''}',
        'อำเภอ${_selectedDistrict ?? ''}',
        'จังหวัด${_selectedProvince ?? ''}',
      ].where((s) => s.isNotEmpty && s != 'ตำบล' && s != 'อำเภอ' && s != 'จังหวัด').join(' ');

      print('📍 Location: $location');
      print('🏘️ Community Name: ${_communityNameController.text.trim()}');
      print('👤 Contact Person: ${_contactPersonController.text.trim()}');
      print('📞 Phone: ${_phoneController.text.trim()}');
      print('📧 Email: ${_emailController.text.trim()}');
      print('🔐 Password length: ${_passwordController.text.length} chars');

      // Create registration request
      final request = CommunityRegistrationRequest(
        communityName: _communityNameController.text.trim(),
        location: location,
        contactPerson: _contactPersonController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        establishedYear: null, // Can add year field if needed
        memberCount: null,     // Can add member count field if needed
        photoType: null,
      );

      print('📤 Sending request to API...');
      
      // Call API
      final response = await _apiClient.registerCommunity(request);

      print('📥 Response received: success=${response.success}');
      if (!response.success) {
        print('❌ Error: ${response.error}');
      }

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (response.success) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            title: const Text('ส่งคำขอเรียบร้อย!'),
            content: Text(
              response.message.isNotEmpty 
                  ? response.message 
                  : 'คำขอลงทะเบียนของคุณได้ถูกส่งไปยังเจ้าหน้าที่แล้ว\n\n'
                    'คุณจะได้รับการแจ้งเตือนผ่านอีเมลเมื่อได้รับการอนุมัติ'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => 
                      route.settings.name == '/' || route.isFirst);
                },
                child: const Text('กลับหน้าแรก'),
              ),
            ],
          ),
        );
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 60),
            title: const Text('เกิดข้อผิดพลาด'),
            content: Text(
              response.error ?? 'ไม่สามารถส่งคำขอลงทะเบียนได้ กรุณาลองใหม่อีกครั้ง'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Exception caught: $e');
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 60),
            title: const Text('เกิดข้อผิดพลาด'),
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _communityNameController.dispose();
    _villageNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}