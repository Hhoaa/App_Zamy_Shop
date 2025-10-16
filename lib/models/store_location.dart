class StoreLocation {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String hours;
  final String description;

  const StoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.hours,
    required this.description,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      phone: json['phone'] ?? '',
      hours: json['hours'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'hours': hours,
      'description': description,
    };
  }

  // Static data for the 3 stores
  static const List<StoreLocation> stores = [
    StoreLocation(
      id: 1,
      name: 'Cơ sở 1 - Chùa Bộc',
      address: '247 P.Chùa Bộc, Hà Nội',
      latitude: 21.0088986, // Approximate coordinates for Chùa Bộc area
      longitude: 105.8255635,
      phone: '024 1234 5678',
      hours: '8:00 - 22:00',
      description: 'Cửa hàng chính tại khu vực Chùa Bộc, Hà Nội',
    ),
    StoreLocation(
      id: 2,
      name: 'Cơ sở 2 - Nguyễn Trãi',
      address: '200 Nguyễn Trãi, Hà Nội',
      latitude: 20.9882416, // Approximate coordinates for Nguyễn Trãi area
      longitude: 105.7981473,
      phone: '024 2345 6789',
      hours: '8:00 - 22:00',
      description: 'Cửa hàng tại khu vực Nguyễn Trãi, Hà Nội',
    ),
    StoreLocation(
      id: 3,
      name: 'Cơ sở 3 - Cầu Giấy',
      address: '130 Cầu Giấy, Hà Nội',
      latitude: 21.0325264, // Approximate coordinates for Cầu Giấy area
      longitude: 105.7990348,
      phone: '024 3456 7890',
      hours: '8:00 - 22:00',
      description: 'Cửa hàng tại khu vực Cầu Giấy, Hà Nội',
    ),
  ];
}
