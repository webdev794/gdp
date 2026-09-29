import 'dart:math';
import '../models/address_model.dart';
import '../models/config_model.dart';

class LocationService {
  // Store locations come from GET /api/config (Admin -> Stores). Defaults: the main store.
  static double storeLat = 6.53189;
  static double storeLng = -10.349486;
  static String storeName = 'Tudee Shopping Center';
  static String storeAddress = 'Kakatown Highway, Margibi County, Kakata, Liberia';
  static double maxDeliveryRadiusKm = 25.0;
  static List<StoreModel> stores = [];
  static bool enforceRadius = true;

  static void updateStoreFromConfig(AppConfigModel config) {
    enforceRadius = config.enforceRadius;
    if (config.stores.isNotEmpty) {
      stores = List.of(config.stores);
      final s = config.stores.first;
      storeLat = s.latitude;
      storeLng = s.longitude;
      storeName = s.name;
      maxDeliveryRadiusKm = s.deliveryRadiusKm.toDouble();
    }
  }

  /// The store nearest to a point (the one the store API would serve it from).
  static StoreModel? nearestStore(double lat, double lng) {
    StoreModel? best;
    double bestKm = double.infinity;
    for (final s in stores) {
      final km = calculateDistanceKm(lat, lng, s.latitude, s.longitude);
      if (km < bestKm) {
        bestKm = km;
        best = s;
      }
    }
    return best;
  }

  // Haversine formula to calculate distance in KM
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Inside the delivery radius of its nearest store (when Admin enforces radius).
  static bool isDeliverable(double distanceKm, {double? radiusKm}) {
    if (!enforceRadius) return true;
    return distanceKm <= (radiusKm ?? maxDeliveryRadiusKm);
  }

  static int calculateDeliveryMinutes(double distanceKm) {
    if (!isDeliverable(distanceKm)) return 0;
    return (8 + (distanceKm * 2.0)).round(); // 8 mins prep + 2 mins/km
  }

  /// The customer's saved addresses, loaded from the store (GET /api/addresses).
  static final List<AddressModel> userAddresses = [];

  /// Shown until the customer picks or saves a real delivery address.
  static final AddressModel noAddress = AddressModel(
    id: '',
    label: 'Choose delivery address',
    fullAddress: 'Choose a delivery address',
    city: '',
    state: '',
    zipCode: '',
    latitude: storeLat,
    longitude: storeLng,
    tag: 'Other',
  );

  static bool get hasAddress => activeAddress.id.isNotEmpty;

  static AddressModel activeAddress = noAddress;

  static void addAddress(AddressModel newAddress) {
    userAddresses.insert(0, newAddress);
    activeAddress = newAddress;
  }

  static void setActiveAddress(AddressModel address) {
    activeAddress = address;
  }

  static void removeAddress(String id) {
    userAddresses.removeWhere((addr) => addr.id == id);
    if (activeAddress.id == id) {
      activeAddress = userAddresses.isNotEmpty ? userAddresses.first : noAddress;
    }
  }
}
