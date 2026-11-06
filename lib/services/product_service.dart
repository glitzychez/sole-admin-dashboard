import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');

  Stream<List<ProductModel>> watchProducts() {
    return _productsRef.snapshots().map((snapshot) {
      final products = snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.id, doc.data());
      }).toList();

      products.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return products;
    });
  }

  Future<void> addProduct({
    required String name,
    required double price,
    required int quantity,
  }) async {
    await _productsRef.add({
      'name': name.trim(),
      'price': price,
      'stock': quantity,
      'brand': '',
      'category': '',
      'description': '',
      'imageUrl': '',
      'sizes': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required double price,
    required int quantity,
  }) async {
    // Updates only these fields. Existing brand, category, imageUrl,
    // description, sizes, and createdAt remain untouched.
    await _productsRef.doc(id).update({
      'name': name.trim(),
      'price': price,
      'stock': quantity,
    });
  }

  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }
}
