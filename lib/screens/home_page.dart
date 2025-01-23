import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce/screens/cart_page.dart';
import 'package:e_commerce/screens/product_detail_page.dart'; // Import the new product detail page
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Map<String, dynamic>> _cart = [];

  // Stream to fetch products from Firestore
  Stream<QuerySnapshot> getProductStream() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  // Add product to Firestore
  Future<void> _addProductToFirestore(
      String name, double price, String category) async {
    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': name,
        'price': price,
        'category': category,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    }
  }

  // Show dialog to add product
  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price =
                    double.tryParse(priceController.text.trim()) ?? 0.0;
                final category = categoryController.text.trim();

                if (name.isNotEmpty && category.isNotEmpty && price > 0) {
                  _addProductToFirestore(name, price, category);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid details')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cart: _cart,
          onRemove: _removeFromCart, // Pass remove function to cart page
        ),
      ),
    );
  }

  void _removeFromCart(Map<String, dynamic> product) {
    setState(() {
      _cart.remove(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} removed from cart!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      _cart.add(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // Navigate back to the login page instead of closing the app
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const AuthPage()), // Navigate to login page
          );
          return false; // Prevent the default back button behavior (closing the app)
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("E-Commerce App"),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _goToCart, // Navigate to cart screen
              ),
              if (_cart.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Text(
                      _cart.length.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 20),
                const Text(
                  "Categories",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Products",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildProductList(),
              ],
            ),
          ),
        ));
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search products...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: getProductStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          var products = snapshot.data!.docs.where((doc) {
            var name = doc['name'].toString().toLowerCase();
            return name.contains(_searchQuery); // Apply search filtering
          }).toList();

          if (products.isEmpty) {
            return const Center(child: Text('No matching products found.'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];
              var productData =
                  product.data() as Map<String, dynamic>; // Fixed data access
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: productData['image'] != null &&
                          productData['image'].isNotEmpty
                      ? Image.network(
                          productData['image'],
                          width: 50, // Adjust size if needed
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image), // Placeholder if no image
                  title: Text(productData['name']),
                  subtitle: Text('Price: \$${productData['price']}'),
                  trailing: ElevatedButton(
                    onPressed: () => _addToCart(productData),
                    child: const Text('Add to Cart'),
                  ),
                  onTap: () {
                    // Navigate to the detail page when the product is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(
                          product: productData, // Pass the product data
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
