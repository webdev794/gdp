import 'dart:convert';

/// Stripe card form (Stripe Elements) shown in a web view by the card payment
/// and "add a card" screens. Separate, labelled fields for name, card number,
/// expiry and CVC so every field is visible on a narrow phone screen (the
/// one-line Stripe card box hides expiry/CVC until the number is typed).
///
/// [confirmCall] is the Stripe.js call to run, e.g. `stripe.confirmCardPayment`
/// or `stripe.confirmCardSetup`; [intentKey] is the result field to check
/// (`paymentIntent` or `setupIntent`). Messages go to the `Pay` JS channel:
/// {type: ready | success | pending | error, message?}.
String stripeCardFormHtml({
  required String publishableKey,
  required String clientSecret,
  required String confirmCall,
  required String intentKey,
  required String buttonLabel,
  bool saveForLater = false,
}) {
  final testHint = publishableKey.startsWith('pk_test')
      ? '<p class="hint">Test card 4242 4242 4242 4242 &middot; any future date &middot; any CVC</p>'
      : '';
  return '''<!doctype html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<script src="https://js.stripe.com/v3/"></script>
<style>
  * { box-sizing: border-box; font-family: -apple-system, Roboto, "Segoe UI", sans-serif; }
  body { margin: 0; padding: 20px; background: #f6f6f2; color: #20291f; }
  label { display: block; font-size: 13px; font-weight: 600; margin: 14px 0 6px; }
  .field, input { width: 100%; padding: 14px; border: 1px solid #d9ddd4; border-radius: 10px; background: #fff; font-size: 16px; color: #20291f; }
  .field.StripeElement--focus, input:focus { border-color: #1f7a3d; outline: none; }
  .field.StripeElement--invalid { border-color: #a23b28; }
  .row { display: flex; gap: 12px; } .row > div { flex: 1; }
  button { margin-top: 22px; width: 100%; padding: 15px; border: 0; border-radius: 10px;
    background: #141a12; color: #fff; font-size: 15px; font-weight: 600; }
  button:disabled { opacity: .55; }
  #msg { margin-top: 14px; color: #a23b28; font-size: 13px; min-height: 18px; }
  .hint { margin-top: 10px; color: #7c857a; font-size: 12px; }
</style></head>
<body>
<label for="name">Name on card</label>
<input id="name" autocomplete="cc-name" placeholder="As printed on the card">
<label>Card number</label>
<div id="number" class="field"></div>
<div class="row">
  <div><label>Expiry (MM / YY)</label><div id="expiry" class="field"></div></div>
  <div><label>CVC</label><div id="cvc" class="field"></div></div>
</div>
<button id="go">$buttonLabel</button>
<div id="msg"></div>
$testHint
<script>
  var post = function (p) { Pay.postMessage(JSON.stringify(p)); };
  try {
    var stripe = Stripe(${json.encode(publishableKey)});
    var elements = stripe.elements();
    var style = { base: { fontSize: '16px', color: '#20291f', '::placeholder': { color: '#9aa396' } } };
    var number = elements.create('cardNumber', { style: style, showIcon: true });
    number.mount('#number');
    elements.create('cardExpiry', { style: style }).mount('#expiry');
    elements.create('cardCvc', { style: style }).mount('#cvc');
    var button = document.getElementById('go');
    var msg = document.getElementById('msg');
    button.addEventListener('click', function () {
      button.disabled = true; msg.textContent = '';
      var name = document.getElementById('name').value.trim();
      var data = { payment_method: { card: number, billing_details: name ? { name: name } : {} } };
      if (${saveForLater ? 'true' : 'false'}) { data.setup_future_usage = 'off_session'; }
      $confirmCall(${json.encode(clientSecret)}, data)
        .then(function (r) {
          var intent = r.$intentKey;
          if (r.error) { msg.textContent = r.error.message; button.disabled = false; post({ type: 'error', message: r.error.message }); }
          else if (intent && (intent.status === 'succeeded' || intent.status === 'processing')) { post({ type: 'success' }); }
          else { button.disabled = false; post({ type: 'pending' }); }
        })
        .catch(function (e) { button.disabled = false; post({ type: 'error', message: String(e) }); });
    });
    post({ type: 'ready' });
  } catch (e) { post({ type: 'error', message: 'Card form failed to load: ' + String(e) }); }
</script>
</body></html>''';
}
