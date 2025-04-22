import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:b2b_marketplace/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProductModel>> getProducts() async {
    try {
      final querySnapshot = await _firestore.collection('products').get();
      return querySnapshot.docs.map((doc) {
        return ProductModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('products')
              .where('category', isEqualTo: category)
              .get();

      return querySnapshot.docs.map((doc) {
        return ProductModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error fetching products by category: $e');
      return [];
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromJson({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      print('Error fetching product by ID: $e');
      return null;
    }
  }

  Future<List<ProductModel>> getSellerProducts(String sellerId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('products')
              .where('sellerId', isEqualTo: sellerId)
              .get();

      return querySnapshot.docs.map((doc) {
        return ProductModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error fetching seller products: $e');
      return [];
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').add(product.toJson());
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toJson());
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('products')
              .orderBy('name')
              .startAt([query.toLowerCase()])
              .endAt([query.toLowerCase() + '\uf8ff'])
              .get();

      return querySnapshot.docs.map((doc) {
        return ProductModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getProductsSortedByPrice({
    bool ascending = true,
  }) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('products')
              .orderBy('price', descending: !ascending)
              .get();

      return querySnapshot.docs.map((doc) {
        return ProductModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error fetching sorted products: $e');
      return [];
    }
  }

  // Add product to favorites
  Future<bool> addToFavorites(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .set({'addedAt': DateTime.now().millisecondsSinceEpoch});
      return true;
    } catch (e) {
      print('Error adding product to favorites: $e');
      return false;
    }
  }

  // Remove product from favorites
  Future<bool> removeFromFavorites(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .delete();
      return true;
    } catch (e) {
      print('Error removing product from favorites: $e');
      return false;
    }
  }

  // Check if a product is in favorites
  Future<bool> isProductFavorite(String userId, String productId) async {
    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('favorites')
              .doc(productId)
              .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Get all favorite products for a user
  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    try {
      final favoritesSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('favorites')
              .get();

      List<ProductModel> favoriteProducts = [];

      for (var doc in favoritesSnapshot.docs) {
        final productId = doc.id;
        final product = await getProductById(productId);
        if (product != null) {
          favoriteProducts.add(product);
        }
      }

      return favoriteProducts;
    } catch (e) {
      print('Error fetching favorite products: $e');
      return [];
    }
  }
}
