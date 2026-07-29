import 'package:flutter/material.dart';

import 'add_recipe_page.dart';
import 'comments_section.dart';
import 'recipe_service.dart';
import 'recipe_widgets.dart';

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recipe.title, style: RecipeTheme.title),
        const SizedBox(height: 10),
        Text(
          recipe.description.isEmpty
              ? 'No description provided.'
              : recipe.description,
          style: RecipeTheme.subtitle,
        ),
        RecipeInfoBar(
          stats: [
            RecipeInfoStat(
              icon: Icons.kitchen_rounded,
              label: 'PREP',
              value: recipe.prepTime,
            ),
            RecipeInfoStat(
              icon: Icons.timer_rounded,
              label: 'COOK',
              value: recipe.cookTime,
            ),
            RecipeInfoStat(
              icon: Icons.restaurant_rounded,
              label: 'FEEDS',
              value: recipe.servings,
            ),
          ],
        ),
        RecipeIngredientsList(ingredients: recipe.ingredients),
      ],
    );

    return Scaffold(
      backgroundColor: RecipeTheme.background,
      appBar: AppBar(
        title: Text(recipe.title),
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
          // Only the person who added this recipe sees the edit button.
          if (recipe.isOwnedByCurrentUser)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Recipe',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRecipePage(existingRecipe: recipe),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                RecipeHeroCard(leftColumn: leftColumn, imageUrl: recipe.imageUrl),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  shadowColor: Colors.black.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: RecipeTheme.cardBorder),
                  ),
                  child: CommentsSection(recipeName: recipe.title),
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
