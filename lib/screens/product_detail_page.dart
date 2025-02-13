import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToCart;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Stream<QuerySnapshot> getRelatedProducts() {
    return FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.product['name'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.product['image'] != null &&
                        widget.product['image'].isNotEmpty
                    ? Image.network(
                        widget.product['image'],
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image,
                            size: 100, color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 20),

              // Product Name
              Text(
                widget.product['name'],
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                '\$${widget.product['price']}',
                style: const TextStyle(
                    fontSize: 22,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                widget.product['description'] ?? 'No description available.',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart, color: Colors.green),
                  label:
                      const Text("Add to Cart", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    widget.onAddToCart(widget.product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${widget.product['name']} added to cart!'),
                          duration: const Duration(seconds: 2)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Related Products Section
              const Text("Related Products",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: getRelatedProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No related products available.'));
                  }

                  var products = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .where((product) =>
                          product['name'] != widget.product['name'])
                      .toList();

                  if (products.isEmpty) {
                    return const Center(
                        child: Text('No related products found.'));
                  }

                  return SizedBox(
                    height: 220, // Adjust height for horizontal scrolling
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        var relatedProduct = products[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  product: relatedProduct,
                                  onAddToCart: widget.onAddToCart,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Related Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: relatedProduct['image'] != null &&
                                          relatedProduct['image'].isNotEmpty
                                      ? Image.network(
                                          relatedProduct['image'],
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image,
                                              size: 50, color: Colors.grey),
                                        ),
                                ),
                                const SizedBox(height: 10),

                                // Product Name
                                Text(
                                  relatedProduct['name'],
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Price
                                Text(
                                  '\$${relatedProduct['price']}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.green),
                                ),

                                const SizedBox(height: 5),

                                // Add to Cart Button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.add_shopping_cart,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        widget.onAddToCart(relatedProduct),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
