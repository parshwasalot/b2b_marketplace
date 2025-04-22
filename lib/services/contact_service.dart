import 'package:cloud_firestore/cloud_firestore.dart';

class ContactMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String productId;
  final String message;
  final DateTime timestamp;

  ContactMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.productId,
    required this.message,
    required this.timestamp,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      productId: json['productId'] ?? '',
      message: json['message'] ?? '',
      timestamp:
          json['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'productId': productId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message to a seller about a product
  Future<bool> sendMessage(
    String buyerId,
    String sellerId,
    String productId,
    String message,
  ) async {
    try {
      await _firestore.collection('messages').add({
        'senderId': buyerId,
        'receiverId': sellerId,
        'productId': productId,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
      });
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get all messages for a conversation
  Future<List<ContactMessage>> getMessagesBetweenUsers(
    String userId,
    String otherId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('messages')
              .where('senderId', whereIn: [userId, otherId])
              .where('receiverId', whereIn: [userId, otherId])
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        return ContactMessage.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }
}
