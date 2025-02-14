import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new product to Firestore
  Future<void> _addProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;

    await _firestore.collection('products').add({
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'image': _imageController.text,
    });

    _nameController.clear();
    _priceController.clear();
    _imageController.clear();
  }

  /// Deletes a product from Firestore
  Future<void> _deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  /// Updates the product name and price
  Future<void> _updateProduct(
      String productId, String newName, String newPrice) async {
    await _firestore.collection('products').doc(productId).update({
      'name': newName,
      'price': double.tryParse(newPrice) ?? 0.0,
    });
  }

  /// Shows a dialog for editing a product
  void _showEditDialog(BuildContext context, String productId,
      String currentName, double currentPrice) {
    TextEditingController nameController =
        TextEditingController(text: currentName);
    TextEditingController priceController =
        TextEditingController(text: currentPrice.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Product"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateProduct(
                    productId, nameController.text, priceController.text);
                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Product Name"),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _imageController,
                  decoration: const InputDecoration(labelText: "Image URL"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addProduct,
                  child: const Text("Add Product"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var products = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var product = products[index];
                    var productData = product.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(productData['name']),
                      subtitle: Text("Price: \$${productData['price']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditDialog(
                                context,
                                product.id,
                                productData['name'],
                                double.tryParse(
                                        productData['price'].toString()) ??
                                    0.0, // Safe conversion
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
