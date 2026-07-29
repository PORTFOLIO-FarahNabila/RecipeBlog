import 'package:flutter/material.dart';
import 'cart_model.dart';
import 'package:provider/provider.dart';
import 'recipe_widgets.dart';
import 'recipe_service.dart';

class IngredientsPage extends StatefulWidget {
  const IngredientsPage({super.key});
  @override
  State<IngredientsPage> createState() => _IngredientsPageState();
}

class _IngredientsPageState extends State<IngredientsPage> {
  static const List<String> _seedIngredients = [
    'cream cheese',
    'sugar',
    'eggs',
    'heavy cream',
    'vanilla extract',
    'all-purpose flour',
    'salt',
    'Marie biscuits',
    'unsalted butter',
    'sweetened condensed milk',
    'cocoa powder',
  ];

  List<String> _mergeIngredients(List<String> fromFirestore) {
    final merged = <String, String>{
      for (final name in _seedIngredients) RecipeService.normalizeKey(name): name,
    };
    for (final name in fromFirestore) {
      merged.putIfAbsent(RecipeService.normalizeKey(name), () => name);
    }
    final combined = merged.values.toList();
    combined.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return combined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecipeTheme.background,
      appBar: AppBar(
        title: const Text('Add Ingredients'),
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
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tap an ingredient to add it to your cart',
                  style: RecipeTheme.sectionHeading,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<String>>(
                    stream: RecipeService.ingredientNamesStream(),
                    builder: (context, snapshot) {
                      final allIngredients = _mergeIngredients(snapshot.data ?? []);

                      return Consumer<CartModel>(
                        builder: (context, cart, _) {
                          final cartItems = cart.items;

                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: allIngredients.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final ingredient = allIngredients[index];
                              final inCart = cartItems.contains(ingredient);

                              void toggleCart() {
                                if (inCart) {
                                  cart.remove(ingredient);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.grey[700],
                                      content:
                                          Text('Removed "$ingredient" from cart'),
                                    ),
                                  );
                                } else {
                                  cart.add(ingredient);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: RecipeTheme.primary,
                                      content: Text('Added "$ingredient" to cart'),
                                    ),
                                  );
                                }
                              }

                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: toggleCart,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: inCart
                                            ? RecipeTheme.primary.withOpacity(0.4)
                                            : RecipeTheme.cardBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          inCart
                                              ? Icons.check_circle_rounded
                                              : Icons.radio_button_unchecked_rounded,
                                          color: inCart
                                              ? RecipeTheme.primary
                                              : Colors.grey[400],
                                          size: 22,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            ingredient[0].toUpperCase() +
                                                ingredient.substring(1),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: inCart
                                                  ? Colors.grey[500]
                                                  : const Color(0xFF2E2E2E),
                                              decoration: inCart
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (inCart)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: RecipeTheme.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Text(
                                                  'Added',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: RecipeTheme.primary,
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Icon(Icons.close_rounded,
                                                    size: 14,
                                                    color: RecipeTheme.primary),
                                              ],
                                            ),
                                          )
                                        else
                                          Icon(Icons.add_circle_outline_rounded,
                                              color: RecipeTheme.primary,
                                              size: 22),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Consumer<CartModel>(
        builder: (context, cart, _) => CartFab(
          itemCount: cart.items.length,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }
}
