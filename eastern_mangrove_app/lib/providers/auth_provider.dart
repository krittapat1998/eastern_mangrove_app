import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && _apiClient.isLoggedIn;

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Check if user is already logged in (from saved token)
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    
    try {
      if (_apiClient.isLoggedIn) {
        // Verify token with backend
        final response = await _apiClient.verifyToken();
        
        if (response.success) {
          // Get user profile
          final profileResponse = await _apiClient.getUserProfile();
          
          if (profileResponse.success && profileResponse.data != null) {
            final userData = profileResponse.data!['user'];
            _user = User(
              id: userData['id'],
              email: userData['email'],
              firstName: userData['firstName'] ?? userData['first_name'],
              lastName: userData['lastName'] ?? userData['last_name'],
              userType: userData['userType'] ?? userData['user_type'],
              phoneNumber: userData['phoneNumber'] ?? userData['phone_number'],
              isApproved: true, // Assuming logged in users are approved
            );
            
            // Save user data locally
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_data', userData.toString());
          }
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
      // Clear invalid token
      await _logout();
    } finally {
      _setLoading(false);
    }
  }

  // Login method
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final request = LoginRequest(username: email, password: password); // Using email as username
      final response = await _apiClient.login(request);

      if (response.success && response.data != null) {
        final userData = response.data!['user'];
        _user = User(
          id: userData['id'],
          email: userData['email'],
          firstName: userData['firstName'] ?? userData['first_name'],
          lastName: userData['lastName'] ?? userData['last_name'],
          userType: userData['userType'] ?? userData['user_type'],
          phoneNumber: userData['phoneNumber'] ?? userData['phone_number'],
          isApproved: true, // Assuming successful login means approved
        );
        
        // Save user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', userData.toString());
        
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'เข้าสู่ระบบไม่สำเร็จ');
        return false;
      }
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register community method
  Future<bool> registerCommunity({
    required String communityName,
    required String location,
    required String contactPerson,
    required String phoneNumber,
    required String email,
    required String password,
    String? description,
    int? establishedYear,
    int? memberCount,
    String? photoType,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final request = CommunityRegistrationRequest(
        communityName: communityName,
        location: location,
        contactPerson: contactPerson,  
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        description: description,
        establishedYear: establishedYear,
        memberCount: memberCount,
        photoType: photoType ?? 'community',
      );

      final response = await _apiClient.registerCommunity(request);

      if (response.success) {
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'ลงทะเบียนชุมชนไม่สำเร็จ');
        return false;
      }
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // User registration method
  Future<bool> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiClient.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        userType: userType,
        phoneNumber: phoneNumber,
      );

      if (response.success && response.data != null) {
        final userData = response.data!['user'];
        _user = User(
          id: userData['id'],
          email: userData['email'],
          firstName: userData['firstName'] ?? userData['first_name'],
          lastName: userData['lastName'] ?? userData['last_name'],
          userType: userData['userType'] ?? userData['user_type'],
          phoneNumber: userData['phoneNumber'] ?? userData['phone_number'],
          isApproved: true,
        );
        
        // Save user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', userData.toString());
        
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'ลงทะเบียนไม่สำเร็จ');
        return false;
      }
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Internal logout helper
  Future<void> _logout() async {
    try {
      await _apiClient.logout();
    } catch (e) {
      // Ignore logout errors
    }
    
    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    
    _user = null;
    _error = null;
    
    notifyListeners();
  }

  // Logout method
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _logout();
    } catch (e) {
      _setError('ออกจากระบบไม่สำเร็จ: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get user role
  String? get userRole => _user?.userType;

  // Check if user is admin
  bool get isAdmin => _user?.userType == 'admin';

  // Check if user is community
  bool get isCommunity => _user?.userType == 'community';

  // Check if user is public
  bool get isPublic => _user?.userType == 'public';

  // Check if community account is approved
  bool get isCommunityApproved => _user?.isApproved ?? false;
}