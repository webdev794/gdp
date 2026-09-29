import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/app_theme.dart';

/// Stripe card form (Stripe Elements) for one order's PaymentIntent.
/// Pops with `true` once the card payment succeeds, `false`/null otherwise.
class CardPaymentScreen extends StatefulWidget {
  final String clientSecret;
  final String publishableKey;
  final double amount;

  const CardPaymentScreen({
    super.key,
    required this.clientSecret,
    required this.publishableKey,
    required this.amount,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  late final WebViewController _controller;
  bool _ready = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Pay', onMessageReceived: (m) => _onMessage(m.message))
      ..loadHtmlString(_html(), baseUrl: 'https://js.stripe.com');
  }

  void _onMessage(String raw) {
    Map<String, dynamic> payload;
    try {
      payload = Map<String, dynamic>.from(json.decode(raw));
    } catch (_) {
      return;
    }
    switch (payload['type']) {
      case 'ready':
        setState(() => _ready = true);
      case 'success':
        Navigator.pop(context, true);
      case 'pending':
        setState(() => _message = 'This card needs an extra verification step. Try another card.');
      case 'error':
        setState(() {
          _ready = true;
          _message = payload['message']?.toString() ?? 'Payment failed.';
        });
    }
  }

  String _html() {
    final testHint = widget.publishableKey.startsWith('pk_test')
        ? '<p class="hint">Test card 4242 4242 4242 4242 &middot; any future date &middot; any CVC</p>'
        : '';
    return '''<!doctype html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<script src="https://js.stripe.com/v3/"></script>
<style>
  * { box-sizing: border-box; font-family: -apple-system, Roboto, "Segoe UI", sans-serif; }
  body { margin: 0; padding: 20px; background: #f6f6f2; color: #20291f; }
  #card { padding: 14px; border: 1px solid #e4e7df; border-radius: 10px; background: #fff; }
  button { margin-top: 18px; width: 100%; padding: 15px; border: 0; border-radius: 10px;
    background: #141a12; color: #fff; font-size: 15px; font-weight: 600; }
  button:disabled { opacity: .55; }
  #msg { margin-top: 14px; color: #a23b28; font-size: 13px; min-height: 18px; }
  .hint { margin-top: 10px; color: #7c857a; font-size: 12px; }
</style></head>
<body>
<div id="card"></div>
<button id="pay">Pay \$${widget.amount.toStringAsFixed(2)} securely</button>
<div id="msg"></div>
$testHint
<script>
  var post = function (p) { Pay.postMessage(JSON.stringify(p)); };
  try {
    var stripe = Stripe(${json.encode(widget.publishableKey)});
    var card = stripe.elements().create('card', { style: { base: { fontSize: '16px', color: '#20291f' } } });
    card.mount('#card');
    var button = document.getElementById('pay');
    var msg = document.getElementById('msg');
    button.addEventListener('click', function () {
      button.disabled = true; msg.textContent = '';
      stripe.confirmCardPayment(${json.encode(widget.clientSecret)}, { payment_method: { card: card } })
        .then(function (r) {
          if (r.error) { msg.textContent = r.error.message; button.disabled = false; post({ type: 'error', message: r.error.message }); }
          else if (r.paymentIntent && r.paymentIntent.status === 'succeeded') { post({ type: 'success' }); }
          else { button.disabled = false; post({ type: 'pending' }); }
        })
        .catch(function (e) { button.disabled = false; post({ type: 'error', message: String(e) }); });
    });
    post({ type: 'ready' });
  } catch (e) { post({ type: 'error', message: 'Card form failed to load: ' + String(e) }); }
</script>
</body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('Card payment', style: TextStyle(fontWeight: FontWeight.w900))),
      body: SafeArea(
        child: Column(
          children: [
            if (!_ready) const LinearProgressIndicator(),
            Expanded(child: WebViewWidget(controller: _controller)),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_message, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
