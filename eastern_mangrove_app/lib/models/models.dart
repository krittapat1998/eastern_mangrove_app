class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;
  final String? phoneNumber;
  final bool isActive;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.phoneNumber,
    this.isActive = true,
    this.isApproved = true,
    this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      userType: json['userType'] ?? json['user_type'],
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      isApproved: json['isApproved'] ?? json['is_approved'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'isApproved': isApproved,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';
}

class Community {
  final int id;
  final String communityName;
  final String? villageName;
  final String? subDistrict;
  final String? district;
  final String? province;
  final String? contactPerson;
  final String? phone;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String registrationStatus;
  final DateTime createdAt;

  Community({
    required this.id,
    required this.communityName,
    this.villageName,
    this.subDistrict,
    this.district,
    this.province,
    this.contactPerson,
    this.phone,
    this.description,
    this.latitude,
    this.longitude,
    required this.registrationStatus,
    required this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'],
      communityName: json['community_name'],
      villageName: json['village_name'],
      subDistrict: json['sub_district'],
      district: json['district'],
      province: json['province'],
      contactPerson: json['contact_person'],
      phone: json['phone'],
      description: json['description'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      registrationStatus: json['registration_status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_name': communityName,
      'village_name': villageName,
      'sub_district': subDistrict,
      'district': district,
      'province': province,
      'contact_person': contactPerson,
      'phone': phone,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'registration_status': registrationStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class EconomicData {
  final int id;
  final int communityId;
  final int year;
  final int quarter;
  final double? incomeFishery;
  final double? incomeTourism;
  final double? incomeAgriculture;
  final double? incomeOthers;
  final double totalIncome;
  final int? employmentCount;
  final String? notes;
  final DateTime createdAt;

  EconomicData({
    required this.id,
    required this.communityId,
    required this.year,
    required this.quarter,
    this.incomeFishery,
    this.incomeTourism,
    this.incomeAgriculture,
    this.incomeOthers,
    required this.totalIncome,
    this.employmentCount,
    this.notes,
    required this.createdAt,
  });

  factory EconomicData.fromJson(Map<String, dynamic> json) {
    return EconomicData(
      id: json['id'],
      communityId: json['community_id'],
      year: json['year'],
      quarter: json['quarter'],
      incomeFishery: json['income_fishery']?.toDouble(),
      incomeTourism: json['income_tourism']?.toDouble(),
      incomeAgriculture: json['income_agriculture']?.toDouble(),
      incomeOthers: json['income_others']?.toDouble(),
      totalIncome: json['total_income']?.toDouble() ?? 0.0,
      employmentCount: json['employment_count'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PollutionReport {
  final int id;
  final int communityId;
  final String reportType;
  final String pollutionSource;
  final String severityLevel;
  final String description;
  final double? latitude;
  final double? longitude;
  final DateTime reportDate;
  final String status;
  final List<String> photos;
  final DateTime createdAt;

  PollutionReport({
    required this.id,
    required this.communityId,
    required this.reportType,
    required this.pollutionSource,
    required this.severityLevel,
    required this.description,
    this.latitude,
    this.longitude,
    required this.reportDate,
    required this.status,
    required this.photos,
    required this.createdAt,
  });

  factory PollutionReport.fromJson(Map<String, dynamic> json) {
    return PollutionReport(
      id: json['id'],
      communityId: json['community_id'],
      reportType: json['report_type'],
      pollutionSource: json['pollution_source'],
      severityLevel: json['severity_level'],
      description: json['description'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      reportDate: DateTime.parse(json['report_date']),
      status: json['status'],
      photos: List<String>.from(json['photos'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': username, // Use email for login
      'password': password,
    };
  }
}

class CommunityRegistrationRequest {
  final String communityName;
  final String location;
  final String contactPerson;
  final String phoneNumber;
  final String email;
  final String password;
  final String? description;
  final int? establishedYear;
  final int? memberCount;
  final String? photoType;

  CommunityRegistrationRequest({
    required this.communityName,
    required this.location,
    required this.contactPerson,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.description,
    this.establishedYear,
    this.memberCount,
    this.photoType,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'communityName': communityName,
      'location': location,
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
      'email': email,
      'password': password,
    };
    
    // Only include optional fields if they have values
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (establishedYear != null) {
      map['establishedYear'] = establishedYear;
    }
    if (memberCount != null) {
      map['memberCount'] = memberCount;
    }
    if (photoType != null && photoType!.isNotEmpty) {
      map['photoType'] = photoType;
    }
    
    return map;
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data, String message) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(
      success: false,
      message: '',
      error: error,
    );
  }
}