import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/address_model.dart';
import '../models/category_model.dart';
import '../models/config_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/support_model.dart';
import '../models/user_model.dart';
import 'branding_service.dart';
import 'checkout_fees.dart';
import 'location_service.dart';
import 'mock_auth_service.dart';
import 'mock_data_service.dart';

class ApiService {
  // Website address lives in lib/config.dart (AppConfig.siteUrl).
  static String baseUrl = AppConfig.apiUrl;
  static String baseWebUrl = AppConfig.siteUrl;

  static String? authToken;

  /// From /api/config: whether cash on delivery is offered, and the Stripe key for card payments.
  static bool codEnabled = false;
  static String stripePublishableKey = '';
  static bool isOnlineBackendAvailable = true;

  static const String _keyToken = 'grocerly_auth_token';
  static const String _keyUser = 'grocerly_user_data';

  /// Restore persistent session from device disk on app start
  static Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_keyToken);
      final savedUserStr = prefs.getString(_keyUser);

      if (savedToken != null && savedToken.isNotEmpty) {
        authToken = savedToken;
      }
      if (savedUserStr != null && savedUserStr.isNotEmpty) {
        final Map<String, dynamic> userMap = json.decode(savedUserStr);
        final user = UserModel.fromJson(userMap);
        MockAuthService.setCurrentUser(user);
      }
    } catch (_) {}
  }

  /// Re-read the signed-in account from the store (GET /api/user), so name/phone
  /// changes made on the website show in the app; signs out if the session was revoked.
  static Future<void> refreshUser() async {
    if (authToken == null || authToken!.isEmpty) {
      if (MockAuthService.isLoggedIn) await clearSession();
      return;
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/user'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final raw = data is Map && data['data'] is Map ? data['data'] : data;
        await saveSession(
          authToken!,
          UserModel.fromJson(Map<String, dynamic>.from(raw)),
        );
      } else if (res.statusCode == 401) {
        await clearSession();
      }
    } catch (_) {} // offline: keep the saved session
  }

  /// Persist session to device disk
  static Future<void> saveSession(String token, UserModel user) async {
    authToken = token;
    MockAuthService.setCurrentUser(user);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUser, json.encode(user.toJson()));
    } catch (_) {}
    // Saved addresses come from the account (same as the website); the default becomes active.
    if (!LocationService.hasAddress) unawaited(getAddresses());
  }

  /// Wipe session from device disk on logout
  static Future<void> clearSession() async {
    authToken = null;
    MockAuthService.logout();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (_) {}
  }

  // Headers generator with Sanctum Bearer token and browser anti-bot disguise
  static Map<String, String> get headers => _headers;
  static String errorMessage(http.Response res, String fallback) =>
      _errorMessage(res, fallback);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile; GrocerlyApp/1.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
    'X-Requested-With': 'XMLHttpRequest',
    'Origin': AppConfig.origin,
    'Referer': '${AppConfig.siteUrl}/',
    if (authToken != null && authToken!.isNotEmpty)
      'Authorization': 'Bearer $authToken',
  };

  // -------------------------------------------------------------
  // 1. CONFIG & SYSTEM APIS (/api/config, /api/delivery-eta)
  // -------------------------------------------------------------
  static Future<AppConfigModel> fetchConfig() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/config'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'] ?? json.decode(res.body);
        isOnlineBackendAvailable = true;
        final config = AppConfigModel.fromJson(data);
        CheckoutFees.load(Map<String, dynamic>.from(data));
        LocationService.updateStoreFromConfig(config);
        await BrandingService.apply(config);
        codEnabled = config.codEnabled;
        stripePublishableKey = config.stripePublishableKey;
        return config;
      }
    } catch (_) {}
    return AppConfigModel.defaults();
  }

  static Future<int> getDeliveryEta(double lat, double lng) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/delivery-eta?lat=$lat&lng=$lng'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['eta_minutes'] ?? 10;
      }
    } catch (_) {}
    double distKm = LocationService.calculateDistanceKm(
      lat,
      lng,
      LocationService.storeLat,
      LocationService.storeLng,
    );
    return LocationService.calculateDeliveryMinutes(distKm);
  }

  // -------------------------------------------------------------
  // 2. AUTH APIS (/api/auth/*)
  // -------------------------------------------------------------
  static Future<Map<String, dynamic>> authStart(String identifier) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/start'),
            headers: _headers,
            body: json.encode({'email': identifier.trim()}),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return {
          'success': true,
          ...Map<String, dynamic>.from(json.decode(res.body)),
        };
      }
      return {
        'success': false,
        'message': _errorMessage(
          res,
          'Could not send a sign-in code to that email.',
        ),
      };
    } catch (_) {
      return {
        'success': false,
        'message':
            'Could not reach the server. Check your connection and try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: json.encode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // With email codes switched on, the store sends a code instead of signing in.
        if (data['requires_otp'] == true) {
          return {
            'success': false,
            'requires_otp': true,
            'purpose': data['purpose'] ?? 'login',
            'message':
                data['message'] ?? 'We sent a verification code to your email.',
          };
        }
        final token = (data['token'] ?? data['access_token'] ?? '').toString();
        if (token.isEmpty || data['user'] == null) {
          return {
            'success': false,
            'message': 'Sign-in failed. Please try again.',
          };
        }
        isOnlineBackendAvailable = true;
        final user = UserModel.fromJson(data['user']);
        await saveSession(token, user);
        return {'success': true, 'user': user, 'token': token};
      } else if (res.statusCode == 422) {
        final data = json.decode(res.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid email or password.',
        };
      } else {
        String msg = 'Login failed (${res.statusCode})';
        try {
          final data = json.decode(res.body);
          if (data['message'] != null) msg = data['message'];
        } catch (_) {
          if (res.body.contains('Imunify360') ||
              res.body.contains('bot-protection')) {
            msg = 'Server firewall bot-protection triggered. Please toggle Airplane mode ON/OFF or open store in browser once.';
          }
        }
        if (msg.contains('Imunify360') ||
            msg.contains('bot-protection') ||
            msg.contains('automation')) {
          msg = 'Server firewall bot-protection triggered on your network. Please toggle Airplane mode ON/OFF or open store in browser once.';
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Unable to connect to login server ($e). Please check your internet.',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String? passwordConfirmation,
  }) async {
    final name = '$firstName $lastName'.trim();
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: json.encode({
              'name': name.isEmpty ? 'Customer' : name,
              'first_name': firstName.trim(),
              'last_name': lastName.trim(),
              'email': email.trim(),
              'phone': phone.trim(),
              'password': password,
              'password_confirmation': passwordConfirmation ?? password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200 ||
          res.statusCode == 201 ||
          res.statusCode == 202) {
        final data = json.decode(res.body);
        // The store may email a code first; the account is created once it's verified.
        if (data['requires_otp'] == true) {
          return {
            'success': false,
            'requires_otp': true,
            'purpose': data['purpose'] ?? 'register',
            'message':
                data['message'] ??
                'We emailed you a code to confirm your address.',
          };
        }
        final token = (data['token'] ?? data['access_token'] ?? '').toString();
        isOnlineBackendAvailable = true;
        final user = UserModel.fromJson(data['user'] ?? data['data'] ?? {});
        await saveSession(token, user);
        return {
          'success': true,
          'message': data['message'] ?? 'Account created successfully!',
          'user': user,
          'token': token,
        };
      } else if (res.statusCode == 422) {
        final data = json.decode(res.body);
        String msg = data['message'] ?? 'Registration validation failed';
        if (data['errors'] != null && data['errors'] is Map) {
          final errs = (data['errors'] as Map).values
              .expand((e) => e is List ? e : [e])
              .join('\n');
          if (errs.isNotEmpty) msg = errs;
        }
        return {'success': false, 'message': msg};
      } else {
        String msg = 'Registration failed (${res.statusCode})';
        try {
          final data = json.decode(res.body);
          if (data['message'] != null) msg = data['message'];
        } catch (_) {
          if (res.body.contains('Imunify360') ||
              res.body.contains('bot-protection')) {
            msg = 'Server firewall bot-protection triggered. Please toggle Airplane mode ON/OFF or open store in browser once.';
          }
        }
        if (msg.contains('Imunify360') ||
            msg.contains('bot-protection') ||
            msg.contains('automation')) {
          msg = 'Server firewall bot-protection triggered on your network. Please toggle Airplane mode ON/OFF or open store in browser once.';
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Unable to connect to server ($e). Please check your internet connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    required String purpose,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: _headers,
            body: json.encode({
              'email': email.trim(),
              'code': code,
              'purpose': purpose,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final token = (data['token'] ?? data['access_token'] ?? '').toString();
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          await saveSession(token, user);
        }
        return {
          'success': true,
          'message': 'Verified! Welcome to ${BrandingService.proseName}.',
          'token': token,
        };
      }
      return {
        'success': false,
        'message': _errorMessage(
          res,
          'That code is not correct or has expired.',
        ),
      };
    } catch (_) {
      return {
        'success': false,
        'message':
            'Could not reach the server to verify the code. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> resendOtp(
    String email, {
    String purpose = 'login',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/resend-otp'),
            headers: _headers,
            body: json.encode({'email': email.trim(), 'purpose': purpose}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': 'A new code was sent to your email.',
        };
      }
      return {
        'success': false,
        'message': _errorMessage(res, 'Could not send a new code.'),
      };
    } catch (_) {
      return {
        'success': false,
        'message':
            'Could not reach the server. Check your connection and try again.',
      };
    }
  }

  static Future<void> logout() async {
    try {
      await http
          .post(Uri.parse('$baseUrl/auth/logout'), headers: _headers)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    await clearSession();
  }

  /// Update Profile (matches web PATCH /api/profile)
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/profile'),
            headers: _headers,
            body: json.encode({'name': name.trim(), 'phone': phone.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final userData = data['data'] ?? data['user'] ?? data;
        final updatedUser = UserModel.fromJson(userData);
        if (authToken != null && authToken!.isNotEmpty) {
          await saveSession(authToken!, updatedUser);
        } else {
          MockAuthService.setCurrentUser(updatedUser);
        }
        return {
          'success': true,
          'message': 'Profile updated successfully!',
          'user': updatedUser,
        };
      } else {
        final data = json.decode(res.body);
        String msg = data['message'] ?? 'Failed to update profile.';
        if (data['errors'] != null && data['errors'] is Map) {
          final errs = (data['errors'] as Map).values
              .expand((e) => e is List ? e : [e])
              .join('\n');
          if (errs.isNotEmpty) msg = errs;
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error updating profile: $e',
      };
    }
  }

  /// Change Password (matches web PATCH /api/profile/password)
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return {
        'success': false,
        'message': 'The two new passwords don\'t match.',
      };
    }
    if (newPassword.length < 8) {
      return {
        'success': false,
        'message': 'Password must be at least 8 characters.',
      };
    }
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/profile/password'),
            headers: _headers,
            body: json.encode({
              'current_password': currentPassword,
              'password': newPassword,
              'password_confirmation': confirmPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully.',
        };
      } else {
        final data = json.decode(res.body);
        String msg = data['message'] ?? 'Could not change the password.';
        if (data['errors'] != null && data['errors'] is Map) {
          final errs = (data['errors'] as Map).values
              .expand((e) => e is List ? e : [e])
              .join('\n');
          if (errs.isNotEmpty) msg = errs;
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error changing password: $e',
      };
    }
  }

  // -------------------------------------------------------------
  // 3. CATALOG APIS (/api/categories, /api/products)
  // -------------------------------------------------------------
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/categories'), headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final List raw = json.decode(res.body)['data'] ?? [];
        isOnlineBackendAvailable = true;
        final cats = raw.map((c) => CategoryModel.fromJson(c)).toList();
        MockDataService.categories
          ..clear()
          ..addAll(cats);
        return cats;
      }
    } catch (_) {}
    return MockDataService.categories;
  }

  static Future<List<ProductModel>> getProducts({
    String? categorySlug,
    String? search,
  }) async {
    try {
      List<ProductModel> allProducts = [];
      String query = 'per_page=50';
      if (categorySlug != null &&
          categorySlug.isNotEmpty &&
          categorySlug != 'ALL') {
        query += '&category=${Uri.encodeComponent(categorySlug)}';
      }
      if (search != null && search.trim().isNotEmpty) {
        query += '&search=${Uri.encodeComponent(search.trim())}';
      }

      final res = await http
          .get(Uri.parse('$baseUrl/products?$query'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body);
        final List raw = body['data'] ?? [];
        final int lastPage = (body['last_page'] as num?)?.toInt() ?? 1;

        allProducts.addAll(raw.map((p) => ProductModel.fromJson(p)));

        if (lastPage > 1) {
          for (int page = 2; page <= lastPage; page++) {
            try {
              final nextRes = await http
                  .get(
                    Uri.parse('$baseUrl/products?$query&page=$page'),
                    headers: _headers,
                  )
                  .timeout(const Duration(seconds: 5));
              if (nextRes.statusCode == 200) {
                final List nextRaw = json.decode(nextRes.body)['data'] ?? [];
                allProducts.addAll(
                  nextRaw.map((p) => ProductModel.fromJson(p)),
                );
              }
            } catch (_) {}
          }
        }

        // The store list is the truth, also when admin has removed everything.
        isOnlineBackendAvailable = true;
        if (categorySlug == null && (search == null || search.isEmpty)) {
          MockDataService.products
            ..clear()
            ..addAll(allProducts);
        }
        return allProducts;
      }
    } catch (_) {}
    return MockDataService.products;
  }

  static Future<ProductModel?> getProductBySlug(String slug) async {
    if (slug.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/products/$slug'), headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body);
        final data = body['data'] ?? body;
        return ProductModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // -------------------------------------------------------------
  // GEOCODE & LOCATION APIS (/api/geocode/search, /api/geocode/reverse)
  // Matching GDP Backend Geocode API with OpenStreetMap Nominatim engine
  // -------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> geocodeSearch(
    String query, {
    double? lat,
    double? lng,
  }) async {
    final cleanQ = query.trim();
    if (cleanQ.length < 2) return [];

    // 1. GDP Live Backend Geocode API
    try {
      String url = '$baseUrl/geocode/search?q=${Uri.encodeComponent(cleanQ)}';
      if (lat != null && lng != null) {
        url += '&lat=$lat&lng=$lng';
      }
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List raw = json.decode(res.body)['data'] ?? [];
        if (raw.isNotEmpty) {
          return raw.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    } catch (_) {}

    // 2. Direct Nominatim OpenStreetMap fallback (same engine configured in GDP Geo.php)
    try {
      String nomUrl =
          'https://nominatim.openstreetmap.org/search?format=jsonv2&addressdetails=1&limit=6&q=${Uri.encodeComponent(cleanQ)}';
      if (lat != null && lng != null) {
        double d = 0.6; // ~65 km half-box bias as implemented in GDP Geo.php
        nomUrl += '&viewbox=${lng - d},${lat + d},${lng + d},${lat - d}';
      }
      final nomRes = await http
          .get(
            Uri.parse(nomUrl),
            headers: {
              'Accept-Language': 'en',
              'User-Agent':
                  'gdp-grocery/1.0 (+https://github.com/webdev794/gdp)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (nomRes.statusCode == 200) {
        final List raw = json.decode(nomRes.body);
        return raw.map((item) {
          final addr = (item['address'] as Map?)?.cast<String, dynamic>() ?? {};
          final city =
              addr['city'] ??
              addr['town'] ??
              addr['village'] ??
              addr['suburb'] ??
              addr['county'] ??
              '';
          final state = addr['state'] ?? '';
          final postcode = addr['postcode'] ?? '';
          final full = item['display_name'] ?? cleanQ;
          final road = addr['road'] ?? addr['house_number'] ?? '';
          final label =
              item['name'] ??
              (road.isNotEmpty
                  ? road
                  : (city.isNotEmpty ? city : 'Selected location'));
          return {
            'label': label,
            'full': full,
            'line1': road,
            'city': city,
            'state': state,
            'postal_code': postcode,
            'lat': double.tryParse(item['lat']?.toString() ?? '') ?? 0.0,
            'lon': double.tryParse(item['lon']?.toString() ?? '') ?? 0.0,
          };
        }).toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<Map<String, dynamic>?> geocodeReverse(
    double lat,
    double lng,
  ) async {
    // 1. GDP Live Backend Geocode Reverse API
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/geocode/reverse?lat=$lat&lng=$lng'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        if (data != null) return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    // 2. Direct Nominatim OpenStreetMap fallback (same engine configured in GDP Geo.php)
    try {
      final nomRes = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?format=jsonv2&addressdetails=1&lat=$lat&lon=$lng',
            ),
            headers: {
              'Accept-Language': 'en',
              'User-Agent':
                  'gdp-grocery/1.0 (+https://github.com/webdev794/gdp)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (nomRes.statusCode == 200) {
        final item = json.decode(nomRes.body);
        final addr = (item['address'] as Map?)?.cast<String, dynamic>() ?? {};
        final city =
            addr['city'] ??
            addr['town'] ??
            addr['village'] ??
            addr['suburb'] ??
            addr['county'] ??
            '';
        final state = addr['state'] ?? '';
        final postcode = addr['postcode'] ?? '';
        final full = item['display_name'] ?? 'Custom Location';
        final road = addr['road'] ?? addr['house_number'] ?? '';
        final label =
            item['name'] ??
            (road.isNotEmpty
                ? road
                : (city.isNotEmpty ? city : 'Selected location'));
        return {
          'label': label,
          'full': full,
          'line1': road,
          'city': city,
          'state': state,
          'postal_code': postcode,
          'lat': lat,
          'lon': lng,
        };
      }
    } catch (_) {}

    return null;
  }

  // -------------------------------------------------------------
  // 4. ADDRESS & PAYMENT APIS (/api/addresses, /api/billing/*)
  // -------------------------------------------------------------
  static Future<List<AddressModel>> getAddresses() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/addresses'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List raw = json.decode(res.body)['data'] ?? [];
        // The store's list is the truth (also when empty), so it matches the website.
        final list = raw.map((a) => AddressModel.fromJson(a)).toList();
        LocationService.userAddresses
          ..clear()
          ..addAll(list);
        if (list.isNotEmpty) {
          final defaultAddr = list.firstWhere(
            (a) => a.isDefault,
            orElse: () => list.first,
          );
          LocationService.setActiveAddress(defaultAddr);
        }
        return list;
      }
    } catch (_) {}
    return LocationService.userAddresses;
  }

  static Future<Map<String, dynamic>> createAddress(
    Map<String, dynamic> addressData,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/addresses'),
            headers: _headers,
            body: json.encode(addressData),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = json.decode(res.body);
        final addr = AddressModel.fromJson(data['data'] ?? data);
        await getAddresses(); // Refresh addresses
        return {
          'success': true,
          'message': 'Address added successfully!',
          'address': addr,
        };
      } else {
        final data = json.decode(res.body);
        String msg = data['message'] ?? 'Could not add address.';
        if (data['errors'] != null && data['errors'] is Map) {
          final errs = (data['errors'] as Map).values
              .expand((e) => e is List ? e : [e])
              .join('\n');
          if (errs.isNotEmpty) msg = errs;
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error saving address: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAddress(
    String id,
    Map<String, dynamic> addressData,
  ) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/addresses/$id'),
            headers: _headers,
            body: json.encode(addressData),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addr = AddressModel.fromJson(data['data'] ?? data);
        await getAddresses(); // Refresh addresses
        return {
          'success': true,
          'message': 'Address updated successfully!',
          'address': addr,
        };
      } else {
        final data = json.decode(res.body);
        String msg = data['message'] ?? 'Could not update address.';
        if (data['errors'] != null && data['errors'] is Map) {
          final errs = (data['errors'] as Map).values
              .expand((e) => e is List ? e : [e])
              .join('\n');
          if (errs.isNotEmpty) msg = errs;
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error updating address: $e',
      };
    }
  }

  static Future<bool> deleteAddress(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/addresses/$id'), headers: _headers)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 || res.statusCode == 204) {
        await getAddresses();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> setDefaultAddress(String id) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/addresses/$id'),
            headers: _headers,
            body: json.encode({'is_default': true}),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        await getAddresses();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/billing/payment-methods'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List raw = json.decode(res.body)['data'] ?? [];
        return raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Stripe SetupIntent client_secret so the app can save a card to the account.
  static Future<String> createSetupIntent() async {
    final res = await http
        .post(Uri.parse('$baseUrl/billing/setup-intent'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not start card setup.'));
    }
    final data = json.decode(res.body);
    final secret = data is Map
        ? (data['data'] is Map
              ? data['data']['client_secret']
              : data['client_secret'])
        : null;
    if (secret == null || secret.toString().isEmpty) {
      throw ApiException('Could not start card setup.');
    }
    return secret.toString();
  }

  static Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    final res = await http
        .post(
          Uri.parse(
            '$baseUrl/billing/payment-methods/$paymentMethodId/default',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw ApiException(
        _errorMessage(res, 'Could not update your default card.'),
      );
    }
  }

  static Future<void> deletePaymentMethod(String paymentMethodId) async {
    final res = await http
        .delete(
          Uri.parse('$baseUrl/billing/payment-methods/$paymentMethodId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw ApiException(_errorMessage(res, 'Could not remove that card.'));
    }
  }

  // -------------------------------------------------------------
  // 5. ORDERS & CHECKOUT APIS (/api/checkout, /api/orders)
  // -------------------------------------------------------------
  // Orders come from the store (GET /api/orders), so orders placed on the
  // website and in the app show in both places.
  static final List<OrderModel> _cachedOrders = [];

  static List<OrderModel> get cachedOrders => _cachedOrders;

  /// First validation message from a Laravel error response.
  static String _errorMessage(http.Response res, String fallback) {
    try {
      final data = json.decode(res.body);
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        if (data['message'] != null) return data['message'].toString();
      }
    } catch (_) {}
    return fallback;
  }

  /// The signed-in customer's orders, newest first.
  static Future<List<OrderModel>> fetchOrders() async {
    final res = await http
        .get(Uri.parse('$baseUrl/orders'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not load your orders.'));
    }
    final List raw = json.decode(res.body)['data'] ?? [];
    final orders = raw
        .map((o) => OrderModel.fromJson(Map<String, dynamic>.from(o)))
        .toList();
    _cachedOrders
      ..clear()
      ..addAll(orders);
    return orders;
  }

  static Future<OrderModel> fetchOrder(String orderId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/orders/$orderId'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not load this order.'));
    }
    final order = OrderModel.fromJson(
      Map<String, dynamic>.from(json.decode(res.body)['data']),
    );
    final idx = _cachedOrders.indexWhere((o) => o.id == order.id);
    if (idx != -1) _cachedOrders[idx] = order;
    return order;
  }

  /// Place a real order: copy the app basket into the store cart, then check out.
  /// [cart] maps "productId" or "productId__var_variantId" to a quantity.
  /// [paymentMethod] is 'cod' or 'card' (card orders still need [paymentIntent]).
  static Future<OrderModel> placeOrder({
    required Map<String, int> cart,
    required String paymentMethod,
    required AddressModel address,
    String? phone,
    String? deliveryInstructions,
    String? giftCardCode,
    String? giftCardPin,
  }) async {
    const timeout = Duration(seconds: 15);
    final coords = {'lat': address.latitude, 'lng': address.longitude};

    final cleared = await http
        .delete(Uri.parse('$baseUrl/cart'), headers: _headers)
        .timeout(timeout);
    if (cleared.statusCode >= 400) {
      throw ApiException(
        _errorMessage(
          cleared,
          'Could not prepare your basket. Please sign in again.',
        ),
      );
    }

    for (final entry in cart.entries) {
      if (entry.value <= 0) continue;
      final parts = entry.key.split('__var_');
      final res = await http
          .post(
            Uri.parse('$baseUrl/cart/items'),
            headers: _headers,
            body: json.encode({
              'product_id': int.tryParse(parts[0]) ?? parts[0],
              if (parts.length > 1)
                'product_variant_id': int.tryParse(parts[1]) ?? parts[1],
              'quantity': entry.value,
              ...coords,
            }),
          )
          .timeout(timeout);
      if (res.statusCode >= 400) {
        throw ApiException(
          _errorMessage(res, 'An item in your basket is no longer available.'),
        );
      }
    }

    final savedId = int.tryParse(address.id);
    final user = MockAuthService.currentUser;
    final body = <String, dynamic>{
      'payment_method': paymentMethod,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (deliveryInstructions != null &&
          deliveryInstructions.trim().isNotEmpty)
        'delivery_instructions': deliveryInstructions.trim(),
      if (giftCardCode != null && giftCardCode.trim().isNotEmpty)
        'gift_card_code': giftCardCode.trim(),
      if (giftCardPin != null && giftCardPin.trim().isNotEmpty)
        'gift_card_pin': giftCardPin.trim(),
      if (savedId != null)
        'address_id': savedId
      else
        'address': {
          'name': address.name ?? user?.fullName ?? 'Customer',
          'line1': (address.line1 ?? '').isNotEmpty
              ? address.line1
              : address.fullAddress,
          if ((address.line2 ?? '').isNotEmpty) 'line2': address.line2,
          if (address.city.isNotEmpty) 'city': address.city,
          if (address.state.isNotEmpty) 'state': address.state,
          if (address.zipCode.isNotEmpty) 'postal_code': address.zipCode,
          'latitude': address.latitude,
          'longitude': address.longitude,
        },
    };

    final res = await http
        .post(
          Uri.parse('$baseUrl/checkout'),
          headers: _headers,
          body: json.encode(body),
        )
        .timeout(timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(
        _errorMessage(res, 'Your order could not be placed. Please try again.'),
      );
    }
    final data = json.decode(res.body);
    final order = OrderModel.fromJson(
      Map<String, dynamic>.from(data['data'] ?? data['order'] ?? data),
    );
    _cachedOrders.insert(0, order);
    return order;
  }

  /// Stripe PaymentIntent for a card order: returns the client secret, or null once already paid.
  static Future<String?> paymentIntent(String orderId) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/orders/$orderId/payment-intent'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw ApiException(
        _errorMessage(res, 'Card payment could not be started.'),
      );
    }
    final data = json.decode(res.body)['data'] ?? {};
    return data['client_secret']?.toString();
  }

  /// Pay an order's PaymentIntent with a card saved on the customer's account
  /// (same as the website): confirm it with Stripe using the publishable key.
  /// Returns null on success, or a message to show the customer.
  static Future<String?> payWithSavedCard(
    String clientSecret,
    String paymentMethodId,
  ) async {
    final intentId = clientSecret.split('_secret_').first;
    try {
      final res = await http
          .post(
            Uri.parse(
              'https://api.stripe.com/v1/payment_intents/$intentId/confirm',
            ),
            headers: {
              'Authorization': 'Bearer $stripePublishableKey',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'client_secret': clientSecret,
              'payment_method': paymentMethodId,
            },
          )
          .timeout(const Duration(seconds: 20));
      final data = json.decode(res.body);
      if (res.statusCode == 200 && data['status'] == 'succeeded') return null;
      if (data['status'] == 'requires_action') {
        return 'Your bank needs to verify this card. Please pay with it on the website, or use another card.';
      }
      return data['error']?['message']?.toString() ??
          'The card payment did not go through.';
    } catch (_) {
      return 'Could not reach the payment service. Please try again.';
    }
  }

  /// The order's bill as PDF bytes (same receipt the website downloads).
  static Future<Uint8List> fetchReceipt(String orderId) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/orders/$orderId/receipt'),
          headers: {..._headers, 'Accept': 'application/pdf'},
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw ApiException(
        _errorMessage(res, 'The bill for this order is not available yet.'),
      );
    }
    return res.bodyBytes;
  }

  static Future<void> cancelOrder(String orderId) async {
    final res = await http
        .post(Uri.parse('$baseUrl/orders/$orderId/cancel'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw ApiException(
        _errorMessage(res, 'This order could not be cancelled.'),
      );
    }
  }

  /// Gift card issued by the store: returns its remaining balance in dollars.
  static Future<double> checkGiftCard(String code, String pin) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/gift-cards/check'),
          headers: _headers,
          body: json.encode({'code': code.trim(), 'pin': pin.trim()}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException(
        _errorMessage(res, 'That gift card and password don\'t match.'),
      );
    }
    final data = json.decode(res.body)['data'] ?? {};
    return ((data['balance_cents'] as num?) ?? 0) / 100.0;
  }

  static Future<bool> submitRiderReview(
    String orderId,
    double rating,
    String comment, {
    String source = 'delivery',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/orders/$orderId/rider-review'),
            headers: _headers,
            body: json.encode({
              'rating': rating.round(),
              'comment': comment,
              'source': source,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final idx = _cachedOrders.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          _cachedOrders[idx] = _cachedOrders[idx].copyWith(
            riderReviewRating: rating,
            riderReviewComment: comment,
          );
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  // -------------------------------------------------------------
  // 6. CUSTOMER SUPPORT APIS (/api/support/threads)
  // -------------------------------------------------------------
  // Support chats live on the store, so the website and the app show the same
  // conversations and replies.
  static final List<SupportThread> _cachedThreads = [];

  static List<SupportThread> get cachedThreads => _cachedThreads;

  static Future<List<SupportThread>> fetchSupportThreads() async {
    final res = await http
        .get(Uri.parse('$baseUrl/support/threads'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException(
        _errorMessage(res, 'Could not load your support chats.'),
      );
    }
    final List raw = json.decode(res.body)['data'] ?? [];
    final threads = raw
        .map((t) => SupportThread.fromJson(Map<String, dynamic>.from(t)))
        .toList();
    _cachedThreads
      ..clear()
      ..addAll(threads);
    return threads;
  }

  static Future<SupportThread> fetchSupportThread(String threadId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/support/threads/$threadId'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not load this chat.'));
    }
    return SupportThread.fromJson(
      Map<String, dynamic>.from(json.decode(res.body)['data']),
    );
  }

  /// Open a chat. [issueType] is one of `supportIssueTypes`; [orderId] links it to an order.
  static Future<SupportThread> createSupportThread(
    String issueType,
    String message, {
    String? orderId,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/support/threads'),
          headers: _headers,
          body: json.encode({
            'issue_type': issueType,
            'message': message,
            if (orderId != null) 'order_id': int.tryParse(orderId) ?? orderId,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(_errorMessage(res, 'Could not open a support chat.'));
    }
    final thread = SupportThread.fromJson(
      Map<String, dynamic>.from(json.decode(res.body)['data']),
    );
    _cachedThreads.insert(0, thread);
    return thread;
  }

  /// The customer ends the chat (store marks it resolved; replying re-opens it).
  static Future<SupportThread> closeSupportThread(String threadId) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/support/threads/$threadId/close'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not end the chat.'));
    }
    return SupportThread.fromJson(
      Map<String, dynamic>.from(json.decode(res.body)['data']),
    );
  }

  /// Rate how the support team handled a chat (1-5 + optional comment), same as the website.
  static Future<SupportThread> rateSupportThread(
    String threadId,
    int rating,
    String comment,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/support/threads/$threadId/rating'),
          headers: _headers,
          body: json.encode({
            'rating': rating,
            'comment': comment.trim().isEmpty ? null : comment.trim(),
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not save your rating.'));
    }
    return SupportThread.fromJson(
      Map<String, dynamic>.from(json.decode(res.body)['data']),
    );
  }

  static Future<void> sendSupportMessage(
    String threadId,
    String message,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/support/threads/$threadId/messages'),
          headers: _headers,
          body: json.encode({'body': message}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 400) {
      throw ApiException(
        _errorMessage(res, 'Your message was not sent. Please try again.'),
      );
    }
  }
}

/// A request the store rejected, with a message fit to show the customer.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
