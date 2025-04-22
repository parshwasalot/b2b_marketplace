import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2b_marketplace/models/order_model.dart';
import 'package:b2b_marketplace/services/order_service.dart';
import 'package:b2b_marketplace/services/auth_service.dart';
import 'package:b2b_marketplace/services/product_service.dart';
import 'package:b2b_marketplace/models/product_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  List<OrderModel> _orders = [];
  Map<String, ProductModel?> _products = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final userModel = authService.userModel;

    if (user == null || userModel == null) return;

    setState(() {
      _isLoading = true;
    });

    List<OrderModel> orders;
    if (userModel.userType == 'buyer') {
      orders = await _orderService.getBuyerOrders(user.uid);
    } else {
      orders = await _orderService.getSellerOrders(user.uid);
    }

    // Load product details for each order
    final products = <String, ProductModel?>{};
    for (final order in orders) {
      if (!products.containsKey(order.productId)) {
        products[order.productId] = await _productService.getProductById(
          order.productId,
        );
      }
    }

    setState(() {
      _orders = orders;
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    await _orderService.updateOrderStatus(orderId, status);
    await _loadOrders();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userType = authService.userModel?.userType ?? 'buyer';
    final isSeller = userType == 'seller';

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
              ? Center(
                child: Text(
                  isSeller
                      ? 'No orders received yet'
                      : 'You haven\'t placed any orders yet',
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadOrders,
                child: ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final product = _products[order.productId];

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${order.id.substring(0, 8)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    _getStatusText(order.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: _getStatusColor(
                                    order.status,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            if (product != null) ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading:
                                    product.imageUrl != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.network(
                                            product.imageUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons.image,
                                                size: 50,
                                              );
                                            },
                                          ),
                                        )
                                        : const Icon(Icons.image, size: 50),
                                title: Text(product.name),
                                subtitle: Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                ),
                              ),
                            ] else ...[
                              const ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.image, size: 50),
                                title: Text('Product not available'),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${order.orderDate.toString().substring(0, 16)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (isSeller && order.status == 'pending')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed:
                                        () => _updateOrderStatus(
                                          order.id,
                                          'rejected',
                                        ),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed:
                                        () => _updateOrderStatus(
                                          order.id,
                                          'accepted',
                                        ),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            if (isSeller && order.status == 'accepted')
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed:
                                      () => _updateOrderStatus(
                                        order.id,
                                        'shipped',
                                      ),
                                  child: const Text('Mark as Shipped'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
