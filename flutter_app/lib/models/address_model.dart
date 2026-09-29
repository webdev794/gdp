import '../services/location_service.dart';

class AddressModel {
  final String id;
  final String label;
  final String fullAddress;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;
  final bool isDefault;

  // Blinkit Structured Address Fields
  final String? flatNo;
  final String? floor;
  final String? buildingName;
  final String? landmark;
  final String tag; // 'Home', 'Work', 'Other'

  final String? name;
  final String? line1;
  final String? line2;

  AddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    this.name,
    this.line1,
    this.line2,
    this.isDefault = false,
    this.flatNo,
    this.floor,
    this.buildingName,
    this.landmark,
    this.tag = 'Home',
  });

  double get distanceKm => LocationService.calculateDistanceKm(
        latitude,
        longitude,
        LocationService.storeLat,
        LocationService.storeLng,
      );

  bool get isDeliverable => LocationService.isDeliverable(distanceKm);

  int get deliveryMinutes => LocationService.calculateDeliveryMinutes(distanceKm);

  String get tagIcon {
    switch (tag.toLowerCase()) {
      case 'work':
        return '💼';
      case 'other':
        return '📍';
      case 'home':
      default:
        return '🏠';
    }
  }

  String get displayHeadline {
    if (flatNo != null && flatNo!.isNotEmpty) {
      if (buildingName != null && buildingName!.isNotEmpty) {
        return '$flatNo, $buildingName';
      }
      return '$flatNo, $label';
    }
    return label;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final line1 = json['line1']?.toString() ?? '';
    final line2 = json['line2']?.toString();
    final city = json['city']?.toString() ?? '';
    final state = json['state']?.toString() ?? '';
    final postalCode = json['postal_code']?.toString() ?? json['zip_code']?.toString() ?? '';
    final fullAddrParts = [line1, if (line2 != null && line2.isNotEmpty) line2, city, state, postalCode]
        .where((s) => s.isNotEmpty)
        .toList();
    final fullAddress = json['full_address']?.toString() ??
        (fullAddrParts.isNotEmpty ? fullAddrParts.join(', ') : 'Saved Address');

    final tag = json['label']?.toString() ?? json['tag']?.toString() ?? 'Home';
    final isDefault = json['is_default'] == true || json['is_default'] == 1 || json['is_default'] == '1';

    return AddressModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Home',
      name: json['name']?.toString() ?? '',
      line1: line1,
      line2: line2,
      fullAddress: fullAddress,
      city: city,
      state: state,
      zipCode: postalCode,
      latitude: (json['latitude'] as num?)?.toDouble() ?? LocationService.storeLat,
      longitude: (json['longitude'] as num?)?.toDouble() ?? LocationService.storeLng,
      isDefault: isDefault,
      flatNo: json['flat_no']?.toString(),
      floor: json['floor']?.toString(),
      buildingName: json['building_name']?.toString(),
      landmark: json['landmark']?.toString(),
      tag: tag,
    );
  }

  Map<String, dynamic> toBackendJson() => {
    'label': label.isNotEmpty ? label : 'Home',
    'name': name != null && name!.isNotEmpty ? name : 'Customer',
    'line1': line1 != null && line1!.isNotEmpty ? line1 : fullAddress,
    if (line2 != null && line2!.isNotEmpty) 'line2': line2,
    'city': city.isNotEmpty ? city : 'City',
    'state': state.isNotEmpty ? state : 'State',
    'postal_code': zipCode.isNotEmpty ? zipCode : '000000',
    'is_default': isDefault,
  };

  AddressModel copyWith({
    String? id,
    String? label,
    String? name,
    String? line1,
    String? line2,
    String? fullAddress,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? flatNo,
    String? floor,
    String? buildingName,
    String? landmark,
    String? tag,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      flatNo: flatNo ?? this.flatNo,
      floor: floor ?? this.floor,
      buildingName: buildingName ?? this.buildingName,
      landmark: landmark ?? this.landmark,
      tag: tag ?? this.tag,
    );
  }
}
