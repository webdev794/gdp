import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../models/address_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/mock_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_address_sheet.dart';
import '../../widgets/blinkit_map_widget.dart';

class LocationPickerScreen extends StatefulWidget {
  final Function(AddressModel) onAddressSelected;

  const LocationPickerScreen({super.key, required this.onAddressSelected});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late AddressModel _selectedAddress;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLocatingGPS = false;
  bool _isDetectingAutoLocation = true;
  bool _isSearchingApi = false;

  // Auto-Detected User Environment
  String _detectedCity = 'Miami';
  String _detectedCountry = 'United States';
  String _detectedFlag = '🇺🇸';

  List<AddressModel> _apiSuggestions = [];

  @override
  void initState() {
    super.initState();
    _selectedAddress = LocationService.activeAddress;
    _autoDetectUserCountryAndCity();
    // Saved addresses on the account (added on the website or in the app).
    if (MockAuthService.isLoggedIn) {
      ApiService.getAddresses().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Auto-Detect User's Current City & Country via Device GPS / GDP Geocode API
  Future<void> _autoDetectUserCountryAndCity() async {
    // 1. Mobile Hardware GPS (if location service enabled & permission already granted)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );

          // Query GDP Geocode Reverse API (/api/geocode/reverse)
          final rev = await ApiService.geocodeReverse(position.latitude, position.longitude);
          if (rev != null) {
            final String city = (rev['city'] ?? '').toString().isNotEmpty ? rev['city'].toString() : 'Current Location';
            final String state = (rev['state'] ?? '').toString();
            final String fullAddr = (rev['full'] ?? '$city, $state').toString();
            final String zip = (rev['postal_code'] ?? '00000').toString();
            final String line1 = (rev['line1'] ?? '').toString();

            AddressModel autoAddr = AddressModel(
              id: 'auto_gps_${DateTime.now().millisecondsSinceEpoch}',
              label: line1.isNotEmpty ? '📍 $line1, $city' : '📍 Current Location ($city)',
              fullAddress: fullAddr,
              city: city,
              state: state.isNotEmpty ? state : _detectedCountry,
              zipCode: zip,
              latitude: position.latitude,
              longitude: position.longitude,
              buildingName: line1.isNotEmpty ? line1 : null,
            );

            if (mounted) {
              setState(() {
                _detectedCity = city;
                _detectedCountry = state.isNotEmpty ? state : _detectedCountry;
                _isDetectingAutoLocation = false;
                _selectAddress(autoAddr);
              });
            }
            return;
          }
        }
      }
    } catch (_) {}

    // 2. IP-based initial city detection fallback (HTTPS ATS Compliant)
    try {
      http.Response res;
      try {
        res = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 3));
      } catch (_) {
        res = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 3));
      }

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);
        final double lat = ((data['latitude'] ?? data['lat']) as num).toDouble();
        final double lon = ((data['longitude'] ?? data['lon']) as num).toDouble();
        final String city = data['city'] ?? 'Miami';
        final String country = data['country_name'] ?? data['country'] ?? 'United States';
        final String countryCode = (data['country_code'] ?? data['countryCode'] ?? 'us').toString().toLowerCase();

        String flag = '🌍';
        if (countryCode == 'in') flag = '🇮🇳';
        if (countryCode == 'us') flag = '🇺🇸';
        if (countryCode == 'gb' || countryCode == 'uk') flag = '🇬🇧';
        if (countryCode == 'ca') flag = '🇨🇦';

        // Refine with GDP Geocode Reverse API
        String fullAddress = '$city, $country';
        String zip = (data['postal'] ?? data['zip'] ?? '00000').toString();
        try {
          final rev = await ApiService.geocodeReverse(lat, lon);
          if (rev != null) {
            fullAddress = (rev['full'] ?? fullAddress).toString();
            if (rev['postal_code'] != null && rev['postal_code'].toString().isNotEmpty) {
              zip = rev['postal_code'].toString();
            }
          }
        } catch (_) {}

        AddressModel autoDetectedAddr = AddressModel(
          id: 'auto_detected_${DateTime.now().millisecondsSinceEpoch}',
          label: 'Current Region ($city, ${countryCode.toUpperCase()} $flag)',
          fullAddress: fullAddress,
          city: city,
          state: country,
          zipCode: zip,
          latitude: lat,
          longitude: lon,
        );

        if (mounted) {
          setState(() {
            _detectedCity = city;
            _detectedCountry = country;
            _detectedFlag = flag;
            _isDetectingAutoLocation = false;
            _selectAddress(autoDetectedAddr);
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isDetectingAutoLocation = false);
    }
  }

  void _onSearchInputChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _apiSuggestions = [];
        _isSearchingApi = false;
      });
      return;
    }

    setState(() => _isSearchingApi = true);

    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _fetchDynamicLocations(query.trim());
    });
  }

  // Building, Landmark, Mall, Hospital & House High-Accuracy Search Engine
  // Powered by GDP Unified Geocode API (/api/geocode/search) with coordinate biasing
  Future<void> _fetchDynamicLocations(String query) async {
    if (query.trim().isEmpty) return;

    String cleanQ = query.trim();
    List<AddressModel> parsedList = [];
    Set<String> seenAddresses = {};

    try {
      // Query GDP Unified Geocode API (/api/geocode/search) biased to current map position
      final backendHits = await ApiService.geocodeSearch(
        cleanQ,
        lat: _selectedAddress.latitude,
        lng: _selectedAddress.longitude,
      );

      for (int i = 0; i < backendHits.length; i++) {
        final hit = backendHits[i];
        final double lat = double.tryParse(hit['lat']?.toString() ?? '') ?? 0.0;
        final double lon = double.tryParse(hit['lon']?.toString() ?? '') ?? 0.0;
        final String full = hit['full'] ?? hit['label'] ?? cleanQ;

        if (seenAddresses.contains(full)) continue;
        seenAddresses.add(full);

        final String label = hit['label'] ?? hit['line1'] ?? cleanQ;
        final String city = hit['city'] ?? _detectedCity;
        final String state = hit['state'] ?? _detectedCountry;
        final String postalCode = hit['postal_code'] ?? '00000';
        final String line1 = hit['line1'] ?? '';

        String titleLabel = line1.isNotEmpty
            ? '📍 $line1, $city'
            : (label.isNotEmpty ? '📍 $label' : '📍 $city');

        parsedList.add(
          AddressModel(
            id: 'gdp_geo_${DateTime.now().millisecondsSinceEpoch}_$i',
            label: titleLabel,
            fullAddress: full,
            city: city.isNotEmpty ? city : _detectedCity,
            state: state.isNotEmpty ? state : _detectedCountry,
            zipCode: postalCode,
            latitude: lat,
            longitude: lon,
            buildingName: line1.isNotEmpty ? line1 : null,
          ),
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _apiSuggestions = parsedList;
        _isSearchingApi = false;
      });
    }
  }

  // Reverse Geocoding when Draggable Map Pin moves (GDP /api/geocode/reverse API)
  Future<void> _onMapPinDragged(double newLat, double newLng) async {
    try {
      final rev = await ApiService.geocodeReverse(newLat, newLng);
      if (rev != null) {
        String city = (rev['city'] ?? '').toString();
        String state = (rev['state'] ?? '').toString();
        String fullAddr = (rev['full'] ?? rev['label'] ?? 'Custom Location').toString();
        String zip = (rev['postal_code'] ?? '00000').toString();
        String line1 = (rev['line1'] ?? '').toString();

        if (city.isEmpty) city = _detectedCity;
        if (state.isEmpty) state = _detectedCountry;

        AddressModel draggedAddr = AddressModel(
          id: 'drag_${DateTime.now().millisecondsSinceEpoch}',
          label: line1.isNotEmpty ? '📍 $line1, $city' : '📍 Pinned: $city',
          fullAddress: fullAddr,
          city: city,
          state: state,
          zipCode: zip,
          latitude: newLat,
          longitude: newLng,
          buildingName: line1.isNotEmpty ? line1 : null,
        );

        if (!mounted) return;
        _selectAddress(draggedAddr);
        return;
      }
    } catch (_) {}

    AddressModel rawAddr = AddressModel(
      id: 'drag_raw_${DateTime.now().millisecondsSinceEpoch}',
      label: 'Pinned Custom Coordinates',
      fullAddress: 'Lat: ${newLat.toStringAsFixed(4)}, Lng: ${newLng.toStringAsFixed(4)}',
      city: _detectedCity,
      state: _detectedCountry,
      zipCode: '00000',
      latitude: newLat,
      longitude: newLng,
    );
    if (!mounted) return;
    _selectAddress(rawAddr);
  }

  // Detect Live GPS Location on Mobile Devices (Using Geolocator + GDP Geocode Reverse API)
  Future<void> _useCurrentGPSLocation() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() => _isLocatingGPS = true);

    // 1. Mobile Hardware GPS (matches navigator.geolocation.getCurrentPosition in GDP web app)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable GPS / Location services in your device settings.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is denied. Please allow location access in your device settings.'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        } else if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );

          // 2. Call GDP Reverse Geocode API (/api/geocode/reverse)
          final revData = await ApiService.geocodeReverse(position.latitude, position.longitude);

          String city = 'Current Location';
          String state = '';
          String fullAddr = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
          String zip = '00000';
          String line1 = '';

          if (revData != null) {
            city = (revData['city'] ?? '').toString();
            state = (revData['state'] ?? '').toString();
            fullAddr = (revData['full'] ?? revData['label'] ?? fullAddr).toString();
            zip = (revData['postal_code'] ?? '00000').toString();
            line1 = (revData['line1'] ?? '').toString();
            if (city.isEmpty) city = _detectedCity;
          }

          AddressModel gpsAddr = AddressModel(
            id: 'gps_${DateTime.now().millisecondsSinceEpoch}',
            label: line1.isNotEmpty ? '📍 $line1, $city' : '📍 Current Location ($city)',
            fullAddress: fullAddr,
            city: city,
            state: state.isNotEmpty ? state : _detectedCountry,
            zipCode: zip,
            latitude: position.latitude,
            longitude: position.longitude,
            buildingName: line1.isNotEmpty ? line1 : null,
          );

          if (!mounted) return;
          setState(() {
            _isLocatingGPS = false;
            _selectAddress(gpsAddr);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 GPS Location Detected: $city (${gpsAddr.distanceKm.toStringAsFixed(1)} km away)'),
              backgroundColor: gpsAddr.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
            ),
          );
          return;
        }
      }
    } catch (_) {}

    // Fallback: If hardware GPS is not available (e.g. desktop/emulator or permission declined), use HTTPS IP + GDP geocode reverse
    try {
      http.Response ipRes;
      try {
        ipRes = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 3));
      } catch (_) {
        ipRes = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 3));
      }

      if (ipRes.statusCode == 200) {
        final Map<String, dynamic> ipData = json.decode(ipRes.body);
        final double lat = ((ipData['latitude'] ?? ipData['lat']) as num).toDouble();
        final double lon = ((ipData['longitude'] ?? ipData['lon']) as num).toDouble();
        String city = ipData['city'] ?? ipData['country_name'] ?? 'Unknown City';
        String country = ipData['country_name'] ?? ipData['country'] ?? '';

        final revData = await ApiService.geocodeReverse(lat, lon);
        String fullAddr = '$city, $country';
        if (revData != null) {
          fullAddr = (revData['full'] ?? revData['label'] ?? fullAddr).toString();
          if (revData['city'] != null && revData['city'].toString().isNotEmpty) {
            city = revData['city'].toString();
          }
          if (revData['state'] != null && revData['state'].toString().isNotEmpty) {
            country = revData['state'].toString();
          }
        }

        AddressModel fallbackAddr = AddressModel(
          id: 'ip_loc_${DateTime.now().millisecondsSinceEpoch}',
          label: 'Detected Region ($city)',
          fullAddress: fullAddr,
          city: city,
          state: country,
          zipCode: (ipData['postal'] ?? ipData['zip'] ?? '00000').toString(),
          latitude: lat,
          longitude: lon,
        );

        if (!mounted) return;
        setState(() {
          _isLocatingGPS = false;
          _selectAddress(fallbackAddr);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location Detected: $city (${fallbackAddr.distanceKm.toStringAsFixed(1)} km away)'),
            backgroundColor: fallbackAddr.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
          ),
        );
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isLocatingGPS = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not determine current location. Please search your address.'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _selectAddress(AddressModel addr) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAddress = addr;
      LocationService.setActiveAddress(addr);
    });
    widget.onAddressSelected(addr);
  }

  void _openAddAddressSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAddressSheet(
        initialAddressLine: _selectedAddress.fullAddress,
        city: _selectedAddress.city,
        state: _selectedAddress.state,
        zipCode: _selectedAddress.zipCode,
        latitude: _selectedAddress.latitude,
        longitude: _selectedAddress.longitude,
        onAddressSaved: (savedAddr) {
          setState(() => _selectAddress(savedAddr));
        },
      ),
    );
  }

  void _confirmAndProceedHome() {
    HapticFeedback.heavyImpact();
    if (!_selectedAddress.isDeliverable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Service Not Available Yet for ${_selectedAddress.city} (${_selectedAddress.distanceKm.toStringAsFixed(1)} km away). Please pick a location within ${LocationService.maxDeliveryRadiusKm.toStringAsFixed(0)} km of our store.',
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    _selectAddress(_selectedAddress);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Address Confirmed! Delivering to ${_selectedAddress.city} in ${_selectedAddress.deliveryMinutes} mins ⚡',
        ),
        backgroundColor: AppTheme.emeraldPrimary,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isTypingSearch = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Choose your location'),
      ),
      body: Column(
        children: [
          // Top Search & GPS Container with Dropdown Suggestions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Region Chip Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.emeraldPrimary.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Text(_detectedFlag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isDetectingAutoLocation
                              ? 'Detecting your current region...'
                              : 'Auto-Detected Region: $_detectedCity, $_detectedCountry',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.emeraldPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Input Field (Supports Building, Mall, Hospital, Society, Landmark & House #)
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchInputChanged,
                  decoration: InputDecoration(
                    hintText: 'Search building, mall, hospital, society, street, or city...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.emeraldPrimary),
                    suffixIcon: _isSearchingApi
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldPrimary)),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchInputChanged('');
                                },
                              )
                            : null,
                  ),
                ),

                // INSTANT LIVE SEARCH SUGGESTIONS DROPDOWN CARD (Right under TextField!)
                if (isTypingSearch) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.emeraldPrimary, width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: AppTheme.sageLight,
                            child: Row(
                              children: [
                                const Icon(Icons.travel_explore, size: 14, color: AppTheme.emeraldPrimary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Matching Places for "${_searchController.text.trim()}" (${_apiSuggestions.length})',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _isSearchingApi && _apiSuggestions.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldPrimary)),
                                      SizedBox(width: 10),
                                      Text('Searching buildings & places...', style: TextStyle(fontSize: 12, color: AppTheme.slateMuted)),
                                    ],
                                  ),
                                )
                              : _apiSuggestions.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'No matching places found. Check spelling or try broader name.',
                                        style: TextStyle(fontSize: 12, color: AppTheme.slateMuted),
                                      ),
                                    )
                                  : Flexible(
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: _apiSuggestions.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final addr = _apiSuggestions[index];
                                          bool isSelected = addr.id == _selectedAddress.id;

                                          return ListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                            leading: Icon(
                                              addr.buildingName != null && addr.buildingName!.isNotEmpty
                                                  ? Icons.domain
                                                  : (addr.isDeliverable ? Icons.location_on : Icons.public_off),
                                              color: addr.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                                              size: 20,
                                            ),
                                            title: Text(
                                              addr.label,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                                color: AppTheme.slateDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              addr.fullAddress,
                                              style: const TextStyle(fontSize: 10.5, color: AppTheme.slateMuted),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${addr.distanceKm.toStringAsFixed(1)} km',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w900,
                                                    color: addr.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                                                  ),
                                                ),
                                                Text(
                                                  addr.isDeliverable ? '⚡ AVAILABLE' : '🚫 >15 KM',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w900,
                                                    color: addr.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            onTap: () {
                                              FocusScope.of(context).unfocus();
                                              _selectAddress(addr);
                                              _searchController.clear();
                                              setState(() => _apiSuggestions = []);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // GPS Detect Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _isLocatingGPS ? null : _useCurrentGPSLocation,
                    icon: _isLocatingGPS
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldPrimary))
                        : const Icon(Icons.my_location, color: AppTheme.emeraldPrimary, size: 18),
                    label: Text(
                      _isLocatingGPS ? 'Detecting Real GPS Location...' : 'Use My Current Location 🎯',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.emeraldPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppTheme.sageLight.withAlpha(120),
                      side: const BorderSide(color: AppTheme.emeraldPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BLINKIT INTERACTIVE MAP WIDGET WITH DRAGGABLE PIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Interactive Map Location',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldPrimary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app, size: 12, color: AppTheme.emeraldPrimary),
                            SizedBox(width: 4),
                            Text('Drag Map to Move Pin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.emeraldPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  BlinkitMapWidget(
                    initialLat: _selectedAddress.latitude,
                    initialLng: _selectedAddress.longitude,
                    locationTitle: _selectedAddress.label,
                    fullAddress: _selectedAddress.fullAddress,
                    onPinDragEnd: (newLat, newLng) {
                      _onMapPinDragged(newLat, newLng);
                    },
                  ),
                  const SizedBox(height: 16),

                  // SELECTED LOCATION STATUS & STRUCTURED DETAILS CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedAddress.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_selectedAddress.tagIcon, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAddress.displayHeadline,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _selectedAddress.isDeliverable ? AppTheme.sageLight : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_selectedAddress.distanceKm.toStringAsFixed(1)} KM Away',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: _selectedAddress.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedAddress.fullAddress,
                          style: const TextStyle(color: AppTheme.slateMuted, fontSize: 11.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedAddress.buildingName != null && _selectedAddress.buildingName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🏢 Building / Place: ${_selectedAddress.buildingName}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.emeraldPrimary),
                          ),
                        ],
                        if (_selectedAddress.landmark != null && _selectedAddress.landmark!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '📍 Landmark: ${_selectedAddress.landmark}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldPrimary),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // Deliverable Banner vs Service Not Available
                        if (_selectedAddress.isDeliverable)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.sageLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, color: AppTheme.emeraldPrimary, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Delivery Available! Arrives in ${_selectedAddress.deliveryMinutes} Mins ⚡',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.emeraldPrimary),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.errorRed.withAlpha(120)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Service Not Available Yet 🚫',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.errorRed),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_selectedAddress.city} is ${_selectedAddress.distanceKm.toStringAsFixed(1)} km away. We deliver within ${LocationService.maxDeliveryRadiusKm.toStringAsFixed(0)} km of our store.',
                                        style: const TextStyle(fontSize: 10.5, color: AppTheme.errorRed),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Button to enter House/Flat No. & Landmark
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: _openAddAddressSheet,
                            icon: const Icon(Icons.edit_location_alt, size: 18, color: AppTheme.emeraldPrimary),
                            label: const Text(
                              '+ Add House No, Floor & Landmark 🏠',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppTheme.emeraldPrimary),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.emeraldPrimary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SAVED ADDRESSES MANAGER (Home 🏠, Work 💼, Other 📍)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Addresses',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                      ),
                      TextButton.icon(
                        onPressed: _openAddAddressSheet,
                        icon: const Icon(Icons.add, size: 16, color: AppTheme.emeraldPrimary),
                        label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.emeraldPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (LocationService.userAddresses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: !MockAuthService.isLoggedIn
                          ? const Text('Sign in to see the addresses saved on your account.',
                              style: TextStyle(fontSize: 12.5, color: AppTheme.slateMuted))
                          : ApiService.addressesError != null
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Text(ApiService.addressesError!,
                                          style: const TextStyle(fontSize: 12.5, color: AppTheme.errorRed)),
                                    ),
                                    TextButton(
                                      onPressed: () => ApiService.getAddresses().then((_) {
                                        if (mounted) setState(() {});
                                      }),
                                      child: const Text('RETRY'),
                                    ),
                                  ],
                                )
                              : const Text('No saved addresses yet.',
                                  style: TextStyle(fontSize: 12.5, color: AppTheme.slateMuted)),
                    ),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: LocationService.userAddresses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final addr = LocationService.userAddresses[index];
                      bool isSelected = addr.id == _selectedAddress.id;

                      return GestureDetector(
                        onTap: () => _selectAddress(addr),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppTheme.emeraldPrimary : AppTheme.borderSubtle,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(addr.tagIcon, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          addr.tag.toUpperCase(),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            addr.displayHeadline,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                              color: AppTheme.slateDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      addr.fullAddress,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.slateMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${addr.distanceKm.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: addr.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Confirm Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _confirmAndProceedHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedAddress.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.emeraldPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedAddress.isDeliverable
                          ? 'CONFIRM LOCATION (${_selectedAddress.distanceKm.toStringAsFixed(1)} KM) ➔'
                          : 'OUTSIDE DELIVERY AREA (${LocationService.maxDeliveryRadiusKm.toStringAsFixed(0)} KM)',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
