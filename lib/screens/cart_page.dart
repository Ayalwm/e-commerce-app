// TODO Implement this library.
import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final Function(Map<String, dynamic>) onRemove;

  const CartPage({Key? key, required this.cart, required this.onRemove})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: cart.isEmpty
          ? const Center(
              child: Text('Your cart is empty.'),
            )
          : ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final product = cart[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading:
                        product['image'] != null && product['image'].isNotEmpty
                            ? Image.network(
                                product['image'],
                                width: 50, // Set width of the image
                                height: 50, // Set height of the image
                                fit: BoxFit
                                    .cover, // Ensure the image covers the space properly
                              )
                            : const Icon(
                                Icons.image), // Placeholder icon if no image
                    title: Text(product['name']),
                    subtitle: Text('Price: \$${product['price']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () => onRemove(product),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
