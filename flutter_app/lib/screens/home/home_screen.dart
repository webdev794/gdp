import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../services/checkout_fees.dart';
import '../../services/location_service.dart';
import '../../services/mock_auth_service.dart';
import '../../services/mock_data_service.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/branding_service.dart';
import '../../theme/responsive.dart';
import '../../widgets/payment_sheet.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../cart/cart_screen.dart';
import '../location/location_picker_screen.dart';
import '../orders/order_history_screen.dart';
import '../orders/order_tracking_screen.dart';
import '../support/support_screen.dart';
import '../account/account_screen.dart';
import '../../widgets/product_details_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedCategoryId = 'ALL';
  String _searchQuery = '';
  final Map<String, int> _cartQuantities = {};
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ReviewService.changeNotifier.addListener(_onReviewChanged);
    _loadLiveCatalog();
  }

  @override
  void dispose() {
    ReviewService.changeNotifier.removeListener(_onReviewChanged);
    super.dispose();
  }

  void _onReviewChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLiveCatalog() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.fetchConfig();
      final cats = await ApiService.getCategories();
      final prods = await ApiService.getProducts();
      if (mounted) {
        setState(() {
          _categories = cats;
          _products = prods;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = MockDataService.categories;
          _products = MockDataService.products;
          _isLoading = false;
        });
      }
    }
  }

  void _updateQuantity(String productId, int delta) {
    HapticFeedback.lightImpact();
    final current = _cartQuantities[productId] ?? 0;
    // Don't let the basket go past the stock the store reports (same rule as the website).
    if (delta > 0 && !productId.contains('__var_')) {
      final p = _products.where((prod) => prod.id == productId).firstOrNull;
      final stock = p == null ? null : (p.inStock ? p.inventoryQuantity : 0);
      if (stock != null && current + delta > stock) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(stock == 0 ? '${p!.name} is out of stock.' : 'Only $stock of ${p!.name} left in stock.'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }
    setState(() {
      int next = current + delta;
      if (next <= 0) {
        _cartQuantities.remove(productId);
      } else {
        _cartQuantities[productId] = next;
      }
    });
  }

  void _openCartScreen() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartQuantities: _cartQuantities,
          catalog: _products.isNotEmpty ? _products : MockDataService.products,
          onUpdateQuantity: (id, delta) => _updateQuantity(id, delta),
          onClearCart: () {
            setState(() => _cartQuantities.clear());
            _loadLiveCatalog(); // stock changed after the order
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openLocationPicker() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          onAddressSelected: (addr) {
            setState(() {});
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openProductDetails(ProductModel product) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailsSheet(
        product: product,
        cartQuantities: _cartQuantities,
        onVariantQuantityChanged: (itemKey, qty) {
          setState(() {
            if (qty <= 0) {
              _cartQuantities.remove(itemKey);
            } else {
              _cartQuantities[itemKey] = qty;
            }
          });
        },
        onVariantBuyNow: (itemKey, qty) {
          setState(() {
            _cartQuantities[itemKey] = qty;
          });
          Navigator.pop(context);
          _openCartScreen();
        },
        initialQuantity: _cartQuantities[product.id] ?? 0,
        onQuantityChanged: (qty) {
          setState(() {
            if (qty <= 0) {
              _cartQuantities.remove(product.id);
            } else {
              _cartQuantities[product.id] = qty;
            }
          });
        },
        onBuyNow: (qty) {
          setState(() {
            _cartQuantities[product.id] = qty;
          });
          Navigator.pop(context);
          _openCartScreen();
        },
      ),
    );
  }

  int get _totalCartCount => _cartQuantities.values.fold(0, (sum, q) => sum + q);

  double get _totalCartPrice {
    double total = 0.0;
    final catalog = _products.isNotEmpty ? _products : MockDataService.products;
    _cartQuantities.forEach((key, qty) {
      if (qty > 0) {
        if (key.contains('__var_')) {
          final parts = key.split('__var_');
          final prodId = parts[0];
          final varId = parts[1];
          final p = catalog.firstWhere(
            (prod) => prod.id == prodId,
            orElse: () => ProductModel(id: '', name: '', categoryId: '', price: 0.0, unit: '', imageEmoji: ''),
          );
          final v = p.variants.where((vr) => vr.id == varId).firstOrNull;
          final price = v?.price ?? p.displayPrice;
          total += price * qty;
        } else {
          final p = catalog.firstWhere(
            (prod) => prod.id == key,
            orElse: () => ProductModel(id: '', name: '', categoryId: '', price: 0.0, unit: '', imageEmoji: ''),
          );
          total += p.displayPrice * qty;
        }
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final user = MockAuthService.currentUser;
    final categories = _categories.isNotEmpty ? _categories : MockDataService.categories;

    List<ProductModel> filteredProducts = _products.isNotEmpty ? _products : MockDataService.products;

    if (_selectedCategoryId != 'ALL') {
      final selectedCat = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
      filteredProducts = filteredProducts.where((p) {
        if (p.categoryId == _selectedCategoryId) return true;
        if (selectedCat != null && selectedCat.slug.isNotEmpty && (p.slug.contains(selectedCat.slug) || p.categoryId == selectedCat.slug)) {
          return true;
        }
        return false;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.bgLight,

      // Side Drawer
      drawer: Drawer(
        backgroundColor: Colors.white,
        width: math.max(300.0, math.min(MediaQuery.sizeOf(context).width * 0.82, 340.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Green Header (Full bleed into iOS status bar / notch / dynamic island)
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.emeraldPrimary,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const BrandLogo(height: 44),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            if (user != null) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())).then((_) {
                                if (mounted) setState(() {});
                              });
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) {
                                if (mounted) setState(() {});
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.coralAccent, width: 2),
                                  ),
                                  child: const Icon(Icons.person, color: AppTheme.emeraldPrimary, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user != null ? user.fullName : 'Guest Customer',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user != null ? user.email : 'Welcome to ${BrandingService.proseName}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (user != null)
                                  const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (user == null)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    ).then((_) {
                                      if (mounted) setState(() {});
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70, width: 1.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    minimumSize: const Size(0, 42),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'SIGN IN',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                    ).then((_) {
                                      if (mounted) setState(() {});
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.coralAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    minimumSize: const Size(0, 42),
                                    elevation: 0,
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'REGISTER',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await ApiService.logout();
                              if (mounted) setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 42),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('LOG OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable Drawer Menu Items (Protected with iOS Home Indicator SafeArea)
            Expanded(
              child: SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home_outlined, color: AppTheme.emeraldPrimary),
                      title: const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => Navigator.pop(context),
                    ),
                    if (user != null) ...[
                      ListTile(
                        leading: const Icon(Icons.person_outline, color: AppTheme.emeraldPrimary),
                        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Profile, addresses & payment methods', style: TextStyle(fontSize: 11, color: AppTheme.slateMuted)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined, color: AppTheme.emeraldPrimary),
                        title: const Text('My Orders 📦', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('View history & receipts', style: TextStyle(fontSize: 11, color: AppTheme.slateMuted)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delivery_dining, color: AppTheme.coralAccent),
                        title: const Text('Track Active Order ⚡', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Live delivery OTP & status', style: TextStyle(fontSize: 11, color: AppTheme.slateMuted)),
                        onTap: () {
                          Navigator.pop(context);
                          if (ApiService.cachedOrders.isNotEmpty) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: ApiService.cachedOrders.first)));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active orders placed yet.')));
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: AppTheme.slateMuted),
                        title: const Text('Saved Delivery Addresses', style: TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          _openLocationPicker();
                        },
                      ),
                      const Divider(height: 24, thickness: 1),
                      ListTile(
                        leading: const Icon(Icons.headset_mic_outlined, color: AppTheme.coralAccent),
                        title: const Text('24/7 Live Support Chat 💬', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Customer care & resolution', style: TextStyle(fontSize: 11, color: AppTheme.slateMuted)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                        },
                      ),
                    ] else ...[
                      // Informative membership banner for guest users
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.emeraldPrimary.withAlpha(50)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_outline, size: 16, color: AppTheme.emeraldPrimary),
                                SizedBox(width: 6),
                                Text(
                                  'Member Features',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppTheme.slateDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sign in to view your past orders, saved addresses, and access 24/7 live support chat.',
                              style: TextStyle(fontSize: 11.5, color: AppTheme.slateMuted, height: 1.35),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  ).then((_) {
                                    if (mounted) setState(() {});
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emeraldPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'LOG IN TO ACCESS',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 24, thickness: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: StoreContactCard(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Header Bar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppTheme.slateDark, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: _openLocationPicker,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LocationService.activeAddress.isDeliverable ? Icons.bolt : Icons.warning_amber_rounded,
                    size: 14,
                    color: LocationService.activeAddress.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      LocationService.activeAddress.isDeliverable
                          ? 'DELIVERING IN ${LocationService.activeAddress.deliveryMinutes} MINS'
                          : 'SERVICE NOT AVAILABLE YET 🚫',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: LocationService.activeAddress.isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(LocationService.activeAddress.tagIcon, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${LocationService.activeAddress.tag.toUpperCase()} • ${LocationService.activeAddress.displayHeadline}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.slateDark,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.slateDark),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'My Account',
            icon: const Icon(Icons.account_circle_outlined, color: AppTheme.slateDark, size: 26),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          GestureDetector(
            onTap: _openCartScreen,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.slateDark, size: 26),
                  onPressed: _openCartScreen,
                ),
                if (_totalCartCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.coralAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$_totalCartCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Adaptive Floating Bottom Checkout Bar (iOS Apple Pay / Android Payment Sheet)
      bottomNavigationBar: _totalCartCount > 0
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _openCartScreen,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$_totalCartCount ITEMS IN CART',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.slateMuted, letterSpacing: 0.5),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 14, color: AppTheme.emeraldPrimary),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${_totalCartPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (!MockAuthService.isLoggedIn) {
                          HapticFeedback.vibrate();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please log in or register to buy products.'),
                              backgroundColor: AppTheme.coralAccent,
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'LOG IN',
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  ).then((_) {
                                    if (mounted) setState(() {});
                                  });
                                },
                              ),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ).then((_) {
                            if (mounted) setState(() {});
                          });
                          return;
                        }
                        if (!LocationService.activeAddress.isDeliverable) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Delivery unavailable to ${LocationService.activeAddress.city} (${LocationService.activeAddress.distanceKm.toStringAsFixed(1)} km). Max radius is ${LocationService.maxDeliveryRadiusKm.toStringAsFixed(0)} km.',
                              ),
                              backgroundColor: AppTheme.errorRed,
                              action: SnackBarAction(
                                label: 'CHANGE',
                                textColor: Colors.white,
                                onPressed: _openLocationPicker,
                              ),
                            ),
                          );
                          _openLocationPicker();
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => PaymentSheet(
                            totalAmount: CheckoutFees.estimate(
                              _totalCartPrice,
                              km: LocationService.activeAddress.distanceKm,
                              radiusKm: LocationService.maxDeliveryRadiusKm,
                            ).total,
                            itemCount: _totalCartCount,
                            cart: Map<String, int>.from(_cartQuantities),
                            onOrderPlaced: (order) {
                              if (mounted) setState(() => _cartQuantities.clear());
                              _loadLiveCatalog(); // stock changed after the order
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                              );
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !LocationService.activeAddress.isDeliverable
                            ? AppTheme.errorRed
                            : (!MockAuthService.isLoggedIn
                                ? AppTheme.coralAccent
                                : ((defaultTargetPlatform == TargetPlatform.iOS)
                                    ? AppTheme.applePayBlack
                                    : AppTheme.emeraldPrimary)),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        minimumSize: const Size(160, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (defaultTargetPlatform == TargetPlatform.iOS && LocationService.activeAddress.isDeliverable && MockAuthService.isLoggedIn)
                            const Icon(Icons.apple, size: 18),
                          if (defaultTargetPlatform == TargetPlatform.iOS && LocationService.activeAddress.isDeliverable && MockAuthService.isLoggedIn)
                            const SizedBox(width: 6),
                          Text(
                            !LocationService.activeAddress.isDeliverable
                                ? 'UNAVAILABLE (>15KM)'
                                : (!MockAuthService.isLoggedIn
                                    ? 'LOG IN TO BUY ➔'
                                    : ((defaultTargetPlatform == TargetPlatform.iOS) ? 'BUY NOW Pay' : 'BUY NOW ➔')),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,

      body: RefreshIndicator(
        onRefresh: _loadLiveCatalog,
        color: AppTheme.emeraldPrimary,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!LocationService.activeAddress.isDeliverable)
                GestureDetector(
                  onTap: _openLocationPicker,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'OUT OF SERVICE AREA (${LocationService.activeAddress.distanceKm.toStringAsFixed(1)} KM). Max radius is ${LocationService.maxDeliveryRadiusKm.toStringAsFixed(0)} KM from ${LocationService.storeName}. Tap to change location.',
                            style: const TextStyle(fontSize: 11, color: AppTheme.errorRed, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.errorRed, size: 18),
                      ],
                    ),
                  ),
                ),
              // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search organic milk, strawberries, salmon...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.slateMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : const Icon(Icons.tune, color: AppTheme.slateMuted),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // Hero Promo Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.emeraldPrimary, Color(0xFF1B6B44)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emeraldPrimary.withAlpha(50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.coralAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '⚡ 20% OFF TODAY',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Fresh Organic Groceries Delivered in 30 Mins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Free delivery on orders over \$${CheckoutFees.freeDeliveryThreshold.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Text('🥑🥩', style: TextStyle(fontSize: 44)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Categories Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Browse Grocery Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 106,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    bool isSelected = _selectedCategoryId == 'ALL';
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategoryId = 'ALL'),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.emeraldPrimary : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? AppTheme.emeraldPrimary : AppTheme.borderSubtle),
                              ),
                              child: Center(
                                child: Text('🛒', style: TextStyle(fontSize: isSelected ? 24 : 22)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'All Items',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppTheme.emeraldPrimary : AppTheme.slateDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final cat = categories[index - 1];
                  bool isSelected = _selectedCategoryId == cat.id;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: Container(
                      width: 84,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.emeraldPrimary : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? AppTheme.emeraldPrimary : AppTheme.borderSubtle),
                            ),
                            child: ClipOval(
                              child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      cat.imageUrl!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(cat.icon, style: const TextStyle(fontSize: 26)),
                                      ),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(child: Text(cat.icon, style: const TextStyle(fontSize: 26)));
                                      },
                                    )
                                  : Center(
                                      child: Text(cat.icon, style: const TextStyle(fontSize: 26)),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? AppTheme.emeraldPrimary : AppTheme.slateDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Products Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Product Cards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                  ),
                  Text(
                    '${filteredProducts.length} Products',
                    style: const TextStyle(color: AppTheme.slateMuted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Live Product Cards Grid
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppTheme.emeraldPrimary),
                          SizedBox(height: 14),
                          Text(
                            'Loading live inventory...',
                            style: TextStyle(color: AppTheme.slateMuted, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : _products.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('Products could not be loaded. Check your connection.',
                                  textAlign: TextAlign.center, style: TextStyle(color: AppTheme.slateMuted)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadLiveCatalog, child: const Text('TRY AGAIN')),
                            ],
                          ),
                        ),
                      )
                : filteredProducts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No products found matching your search.', style: TextStyle(color: AppTheme.slateMuted)),
                        ),
                      )
                    : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Responsive.gridColumnCount(context),
                      childAspectRatio: Responsive.isLandscape(context)
                          ? 0.70
                          : (Responsive.gridColumnCount(context) > 2
                              ? 0.68
                              : (Responsive.isSmallPhone(context) ? 0.52 : 0.56)),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      int prodTotalCartCount = _cartQuantities[p.id] ?? 0;
                      for (final v in p.variants) {
                        prodTotalCartCount += _cartQuantities['${p.id}__var_${v.id}'] ?? 0;
                      }
                      int q = _cartQuantities[p.id] ?? 0;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openProductDetails(p),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            // 1. Product Image Container with Badges (Fixed Height 110)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Container(
                                    height: 110,
                                    width: double.infinity,
                                    color: Colors.white,
                                    // Whole image, padded — same as the website product cards.
                                    padding: const EdgeInsets.all(8),
                                    child: p.imageUrl != null
                                        ? Image.network(
                                            p.imageUrl!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => Center(
                                              child: Text(p.imageEmoji, style: const TextStyle(fontSize: 44)),
                                            ),
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldPrimary),
                                                ),
                                              );
                                            },
                                          )
                                        : Center(
                                            child: Text(p.imageEmoji, style: const TextStyle(fontSize: 44)),
                                          ),
                                  ),
                                ),
                                if (p.badgeText != null)
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.emeraldPrimary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.badgeText!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (p.variants.isNotEmpty)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.slateDark.withAlpha(220),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(25),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.tune, size: 9, color: Colors.white),
                                          const SizedBox(width: 2.5),
                                          Text(
                                            '${p.variants.length + 1} OPTIONS',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // 2. Card Content Body
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Rating & Unit Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.unit,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10, color: AppTheme.slateMuted, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      if (ReviewService.getReviewCount(p.id) > 0)
                                        Row(
                                          children: [
                                            const Icon(Icons.star, size: 12, color: Colors.amber),
                                            const SizedBox(width: 2),
                                            Text(
                                              ReviewService.getAverageRating(p.id).toStringAsFixed(1),
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slateDark),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),

                                  // Variant Selector Preview Pill
                                  if (p.variants.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    GestureDetector(
                                      onTap: () => _openProductDetails(p),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.emeraldPrimary.withAlpha(16),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.emeraldPrimary.withAlpha(50)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.style_outlined, size: 9, color: AppTheme.emeraldPrimary),
                                            const SizedBox(width: 3),
                                            Flexible(
                                              child: Text(
                                                '${p.variants.length + 1} options available ▾',
                                                style: const TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.emeraldPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),

                                  // Product Title
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(minHeight: 28, maxHeight: 36),
                                    child: Text(
                                      p.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.slateDark,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Price Row (Dynamic range if variants have different prices)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.variants.isNotEmpty && p.priceMin != null && p.priceMax != null && p.priceMin != p.priceMax
                                              ? '\$${p.priceMin!.toStringAsFixed(2)} - \$${p.priceMax!.toStringAsFixed(2)}'
                                              : '\$${p.displayPrice.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: (p.variants.isNotEmpty && p.priceMin != null && p.priceMax != null && p.priceMin != p.priceMax) ? 12 : 14,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.emeraldPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (p.comparePrice != null && !(p.variants.isNotEmpty && p.priceMin != null && p.priceMax != null && p.priceMin != p.priceMax)) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '\$${p.comparePrice!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: AppTheme.slateMuted,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Action Buttons: Variant-Aware (+ CART & BUY NOW)
                                  if (p.variants.isEmpty && !p.inStock)
                                    Container(
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('OUT OF STOCK',
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.slateMuted)),
                                    )
                                  else if (p.variants.isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 30,
                                            child: OutlinedButton(
                                              onPressed: () => _openProductDetails(p),
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: prodTotalCartCount > 0 ? AppTheme.emeraldPrimary.withAlpha(20) : null,
                                                foregroundColor: AppTheme.emeraldPrimary,
                                                side: const BorderSide(color: AppTheme.emeraldPrimary, width: 1.2),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                                  child: Text(
                                                    prodTotalCartCount > 0 ? '$prodTotalCartCount IN CART ▾' : 'OPTIONS ▾',
                                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 8.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: SizedBox(
                                            height: 30,
                                            child: ElevatedButton(
                                              onPressed: () => _openProductDetails(p),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.coralAccent,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.zero,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              child: const FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                                  child: Text('BUY NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9.5)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        // Standard Product Add to Cart / Quantity Controller
                                        Expanded(
                                          child: q == 0
                                              ? SizedBox(
                                                  height: 30,
                                                  child: OutlinedButton(
                                                    onPressed: () => _updateQuantity(p.id, 1),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppTheme.emeraldPrimary,
                                                      side: const BorderSide(color: AppTheme.emeraldPrimary, width: 1.2),
                                                      padding: EdgeInsets.zero,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                    ),
                                                    child: const FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                                        child: Text('+ CART', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9.5)),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.emeraldPrimary,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () => _updateQuantity(p.id, -1),
                                                        child: const Icon(Icons.remove, size: 12, color: Colors.white),
                                                      ),
                                                      Text(
                                                        '$q',
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () => _updateQuantity(p.id, 1),
                                                        child: const Icon(Icons.add, size: 12, color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 4),

                                        // Standard BUY NOW Button
                                        Expanded(
                                          child: SizedBox(
                                            height: 30,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                if (q == 0) _updateQuantity(p.id, 1);
                                                if (!MockAuthService.isLoggedIn) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Text('Please log in or register to purchase products.'),
                                                      backgroundColor: AppTheme.coralAccent,
                                                      behavior: SnackBarBehavior.floating,
                                                      action: SnackBarAction(
                                                        label: 'LOG IN',
                                                        textColor: Colors.white,
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                                          ).then((_) {
                                                            if (mounted) setState(() {});
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                                  ).then((_) {
                                                    if (mounted) setState(() {});
                                                  });
                                                  return;
                                                }
                                                _openCartScreen();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.coralAccent,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.zero,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                                  child: Text(!MockAuthService.isLoggedIn ? 'LOG IN' : 'BUY NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9.5)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                    },
                  ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
  );
}
}
