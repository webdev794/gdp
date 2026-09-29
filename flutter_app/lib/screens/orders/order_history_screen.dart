import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Orders from the store, so website and app orders both show here.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await ApiService.fetchOrders();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Could not load your orders. Check your connection and try again.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final orders = ApiService.cachedOrders;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('My Orders 📦', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: _loading && orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty && orders.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('TRY AGAIN')),
                    ],
                  ),
                ),
              )
            : orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📦', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    const Text(
                      'No Orders Placed Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your fresh grocery orders will appear here.',
                      style: TextStyle(color: AppTheme.slateMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            : Responsive.maxContainer(
                context: context,
                maxWidth: 700,
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: orders.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                ),
                ),
              ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color badgeBg;
    Color badgeText;
    String statusLabel;

    switch (order.status) {
      case 'out_for_delivery':
        badgeBg = AppTheme.sageLight;
        badgeText = AppTheme.emeraldPrimary;
        statusLabel = 'OUT FOR DELIVERY ⚡';
        break;
      case 'delivered':
        badgeBg = Colors.blue.shade50;
        badgeText = Colors.blue.shade800;
        statusLabel = 'DELIVERED';
        break;
      case 'cancelled':
        badgeBg = Colors.red.shade50;
        badgeText = AppTheme.errorRed;
        statusLabel = 'CANCELLED';
        break;
      case 'packing':
        badgeBg = Colors.orange.shade50;
        badgeText = Colors.orange.shade900;
        statusLabel = 'PACKING';
        break;
      case 'pending_payment':
        badgeBg = Colors.grey.shade200;
        badgeText = AppTheme.slateDark;
        statusLabel = 'AWAITING PAYMENT';
        break;
      default:
        badgeBg = Colors.orange.shade50;
        badgeText = Colors.orange.shade900;
        statusLabel = 'CONFIRMED';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
            ).then((_) => _load());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.slateDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Items preview
                Text(
                  order.items.map((i) => '${i.productName} (${i.quantity})').join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.slateMuted),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.borderSubtle),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total: \$${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.emeraldPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (order.deliveryCode.isNotEmpty)
                          Text(
                            'Delivery PIN: ${order.deliveryCode}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slateDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Track Order',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.coralAccent),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.coralAccent),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
