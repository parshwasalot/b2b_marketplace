import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2b_marketplace/models/product_model.dart';
import 'package:b2b_marketplace/services/product_service.dart';
import 'package:b2b_marketplace/services/auth_service.dart';
import 'package:b2b_marketplace/screens/products/product_detail_screen.dart';
import 'package:b2b_marketplace/screens/products/add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _sortByPriceAsc = true;
  bool _isSearching = false;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Food',
    'Furniture',
    'Other',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    List<ProductModel> products;

    // If there's a search query, use the search method
    if (_searchQuery.isNotEmpty) {
      products = await _productService.searchProducts(_searchQuery);
      // Filter by category if needed
      if (_selectedCategory != 'All') {
        products =
            products.where((p) => p.category == _selectedCategory).toList();
      }
    } else if (_selectedCategory == 'All') {
      // Get products sorted by price if sorting is enabled
      if (_sortByPriceAsc != null) {
        products = await _productService.getProductsSortedByPrice(
          ascending: _sortByPriceAsc,
        );
      } else {
        products = await _productService.getProducts();
      }
    } else {
      products = await _productService.getProductsByCategory(_selectedCategory);
      // Sort products by price if needed
      if (_sortByPriceAsc != null) {
        products.sort(
          (a, b) =>
              _sortByPriceAsc
                  ? a.price.compareTo(b.price)
                  : b.price.compareTo(a.price),
        );
      }
    }

    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = false;
    });
    _loadProducts();
  }

  void _toggleSort() {
    setState(() {
      _sortByPriceAsc = !_sortByPriceAsc;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isSeller = authService.userModel?.userType == 'seller';

    return Scaffold(
      appBar:
          _isSearching
              ? AppBar(
                title: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: _performSearch,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _loadProducts();
                  },
                ),
              )
              : null,
      body: Column(
        children: [
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: ChoiceChip(
                              label: Text(_categories[index]),
                              selected: _selectedCategory == _categories[index],
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = _categories[index];
                                  _loadProducts();
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _sortByPriceAsc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    tooltip:
                        _sortByPriceAsc
                            ? 'Price: Low to High'
                            : 'Price: High to Low',
                    onPressed: _toggleSort,
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                    ? const Center(child: Text('No products available'))
                    : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              leading:
                                  product.imageUrl != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          product.imageUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Icon(
                                              Icons.image,
                                              size: 60,
                                            );
                                          },
                                        ),
                                      )
                                      : const Icon(Icons.image, size: 60),
                              title: Text(product.name),
                              subtitle: Text(
                                '\$${product.price.toStringAsFixed(2)} - ${product.category}',
                              ),
                              trailing: Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
                                ).then((_) => _loadProducts());
                              },
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton:
          isSeller
              ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductScreen(),
                    ),
                  ).then((_) => _loadProducts());
                },
              )
              : null,
    );
  }
}
