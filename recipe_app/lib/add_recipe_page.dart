import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'recipe_service.dart';
import 'recipe_widgets.dart';

class AddRecipePage extends StatefulWidget {
  /// Pass an existing recipe to edit it in place. Leave null to add a new
  /// recipe. Only the recipe's original creator will be able to reach this
  /// page in edit mode (see RecipeDetailPage).
  final Recipe? existingRecipe;

  const AddRecipePage({super.key, this.existingRecipe});

  bool get isEditing => existingRecipe != null;

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepController = TextEditingController();
  final _cookController = TextEditingController();
  final _servingsController = TextEditingController();
  final _ingredientController = TextEditingController();

  final List<String> _ingredients = [];
  String? _ingredientError;
  bool _isSubmitting = false;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _isPickingImage = false;

  // Existing ingredient names across all recipes, used to suggest matches
  // as the user types instead of them having to retype an ingredient that
  // already exists.
  List<String> _knownIngredientNames = [];
  StreamSubscription<List<String>>? _ingredientNamesSub;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingRecipe;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _prepController.text = existing.prepTime == '-' ? '' : existing.prepTime;
      _cookController.text = existing.cookTime == '-' ? '' : existing.cookTime;
      _servingsController.text =
          existing.servings == '-' ? '' : existing.servings;
      _ingredients.addAll(existing.ingredients);
    }

    _ingredientNamesSub = RecipeService.ingredientNamesStream().listen((names) {
      if (mounted) setState(() => _knownIngredientNames = names);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepController.dispose();
    _cookController.dispose();
    _servingsController.dispose();
    _ingredientController.dispose();
    _ingredientNamesSub?.cancel();
    super.dispose();
  }

  List<String> get _ingredientSuggestions {
    final query = _ingredientController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _knownIngredientNames.where((name) {
      final matches = name.toLowerCase().contains(query);
      final alreadyAdded = _ingredients.any(
        (existing) =>
            RecipeService.normalizeKey(existing) ==
            RecipeService.normalizeKey(name),
      );
      return matches && !alreadyAdded;
    }).take(5).toList();
  }

  void _addIngredient([String? suggested]) {
    final value = suggested ?? _ingredientController.text.trim();
    if (value.isEmpty) return;

    final isDuplicate = _ingredients.any(
      (existing) =>
          RecipeService.normalizeKey(existing) ==
          RecipeService.normalizeKey(value),
    );

    if (isDuplicate) {
      setState(() {
        _ingredientError = '"$value" is already in this recipe';
      });
      return;
    }

    setState(() {
      _ingredients.add(value);
      _ingredientController.clear();
      _ingredientError = null;
    });
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Keeping these numbers modest matters a lot for upload speed: a
        // full-resolution phone photo can be several MB, which is what
        // makes "add recipe with a photo" feel slow. Downscaling and
        // recompressing here keeps the upload to a few hundred KB without
        // a visible quality loss for a recipe thumbnail/hero image.
        imageQuality: 70,
        maxWidth: 1080,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = picked.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageName = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ingredients.isEmpty) {
      setState(() {
        _ingredientError = 'Add at least one ingredient';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = widget.existingRecipe?.imageUrl;
      if (_pickedImageBytes != null) {
        imageUrl = await RecipeService.uploadRecipeImage(
          _pickedImageBytes!,
          _pickedImageName ?? 'photo.jpg',
        );
      }

      final prepTime =
          _prepController.text.trim().isEmpty ? '-' : _prepController.text.trim();
      final cookTime =
          _cookController.text.trim().isEmpty ? '-' : _cookController.text.trim();
      final servings = _servingsController.text.trim().isEmpty
          ? '-'
          : _servingsController.text.trim();

      if (widget.isEditing) {
        await RecipeService.updateRecipe(
          id: widget.existingRecipe!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          ingredients: _ingredients,
          prepTime: prepTime,
          cookTime: cookTime,
          servings: servings,
          imageUrl: imageUrl,
        );
      } else {
        await RecipeService.addRecipe(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          ingredients: _ingredients,
          prepTime: prepTime,
          cookTime: cookTime,
          servings: servings,
          imageUrl: imageUrl,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: RecipeTheme.primary,
          content: Text(
            widget.isEditing
                ? '"${_titleController.text.trim()}" updated!'
                : '"${_titleController.text.trim()}" added!',
          ),
        ),
      );
      // Both the add and edit flows can be reached from a couple of levels
      // deep in the navigation stack, so jump straight back to Home, whose
      // recipe list is Firestore-stream-driven and will reflect the change.
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recipe: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _ingredientSuggestions;

    return Scaffold(
      backgroundColor: RecipeTheme.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Recipe' : 'Add Recipe'),
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Text('Recipe details', style: RecipeTheme.sectionHeading),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: _fieldDecoration('Recipe name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a recipe name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _fieldDecoration('Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prepController,
                        decoration: _fieldDecoration('Prep', hint: 'e.g. 15 min'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _cookController,
                        decoration: _fieldDecoration('Cook', hint: 'e.g. 30 min'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _servingsController,
                        decoration: _fieldDecoration('Feeds', hint: 'e.g. 4'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Photo', style: RecipeTheme.sectionHeading),
                const SizedBox(height: 4),
                Text(
                  'Optional, but a photo helps your recipe stand out.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    color: RecipeTheme.primary.withOpacity(0.08),
                    child: _pickedImageBytes != null
                        ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                        : (widget.existingRecipe?.imageUrl != null &&
                                widget.existingRecipe!.imageUrl!.isNotEmpty)
                            ? Image.network(
                                widget.existingRecipe!.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: RecipeTheme.primary.withOpacity(0.4),
                                ),
                              )
                            : Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: RecipeTheme.primary.withOpacity(0.4),
                              ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isPickingImage ? null : _pickImage,
                      icon: _isPickingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        (_pickedImageBytes == null &&
                                widget.existingRecipe?.imageUrl == null)
                            ? 'Choose Photo'
                            : 'Change Photo',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RecipeTheme.primary,
                        side: const BorderSide(color: RecipeTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (_pickedImageBytes != null) ...[
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Remove'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text('Ingredients', style: RecipeTheme.sectionHeading),
                const SizedBox(height: 4),
                Text(
                  'Anything you add here is automatically added to the shared ingredients list too.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ingredientController,
                        decoration: _fieldDecoration(
                          'Ingredient',
                          hint: 'e.g. brown sugar',
                        ).copyWith(errorText: _ingredientError),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _addIngredient(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _addIngredient(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RecipeTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                // Suggestions from the shared ingredients list, filtered as
                // the user types. Tapping one adds it directly; the user is
                // always free to ignore these and add their own instead.
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions
                        .map(
                          (name) => ActionChip(
                            avatar: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16,
                              color: RecipeTheme.primary,
                            ),
                            label: Text(name),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: RecipeTheme.cardBorder),
                            onPressed: () => _addIngredient(name),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                if (_ingredients.isEmpty)
                  Text(
                    'No ingredients added yet.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ingredients
                        .map(
                          (ingredient) => Chip(
                            label: Text(ingredient),
                            backgroundColor: RecipeTheme.primary.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: RecipeTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            deleteIcon: const Icon(Icons.close_rounded, size: 18),
                            deleteIconColor: RecipeTheme.primary,
                            onDeleted: () => _removeIngredient(ingredient),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Saving...'
                          : (widget.isEditing ? 'Save Changes' : 'Save Recipe'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RecipeTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
