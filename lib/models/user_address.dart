class UserAddress {
  final int id;
  final int userId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String? ward;
  final String? district;
  final String city;
  final String? postalCode;
  final bool isDefault;
  final String addressType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserAddress({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    this.ward,
    this.district,
    required this.city,
    this.postalCode,
    this.isDefault = false,
    this.addressType = 'home',
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor để tạo từ JSON
  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      addressLine1: json['address_line1'] as String,
      addressLine2: json['address_line2'] as String?,
      ward: json['ward'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String,
      postalCode: json['postal_code'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      addressType: json['address_type'] as String? ?? 'home',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'ward': ward,
      'district': district,
      'city': city,
      'postal_code': postalCode,
      'is_default': isDefault,
      'address_type': addressType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to JSON for insert/update (without id, timestamps)
  Map<String, dynamic> toJsonForInsert() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'ward': ward,
      'district': district,
      'city': city,
      'postal_code': postalCode,
      'is_default': isDefault,
      'address_type': addressType,
    };
  }

  // Tạo copy với các thay đổi
  UserAddress copyWith({
    int? id,
    int? userId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? ward,
    String? district,
    String? city,
    String? postalCode,
    bool? isDefault,
    String? addressType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      addressType: addressType ?? this.addressType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Lấy địa chỉ đầy đủ
  String get fullAddress {
    final parts = <String>[];
    
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city.isNotEmpty) parts.add(city);
    
    return parts.join(', ');
  }

  // Lấy địa chỉ ngắn gọn
  String get shortAddress {
    final parts = <String>[];
    
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city.isNotEmpty) parts.add(city);
    
    return parts.join(', ');
  }

  // Lấy icon cho loại địa chỉ
  String get addressTypeIcon {
    switch (addressType.toLowerCase()) {
      case 'home':
        return '🏠';
      case 'office':
        return '🏢';
      case 'other':
        return '📍';
      default:
        return '📍';
    }
  }

  // Lấy tên loại địa chỉ
  String get addressTypeName {
    switch (addressType.toLowerCase()) {
      case 'home':
        return 'Nhà riêng';
      case 'office':
        return 'Văn phòng';
      case 'other':
        return 'Khác';
      default:
        return 'Khác';
    }
  }

  @override
  String toString() {
    return 'UserAddress(id: $id, fullName: $fullName, phone: $phone, fullAddress: $fullAddress, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAddress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
