import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'admin_dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Map<String, dynamic>> _cart = [];
  final ValueNotifier<int> _cartCount = ValueNotifier<int>(0);
  final Color _backgroundColor = Colors.blueGrey.shade50;

  String? _userEmail;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    _checkAdminAccess();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartCount.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getProductStream() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cart: _cart,
          onRemove: _removeFromCart,
        ),
      ),
    );
  }

  void _removeFromCart(Map<String, dynamic> product) {
    setState(() {
      _cart.remove(product);
      _cartCount.value = _cart.length;
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    if (!_cart.contains(product)) {
      _cart.add(product);
      _cartCount.value = _cart.length;
    }
  }

  Future<void> _checkAdminAccess() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmail = user.email;

      var adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: _userEmail)
          .get();

      setState(() {
        _isAdmin = adminSnapshot.docs.isNotEmpty;
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Skirt ',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _goToCart,
              ),
              ValueListenableBuilder<int>(
                valueListenable: _cartCount,
                builder: (context, count, child) {
                  return count > 0
                      ? Positioned(
                          right: 6,
                          top: 6,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        )
                      : const SizedBox();
                },
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildProductGrid(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userEmail ?? "Guest"),
            accountEmail: Text(_userEmail ?? "Not logged in"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _userEmail != null ? _userEmail![0].toUpperCase() : "?",
                style: const TextStyle(fontSize: 24, color: Colors.indigo),
              ),
            ),
            decoration: const BoxDecoration(color: Colors.indigo),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text("Cart"),
            onTap: _goToCart,
          ),
          if (_isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Admin Dashboard"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Padding(
      padding: const EdgeInsets.all(10),
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
            return name.contains(_searchQuery);
          }).toList();

          if (products.isEmpty) {
            return const Center(child: Text('No matching products found.'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];
              var productData = product.data() as Map<String, dynamic>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            product: productData,
                            onAddToCart: _addToCart,
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            productData['image'] ?? '',
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image,
                                    size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add_shopping_cart,
                                  color: Colors.green, size: 28),
                              onPressed: () => _addToCart(productData),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productData['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Price: \$${productData['price']}',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
