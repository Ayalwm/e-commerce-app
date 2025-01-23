import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String name;
  final double price;
  final String category; // Category field
  final String image; // Image field
  final String description; // Description field

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.image, // Image in constructor
    required this.description, // Description in constructor
  });

  // Convert Firestore document to Product model
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map; // Get data from Firestore document as a Map

    return Product(
      name: data['name'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
      category: data['category'] ?? '', // Fetch category field from Firestore
      image: data['image'] ?? '', // Fetch image field from Firestore
      description:
          data['description'] ?? '', // Fetch description field from Firestore
    );
  }

  // Convert Product model to Map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category, // Include category in the map
      'image': image, // Include image in the map
      'description': description, // Include description in the map
    };
  }
}
