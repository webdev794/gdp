import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../services/checkout_fees.dart';
import '../../services/location_service.dart';
import '../../services/mock_data_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/payment_sheet.dart';
import '../auth/login_screen.dart';
import '../../services/mock_auth_service.dart';
import '../location/location_picker_screen.dart';
import '../orders/order_tracking_screen.dart';
import '../../widgets/product_details_sheet.dart';

class CartItemEntry {
  final String key;
  final ProductModel product;
  final ProductVariantModel? variant;
  final int quantity;

  CartItemEntry({
    required this.key,
    required this.product,
    this.variant,
    required this.quantity,
  });

  String get displayName => variant != null ? '${product.name} (${variant!.label})' : product.name;
  String get displayUnit => variant != null ? variant!.label : product.unit;
  double get unitPrice => variant != null ? variant!.price : product.displayPrice;
  double? get comparePrice => variant != null ? variant!.comparePrice : product.comparePrice;
  String? get imageUrl => (variant?.imageUrl != null && variant!.imageUrl!.isNotEmpty) ? variant!.imageUrl : product.imageUrl;
  String get imageEmoji => product.imageEmoji;
  String get sku => (variant != null && variant!.sku.isNotEmpty) ? variant!.sku : (product.sku ?? 'GDP-${product.id}');
}

class CartScreen extends StatefulWidget {
  final Map<String, int> cartQuantities;
  final Function(String, int) onUpdateQuantity;
  final VoidCallback onClearCart;
  final List<ProductModel>? catalog;

  const CartScreen({
    super.key,
    required this.cartQuantities,
    required this.onUpdateQuantity,
    required this.onClearCart,
    this.catalog,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Promo codes removed: there is no promo-code support on the store backend.
  FeeEstimate _fees = FeeEstimate(0, 0, 0, 0, 0);

  void _openProductDetails(ProductModel product) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailsSheet(
        product: product,
        cartQuantities: widget.cartQuantities,
        onVariantQuantityChanged: (itemKey, qty) {
          final currentQty = widget.cartQuantities[itemKey] ?? 0;
          widget.onUpdateQuantity(itemKey, qty - currentQty);
          setState(() {});
        },
        onVariantBuyNow: (itemKey, qty) {
          Navigator.pop(context);
        },
        onQuantityChanged: (qty) {
          final currentQty = widget.cartQuantities[product.id] ?? 0;
          widget.onUpdateQuantity(product.id, qty - currentQty);
          setState(() {});
        },
        onBuyNow: (qty) {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _processCheckout(List<CartItemEntry> cartItems, double subtotal, double deliveryFee, double estimatedTax, double grandTotal) {
    if (!MockAuthService.isLoggedIn) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in or register to complete your purchase.'),
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
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery address is outside our ${LocationService.maxDeliveryRadiusKm.toStringAsFixed(0)} km delivery area.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PaymentSheet(
        totalAmount: grandTotal,
        itemCount: cartItems.fold(0, (sum, i) => sum + i.quantity),
        cart: {for (final e in cartItems) e.key: e.quantity},
        onOrderPlaced: (order) {
          widget.onClearCart();
          if (!mounted) return;
          _showOrderSuccessDialog(context, order);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    bool isLandscape = Responsive.isLandscape(context);

    final List<CartItemEntry> cartItems = [];
    final allProducts = [
      if (widget.catalog != null) ...widget.catalog!,
      ...MockDataService.products,
    ];

    widget.cartQuantities.forEach((key, qty) {
      if (qty > 0) {
        if (key.contains('__var_')) {
          final parts = key.split('__var_');
          final prodId = parts[0];
          final varId = parts[1];
          final p = allProducts.firstWhere(
            (prod) => prod.id == prodId,
            orElse: () => ProductModel(id: prodId, name: 'Grocery Item', categoryId: '', price: 0.0, unit: '', imageEmoji: '🛒'),
          );
          final v = p.variants.where((vr) => vr.id == varId).firstOrNull;
          cartItems.add(CartItemEntry(
            key: key,
            product: p,
            variant: v,
            quantity: qty,
          ));
        } else {
          final p = allProducts.firstWhere(
            (prod) => prod.id == key,
            orElse: () => ProductModel(id: key, name: 'Grocery Item', categoryId: '', price: 0.0, unit: '', imageEmoji: '🛒'),
          );
          cartItems.add(CartItemEntry(
            key: key,
            product: p,
            variant: null,
            quantity: qty,
          ));
        }
      }
    });

    double subtotal = cartItems.fold(0.0, (sum, entry) => sum + (entry.unitPrice * entry.quantity));
    // Same fee rules as the store checkout (Admin -> Store settings).
    final addr = LocationService.activeAddress;
    _fees = CheckoutFees.estimate(subtotal, km: addr.distanceKm, radiusKm: LocationService.maxDeliveryRadiusKm);
    double estimatedTax = _fees.tax;
    double deliveryFee = _fees.delivery;
    double grandTotal = _fees.total;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('My Cart 🛒', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onClearCart();
                setState(() {});
              },
              child: const Text('Clear All', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛍️', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Shopping Cart is Empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore fresh organic produce, dairy, and snacks!',
                    style: TextStyle(color: AppTheme.slateMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                    child: const Text('START SHOPPING'),
                  ),
                ],
              ),
            )
          : (isLandscape
              // Landscape / Tablet Split Layout
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Pane: Items List
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items in Order (${cartItems.length})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                            ),
                            const SizedBox(height: 10),
                            _buildItemsList(cartItems),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppTheme.borderSubtle),
                    // Right Pane: Address, Bill & Checkout Button
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildAddressCard(),
                            const SizedBox(height: 14),
                            _buildBillCard(subtotal, estimatedTax, deliveryFee, grandTotal),
                            const SizedBox(height: 16),
                            _buildCheckoutButton(
                              isIOS: isIOS,
                              grandTotal: grandTotal,
                              onTap: () => _processCheckout(cartItems, subtotal, deliveryFee, estimatedTax, grandTotal),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              // Portrait Mobile View
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  child: Responsive.maxContainer(
                    context: context,
                    maxWidth: 600,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddressCard(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Items in Order (${cartItems.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildItemsList(cartItems),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildBillCard(subtotal, estimatedTax, deliveryFee, grandTotal),
                        ),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                )),

      // Bottom Bar for Portrait Mode
      bottomNavigationBar: cartItems.isEmpty || isLandscape
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
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
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL PAYABLE',
                            style: TextStyle(color: AppTheme.slateMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '\$${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppTheme.emeraldPrimary, fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 2,
                      child: _buildCheckoutButton(
                        isIOS: isIOS,
                        grandTotal: grandTotal,
                        onTap: () => _processCheckout(cartItems, subtotal, deliveryFee, estimatedTax, grandTotal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCheckoutButton({required bool isIOS, required double grandTotal, required VoidCallback onTap}) {
    bool isDeliverable = LocationService.activeAddress.isDeliverable;
    bool isLoggedIn = MockAuthService.isLoggedIn;

    String buttonLabel;
    if (!isDeliverable) {
      buttonLabel = 'OUT OF RANGE (>15KM)';
    } else if (!isLoggedIn) {
      buttonLabel = 'LOG IN TO CHECKOUT ➔';
    } else {
      buttonLabel = isIOS ? 'CHECKOUT WITH PAY' : 'CHECKOUT NOW';
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: !isDeliverable
            ? AppTheme.errorRed
            : (!isLoggedIn
                ? AppTheme.coralAccent
                : (isIOS ? AppTheme.applePayBlack : AppTheme.emeraldPrimary)),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        minimumSize: const Size(140, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isIOS && isDeliverable && isLoggedIn) const Icon(Icons.apple, size: 20),
            if (isIOS && isDeliverable && isLoggedIn) const SizedBox(width: 6),
            Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    bool isDeliverable = LocationService.activeAddress.isDeliverable;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LocationPickerScreen(
              onAddressSelected: (addr) => setState(() {}),
            ),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDeliverable ? AppTheme.borderSubtle : AppTheme.errorRed,
            width: isDeliverable ? 1 : 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDeliverable ? AppTheme.sageLight : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Deliver to: ${LocationService.activeAddress.label}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDeliverable ? AppTheme.slateMuted : AppTheme.errorRed,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${LocationService.activeAddress.distanceKm.toStringAsFixed(1)} km)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocationService.activeAddress.fullAddress,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.slateMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<CartItemEntry> cartItems) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final itemTotal = item.unitPrice * item.quantity;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _openProductDetails(item.product),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.bgLight,
                          child: item.imageUrl != null
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Text(item.imageEmoji, style: const TextStyle(fontSize: 26)),
                                  ),
                                )
                              : Center(
                                  child: Text(item.imageEmoji, style: const TextStyle(fontSize: 26)),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (item.variant != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.emeraldPrimary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PACK SIZE',
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                                    ),
                                  ),
                                ],
                                Flexible(
                                  child: Text(
                                    '${item.displayUnit} • \$${item.unitPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.slateMuted, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${itemTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.emeraldPrimary, width: 1),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26),
                      icon: const Icon(Icons.remove, size: 14, color: AppTheme.emeraldPrimary),
                      onPressed: () {
                        widget.onUpdateQuantity(item.key, -1);
                        setState(() {});
                      },
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary, fontSize: 12.5),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26),
                      icon: const Icon(Icons.add, size: 14, color: AppTheme.emeraldPrimary),
                      onPressed: () {
                        widget.onUpdateQuantity(item.key, 1);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillCard(double subtotal, double estimatedTax, double deliveryFee, double grandTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details Summary',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
          ),
          const Divider(height: 18),
          _buildBillRow('Item Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          _buildBillRow(
            'Delivery Fee',
            deliveryFee == 0.0 ? 'FREE' : '\$${deliveryFee.toStringAsFixed(2)}',
            isFree: deliveryFee == 0.0,
          ),
          if (_fees.handling > 0) _buildBillRow('Handling Fee', '\$${_fees.handling.toStringAsFixed(2)}'),
          if (_fees.smallCart > 0) _buildBillRow('Small Basket Fee', '\$${_fees.smallCart.toStringAsFixed(2)}'),
          if (estimatedTax > 0) _buildBillRow('Tax (${CheckoutFees.taxPercent.toStringAsFixed(2)}%)', '\$${estimatedTax.toStringAsFixed(2)}'),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
              ),
              Text(
                '\$${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isFree = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.slateMuted, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isFree
                  ? AppTheme.emeraldPrimary
                  : (isDiscount ? AppTheme.coralAccent : AppTheme.slateDark),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(BuildContext context, OrderModel createdOrder) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        content: Responsive.maxContainer(
          context: context,
          maxWidth: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppTheme.emeraldPrimary, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Placed! 🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Order ${createdOrder.orderNumber} is confirmed!\nDelivery PIN: ${createdOrder.deliveryCode}',
                style: const TextStyle(color: AppTheme.slateMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.delivery_dining, size: 18),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close cart
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: createdOrder)),
                  );
                },
                label: const Text('TRACK LIVE ORDER ⚡'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Back to Home', style: TextStyle(color: AppTheme.slateMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
