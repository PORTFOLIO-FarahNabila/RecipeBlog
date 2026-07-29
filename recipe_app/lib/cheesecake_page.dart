import 'package:flutter/material.dart';

import 'comments_section.dart';
import 'recipe_widgets.dart';

class RecipePage extends StatelessWidget {
  const RecipePage({super.key});

  static const String _recipeName = 'Basque Burnt Cheesecake';

  @override
  Widget build(BuildContext context) {
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(_recipeName, style: RecipeTheme.title),
        const SizedBox(height: 10),
        const Text(
          'Basque burnt cheesecake is a crustless, caramelized cheesecake '
          'originating from San Sebastian, Spain. It features a deeply '
          'browned, almost burnt exterior with a creamy, mousse-like '
          'interior. Baked at high temperatures (200°C/400°F), it creates a '
          'rustic, sunken appearance with a distinct custard-like flavor.',
          style: RecipeTheme.subtitle,
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: RecipeRatingBadge(rating: 4, reviewCount: 170),
        ),
        const RecipeInfoBar(
          stats: [
            RecipeInfoStat(icon: Icons.kitchen_rounded, label: 'PREP', value: '25 min'),
            RecipeInfoStat(icon: Icons.timer_rounded, label: 'COOK', value: '30-40 min'),
            RecipeInfoStat(icon: Icons.restaurant_rounded, label: 'FEEDS', value: '4-6'),
          ],
        ),
        const RecipeIngredientsList(
          ingredients: [
            '2 cups cream cheese',
            '1 cup sugar',
            '3 large eggs',
            '1 1/2 cups heavy cream',
            '1 tsp vanilla extract',
            '1/4 cup all-purpose flour',
            'Pinch of salt',
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: RecipeTheme.background,
      appBar: AppBar(
        title: const Text(_recipeName),
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
                  imageAsset: 'images/cheesecake.png',
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
