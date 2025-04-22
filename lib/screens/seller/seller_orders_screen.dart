import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2b_marketplace/models/order_model.dart';
import 'package:b2b_marketplace/models/product_model.dart';
import 'package:b2b_marketplace/services/auth_service.dart';
import 'package:b2b_marketplace/services/order_service.dart';
import 'package:b2b_marketplace/services/product_service.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({Key? key}) : super(key: key);

  @override
  _SellerOrdersScreenState createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  List<OrderModel> _orders = [];
  Map<String, ProductModel?> _products = {};
  bool _isLoading = true;

  // For filtering
  String _statusFilter = 'All';
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Accepted',
    'Shipped',
    'Delivered',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final sellerId = authService.user?.uid;

    if (sellerId != null) {
      // Get all orders for the seller
      List<OrderModel> orders = await _orderService.getSellerOrders(sellerId);

      // Apply status filter if not "All"
      if (_statusFilter != 'All') {
        orders =
            orders
                .where(
                  (order) =>
                      order.status.toLowerCase() == _statusFilter.toLowerCase(),
                )
                .toList();
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
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    final success = await _orderService.updateOrderStatus(orderId, status);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as ${status.toUpperCase()}')),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Column(
        children: [
          // Status filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _statusOptions.map((status) {
                      final isSelected = status == _statusFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(status),
                          onSelected: (selected) {
                            setState(() {
                              _statusFilter = status;
                            });
                            _loadOrders();
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.blue[100],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // Orders list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _orders.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusFilter == 'All'
                                ? 'You have no orders yet'
                                : 'No $_statusFilter orders found',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final product = _products[order.productId];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Order ID and Status
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${order.id.substring(0, 8)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          order.status.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: _getStatusColor(
                                          order.status,
                                        ),
                                        padding: EdgeInsets.zero,
                                        labelPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 0,
                                            ),
                                      ),
                                    ],
                                  ),

                                  const Divider(),

                                  // Product info
                                  if (product != null) ...[
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading:
                                          product.imageUrl != null
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                              : const Icon(
                                                Icons.image,
                                                size: 50,
                                              ),
                                      title: Text(product.name),
                                      subtitle: Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                      ),
                                    ),
                                  ] else ...[
                                    const ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.image, size: 50),
                                      title: Text('Product unavailable'),
                                    ),
                                  ],

                                  // Order details
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${order.orderDate.toString().substring(0, 16)}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),

                                  // Action buttons based on status
                                  if (order.status == 'pending') ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed:
                                              () => _updateOrderStatus(
                                                order.id,
                                                'rejected',
                                              ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                        const SizedBox(width: 12),
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
                                  ] else if (order.status == 'accepted') ...[
                                    const SizedBox(height: 16),
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
                                  ] else if (order.status == 'shipped') ...[
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed:
                                            () => _updateOrderStatus(
                                              order.id,
                                              'delivered',
                                            ),
                                        child: const Text('Mark as Delivered'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
