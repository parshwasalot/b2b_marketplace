class OrderModel {
  final String id;
  final String buyerId;
  final String productId;
  final String sellerId;
  final double totalAmount;
  final String status; // pending, accepted, rejected, shipped, delivered
  final DateTime orderDate;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.productId,
    required this.sellerId,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      buyerId: json['buyerId'] ?? '',
      productId: json['productId'] ?? '',
      sellerId: json['sellerId'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      orderDate:
          json['orderDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['orderDate'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerId': buyerId,
      'productId': productId,
      'sellerId': sellerId,
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': orderDate.millisecondsSinceEpoch,
    };
  }
}
