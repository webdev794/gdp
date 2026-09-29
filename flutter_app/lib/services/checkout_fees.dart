/// The store's checkout fee rules (from GET /api/config), computed the same way
/// as the backend (app/Support/CheckoutFees.php + CheckoutController), so the
/// basket shows the total the order will actually be charged.
class CheckoutFees {
  static String deliveryMode = 'fixed'; // 'fixed' or 'distance'
  static int deliveryFeeCents = 299;
  static int nearFeeCents = 199;
  static int farFeeCents = 599;
  static int freeDeliveryThresholdCents = 3500;
  static int handlingFeeCents = 99;
  static int smallCartFeeCents = 199;
  static int smallCartMinCents = 1000;
  static int taxRateBps = 0;

  static void load(Map<String, dynamic> config) {
    int read(String key, int current) => (config[key] as num?)?.toInt() ?? current;
    deliveryMode = config['delivery_mode'] == 'distance' ? 'distance' : 'fixed';
    deliveryFeeCents = read('delivery_fee_cents', deliveryFeeCents);
    nearFeeCents = read('delivery_near_fee_cents', nearFeeCents);
    farFeeCents = read('delivery_far_fee_cents', farFeeCents);
    freeDeliveryThresholdCents = read('free_delivery_threshold_cents', freeDeliveryThresholdCents);
    handlingFeeCents = read('handling_fee_cents', handlingFeeCents);
    smallCartFeeCents = read('small_cart_fee_cents', smallCartFeeCents);
    smallCartMinCents = read('small_cart_min_cents', smallCartMinCents);
    taxRateBps = read('tax_rate_bps', taxRateBps);
  }

  static double get freeDeliveryThreshold => freeDeliveryThresholdCents / 100;
  static double get taxPercent => taxRateBps / 100;

  /// Fee breakdown in dollars for a basket subtotal (dollars) delivered [km] away.
  static FeeEstimate estimate(double subtotal, {double? km, double? radiusKm}) {
    final sub = (subtotal * 100).round();
    if (sub == 0) return FeeEstimate(0, 0, 0, 0, 0);

    int delivery;
    if (sub >= freeDeliveryThresholdCents) {
      delivery = 0;
    } else if (deliveryMode != 'distance') {
      delivery = deliveryFeeCents;
    } else if (km == null || radiusKm == null || radiusKm <= 0) {
      delivery = farFeeCents;
    } else {
      final t = (km / radiusKm).clamp(0.0, 1.0);
      delivery = (nearFeeCents + t * (farFeeCents - nearFeeCents)).round();
    }
    final tax = (sub * taxRateBps / 10000).round();
    final small = sub < smallCartMinCents ? smallCartFeeCents : 0;
    return FeeEstimate(sub / 100, delivery / 100, handlingFeeCents / 100, small / 100, tax / 100);
  }
}

class FeeEstimate {
  final double subtotal;
  final double delivery;
  final double handling;
  final double smallCart;
  final double tax;

  FeeEstimate(this.subtotal, this.delivery, this.handling, this.smallCart, this.tax);

  double get total => subtotal == 0 ? 0 : subtotal + delivery + handling + smallCart + tax;
}
