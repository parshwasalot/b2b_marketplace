import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2b_marketplace/models/product_model.dart';
import 'package:b2b_marketplace/models/order_model.dart';
import 'package:b2b_marketplace/services/product_service.dart';
import 'package:b2b_marketplace/services/order_service.dart';
import 'package:b2b_marketplace/services/auth_service.dart';
import 'package:b2b_marketplace/services/contact_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final ContactService _contactService = ContactService();
  ProductModel? _product;
  bool _isLoading = false;
  bool _placingOrder = false;
  bool _isFavorite = false;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });

    final product = await _productService.getProductById(widget.productId);

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user != null && product != null) {
      final isFav = await _productService.isProductFavorite(
        user.uid,
        product.id,
      );
      setState(() {
        _isFavorite = isFav;
      });
    }

    setState(() {
      _product = product;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null || _product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to save products'),
        ),
      );
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    final success =
        _isFavorite
            ? await _productService.addToFavorites(user.uid, _product!.id)
            : await _productService.removeFromFavorites(user.uid, _product!.id);

    if (!success) {
      // Revert state if operation failed
      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? 'Failed to add to favorites'
                : 'Failed to remove from favorites',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final userModel = authService.userModel;

    if (user == null || userModel == null || _product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to place an order'),
        ),
      );
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    final order = OrderModel(
      id: '',
      buyerId: user.uid,
      productId: _product!.id,
      sellerId: _product!.sellerId,
      totalAmount: _product!.price,
      status: 'pending',
      orderDate: DateTime.now(),
    );

    final success = await _orderService.placeOrder(order);

    setState(() {
      _placingOrder = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to place order')));
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Contact Seller'),
            content: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Enter your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a message')),
                    );
                    return;
                  }

                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  final user = authService.user;

                  if (user != null && _product != null) {
                    final success = await _contactService.sendMessage(
                      user.uid,
                      _product!.sellerId,
                      _product!.id,
                      _messageController.text.trim(),
                    );

                    Navigator.pop(context);
                    _messageController.clear();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Message sent to seller'
                              : 'Failed to send message',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userType = authService.userModel?.userType ?? 'buyer';
    final isBuyer = userType == 'buyer';
    final isProductOwner = _product?.sellerId == authService.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Product Details' : _product?.name ?? 'Product Details',
        ),
        actions: [
          if (isBuyer && !isProductOwner && _product != null)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _product == null
              ? const Center(child: Text('Product not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_product!.imageUrl != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _product!.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 80),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _product!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${_product!.category}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Price: \$${_product!.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _product!.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      bottomNavigationBar:
          _product == null
              ? null
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    isBuyer && !isProductOwner
                        ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _showContactDialog,
                              icon: const Icon(Icons.message),
                              label: const Text('Contact Seller'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(45),
                                backgroundColor: Colors.lightBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _placingOrder ? null : _placeOrder,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child:
                                  _placingOrder
                                      ? const CircularProgressIndicator()
                                      : const Text('Place Order'),
                            ),
                          ],
                        )
                        : null,
              ),
    );
  }
}
