import 'dart:math';
import '../models/address_model.dart';
import '../models/config_model.dart';

class LocationService {
  // Live Store Location: Caresort Solutions (loaded dynamically from /api/config)
  static double storeLat = 30.6908804;
  static double storeLng = 76.7114879;
  static String storeName = 'Tudee Shopping Center';
  static String storeAddress = 'Kakatown Highway, Margibi County, Kataka, Liberia';
  static double maxDeliveryRadiusKm = 25.0;

  static void updateStoreFromConfig(AppConfigModel config) {
    if (config.stores.isNotEmpty) {
      final s = config.stores.first;
      storeLat = s.latitude;
      storeLng = s.longitude;
      storeName = s.name;
      maxDeliveryRadiusKm = s.deliveryRadiusKm.toDouble();
    }
  }

  // Haversine formula to calculate distance in KM
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Universal Mode: All locations worldwide are eligible for delivery
  static bool isDeliverable(double distanceKm) {
    return true;
  }

  static int calculateDeliveryMinutes(double distanceKm) {
    if (distanceKm <= 10.0) {
      return (8 + (distanceKm * 1.5)).round().clamp(8, 25);
    }
    // Express delivery representation for testing worldwide locations
    return (10 + (distanceKm.toInt() % 12)).clamp(10, 20);
  }

  // Pre-populated Sample Saved Addresses with Blinkit Tags
  static final List<AddressModel> userAddresses = [
    AddressModel(
      id: 'addr_home_1',
      label: 'Home - Phase 8B',
      fullAddress: 'Plot No. C-205, Phase 8B, Industrial Area, Sector 74, Mohali, Punjab 160055',
      city: 'Mohali',
      state: 'Punjab',
      zipCode: '160055',
      latitude: 30.6908804,
      longitude: 76.7114879,
      isDefault: true,
      flatNo: 'Flat 402',
      floor: '4th Floor',
      buildingName: 'Tech Park View',
      landmark: 'Near Bestech Business Tower',
      tag: 'Home',
    ),
    AddressModel(
      id: 'addr_work_2',
      label: 'Office - Sector 62',
      fullAddress: 'Phase 7, Sector 62, Mohali, Punjab 160062',
      city: 'Mohali',
      state: 'Punjab',
      zipCode: '160062',
      latitude: 30.7046,
      longitude: 76.7179,
      flatNo: 'Cabin 12',
      floor: '2nd Floor',
      buildingName: 'Phase 7 Market Hub',
      landmark: 'Opp. Phase 7 Police Station',
      tag: 'Work',
    ),
    AddressModel(
      id: 'addr_other_3',
      label: 'Chandigarh Sector 35',
      fullAddress: 'SCO 120-122, Sector 35C, Chandigarh 160035',
      city: 'Chandigarh',
      state: 'Chandigarh',
      zipCode: '160035',
      latitude: 30.7259,
      longitude: 76.7681,
      flatNo: 'Shop 4',
      floor: 'Ground Floor',
      buildingName: 'Sub City Center',
      landmark: 'Near Aroma Hotel',
      tag: 'Other',
    ),
  ];

  static AddressModel activeAddress = userAddresses[0];

  static void addAddress(AddressModel newAddress) {
    userAddresses.insert(0, newAddress);
    activeAddress = newAddress;
  }

  static void setActiveAddress(AddressModel address) {
    activeAddress = address;
  }

  static void removeAddress(String id) {
    userAddresses.removeWhere((addr) => addr.id == id);
    if (activeAddress.id == id && userAddresses.isNotEmpty) {
      activeAddress = userAddresses.first;
    }
  }
}
