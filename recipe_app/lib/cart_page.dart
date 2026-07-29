import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_model.dart';
import 'recipe_widgets.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartModel>(
      builder: (context, cart, _) {
        final items = cart.items;
        return Scaffold(
          backgroundColor: RecipeTheme.background,
          appBar: AppBar(
            title: const Text('Your Cart'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: RecipeTheme.background,
            foregroundColor: const Color(0xFF2E2E2E),
            leading: IconButton(
              icon: const Icon(Icons.home_rounded),
              tooltip: 'Home',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                tooltip: 'Clear Cart',
                onPressed: items.isEmpty
                    ? null
                    : () {
                        cart.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Cart cleared'),
                          ),
                        );
                      },
              ),
            ],
          ),
          body: items.isEmpty
              ? _EmptyCart(onBrowse: () => Navigator.pushNamed(context, '/ingredients'))
              : Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              Icon(Icons.shopping_basket_rounded,
                                  color: RecipeTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${items.length} ${items.length == 1 ? 'item' : 'items'} in your cart',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: RecipeTheme.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: RecipeTheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.kitchen_rounded,
                                        color: RecipeTheme.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        item[0].toUpperCase() + item.substring(1),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close_rounded,
                                          color: Colors.grey[500], size: 20),
                                      onPressed: () => cart.remove(item),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyCart({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RecipeTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: RecipeTheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add ingredients from a recipe to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Browse Ingredients'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RecipeTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
