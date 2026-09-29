// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocerly/main.dart';
import 'package:grocerly/screens/home/home_screen.dart';
import 'package:grocerly/screens/auth/login_screen.dart';
import 'package:grocerly/models/address_model.dart';
import 'package:grocerly/models/order_model.dart';
import 'package:grocerly/models/product_model.dart';
import 'package:grocerly/models/user_model.dart';
import 'package:grocerly/screens/cart/cart_screen.dart';
import 'package:grocerly/screens/orders/order_tracking_screen.dart';
import 'package:grocerly/services/api_service.dart';
import 'package:grocerly/services/location_service.dart';
import 'package:grocerly/services/mock_auth_service.dart';
import 'package:grocerly/services/review_service.dart';
import 'package:grocerly/widgets/add_address_sheet.dart';
import 'package:grocerly/widgets/payment_sheet.dart';
import 'package:grocerly/widgets/product_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StoreApp());
    expect(find.byType(StoreApp), findsOneWidget);
  });

  testWidgets('ProductDetailsSheet displays all database information and close button', (tester) async {
    final product = ProductModel(
      id: '55',
      name: 'Organic Lemon',
      categoryId: '1',
      categoryName: 'Fruits & Vegetables',
      categorySlug: 'fresh-produce',
      price: 1.00,
      comparePrice: 2.00,
      unit: '1 pack',
      sku: 'LM343235',
      inventoryQuantity: 99,
      description: 'Fresh lemons are vibrant, smooth, and citrus-scented oval fruits.',
      imageEmoji: '🍋',
      variants: [
        ProductVariantModel(
          id: '6',
          productId: '55',
          label: 'Set of 6 pcs',
          sku: 'LMsds34',
          price: 5.00,
          comparePrice: 10.00,
          inventoryQuantity: 10,
        ),
      ],
    );

    int qty = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductDetailsSheet(
            product: product,
            initialQuantity: qty,
            onQuantityChanged: (q) => qty = q,
            onBuyNow: (q) => qty = q,
          ),
        ),
      ),
    );

    expect(find.text('Organic Lemon'), findsOneWidget);
    expect(find.text('Fruits & Vegetables'), findsNWidgets(2));
    expect(find.textContaining('LM343235'), findsWidgets);
    expect(find.text('Fresh lemons are vibrant, smooth, and citrus-scented oval fruits.'), findsOneWidget);
    expect(find.text('Set of 6 pcs'), findsOneWidget);
    expect(find.text('CLOSE'), findsOneWidget);
  });

  testWidgets('ProductDetailsSheet switches variants and displays in-cart count', (tester) async {
    final product = ProductModel(
      id: '55',
      name: 'Organic Lemon',
      categoryId: '1',
      categoryName: 'Fruits & Vegetables',
      price: 2.99,
      unit: '1 kg',
      imageEmoji: '🍋',
      variants: [
        ProductVariantModel(
          id: '6',
          productId: '55',
          label: 'Set of 6 pcs',
          sku: 'LMsds34',
          price: 5.00,
          inventoryQuantity: 10,
        ),
        ProductVariantModel(
          id: '7',
          productId: '55',
          label: 'Set of 10 pcs',
          sku: 'LM8734',
          price: 8.00,
          inventoryQuantity: 10,
        ),
      ],
    );

    final cartQuantities = <String, int>{
      '55': 1,
      '55__var_6': 3,
    };

    String? updatedKey;
    int? updatedQty;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductDetailsSheet(
            product: product,
            cartQuantities: cartQuantities,
            onVariantQuantityChanged: (key, q) {
              updatedKey = key;
              updatedQty = q;
            },
            onQuantityChanged: (_) {},
            onBuyNow: (_) {},
          ),
        ),
      ),
    );

    // Initial state: standard pack selected, quantity is 1
    expect(find.text('1 in cart'), findsWidgets);
    expect(find.text('3 in cart'), findsOneWidget); // Variant 6 card badge

    // Tap on Variant 6 ('Set of 6 pcs')
    await tester.ensureVisible(find.text('Set of 6 pcs'));
    await tester.tap(find.text('Set of 6 pcs'));
    await tester.pumpAndSettle();

    // Now current selection is Variant 6 with quantity 3
    expect(find.text('3 in cart'), findsWidgets);
    expect(find.text('\$5.00'), findsWidgets);

    // Tap increment for Variant 6
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();

    expect(updatedKey, '55__var_6');
    expect(updatedQty, 4);
    expect(find.text('4 in cart'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CartScreen displays variant items with PACK SIZE badge and correct pricing', (tester) async {
    final product = ProductModel(
      id: '55',
      name: 'Organic Lemon',
      categoryId: '1',
      price: 2.99,
      unit: '1 kg',
      imageEmoji: '🍋',
      variants: [
        ProductVariantModel(
          id: '6',
          productId: '55',
          label: 'Set of 6 pcs',
          sku: 'LMsds34',
          price: 5.00,
          inventoryQuantity: 10,
        ),
      ],
    );

    final cartQuantities = <String, int>{
      '55__var_6': 2,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartQuantities: cartQuantities,
          catalog: [product],
          onUpdateQuantity: (id, delta) {},
          onClearCart: () {},
        ),
      ),
    );

    expect(find.text('Organic Lemon (Set of 6 pcs)'), findsWidgets);
    expect(find.text('PACK SIZE'), findsWidgets);
    expect(find.textContaining('\$10.00'), findsWidgets);
  });

  group('Product & Variant Models Functionality', () {
    test('Standard product calculates displayPrice and discount correctly', () {
      final product = ProductModel(
        id: 'p1',
        name: 'Organic Honey',
        categoryId: 'c1',
        price: 8.0,
        comparePrice: 10.0,
        unit: '500g',
        imageEmoji: '🍯',
      );

      expect(product.displayPrice, 8.0);
      expect(product.comparePrice, 10.0);
      expect(product.comparePrice != null && product.comparePrice! > product.price, isTrue);
      expect(product.variants.isEmpty, isTrue);
    });

    test('Multi-variant product calculates min/max price range correctly', () {
      final product = ProductModel(
        id: 'p2',
        name: 'Farm Fresh Eggs',
        categoryId: 'c2',
        price: 4.50,
        unit: '6 pcs',
        imageEmoji: '🥚',
        priceMin: 4.50,
        priceMax: 18.00,
        variants: [
          ProductVariantModel(
            id: 'v1',
            productId: 'p2',
            label: 'Pack of 6',
            sku: 'EGG-6',
            price: 4.50,
            comparePrice: 5.50,
          ),
          ProductVariantModel(
            id: 'v2',
            productId: 'p2',
            label: 'Pack of 12',
            sku: 'EGG-12',
            price: 8.00,
            comparePrice: 10.00,
          ),
          ProductVariantModel(
            id: 'v3',
            productId: 'p2',
            label: 'Pack of 30',
            sku: 'EGG-30',
            price: 18.00,
            comparePrice: 22.00,
          ),
        ],
      );

      expect(product.variants.length, 3);
      expect(product.priceMin, 4.50);
      expect(product.priceMax, 18.00);
      expect(product.variants.first.label, 'Pack of 6');
      expect(product.variants.last.price, 18.00);
    });
  });

  group('Cart Billing & Promo Calculations', () {
    test('Delivery fee logic: charges \$2.99 under \$15, FREE over \$15', () {
      double subtotalSmall = 12.00;
      double deliverySmall = subtotalSmall > 15.0 || subtotalSmall == 0.0 ? 0.0 : 2.99;
      expect(deliverySmall, 2.99);

      double subtotalLarge = 25.00;
      double deliveryLarge = subtotalLarge > 15.0 || subtotalLarge == 0.0 ? 0.0 : 2.99;
      expect(deliveryLarge, 0.0);

      double subtotalEmpty = 0.00;
      double deliveryEmpty = subtotalEmpty > 15.0 || subtotalEmpty == 0.0 ? 0.0 : 2.99;
      expect(deliveryEmpty, 0.0);
    });

    test('Tax and Grand Total calculations with discount', () {
      double subtotal = 20.00;
      double tax = subtotal * 0.08;
      double delivery = subtotal > 15.0 ? 0.0 : 2.99;
      double discount = 2.50;
      double grandTotal = (subtotal + tax + delivery - discount).clamp(0.0, 99999.0);

      expect(tax, 1.60);
      expect(delivery, 0.0);
      expect(grandTotal, 19.10);
    });
  });

  group('Location & Delivery Radius Calculations', () {
    test('Haversine distance calculation is accurate', () {
      double dist = LocationService.calculateDistanceKm(
        LocationService.storeLat,
        LocationService.storeLng,
        30.7259,
        76.7681,
      );

      expect(dist, greaterThan(5.0));
      expect(dist, lessThan(9.0));
    });

    test('isDeliverable checks threshold correctly against radius', () {
      expect(LocationService.isDeliverable(5.0), isTrue);
      expect(LocationService.isDeliverable(14.9), isTrue);
      expect(LocationService.isDeliverable(25.0), isTrue);
      expect(LocationService.isDeliverable(25.1), isFalse);
    });

    test('calculateDeliveryMinutes scales dynamically with distance', () {
      expect(LocationService.calculateDeliveryMinutes(0.0), 8);
      expect(LocationService.calculateDeliveryMinutes(5.0), 18);
      expect(LocationService.calculateDeliveryMinutes(30.0), 0);
    });
  });

  group('Authentication & User Session Functionality', () {
    test('MockAuthService registers new user and prevents duplicate email', () async {
      String uniqueEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final res = await MockAuthService.register(
        firstName: 'Alice',
        lastName: 'Smith',
        email: uniqueEmail,
        phone: '+1 555-4321',
        password: 'password123',
      );

      expect(res['success'], isTrue);
      expect(MockAuthService.isLoggedIn, isTrue);
      expect(MockAuthService.currentUser?.fullName, 'Alice Smith');

      final dup = await MockAuthService.register(
        firstName: 'Bob',
        lastName: 'Jones',
        email: uniqueEmail,
        phone: '+1 555-9999',
        password: 'password123',
      );

      expect(dup['success'], isFalse);
      expect(dup['message'], contains('already registered'));
    });

    test('MockAuthService login and logout lifecycle', () async {
      final res = await MockAuthService.login('alice@example.com', 'password');
      expect(res['success'], isTrue);
      expect(MockAuthService.isLoggedIn, isTrue);

      MockAuthService.logout();
      expect(MockAuthService.isLoggedIn, isFalse);
      expect(MockAuthService.currentUser, isNull);
    });
  });

  group('Order Creation & Tracking Lifecycle', () {
    test('OrderModel reads a store order (cents, status, address object)', () {
      final order = OrderModel.fromJson({
        'id': 32,
        'status': 'completed',
        'payment_method': 'cod',
        'payment_status': 'paid',
        'subtotal_cents': 449,
        'tax_cents': 40,
        'delivery_fee_cents': 299,
        'handling_fee_cents': 99,
        'small_cart_fee_cents': 199,
        'gift_card_discount_cents': 100,
        'total_cents': 986,
        'delivery_code': null,
        'delivery_address': {'line1': 'Kakata-Harbel Road', 'city': 'Kakata', 'state': 'Margibi County'},
        'created_at': '2026-09-29T04:42:46.000000Z',
        'items': [
          {'id': 45, 'product_id': 2, 'product_name': 'Gala Apples', 'variant_label': null, 'quantity': 1, 'unit_price_cents': 449, 'line_total_cents': 449},
        ],
      });

      expect(order.orderNumber, '#32');
      expect(order.status, 'delivered');
      expect(order.paymentMethod, 'COD');
      expect(order.subtotal, 4.49);
      expect(order.deliveryFee, closeTo(5.97, 0.001));
      expect(order.discount, 1.00);
      expect(order.total, 9.86);
      expect(order.deliveryCode, '');
      expect(order.deliveryAddress, 'Kakata-Harbel Road, Kakata, Margibi County');
      expect(order.items.single.totalPrice, 4.49);
    });

    test('OrderModel copyWith updates rider review and rating', () {
      final original = OrderModel(
        id: 'ord_123',
        orderNumber: 'ORD-123456',
        items: [],
        subtotal: 10.0,
        deliveryFee: 2.99,
        tax: 0.80,
        discount: 0.0,
        total: 13.79,
        paymentMethod: 'GOOGLE_PAY',
        paymentStatus: 'PAID',
        deliveryAddress: 'Home',
        deliveryCode: '7821',
        status: 'out_for_delivery',
        createdAt: DateTime.now(),
      );

      expect(original.riderReviewRating, isNull);

      final rated = original.copyWith(
        riderReviewRating: 5,
        riderReviewComment: 'Super fast delivery!',
      );

      expect(rated.riderReviewRating, 5);
      expect(rated.riderReviewComment, 'Super fast delivery!');
      expect(rated.deliveryCode, '7821');
    });
  });

  group('Interactive UI Widget Functionality Tests', () {
    testWidgets('Checkout sheet offers only real payment methods from store settings', (tester) async {
      ApiService.codEnabled = true;
      ApiService.stripePublishableKey = ''; // no card key -> card hidden

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSheet(
              totalAmount: 35.00,
              itemCount: 2,
              cart: const {'1': 2},
              onOrderPlaced: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('~\$35.00'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.text('Credit / Debit Card'), findsNothing);
      expect(find.text('Google Pay (GPay)'), findsNothing);
      expect(find.text('PLACE ORDER (PAY ON DELIVERY)'), findsOneWidget);
    });

    testWidgets('AddAddressSheet validates required fields and submits address', (tester) async {
      AddressModel? savedAddress;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddAddressSheet(
              initialAddressLine: '456 Elm St',
              city: 'Mohali',
              state: 'Punjab',
              zipCode: '160055',
              latitude: 30.6908,
              longitude: 76.7114,
              onAddressSaved: (addr) => savedAddress = addr,
            ),
          ),
        ),
      );

      // Submitting empty should trigger validation
      final saveBtn = find.byType(ElevatedButton);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
      expect(savedAddress, isNull);

      // Enter flat number
      final flatField = find.widgetWithText(TextFormField, 'House / Flat No. *');
      await tester.enterText(flatField, 'Flat 101');
      await tester.pump();

      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedAddress, isNotNull);
      expect(savedAddress!.flatNo, 'Flat 101');
    });

    testWidgets('OrderTrackingScreen displays 4-digit PIN and delivery stepper', (tester) async {
      final order = OrderModel(
        id: 'ord_test_track',
        orderNumber: 'ORD-554433',
        items: [
          OrderItem(
            id: 'it1',
            productId: 'p1',
            productName: 'Fresh Strawberries',
            unit: '1 box',
            emoji: '🍓',
            quantity: 1,
            unitPrice: 4.50,
            totalPrice: 4.50,
          ),
        ],
        subtotal: 4.50,
        deliveryFee: 2.99,
        tax: 0.36,
        discount: 0.0,
        total: 7.85,
        paymentMethod: 'APPLE_PAY',
        paymentStatus: 'PAID',
        deliveryAddress: 'Phase 8B, Mohali',
        deliveryCode: '6192',
        status: 'out_for_delivery',
        createdAt: DateTime.now(),
        riderName: 'Marcus Vance',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderTrackingScreen(order: order),
        ),
      );

      expect(find.text('Track ORD-554433'), findsOneWidget);
      expect(find.text('Order status'), findsOneWidget);
      expect(find.text('ON THE WAY'), findsOneWidget);
      expect(find.text('6192'), findsOneWidget);
      expect(find.text('Marcus Vance'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsOneWidget);
    });

    test('GDP Unified Geocode Search and Reverse APIs return valid structured data', () async {
      // Test search
      final searchResults = await ApiService.geocodeSearch('Mohali', lat: 30.6908, lng: 76.7114);
      expect(searchResults, isA<List<Map<String, dynamic>>>());

      // Test reverse
      final reverseResult = await ApiService.geocodeReverse(30.6908804, 76.7114879);
      if (reverseResult != null) {
        expect(reverseResult.containsKey('city') || reverseResult.containsKey('label'), isTrue);
        expect(reverseResult['lat'], isNotNull);
        expect(reverseResult['lon'], isNotNull);
      }
    });

    test('ReviewService isolates reviews per product and computes dynamic average', () async {
      SharedPreferences.setMockInitialValues({});
      await ReviewService.init();
      ReviewService.clearMemoryForTesting();

      expect(ReviewService.getReviewCount('p_apple'), 0);
      expect(ReviewService.getAverageRating('p_apple'), 0.0);
      expect(ReviewService.getReviewCount('p_banana'), 0);

      // Add review to p_apple only
      await ReviewService.addReview(
        productId: 'p_apple',
        userId: 'u1',
        userName: 'Alice',
        rating: 5.0,
        comment: 'Super crisp and delicious!',
      );

      // Verify p_apple has 1 review
      expect(ReviewService.getReviewCount('p_apple'), 1);
      expect(ReviewService.getAverageRating('p_apple'), 5.0);
      expect(ReviewService.getReviews('p_apple').first.comment, 'Super crisp and delicious!');

      // Verify p_banana remains completely untouched (0 reviews)
      expect(ReviewService.getReviewCount('p_banana'), 0);
      expect(ReviewService.getAverageRating('p_banana'), 0.0);
      expect(ReviewService.getReviews('p_banana').isEmpty, isTrue);

      // Add second review to p_apple
      await ReviewService.addReview(
        productId: 'p_apple',
        userId: 'u2',
        userName: 'Bob',
        rating: 4.0,
        comment: 'Good quality, fast delivery.',
      );

      // Average should now be 4.5
      expect(ReviewService.getReviewCount('p_apple'), 2);
      expect(ReviewService.getAverageRating('p_apple'), 4.5);
    });

    testWidgets('ProductDetailsSheet displays customer reviews section and requires login for guest', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ReviewService.init();
      ReviewService.clearMemoryForTesting();
      MockAuthService.logout(); // Guest user

      final product = ProductModel(
        id: 'test_item_99',
        name: 'Fresh Strawberries',
        categoryId: '1',
        categoryName: 'Berries',
        price: 3.99,
        unit: '250g pack',
        imageEmoji: '🍓',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductDetailsSheet(
              product: product,
              initialQuantity: 0,
              onQuantityChanged: (_) {},
              onBuyNow: (_) {},
            ),
          ),
        ),
      );

      // Verify top rating badge shows "No reviews yet"
      expect(find.text('No reviews yet'), findsWidgets);

      // Scroll down to reviews section
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify reviews header and empty state
      expect(find.text('Customer Reviews'), findsOneWidget);
      expect(find.text('No reviews yet'), findsWidgets);
      expect(find.text('Be the first verified customer to share your thoughts on Fresh Strawberries!'), findsOneWidget);

      // Guest prompt
      expect(find.text('Write a Review'), findsOneWidget);
      expect(find.text('LOG IN'), findsOneWidget);

      // Now simulate logged-in user
      MockAuthService.setCurrentUser(
        UserModel(id: 'u_tester', firstName: 'Sarah', lastName: 'Connor', email: 'sarah@test.com', phone: '1234567890'),
      );

      // Re-render sheet
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductDetailsSheet(
              product: product,
              initialQuantity: 0,
              onQuantityChanged: (_) {},
              onBuyNow: (_) {},
            ),
          ),
        ),
      );
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Composer should now be visible with user's name
      expect(find.text('Rate & Review as Sarah Connor'), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);

      // Clean up
      MockAuthService.logout();
      ReviewService.clearMemoryForTesting();
    });

    testWidgets('HomeScreen Drawer hides member items when logged out and shows them when logged in', (tester) async {
      MockAuthService.logout();

      await tester.pumpWidget(const StoreApp());
      await tester.pumpAndSettle();

      // Tap drawer menu icon
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify guest header
      expect(find.text('Guest Customer'), findsOneWidget);
      expect(find.text('Welcome to Tudee Shopping Center'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('REGISTER'), findsOneWidget);

      // Guest: Home & Member Features banner should be present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Member Features'), findsOneWidget);
      expect(find.text('LOG IN TO ACCESS'), findsOneWidget);

      // Guest: Orders, Addresses, and Support should be HIDDEN
      expect(find.text('My Orders 📦'), findsNothing);
      expect(find.text('Track Active Order ⚡'), findsNothing);
      expect(find.text('Saved Delivery Addresses'), findsNothing);
      expect(find.text('24/7 Live Support Chat 💬'), findsNothing);

      // Close drawer
      Navigator.pop(tester.element(find.byType(Drawer)));
      await tester.pumpAndSettle();

      // Now log in user
      MockAuthService.setCurrentUser(
        UserModel(id: 'usr_active', firstName: 'John', lastName: 'Doe', email: 'john@example.com', phone: '1234567890'),
      );

      // Re-pump HomeScreen with UniqueKey so it rebuilds with new user
      await tester.pumpWidget(MaterialApp(home: HomeScreen(key: UniqueKey())));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Logged in: Member items should now be visible
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Account'), findsOneWidget);
      expect(find.text('My Orders 📦'), findsOneWidget);
      expect(find.text('Track Active Order ⚡'), findsOneWidget);
      expect(find.text('Saved Delivery Addresses'), findsOneWidget);
      // The drawer list is lazy and taller with the store logo — scroll to its last item.
      await tester.dragUntilVisible(find.text('24/7 Live Support Chat 💬'), find.byType(ListView).last, const Offset(0, -100));
      expect(find.text('24/7 Live Support Chat 💬'), findsOneWidget);

      // Clean up
      MockAuthService.logout();
    });

    testWidgets('Guest user cannot buy products without logging in and is directed to login', (tester) async {
      MockAuthService.logout();

      final product = ProductModel(
        id: 'buy_test_item',
        name: 'Fresh Mangoes',
        categoryId: '1',
        price: 4.99,
        unit: '1 kg',
        imageEmoji: '🥭',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductDetailsSheet(
              product: product,
              initialQuantity: 1,
              onQuantityChanged: (_) {},
              onBuyNow: (_) {},
            ),
          ),
        ),
      );

      // Button says LOG IN TO BUY
      expect(find.text('LOG IN TO BUY ➔'), findsOneWidget);

      // Tap buy button as guest
      await tester.tap(find.text('LOG IN TO BUY ➔'));
      await tester.pumpAndSettle();

      // Should open LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
