import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2b_marketplace/models/product_model.dart';
import 'package:b2b_marketplace/services/product_service.dart';
import 'package:b2b_marketplace/services/auth_service.dart';
import 'package:b2b_marketplace/screens/products/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ProductService _productService = ProductService();
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user != null) {
      final products = await _productService.getFavoriteProducts(user.uid);
      setState(() {
        _favoriteProducts = products;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(String productId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user != null) {
      final success = await _productService.removeFromFavorites(
        user.uid,
        productId,
      );

      if (success) {
        setState(() {
          _favoriteProducts.removeWhere((product) => product.id == productId);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove from favorites')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Products')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _favoriteProducts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No favorite products yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Products you save will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadFavorites,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _favoriteProducts.length,
                  itemBuilder: (context, index) {
                    final product = _favoriteProducts[index];
                    return Dismissible(
                      key: Key(product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _removeFromFavorites(product.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading:
                              product.imageUrl != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
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
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                          title: Text(product.name),
                          subtitle: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () => _removeFromFavorites(product.id),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProductDetailScreen(
                                      productId: product.id,
                                    ),
                              ),
                            ).then((_) => _loadFavorites());
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
