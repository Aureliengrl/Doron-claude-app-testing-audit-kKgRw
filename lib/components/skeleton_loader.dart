import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget skeleton avec effet shimmer premium pour les états de chargement
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF8A2BE2).withOpacity(0.08),
      highlightColor: const Color(0xFFEC4899).withOpacity(0.15),
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Skeleton pour une carte produit avec shimmer
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFFFFFFF),
      period: const Duration(milliseconds: 1200),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Container(
                    width: 150,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sous-titre
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Prix
                  Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid de skeletons pour la page d'accueil (widget normal)
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

/// VERSION SLIVER du grid de skeletons - À UTILISER dans CustomScrollView/SliverPadding
/// FIX: Cette version retourne un Sliver au lieu d'un widget normal
class SliverProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const SliverProductGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => const ProductCardSkeleton(),
        childCount: itemCount,
      ),
    );
  }
}

/// Skeleton pour liste de profils (page recherche)
class ProfileListSkeleton extends StatelessWidget {
  const ProfileListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                SkeletonLoader(
                  width: 70,
                  height: 70,
                  borderRadius: BorderRadius.circular(35),
                ),
                const SizedBox(height: 8),
                const SkeletonLoader(width: 60, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton pour écran de profil
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Avatar
        SkeletonLoader(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.circular(50),
        ),
        const SizedBox(height: 16),
        // Nom
        const SkeletonLoader(width: 150, height: 20),
        const SizedBox(height: 8),
        // Email
        const SkeletonLoader(width: 200, height: 14),
        const SizedBox(height: 32),
        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const SkeletonLoader(width: 60, height: 30),
                const SizedBox(height: 8),
                const SkeletonLoader(width: 80, height: 12),
              ],
            ),
            Column(
              children: [
                const SkeletonLoader(width: 60, height: 30),
                const SizedBox(height: 8),
                const SkeletonLoader(width: 80, height: 12),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
