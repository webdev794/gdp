import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order_model.dart';
import '../screens/checkout/card_payment_screen.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/mock_auth_service.dart';
import '../theme/app_theme.dart';

/// Checkout sheet: payment method, phone, optional gift card -> a real store order.
/// Calls [onOrderPlaced] with the order the store created (card orders once paid).
class PaymentSheet extends StatefulWidget {
  final double totalAmount; // estimate shown before the store prices the order
  final int itemCount;
  final Map<String, int> cart;
  final void Function(OrderModel order) onOrderPlaced;

  const PaymentSheet({
    super.key,
    required this.totalAmount,
    required this.itemCount,
    required this.cart,
    required this.onOrderPlaced,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  // Card payments run in a web view (Stripe card form) — Android/iOS only.
  bool get _cardAvailable => !kIsWeb && ApiService.stripePublishableKey.isNotEmpty;

  late String _method;
  final _phone = TextEditingController(text: MockAuthService.currentUser?.phone ?? '');
  final _notes = TextEditingController();
  final _giftCode = TextEditingController();
  final _giftPin = TextEditingController();
  bool _showGift = false;
  String _giftMsg = '';
  bool _giftOk = false;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _method = _cardAvailable ? 'card' : 'cod';
  }

  @override
  void dispose() {
    _phone.dispose();
    _notes.dispose();
    _giftCode.dispose();
    _giftPin.dispose();
    super.dispose();
  }

  Future<void> _checkGift() async {
    setState(() => _giftMsg = 'Checking…');
    try {
      final balance = await ApiService.checkGiftCard(_giftCode.text, _giftPin.text);
      setState(() {
        _giftOk = balance > 0;
        _giftMsg = balance > 0
            ? 'Gift card balance: \$${balance.toStringAsFixed(2)} — applied at checkout.'
            : 'This gift card has no balance left.';
      });
    } catch (e) {
      setState(() {
        _giftOk = false;
        _giftMsg = e.toString();
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_method == 'cod' && !ApiService.codEnabled) {
      setState(() => _error = 'Cash on delivery is not available right now.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    HapticFeedback.mediumImpact();
    final navigator = Navigator.of(context);
    try {
      var order = await ApiService.placeOrder(
        cart: widget.cart,
        paymentMethod: _method,
        address: LocationService.activeAddress,
        phone: _phone.text,
        deliveryInstructions: _notes.text,
        giftCardCode: _giftOk ? _giftCode.text : null,
        giftCardPin: _giftOk ? _giftPin.text : null,
      );

      // Card orders are created as "awaiting payment"; take the card now
      // (a gift card may already have covered the whole total).
      if (_method == 'card' && order.paymentStatus != 'paid') {
        final secret = await ApiService.paymentIntent(order.id);
        if (secret != null) {
          final paid = await navigator.push<bool>(MaterialPageRoute(
            builder: (_) => CardPaymentScreen(
              clientSecret: secret,
              publishableKey: ApiService.stripePublishableKey,
              amount: order.total,
            ),
          ));
          if (paid != true) {
            setState(() {
              _busy = false;
              _error = 'Payment was not completed. Order ${order.orderNumber} is saved — pay for it from My Orders, or it will be cancelled.';
            });
            return;
          }
          await ApiService.paymentIntent(order.id); // confirms the payment with the store
        }
        order = await ApiService.fetchOrder(order.id);
      }

      if (!mounted) return;
      navigator.pop();
      widget.onOrderPlaced(order);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.borderSubtle, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slateDark)),
                        Text(
                          '${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'} · final total confirmed by the store',
                          style: const TextStyle(fontSize: 12, color: AppTheme.slateMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.sageLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '~\$${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.emeraldPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Deliver to', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slateMuted)),
              const SizedBox(height: 4),
              Text(LocationService.activeAddress.fullAddress, style: const TextStyle(fontSize: 13, color: AppTheme.slateDark)),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone for the delivery rider', isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Delivery instructions (optional)', isDense: true),
              ),
              const SizedBox(height: 16),
              const Text('Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slateMuted)),
              const SizedBox(height: 8),
              if (_cardAvailable) ...[
                _option('card', 'Credit / Debit Card', 'Visa, Mastercard, Amex — paid securely via Stripe', Icons.credit_card),
                const SizedBox(height: 10),
              ],
              if (ApiService.codEnabled)
                _option('cod', 'Cash on Delivery', 'Pay the rider when your order arrives', Icons.local_shipping),
              if (!_cardAvailable && !ApiService.codEnabled)
                const Text(
                  'No payment method is available right now. Please try again later.',
                  style: TextStyle(color: AppTheme.errorRed, fontSize: 12),
                ),
              if (kIsWeb && ApiService.stripePublishableKey.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Card payment is available in the Android / iPhone app.',
                      style: TextStyle(fontSize: 11, color: AppTheme.slateMuted)),
                ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _showGift = !_showGift),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard, size: 18, color: AppTheme.coralAccent),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Use a gift card', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.slateDark)),
                      ),
                      Icon(_showGift ? Icons.expand_less : Icons.expand_more, color: AppTheme.slateMuted),
                    ],
                  ),
                ),
              ),
              if (_showGift) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _giftCode,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Gift card code', isDense: true),
                        onChanged: (_) => setState(() => _giftOk = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _giftPin,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', isDense: true),
                        onChanged: (_) => setState(() => _giftOk = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: _checkGift, child: const Text('APPLY')),
                  ],
                ),
                if (_giftMsg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _giftMsg,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _giftOk ? AppTheme.emeraldPrimary : AppTheme.errorRed),
                    ),
                  ),
              ],
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _busy || (!_cardAvailable && !ApiService.codEnabled) ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(
                        _method == 'card' ? 'PLACE ORDER & PAY BY CARD' : 'PLACE ORDER (PAY ON DELIVERY)',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(String id, String title, String subtitle, IconData icon) {
    final selected = _method == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _method = id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.sageLight.withAlpha(120) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.emeraldPrimary : AppTheme.borderSubtle, width: selected ? 2 : 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.emeraldPrimary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w900 : FontWeight.w700, color: AppTheme.slateDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.slateMuted)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppTheme.emeraldPrimary : AppTheme.slateMuted),
          ],
        ),
      ),
    );
  }
}
