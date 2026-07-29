import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'kek_batik_page.dart';
import 'cheesecake_page.dart';
import 'ingredients_page.dart';
import 'cart_model.dart';
import 'cart_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comments_section.dart';
import 'recipe_widgets.dart';
import 'recipe_service.dart';
import 'add_recipe_page.dart';
import 'recipe_detail_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartModel(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: RecipeTheme.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: RecipeTheme.primary,
          primary: RecipeTheme.primary,
        ),
      ),
      initialRoute: '/sign-in',
      routes: {
        '/sign-in': (context) => fui.SignInScreen(
              providers: [
                fui.EmailAuthProvider(),
                ],
              actions: [
                fui.AuthStateChangeAction<fui.UserCreated>((context, state) {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/sign-in');
                }),
                fui.AuthStateChangeAction<fui.SignedIn>((context, state) { //if signed in, redirect to home page
                  Navigator.pushReplacementNamed(context, '/');
                }),
              ],
            ),
        '/': (context) => const HomePage(),
        '/recipe': (context) => const RecipePage(),
        '/kekbatik': (context) => const KekBatikPage(),
        '/ingredients': (context) => const IngredientsPage(),
        '/cart': (context) => const CartPage(),
        '/add-recipe': (context) => const AddRecipePage(),
        '/comments': (context) => const CommentsSection(recipeName: 'Sample Recipe'),
      },
      localizationsDelegates: [
        FirebaseUILocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecipeTheme.background,
      appBar: AppBar(
        title: const Text('Recipes'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: RecipeTheme.background,
        foregroundColor: const Color(0xFF2E2E2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              const Text(
                'What would you like to cook?',
                style: RecipeTheme.sectionHeading,
              ),
              const SizedBox(height: 4),
              Text(
                'Pick a recipe to see ingredients, steps, and reviews.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              RecipeListCard(
                title: 'Basque Burnt Cheesecake',
                description:
                    'A crustless, caramelized cheesecake with a deeply browned exterior and creamy, mousse-like center.',
                imageAsset: 'images/cheesecake.png',
                rating: 4,
                reviewCount: 170,
                onTap: () => Navigator.pushNamed(context, '/recipe'),
              ),
              RecipeListCard(
                title: 'Kek Batik',
                description:
                    'A popular Malaysian no-bake dessert made with Marie biscuits and a rich chocolatey sauce.',
                imageAsset: 'images/batik.png',
                rating: 4,
                reviewCount: 120,
                onTap: () => Navigator.pushNamed(context, '/kekbatik'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/ingredients'),
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Browse all ingredients'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RecipeTheme.primary,
                  side: const BorderSide(color: RecipeTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/add-recipe'),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Add Your Own Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RecipeTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              StreamBuilder<List<Recipe>>(
                stream: RecipeService.recipesStream(),
                builder: (context, snapshot) {
                  final recipes = snapshot.data ?? [];
                  if (recipes.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Community recipes',
                        style: RecipeTheme.sectionHeading,
                      ),
                      const SizedBox(height: 12),
                      ...recipes.map(
                        (recipe) => RecipeListCard(
                          title: recipe.title,
                          description: recipe.description.isEmpty
                              ? 'No description provided.'
                              : recipe.description,
                          imageUrl: recipe.imageUrl,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecipeDetailPage(recipe: recipe),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
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
