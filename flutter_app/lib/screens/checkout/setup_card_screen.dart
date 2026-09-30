import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/app_theme.dart';
import 'stripe_card_form.dart';

/// Stripe card form that confirms a SetupIntent (save card to the account).
/// Pops with `true` once the card is saved, `false`/null otherwise.
class SetupCardScreen extends StatefulWidget {
  final String clientSecret;
  final String publishableKey;

  const SetupCardScreen({
    super.key,
    required this.clientSecret,
    required this.publishableKey,
  });

  @override
  State<SetupCardScreen> createState() => _SetupCardScreenState();
}

class _SetupCardScreenState extends State<SetupCardScreen> {
  late final WebViewController _controller;
  bool _ready = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Pay',
        onMessageReceived: (m) => _onMessage(m.message),
      )
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
        setState(
          () => _message =
              'This card needs an extra verification step. Try another card.',
        );
      case 'error':
        setState(() {
          _ready = true;
          _message =
              payload['message']?.toString() ?? 'Could not save this card.';
        });
    }
  }

  String _html() => stripeCardFormHtml(
        publishableKey: widget.publishableKey,
        clientSecret: widget.clientSecret,
        confirmCall: 'stripe.confirmCardSetup',
        intentKey: 'setupIntent',
        buttonLabel: 'Save card securely',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'Add a card',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_ready) const LinearProgressIndicator(),
            Expanded(child: WebViewWidget(controller: _controller)),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _message,
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
