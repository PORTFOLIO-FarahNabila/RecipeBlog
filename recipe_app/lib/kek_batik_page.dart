import 'package:flutter/material.dart';

import 'comments_section.dart';
import 'recipe_widgets.dart';

class KekBatikPage extends StatelessWidget {
  const KekBatikPage({super.key});

  static const String _recipeName = 'Kek Batik';

  @override
  Widget build(BuildContext context) {
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(_recipeName, style: RecipeTheme.title),
        const SizedBox(height: 10),
        const Text(
          'Kek Batik is a popular Malaysian no-bake dessert made with Marie '
          'biscuits and a rich chocolatey sauce. It is easy to prepare and '
          'loved by all ages.',
          style: RecipeTheme.subtitle,
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: RecipeRatingBadge(rating: 4, reviewCount: 120),
        ),
        const RecipeInfoBar(
          stats: [
            RecipeInfoStat(icon: Icons.kitchen_rounded, label: 'PREP', value: '15 min'),
            RecipeInfoStat(icon: Icons.ac_unit_rounded, label: 'CHILL', value: '2 hr'),
            RecipeInfoStat(icon: Icons.restaurant_rounded, label: 'FEEDS', value: '8'),
          ],
        ),
        const RecipeIngredientsList(
          ingredients: [
            '250g Marie biscuits',
            '1/2 cup unsalted butter',
            '1/2 cup sweetened condensed milk',
            '1/2 cup cocoa powder',
            '1/2 cup water',
            '1/4 cup sugar',
            '1 tsp vanilla essence',
            'Pinch of salt',
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: RecipeTheme.background,
      appBar: AppBar(
        title: const Text('$_recipeName Recipe'),
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
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                RecipeHeroCard(
                  leftColumn: leftColumn,
                  imageAsset: 'images/batik.png',
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  shadowColor: Colors.black.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: RecipeTheme.cardBorder),
                  ),
                  child: const CommentsSection(recipeName: _recipeName),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/ingredients'),
        icon: const Icon(Icons.list_alt_rounded),
        label: const Text('Ingredients'),
        backgroundColor: RecipeTheme.primary,
      ),
    );
  }
}
