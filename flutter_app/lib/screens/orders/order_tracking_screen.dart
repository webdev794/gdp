import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import '../../widgets/rider_review_dialog.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderModel _currentOrder;
  // From the checkout reply only; kept when the order refreshes.
  late final double? _giftLeft = widget.order.giftCardRemaining;
  Timer? _poll;

  bool get _isFinal => _currentOrder.status == 'delivered' || _currentOrder.status == 'cancelled';

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _refresh();
    // Status changes made by the store/rider (or on the website) show up here.
    // Status changes made by the store/rider (or on the website) show up here;
    // checks every 5 s while the rider is on the way so the handover code pops up fast.
    _poll = Timer.periodic(const Duration(seconds: 5), (tick) {
      if (_isFinal) return;
      if (_currentOrder.status == 'out_for_delivery' || tick.tick % 4 == 0) _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await ApiService.fetchOrder(_currentOrder.id);
      if (!mounted) return;
      final newCode = fresh.deliveryCode.isNotEmpty && fresh.deliveryCode != _currentOrder.deliveryCode;
      setState(() => _currentOrder = fresh);
      if (newCode) _showHandoverCode(fresh.deliveryCode);
    } catch (_) {}
  }

  /// The rider asked for the handover code: show it straight away.
  void _showHandoverCode(String code) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your rider has arrived', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Read this delivery code to your rider:', textAlign: TextAlign.center),
            const SizedBox(height: 14),
            SelectableText(
              code,
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 8, color: AppTheme.emeraldPrimary),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _openReviewModal() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => RiderReviewDialog(
        orderId: _currentOrder.id,
        riderName: _currentOrder.riderName ?? 'your rider',
        onReviewSubmitted: (rating, comment) {
          setState(() {
            _currentOrder = _currentOrder.copyWith(
              riderReviewRating: rating,
              riderReviewComment: comment,
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          'Track ${_currentOrder.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          if (_canDownloadBill)
            IconButton(
              tooltip: 'Download bill',
              icon: const Icon(Icons.receipt_long, color: AppTheme.emeraldPrimary),
              onPressed: _downloadReceipt,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppTheme.emeraldPrimary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: isLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatusCard(),
                          if (_hasRider) ...[const SizedBox(height: 16), _buildRiderCard()],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_currentOrder.deliveryCode.isNotEmpty) ...[_buildDeliveryCodeCard(), const SizedBox(height: 16)],
                          _buildOrderSummaryCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Responsive.maxContainer(
                  context: context,
                  maxWidth: 650,
                  child: Column(
                    children: [
                      _buildStatusCard(),
                      if (_currentOrder.deliveryCode.isNotEmpty) ...[const SizedBox(height: 16), _buildDeliveryCodeCard()],
                      if (_hasRider) ...[const SizedBox(height: 16), _buildRiderCard()],
                      const SizedBox(height: 16),
                      _buildOrderSummaryCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Live Status Stepper Card
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.coralAccent, size: 22),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Order status',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.slateDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stepper (from the store's order status)
          if (_currentOrder.status == 'cancelled')
            _buildStepRow(
              icon: Icons.cancel,
              title: 'Order Cancelled',
              subtitle: [
                if (_currentOrder.cancelReason != null) 'Reason: ${_currentOrder.cancelReason}.',
                'Any payment taken is refunded to your original method.',
              ].join(' '),
              isDone: false,
              isCurrent: true,
            )
          else ...[
            _buildStepRow(
              icon: Icons.check_circle,
              title: _currentOrder.status == 'pending_payment' ? 'Awaiting Payment' : 'Order Confirmed',
              subtitle: _currentOrder.paymentMethod == 'COD' ? 'Pay the rider on delivery' : 'Paid by card',
              isDone: _step >= 1,
              isCurrent: _step == 0,
            ),
            _buildStepDivider(isDone: _step >= 1),
            _buildStepRow(
              icon: Icons.inventory_2,
              title: 'Packing Your Items',
              subtitle: 'The store is preparing your order',
              isDone: _step >= 2,
              isCurrent: _step == 1,
            ),
            _buildStepDivider(isDone: _step >= 2),
            _buildStepRow(
              icon: Icons.delivery_dining,
              title: 'Out for Delivery',
              subtitle: _currentOrder.riderName != null ? '${_currentOrder.riderName} is on the way' : 'A rider will pick it up soon',
              isDone: _step >= 3,
              isCurrent: _step == 2,
            ),
            _buildStepDivider(isDone: _step >= 3),
            _buildStepRow(
              icon: Icons.home,
              title: 'Delivered',
              subtitle: 'Enjoy your groceries!',
              isDone: _step >= 3,
              isCurrent: false,
            ),
          ],
        ],
      ),
    );
  }

  // Same rule as the store: a bill exists once paid, or for cash on delivery, unless cancelled.
  bool get _canDownloadBill =>
      _currentOrder.status != 'cancelled' && (_currentOrder.paymentStatus == 'paid' || _currentOrder.paymentMethod == 'COD');

  Future<void> _downloadReceipt() async {
    HapticFeedback.lightImpact();
    try {
      final bytes = await ApiService.fetchReceipt(_currentOrder.id);
      await Printing.sharePdf(bytes: bytes, filename: 'receipt-order-${_currentOrder.id}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed));
    }
  }

  // Items can be rated once the order is confirmed (store rule), once per item per order.
  bool get _canRateItems => _currentOrder.status != 'cancelled' && _currentOrder.status != 'pending_payment';

  Future<void> _rateItem(OrderItem item) async {
    HapticFeedback.lightImpact();
    int stars = 0;
    String error = '';
    bool saving = false;
    final comment = TextEditingController();
    final rated = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rate ${item.productName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.slateDark)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var n = 1; n <= 5; n++)
                    IconButton(
                      tooltip: '$n star${n > 1 ? 's' : ''}',
                      onPressed: () => setSheet(() => stars = n),
                      icon: Icon(n <= stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                    ),
                ],
              ),
              TextField(
                controller: comment,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'A few words about it (optional)'),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(error, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
                ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (stars == 0) {
                          setSheet(() => error = 'Pick a star rating first.');
                          return;
                        }
                        setSheet(() {
                          saving = true;
                          error = '';
                        });
                        try {
                          await ReviewService.reviewOrderItem(
                            orderId: _currentOrder.id,
                            productId: item.productId,
                            rating: stars,
                            comment: comment.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx, stars);
                        } catch (e) {
                          setSheet(() {
                            saving = false;
                            error = e.toString();
                          });
                        }
                      },
                child: Text(saving ? 'SAVING…' : 'POST REVIEW'),
              ),
            ],
          ),
        ),
      ),
    );
    comment.dispose();
    if (rated != null && mounted) {
      setState(() => _currentOrder = _currentOrder.copyWith(itemRatings: {..._currentOrder.itemRatings, item.productId: rated}));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your review is posted.'), backgroundColor: AppTheme.emeraldPrimary),
      );
    }
  }

  bool get _hasRider => (_currentOrder.riderName ?? '').isNotEmpty;

  /// 0 confirmed/awaiting payment, 1 packing, 2 out for delivery, 3 delivered.
  int get _step {
    switch (_currentOrder.status) {
      case 'packing':
        return 1;
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  String get _statusLabel {
    switch (_currentOrder.status) {
      case 'pending_payment':
        return 'AWAITING PAYMENT';
      case 'packing':
        return 'PACKING';
      case 'out_for_delivery':
        return 'ON THE WAY';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'CONFIRMED';
    }
  }

  Widget _buildStepRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
  }) {
    Color color = isCurrent
        ? AppTheme.coralAccent
        : (isDone ? AppTheme.emeraldPrimary : AppTheme.slateMuted.withAlpha(100));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDone || isCurrent ? AppTheme.slateDark : AppTheme.slateMuted,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.slateMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isDone}) {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 2, bottom: 2),
      width: 2,
      height: 20,
      color: isDone ? AppTheme.emeraldPrimary : AppTheme.borderSubtle,
    );
  }

  // Delivery OTP Card
  Widget _buildDeliveryCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.emeraldPrimary, const Color(0xFF1E3A2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text(
                'SECURE DELIVERY OTP',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _currentOrder.deliveryCode,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.emeraldPrimary,
                letterSpacing: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Read this code to your rider on arrival to receive your package.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Rider Card
  Widget _buildRiderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppTheme.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppTheme.emeraldPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _currentOrder.riderName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.slateDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_currentOrder.riderRating > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '${_currentOrder.riderRating}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        ],
                      ],
                    ),
                    Text(
                      _currentOrder.riderVehicle ?? 'Your delivery partner',
                      style: const TextStyle(fontSize: 12, color: AppTheme.slateMuted),
                    ),
                  ],
                ),
              ),
              if ((_currentOrder.riderPhone ?? '').isNotEmpty)
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rider phone: ${_currentOrder.riderPhone}')),
                  );
                },
                icon: const CircleAvatar(
                  backgroundColor: AppTheme.sageLight,
                  radius: 18,
                  child: Icon(Icons.phone, color: AppTheme.emeraldPrimary, size: 18),
                ),
              ),
            ],
          ),
          // Delivery feedback once delivered (same as the website): stars go to the
          // rider, the comment is seen by the store only.
          if (_currentOrder.status == 'delivered') ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 12),

          // Rating CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _currentOrder.riderReviewRating != null
                      ? 'Rated: ${_currentOrder.riderReviewRating} ⭐'
                      : 'Rate your delivery partner:',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.slateDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _openReviewModal,
                icon: const Icon(Icons.rate_review, size: 16, color: AppTheme.coralAccent),
                label: Text(
                  _currentOrder.riderReviewRating != null ? 'Edit Rating' : 'Leave Review',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.coralAccent, fontSize: 12),
                ),
              ),
            ],
          ),
          ],
        ],
      ),
    );
  }

  // Order Items & Price Summary
  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.slateDark),
              ),
              Text(
                '${_currentOrder.items.length} items',
                style: const TextStyle(fontSize: 12, color: AppTheme.slateMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._currentOrder.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.slateDark),
                          ),
                          Text(
                            '${item.unit} x ${item.quantity}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.slateMuted),
                          ),
                          if (_canRateItems && item.productId.isNotEmpty)
                            _currentOrder.itemRatings.containsKey(item.productId)
                                ? Text(
                                    '${'★' * _currentOrder.itemRatings[item.productId]!}${'☆' * (5 - _currentOrder.itemRatings[item.productId]!)}  You rated this',
                                    style: const TextStyle(fontSize: 11.5, color: Colors.amber, fontWeight: FontWeight.w700),
                                  )
                                : InkWell(
                                    onTap: () => _rateItem(item),
                                    child: const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Text('☆ Rate this item',
                                          style: TextStyle(fontSize: 12, color: AppTheme.coralAccent, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.slateDark),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 12),

          _buildCostRow('Subtotal', '\$${_currentOrder.subtotal.toStringAsFixed(2)}'),
          _buildCostRow('Delivery Fee', _currentOrder.deliveryFee == 0 ? 'FREE' : '\$${_currentOrder.deliveryFee.toStringAsFixed(2)}'),
          _buildCostRow('Tax','\$${_currentOrder.tax.toStringAsFixed(2)}'),
          if (_currentOrder.discount > 0)
            _buildCostRow('Gift card applied', '-\$${_currentOrder.discount.toStringAsFixed(2)}', isGreen: true),
          if (_giftLeft != null && _giftLeft > 0)
            _buildCostRow('Left on your gift card for next order', '\$${_giftLeft.toStringAsFixed(2)}', isGreen: true),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.slateDark),
              ),
              Text(
                '\$${_currentOrder.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.emeraldPrimary),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Delivery Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppTheme.coralAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentOrder.deliveryAddress,
                  style: const TextStyle(fontSize: 12, color: AppTheme.slateMuted, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.slateMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isGreen ? AppTheme.emeraldPrimary : AppTheme.slateDark,
            ),
          ),
        ],
      ),
    );
  }
}
