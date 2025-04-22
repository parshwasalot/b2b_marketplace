import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2b_marketplace/services/auth_service.dart';
import 'package:b2b_marketplace/services/product_service.dart';
import 'package:b2b_marketplace/services/order_service.dart';
import 'package:b2b_marketplace/screens/seller/seller_products_screen.dart';
import 'package:b2b_marketplace/screens/seller/seller_orders_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({Key? key}) : super(key: key);

  @override
  _SellerDashboardScreenState createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool _isLoading = true;
  int _productCount = 0;
  int _orderCount = 0;
  int _pendingOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final sellerId = authService.user?.uid;

    if (sellerId != null) {
      // Load seller products
      final productService = ProductService();
      final products = await productService.getSellerProducts(sellerId);

      // Load seller orders
      final orderService = OrderService();
      final orders = await orderService.getSellerOrders(sellerId);
      final pendingOrders =
          orders.where((order) => order.status == 'pending').toList();

      setState(() {
        _productCount = products.length;
        _orderCount = orders.length;
        _pendingOrderCount = pendingOrders.length;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Analytics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Products',
                              _productCount.toString(),
                              Icons.inventory,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Orders',
                              _orderCount.toString(),
                              Icons.shopping_bag,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Pending Orders',
                              _pendingOrderCount.toString(),
                              Icons.pending_actions,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: SizedBox(),
                          ), // Empty for alignment
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      _buildActionButton(
                        'Manage Products',
                        Icons.inventory_2,
                        Colors.indigo,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SellerProductsScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),

                      const SizedBox(height: 16),

                      _buildActionButton(
                        'Manage Orders',
                        Icons.list_alt,
                        Colors.teal,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SellerOrdersScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: color.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
