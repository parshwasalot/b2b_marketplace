import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:b2b_marketplace/models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<OrderModel>> getBuyerOrders(String buyerId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('orders')
              .where('buyerId', isEqualTo: buyerId)
              .orderBy('orderDate', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        return OrderModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error fetching buyer orders: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getSellerOrders(String sellerId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('orders')
              .where('sellerId', isEqualTo: sellerId)
              .orderBy('orderDate', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        return OrderModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error fetching seller orders: $e');
      return [];
    }
  }

  Future<bool> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').add(order.toJson());
      return true;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
      });
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }
}
