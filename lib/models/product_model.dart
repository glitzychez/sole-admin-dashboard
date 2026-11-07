class ProductModel {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      name: (data['name'] ?? '').toString(),
      price: _toDouble(data['price']),
      // Firestore uses "stock"; quantity is retained for dashboard compatibility.
      quantity: _toInt(data['stock'] ?? data['quantity']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'stock': quantity};
  }
}
