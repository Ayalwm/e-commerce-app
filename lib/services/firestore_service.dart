import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce/models/product_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch products from Firestore
  Future<List<Product>> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await _db.collection('products').get();
      List<Product> products = snapshot.docs.map((doc) {
        return Product.fromFirestore(doc);
      }).toList();
      return products;
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }
}
