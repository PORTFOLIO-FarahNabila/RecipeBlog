import 'package:flutter/material.dart';


class RecipeTheme {
  static const Color primary = Color(0xFF8B4A1E); // warm caramel/brown
  static const Color accent = Color(0xFFFFC107); // amber
  static const Color background = Color(0xFFFFFBF5); // soft cream
  static const Color cardBorder = Color(0xFFF0E4D8);

  static const TextStyle title = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
    height: 1.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    color: Color(0xFF6B6B6B),
    height: 1.5,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF2E2E2E),
  );
}

class RecipeHeaderImage extends StatelessWidget {
  final String? assetPath;
  final String? imageUrl;
  final double? width;
  final double? height;

  const RecipeHeaderImage({
    super.key,
    this.assetPath,
    this.imageUrl,
    this.width,
    this.height,
  });

  Widget _placeholder() => Container(
        width: width,
        height: height ?? 260,
        color: RecipeTheme.primary.withOpacity(0.08),
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_menu,
          size: 56,
          color: RecipeTheme.primary.withOpacity(0.4),
        ),
      );

  Widget _loading() => Container(
        width: width,
        height: height ?? 260,
        color: RecipeTheme.primary.withOpacity(0.05),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loading();
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: _buildImage(),
    );
  }
}

class RecipeRatingBadge extends StatelessWidget {
  final double rating; 
  final int reviewCount;

  const RecipeRatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.round().clamp(0, 5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: RecipeTheme.accent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < fullStars ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber[800],
                size: 18,
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '$reviewCount reviews',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeInfoStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RecipeInfoStat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: RecipeTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: RecipeTheme.primary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class RecipeInfoBar extends StatelessWidget {
  final List<RecipeInfoStat> stats;

  const RecipeInfoBar({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats,
      ),
    );
  }
}

class RecipeIngredientsList extends StatelessWidget {
  final List<String> ingredients;

  const RecipeIngredientsList({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_rounded, color: RecipeTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Ingredients', style: RecipeTheme.sectionHeading),
          ],
        ),
        const SizedBox(height: 12),
        ...ingredients.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: RecipeTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RecipeHeroCard extends StatelessWidget {
  final Widget leftColumn;
  final String? imageAsset;
  final String? imageUrl;

  const RecipeHeroCard({
    super.key,
    required this.leftColumn,
    this.imageAsset,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: RecipeTheme.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 20, 32),
                        child: leftColumn,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: RecipeHeaderImage(
                        assetPath: imageAsset,
                        imageUrl: imageUrl,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecipeHeaderImage(assetPath: imageAsset, imageUrl: imageUrl, height: 220),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: leftColumn,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RecipeListCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageAsset;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final VoidCallback onTap;

  const RecipeListCard({
    super.key,
    required this.title,
    required this.description,
    this.imageAsset,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: RecipeTheme.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RecipeHeaderImage(
                assetPath: imageAsset,
                imageUrl: imageUrl,
                width: 120,
                height: 120,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      if (rating != null)
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: Colors.amber[800], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$rating (${reviewCount ?? 0})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: RecipeTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Community recipe',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: RecipeTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded, color: RecipeTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartFab extends StatelessWidget {
  final int itemCount;
  final VoidCallback onPressed;

  const CartFab({super.key, required this.itemCount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: RecipeTheme.primary,
          tooltip: 'View Cart',
          child: const Icon(Icons.shopping_cart_rounded),
        ),
        if (itemCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$itemCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
