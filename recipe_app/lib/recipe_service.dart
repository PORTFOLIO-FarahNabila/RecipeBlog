import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  });

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

  static Future<void> addRecipe({
    required String title,
    required String description,
    required List<String> ingredients,
    required String prepTime,
    required String cookTime,
    required String servings,
    String? imageUrl,
  }) async {
    await _recipes.add({
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final ingredient in ingredients) {
      final key = normalizeKey(ingredient);
      if (key.isEmpty) continue;
      final docRef = _ingredients.doc(key);
      final existing = await docRef.get();
      if (!existing.exists) {
        await docRef.set({
          'name': ingredient.trim(),
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    }
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
