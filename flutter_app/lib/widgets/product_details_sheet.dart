import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../screens/auth/login_screen.dart';
import '../services/api_service.dart';
import '../services/mock_auth_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';

class ProductDetailsSheet extends StatefulWidget {
  final ProductModel product;
  final int initialQuantity;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<int> onBuyNow;
  final Map<String, int>? cartQuantities;
  final Function(String itemKey, int quantity)? onVariantQuantityChanged;
  final Function(String itemKey, int quantity)? onVariantBuyNow;

  const ProductDetailsSheet({
    super.key,
    required this.product,
    this.initialQuantity = 0,
    required this.onQuantityChanged,
    required this.onBuyNow,
    this.cartQuantities,
    this.onVariantQuantityChanged,
    this.onVariantBuyNow,
  });

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  late ProductModel _product;
  late int _quantity;
  ProductVariantModel? _selectedVariant;
  int _currentImageIndex = 0;
  bool _isLoadingFreshData = false;
  final PageController _pageController = PageController();

  String get _currentCartKey {
    return _selectedVariant != null
        ? '${_product.id}__var_${_selectedVariant!.id}'
        : _product.id;
  }

  int _getQtyForSelection(ProductVariantModel? variant) {
    if (widget.cartQuantities != null) {
      final key = variant != null ? '${_product.id}__var_${variant.id}' : _product.id;
      return widget.cartQuantities![key] ?? 0;
    }
    return _quantity;
  }

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _quantity = widget.cartQuantities != null
        ? (widget.cartQuantities![_product.id] ?? 0)
        : widget.initialQuantity;
    _fetchFreshDetails();
    ReviewService.changeNotifier.addListener(_onReviewsUpdated);
    // Shared reviews from the store (same as the website).
    if (_product.slug.isNotEmpty) ReviewService.load(_product.id, _product.slug);
  }

  void _onReviewsUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchFreshDetails() async {
    if (_product.slug.isEmpty) return;
    setState(() => _isLoadingFreshData = true);
    final fresh = await ApiService.getProductBySlug(_product.slug);
    if (mounted && fresh != null) {
      setState(() {
        _product = fresh;
        _isLoadingFreshData = false;
        if (_selectedVariant != null) {
          _selectedVariant = _product.variants
              .where((v) => v.id == _selectedVariant!.id)
              .firstOrNull;
        }
        _quantity = _getQtyForSelection(_selectedVariant);
      });
    } else if (mounted) {
      setState(() => _isLoadingFreshData = false);
    }
  }

  @override
  void dispose() {
    ReviewService.changeNotifier.removeListener(_onReviewsUpdated);
    _pageController.dispose();
    super.dispose();
  }

  double get _currentPrice {
    if (_selectedVariant != null) {
      return _selectedVariant!.price;
    }
    return _product.displayPrice;
  }

  double? get _currentComparePrice {
    if (_selectedVariant != null) {
      return _selectedVariant!.comparePrice;
    }
    return _product.comparePrice;
  }

  int get _currentInventory {
    if (_selectedVariant != null) {
      return _selectedVariant!.inventoryQuantity;
    }
    return _product.inventoryQuantity ?? 100;
  }

  bool get _isCurrentInStock {
    if (_selectedVariant != null) {
      return _selectedVariant!.inventoryQuantity > 0 && _selectedVariant!.isActive;
    }
    return _product.inStock;
  }

  List<String> get _allImages {
    final list = <String>[];
    if (_selectedVariant?.imageUrl != null && _selectedVariant!.imageUrl!.isNotEmpty) {
      list.add(_selectedVariant!.imageUrl!);
    }
    if (_product.imageUrl != null && _product.imageUrl!.isNotEmpty && !list.contains(_product.imageUrl)) {
      list.add(_product.imageUrl!);
    }
    for (final img in _product.galleryImages) {
      if (!list.contains(img)) {
        list.add(img);
      }
    }
    for (final v in _product.variants) {
      if (v.imageUrl != null && v.imageUrl!.isNotEmpty && !list.contains(v.imageUrl)) {
        list.add(v.imageUrl!);
      }
    }
    return list;
  }

  void _selectVariant(ProductVariantModel? variant) {
    setState(() {
      _selectedVariant = variant;
      _quantity = _getQtyForSelection(variant);
    });

    if (variant?.imageUrl != null && variant!.imageUrl!.isNotEmpty) {
      final imgList = _allImages;
      final idx = imgList.indexOf(variant.imageUrl!);
      if (idx != -1 && _pageController.hasClients) {
        _pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _increment() {
    setState(() {
      _quantity++;
    });
    final key = _currentCartKey;
    if (widget.onVariantQuantityChanged != null) {
      widget.onVariantQuantityChanged!(key, _quantity);
    }
    widget.onQuantityChanged(_quantity);
  }

  void _decrement() {
    if (_quantity > 0) {
      setState(() {
        _quantity--;
      });
      final key = _currentCartKey;
      if (widget.onVariantQuantityChanged != null) {
        widget.onVariantQuantityChanged!(key, _quantity);
      }
      widget.onQuantityChanged(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _allImages;
    final compare = _currentComparePrice;
    final price = _currentPrice;
    final hasDiscount = compare != null && compare > price;
    final discountPercent = hasDiscount ? (((compare - price) / compare) * 100).round() : 0;
    final youSave = hasDiscount ? (compare - price) : 0.0;
    final dynamicReviewCount = ReviewService.getReviewCount(_product.id);
    final dynamicAvgRating = ReviewService.getAverageRating(_product.id);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. Top Header Handle & Close Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category Chip / Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldPrimary.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_product.imageEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        _product.categoryName ?? 'Groceries',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.emeraldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Drag Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Prominent Close Button
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.close_rounded, size: 20, color: AppTheme.slateDark),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. Scrollable Body containing all Product & DB Information
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery PageView
                  Stack(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: images.length,
                                  onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                                  itemBuilder: (context, index) {
                                    return Image.network(
                                      images[index],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(_product.imageEmoji, style: const TextStyle(fontSize: 70)),
                                      ),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppTheme.emeraldPrimary,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Text(_product.imageEmoji, style: const TextStyle(fontSize: 80)),
                              ),
                      ),

                      // Discount Badge
                      if (hasDiscount)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.coralAccent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              '$discountPercent% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),

                      // In-Stock / Out-of-Stock Badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isCurrentInStock ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isCurrentInStock ? 'IN STOCK ($_currentInventory)' : 'OUT OF STOCK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),

                      // Image Dots Indicator
                      if (images.length > 1)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (i) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentImageIndex == i ? 14 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == i
                                      ? AppTheme.emeraldPrimary
                                      : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Rating & Delivery ETA Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              dynamicReviewCount > 0
                                  ? dynamicAvgRating.toStringAsFixed(1)
                                  : 'No reviews yet',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            if (dynamicReviewCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '($dynamicReviewCount reviews)',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldPrimary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, size: 14, color: AppTheme.emeraldPrimary),
                            SizedBox(width: 3),
                            Text(
                              '10 MINS DELIVERY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.emeraldPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Product Title
                  Text(
                    _product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.slateDark,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Unit & SKU Subtitle
                  Text(
                    _product.unit.isNotEmpty ? _product.unit : (_product.categoryName ?? ''),
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.slateMuted, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 14),

                  // Price and Savings Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F9F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.emeraldPrimary.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.emeraldPrimary,
                                  ),
                                ),
                                if (compare != null && compare > price) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${compare.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.slateMuted,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Inclusive of all applicable taxes',
                              style: TextStyle(fontSize: 11, color: AppTheme.slateMuted),
                            ),
                          ],
                        ),
                        if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.coralAccent.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.coralAccent.withAlpha(60)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'SAVE \$${youSave.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.coralAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '($discountPercent% Discount)',
                                  style: const TextStyle(
                                    color: AppTheme.coralAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 3. Variants Selection Section (Pack Sizes)
                  if (_product.variants.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Pack Size / Option',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
                        ),
                        Text(
                          '${_product.variants.length + 1} options available',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.slateMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Base / Standard Option
                        _buildVariantCard(
                          label: _product.unit.isNotEmpty ? _product.unit : 'Standard Pack',
                          price: _product.displayPrice,
                          comparePrice: _product.comparePrice,
                          isSelected: _selectedVariant == null,
                          inCartQty: _getQtyForSelection(null),
                          onTap: () => _selectVariant(null),
                        ),
                        // Each Database Variant
                        ..._product.variants.map((v) {
                          return _buildVariantCard(
                            label: v.label,
                            price: v.price,
                            comparePrice: v.comparePrice,
                            isSelected: _selectedVariant?.id == v.id,
                            inCartQty: _getQtyForSelection(v),
                            onTap: () => _selectVariant(v),
                          );
                        }),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 4. Product Description Section (from DB)
                  const Text(
                    'Product Description',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      (_product.description != null && _product.description!.trim().isNotEmpty)
                          ? _product.description!
                          : 'Farm-fresh, high quality ${_product.name.toLowerCase()} sourced and packaged following strict safety and quality standards.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.45),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 5. Product details (customer-facing only; no internal/admin fields)
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.emeraldPrimary),
                      const SizedBox(width: 6),
                      const Text(
                        'Product details',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
                      ),
                      if (_isLoadingFreshData) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldPrimary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        _buildSpecRow('Category', _product.categoryName ?? 'Grocery'),
                        if (_product.unit.isNotEmpty) _buildSpecRow('Pack / Unit', _product.unit),
                        _buildSpecRow('Availability', _isCurrentInStock ? 'In stock' : 'Out of stock', isLast: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 6. Customer Reviews & Ratings Section
                  _buildCustomerReviewsSection(),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // 6. Bottom Sticky Action Bar (Cart + Buy Now + Close)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Quantity Controller or Add to Cart Button
                  if (_quantity == 0)
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        onPressed: _isCurrentInStock ? _increment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          minimumSize: const Size(double.infinity, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _isCurrentInStock ? 'ADD TO CART' : 'OUT OF STOCK',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _decrement,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                child: const SizedBox(
                                  width: 38,
                                  height: 46,
                                  child: Center(
                                    child: Icon(Icons.remove, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$_quantity in cart',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _increment,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                child: const SizedBox(
                                  width: 38,
                                  height: 46,
                                  child: Center(
                                    child: Icon(Icons.add, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  // BUY NOW Button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _isCurrentInStock
                          ? () {
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
                                        );
                                      },
                                    ),
                                  ),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                                return;
                              }
                              final finalQty = _quantity > 0 ? _quantity : 1;
                              final key = _currentCartKey;
                              if (widget.onVariantBuyNow != null) {
                                widget.onVariantBuyNow!(key, finalQty);
                              }
                              widget.onBuyNow(finalQty);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coralAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        minimumSize: const Size(double.infinity, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          !MockAuthService.isLoggedIn ? 'LOG IN TO BUY ➔' : 'BUY NOW ➔',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Close Button
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(54, 46),
                      foregroundColor: AppTheme.slateDark,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantCard({
    required String label,
    required double price,
    double? comparePrice,
    required bool isSelected,
    int inCartQty = 0,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emeraldPrimary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.emeraldPrimary : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle, size: 14, color: AppTheme.emeraldPrimary),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? AppTheme.emeraldPrimary : AppTheme.slateDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppTheme.emeraldPrimary : AppTheme.slateDark,
                  ),
                ),
                if (comparePrice != null && comparePrice > price) ...[
                  const SizedBox(width: 4),
                  Text(
                    '\$${comparePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.slateMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            if (inCartQty > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$inCartQty in cart',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String title, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slateDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CUSTOMER REVIEWS & RATINGS SECTION
  // ==========================================

  Widget _buildCustomerReviewsSection() {
    final reviews = ReviewService.getReviews(_product.id);
    final count = ReviewService.getReviewCount(_product.id);
    final avgRating = ReviewService.getAverageRating(_product.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            const Icon(Icons.rate_review_outlined, size: 18, color: AppTheme.emeraldPrimary),
            const SizedBox(width: 6),
            const Text(
              'Customer Reviews',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
            ),
            const Spacer(),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 13, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($count)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Reviews list or empty placeholder
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 34, color: Colors.grey.shade400),
                const SizedBox(height: 6),
                const Text(
                  'No reviews yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.slateDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first verified customer to share your thoughts on ${_product.name}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          Column(
            children: reviews.map((r) => _buildReviewCard(r)).toList(),
          ),

        const SizedBox(height: 14),

        // Reviews are written from an order (My Orders -> order -> Rate), once per item per order.
        Text('Ordered this? Rate it from My Orders.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.emeraldPrimary.withAlpha(30),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emeraldPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slateDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatReviewDate(review.createdAt),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (starIdx) {
                  return Icon(
                    starIdx < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade800,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
