import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiClient {
  // Auto-detect: Use IP for real device, localhost for simulator/web
  static String get baseUrl {
    // For web or development
    const bool isWeb = bool.fromEnvironment('dart.library.js_util');
    if (isWeb) {
      return 'http://localhost:3002/api';
    }
    
    // For iOS/Android real device - use Mac IP
    // To find your Mac IP: ifconfig | grep "inet " | grep -v 127.0.0.1
    if (Platform.isIOS || Platform.isAndroid) {
      return 'http://192.168.1.42:3002/api';
    }
    
    // Fallback to localhost
    return 'http://localhost:3002/api';
  }
  
  String? _token;
  Future<void>? _tokenLoadFuture;
  
  ApiClient() {
    _tokenLoadFuture = _loadToken();
  }

  // Ensure token is loaded before making API calls
  Future<void> _ensureTokenLoaded() async {
    if (_tokenLoadFuture != null) {
      await _tokenLoadFuture;
      _tokenLoadFuture = null;
    }
  }

  // Load saved token from SharedPreferences
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  // Clear token from SharedPreferences
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  // Get headers with authentication
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          fromJson != null ? fromJson(data) : data as T,
          data['message'] ?? 'Success',
        );
      } else {
        return ApiResponse.error(
          data['error'] ?? data['message'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }

  // Handle HTTP errors
  ApiResponse<T> _handleError<T>(dynamic error) {
    if (error is SocketException) {
      return ApiResponse.error('No internet connection');
    } else if (error is HttpException) {
      return ApiResponse.error('HTTP error: ${error.message}');
    } else {
      return ApiResponse.error('Network error: $error');
    }
  }

  // Auth methods
  Future<ApiResponse<Map<String, dynamic>>> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          await _saveToken(data['data']['token']);
          return ApiResponse.success(data['data'], data['message'] ?? 'Login successful');
        } else {
          return ApiResponse.error(data['message'] ?? 'Login failed');
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? data['error'] ?? 'Login failed');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> registerCommunity(
    CommunityRegistrationRequest request,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-community'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Community registration submitted');
      } else {
        final data = json.decode(response.body);
        // Check if there are validation details
        if (data['details'] != null && data['details'] is List && data['details'].isNotEmpty) {
          final errors = (data['details'] as List)
              .map((e) => '${e['field']}: ${e['message']}')
              .join('\n');
          return ApiResponse.error(errors);
        }
        return ApiResponse.error(data['message'] ?? data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // User registration
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'userType': userType,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          await _saveToken(data['data']['token']);
          return ApiResponse.success(data['data'], data['message'] ?? 'Registration successful');
        } else {
          return ApiResponse.error(data['message'] ?? 'Registration failed');
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Profile fetched');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? data['error'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Verify token
  Future<ApiResponse<bool>> verifyToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify-token'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['success'] ?? true, data['message'] ?? 'Token valid');
      } else {
        await _clearToken();
        return ApiResponse.error('Invalid or expired token');
      }
    } catch (e) {
      await _clearToken();
      return _handleError(e);
    }
  }

  Future<ApiResponse<bool>> logout() async {
    try {
      if (_token != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _headers,
        );
        // Always clear token, regardless of response
        await _clearToken();
        
        if (response.statusCode == 200) {
          return ApiResponse.success(true, 'Logged out successfully');
        }
      }
      
      await _clearToken();
      return ApiResponse.success(true, 'Logged out successfully');
    } catch (e) {
      await _clearToken();
      return ApiResponse.success(true, 'Logged out successfully');
    }
  }

  // Community methods
  Future<ApiResponse<Map<String, dynamic>>> getCommunityProfileData() async {
    await _ensureTokenLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/community/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Profile fetched');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Community>> getCommunityProfile() async {
    await _ensureTokenLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/community/profile'),
        headers: _headers,
      );

      return _handleResponse(response, (data) => Community.fromJson(data['community']));
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCommunityProfile(Map<String, dynamic> profileData) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/community/profile'),
        headers: _headers,
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Profile updated');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<EconomicData>>> getEconomicData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/community/economic-data'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> economicDataList = data['economic_data'];
        final economicData = economicDataList
            .map((json) => EconomicData.fromJson(json))
            .toList();
        
        return ApiResponse.success(economicData, data['message'] ?? 'Success');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch economic data');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<PollutionReport>>> getPollutionReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/community/pollution-reports'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reportsList = data['reports'];
        final reports = reportsList
            .map((json) => PollutionReport.fromJson(json))
            .toList();
        
        return ApiResponse.success(reports, data['message'] ?? 'Success');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch pollution reports');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Admin methods
  
  // Get dashboard statistics
  Future<ApiResponse<Map<String, dynamic>>> getAdminDashboardStats() async {
    await _ensureTokenLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Success');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch dashboard stats');
      }
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // Get pending communities
  Future<ApiResponse<List<Map<String, dynamic>>>> getPendingCommunities() async {
    await _ensureTokenLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/communities/pending'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> communitiesList = data['data'] ?? [];
        
        return ApiResponse.success(
          communitiesList.cast<Map<String, dynamic>>(),
          data['message'] ?? 'Success',
        );
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch pending communities');
      }
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // Get all communities with filters
  Future<ApiResponse<Map<String, dynamic>>> getAllCommunities({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureTokenLoaded();
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final uri = Uri.parse('$baseUrl/admin/communities').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data, 'Success');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch communities');
      }
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // Get all users with filters
  Future<ApiResponse<Map<String, dynamic>>> getAllUsers({
    String? userType,
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    await _ensureTokenLoaded();
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (userType != null && userType != 'all') {
        queryParams['userType'] = userType;
      }
      
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final uri = Uri.parse('$baseUrl/admin/users').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data, 'Success');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Approve community registration
  Future<ApiResponse<Map<String, dynamic>>> approveCommunity(int communityId, {String? notes}) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/communities/$communityId/approve'),
        headers: _headers,
        body: json.encode({
          if (notes != null) 'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Community approved');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to approve community');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Reject community registration
  Future<ApiResponse<Map<String, dynamic>>> rejectCommunity(int communityId, {required String reason}) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/communities/$communityId/reject'),
        headers: _headers,
        body: json.encode({
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Community rejected');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to reject community');
      }
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // Toggle user active status
  Future<ApiResponse<Map<String, dynamic>>> toggleUserStatus(int communityId, {String? reason}) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/communities/$communityId/toggle-status'),
        headers: _headers,
        body: json.encode({
          if (reason != null) 'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'สถานะชุมชนถูกเปลี่ยนแล้ว');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'ไม่สามารถเปลี่ยนสถานะชุมชนได้');
      }
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // Get admin action logs
  Future<ApiResponse<Map<String, dynamic>>> getAdminActions({
    int page = 1,
    int limit = 50,
  }) async {
    await _ensureTokenLoaded();
    try {
      final uri = Uri.parse('$baseUrl/admin/actions').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data, 'Success');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch admin actions');
      }
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // Reset user password
  Future<ApiResponse<Map<String, dynamic>>> resetUserPassword(int userId, String newPassword) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/reset-password'),
        headers: _headers,
        body: json.encode({
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Password reset successfully');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      return _handleError(e);
    }
  }
  
  // Create new community
  Future<ApiResponse<Map<String, dynamic>>> createCommunity({
    required String communityName,
    required String location,
    required String contactPerson,
    required String phoneNumber,
    required String email,
    required String password,
    String? description,
    int? establishedYear,
    int? memberCount,
  }) async {
    await _ensureTokenLoaded();
    try {
      print('🔵 API: Creating community...');
      print('   URL: $baseUrl/admin/communities');
      print('   Token: ${_token != null ? "✅ มี (${_token!.substring(0, 20)}...)" : "❌ ไม่มี"}');
      print('   Data: communityName=$communityName, email=$email');
      
      final requestBody = {
        'communityName': communityName,
        'location': location,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
        if (description != null) 'description': description,
        if (establishedYear != null) 'establishedYear': establishedYear,
        if (memberCount != null) 'memberCount': memberCount,
      };
      
      print('   Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/communities'),
        headers: _headers,
        body: json.encode(requestBody),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ API: Community created successfully');
        return ApiResponse.success(data['data'], data['message'] ?? 'Community created successfully');
      } else {
        final data = json.decode(response.body);
        print('❌ API: Failed to create community - ${data['message']}');
        return ApiResponse.error(data['message'] ?? 'Failed to create community');
      }
    } catch (e) {
      print('💥 API: Exception in createCommunity - $e');
      return _handleError(e);
    }
  }

  // Check if community name or email already exists
  Future<ApiResponse<Map<String, dynamic>>> checkDuplicateCommunity({
    required String communityName,
    required String email,
  }) async {
    await _ensureTokenLoaded();
    try {
      print('🔍 API: Checking duplicate community...');
      print('   communityName: $communityName, email: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/communities/check-duplicate'),
        headers: _headers,
        body: json.encode({
          'communityName': communityName,
          'email': email,
        }),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data, data['message'] ?? '');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to check duplicate');
      }
    } catch (e) {
      print('💥 API: Exception in checkDuplicateCommunity - $e');
      return _handleError(e);
    }
  }
  
  // Update community information
  Future<ApiResponse<Map<String, dynamic>>> updateCommunity(
    int communityId, {
    String? communityName,
    String? location,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? description,
    int? establishedYear,
    int? memberCount,
  }) async {
    await _ensureTokenLoaded();
    try {
      final body = <String, dynamic>{};
      
      if (communityName != null) body['communityName'] = communityName;
      if (location != null) body['location'] = location;
      if (contactPerson != null) body['contactPerson'] = contactPerson;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (email != null) body['email'] = email;
      if (description != null) body['description'] = description;
      if (establishedYear != null) body['establishedYear'] = establishedYear;
      if (memberCount != null) body['memberCount'] = memberCount;
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/communities/$communityId'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Community updated successfully');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to update community');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteCommunity(int communityId) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/communities/$communityId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Community deleted successfully');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to delete community');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Public methods
  Future<ApiResponse<Map<String, dynamic>>> getPublicStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public/statistics'),
        headers: {'Content-Type': 'application/json'},
      );

      return _handleResponse(response, (data) => data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getPublicMangroveAreas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public/areas'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> areasList = data['data'];
        return ApiResponse.success(
          List<Map<String, dynamic>>.from(areasList),
          data['message'] ?? 'Success'
        );
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch mangrove areas');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Economic Data methods
  Future<ApiResponse<List<Map<String, dynamic>>>> getEconomicDataNew() async {
    await _ensureTokenLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/economic/data'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> dataList = data['data'];
        return ApiResponse.success(
          List<Map<String, dynamic>>.from(dataList),
          data['message'] ?? 'Success'
        );
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch economic data');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createEconomicData(Map<String, dynamic> dataMap) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/economic/data'),
        headers: _headers,
        body: json.encode(dataMap),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Economic data created');
      } else {
        final data = json.decode(response.body);
        String errorMessage = data['message'] ?? 'Failed to create economic data';
        
        // Improve error message for duplicate key
        if (errorMessage.contains('duplicate key') || errorMessage.contains('economic_data_unique')) {
          errorMessage = 'มีข้อมูลไตรมาสนี้อยู่แล้ว กรุณาเลือกไตรมาสอื่น หรือแก้ไขข้อมูลเดิม';
        }
        
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateEconomicData(int id, Map<String, dynamic> dataMap) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/economic/data/$id'),
        headers: _headers,
        body: json.encode(dataMap),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Economic data updated');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to update economic data');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<bool>> deleteEconomicData(int id) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/economic/data/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(true, data['message'] ?? 'Economic data deleted');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to delete economic data');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Ecosystem Services methods
  Future<ApiResponse<List<Map<String, dynamic>>>> getEcosystemServices() async {
    await _ensureTokenLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ecosystem/services'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> servicesList = data['data'];
        return ApiResponse.success(
          List<Map<String, dynamic>>.from(servicesList),
          data['message'] ?? 'Success'
        );
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch ecosystem services');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createEcosystemService(Map<String, dynamic> serviceMap) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ecosystem/services'),
        headers: _headers,
        body: json.encode(serviceMap),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Ecosystem service created');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to create ecosystem service');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateEcosystemService(int id, Map<String, dynamic> serviceMap) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/ecosystem/services/$id'),
        headers: _headers,
        body: json.encode(serviceMap),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Ecosystem service updated');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to update ecosystem service');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<bool>> deleteEcosystemService(int id) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/ecosystem/services/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(true, data['message'] ?? 'Ecosystem service deleted');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to delete ecosystem service');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Pollution Reports methods
  Future<ApiResponse<List<Map<String, dynamic>>>> getPollutionReportsNew() async {
    await _ensureTokenLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pollution/reports'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reportsList = data['data'];
        
        // Map English pollution types back to Thai for display
        final mappedReports = reportsList.map((report) {
          if (report['report_type'] != null) {
            report['report_type'] = _mapPollutionTypeToThai(report['report_type']);
          }
          return report as Map<String, dynamic>;
        }).toList();
        
        return ApiResponse.success(
          mappedReports,
          data['message'] ?? 'Success'
        );
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch pollution reports');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Map Thai pollution type to English for API
  static String _mapPollutionTypeToEnglish(String thaiType) {
    const Map<String, String> typeMap = {
      'มลพิษทางน้ำ': 'Water Pollution',
      'มลพิษทางอากาศ': 'Air Pollution',
      'ขยะชุมชน': 'Community Waste',
      'ขยะอุตสาหกรรม': 'Industrial Waste',
    };
    return typeMap[thaiType] ?? thaiType;
  }

  // Map English pollution type to Thai for display
  static String _mapPollutionTypeToThai(String englishType) {
    const Map<String, String> typeMap = {
      'Water Pollution': 'มลพิษทางน้ำ',
      'Air Pollution': 'มลพิษทางอากาศ',
      'Community Waste': 'ขยะชุมชน',
      'Industrial Waste': 'ขยะอุตสาหกรรม',
    };
    return typeMap[englishType] ?? englishType;
  }

  Future<ApiResponse<Map<String, dynamic>>> createPollutionReport(Map<String, dynamic> reportMap) async {
    await _ensureTokenLoaded();
    try {
      // Map Thai pollution type to English before sending to API
      if (reportMap['reportType'] != null) {
        reportMap['reportType'] = _mapPollutionTypeToEnglish(reportMap['reportType']);
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/pollution/reports'),
        headers: _headers,
        body: json.encode(reportMap),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Pollution report created');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to create pollution report');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updatePollutionReport(int id, Map<String, dynamic> reportMap) async {
    await _ensureTokenLoaded();
    try {
      // Map Thai pollution type to English before sending to API
      if (reportMap['reportType'] != null) {
        reportMap['reportType'] = _mapPollutionTypeToEnglish(reportMap['reportType']);
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/pollution/reports/$id'),
        headers: _headers,
        body: json.encode(reportMap),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Pollution report updated');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to update pollution report');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<bool>> deletePollutionReport(int id) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pollution/reports/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(true, data['message'] ?? 'Pollution report deleted');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to delete pollution report');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Mangrove Areas methods (Admin Only)
  Future<ApiResponse<List<Map<String, dynamic>>>> getMangroveAreas({String? province, String? search}) async {
    await _ensureTokenLoaded();
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (province != null && province.isNotEmpty) {
        queryParams['province'] = province;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('$baseUrl/admin/mangrove-areas').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> areasList = data['data'];
        
        return ApiResponse.success(
          areasList.map((area) => area as Map<String, dynamic>).toList(),
          data['message'] ?? 'Success'
        );
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch mangrove areas');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getMangroveArea(int id) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/mangrove-areas/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Success');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to fetch mangrove area');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createMangroveArea(Map<String, dynamic> areaMap) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/mangrove-areas'),
        headers: _headers,
        body: json.encode(areaMap),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Mangrove area created');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to create mangrove area');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateMangroveArea(int id, Map<String, dynamic> areaMap) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/mangrove-areas/$id'),
        headers: _headers,
        body: json.encode(areaMap),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'], data['message'] ?? 'Mangrove area updated');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to update mangrove area');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<bool>> deleteMangroveArea(int id) async {
    await _ensureTokenLoaded();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/mangrove-areas/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(true, data['message'] ?? 'Mangrove area deleted');
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Failed to delete mangrove area');
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Utility methods
  bool get isLoggedIn => _token != null;

  String? get token => _token;
}