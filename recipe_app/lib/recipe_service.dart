import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final String prepTime;
  final String cookTime;
  final String servings;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? ownerId;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    this.imageUrl,
    this.createdAt,
    this.ownerId,
  });

  /// Whether the currently signed-in user is the one who created this recipe.
  /// Community recipes created before ownership tracking was added (no
  /// ownerId stored) will not be editable by anyone.
  bool get isOwnedByCurrentUser {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return ownerId != null && uid != null && ownerId == uid;
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title']?.toString() ?? 'Untitled Recipe',
      description: data['description']?.toString() ?? '',
      ingredients: (data['ingredients'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      prepTime: data['prepTime']?.toString() ?? '-',
      cookTime: data['cookTime']?.toString() ?? '-',
      servings: data['servings']?.toString() ?? '-',
      imageUrl: data['imageUrl']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      ownerId: data['ownerId']?.toString(),
    );
  }
}

class RecipeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  static CollectionReference<Map<String, dynamic>> get _ingredients =>
      _db.collection('ingredients');

  static Stream<List<Recipe>> recipesStream() {
    return _recipes
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Recipe.fromFirestore(d)).toList());
  }

  static Stream<List<String>> ingredientNamesStream() {
    return _ingredients.snapshots().map((snap) {
      final names = snap.docs
          .map((d) => (d.data()['name'] as String?) ?? d.id)
          .toList();
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return names;
    });
  }

  static String normalizeKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Upserts every ingredient into the shared ingredients collection in a
  /// single batched write instead of a per-ingredient read-then-write, which
  /// used to add one extra sequential network round trip per ingredient.
  static Future<void> _upsertIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) return;
    final batch = _db.batch();
    for (final ingredient in ingredients) {
      final key = normalizeKey(ingredient);
      if (key.isEmpty) continue;
      batch.set(
        _ingredients.doc(key),
        {
          'name': ingredient.trim(),
          'addedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  static Future<void> addRecipe({
    required String title,
    required String description,
    required List<String> ingredients,
    required String prepTime,
    required String cookTime,
    required String servings,
    String? imageUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    await _recipes.add({
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'ownerId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _upsertIngredients(ingredients);
  }

  /// Updates an existing recipe. Only the recipe's original creator is
  /// allowed to do this — enforced here for defense in depth, but this MUST
  /// also be enforced with Firestore Security Rules (see note below), since
  /// a client-side check alone can't stop a modified/rogue client from
  /// calling the API directly.
  static Future<void> updateRecipe({
    required String id,
    required String title,
    required String description,
    required List<String> ingredients,
    required String prepTime,
    required String cookTime,
    required String servings,
    String? imageUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final existing = await _recipes.doc(id).get();
    final ownerId = existing.data()?['ownerId']?.toString();

    if (uid == null || ownerId == null || uid != ownerId) {
      throw Exception('You can only edit recipes you created.');
    }

    await _recipes.doc(id).update({
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    });

    await _upsertIngredients(ingredients);
  }

  static Future<String> uploadRecipeImage(
    Uint8List bytes,
    String fileName,
  ) async {
    final safeName = fileName.isEmpty ? 'photo.jpg' : fileName;
    final ref = FirebaseStorage.instance
        .ref()
        .child('recipe_images')
        .child('${DateTime.now().millisecondsSinceEpoch}_$safeName');

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }
}
