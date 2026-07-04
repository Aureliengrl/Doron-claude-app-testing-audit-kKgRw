const fs = require('fs');

const file = './lib/pages/new_pages/public_profile/public_profile_page.dart';
let content = fs.readFileSync(file, 'utf8');

// Replace build method
content = content.replace(
  /CustomScrollView\(\s*slivers: \[\s*_buildAppBar\(\),\s*_buildTabBar\(\),\s*_buildTabContent\(\),\s*\],\s*\)/s,
  `CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Row(
                          children: [
                            const Icon(IconlyLight.document, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('Listes de cadeaux', 'Gift lists'),
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildWishlistsSliver(),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                        child: Row(
                          children: [
                            const Icon(IconlyBold.heart, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('Coups de coeur', 'Favourites'),
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildLikedProductsSliver(),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                )`
);

// We need to convert _buildWishlists to _buildWishlistsSliver
content = content.replace(
  /Widget _buildWishlists\(\) \{[\s\S]*?Widget _buildWishlistCard/s,
  `Widget _buildWishlistsSliver() {
    if (_wishlists.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(IconlyLight.bookmark, size: 60, color: Colors.white.withOpacity(0.35)),
              const SizedBox(height: 16),
              Text(context.tr('Aucune wishlist publique', 'No public wishlists'),
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 8),
              Text('Cet utilisateur n\\'a pas encore de wishlist publique',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _wishlists.length,
        itemBuilder: (context, index) => _buildWishlistCard(_wishlists[index]),
      ),
    );
  }

  Widget _buildWishlistCard`
);

// We need to convert _buildLikedProducts to _buildLikedProductsSliver
content = content.replace(
  /Widget _buildLikedProducts\(\) \{[\s\S]*?Widget _buildNotFound\(\) \{/s,
  `Widget _buildLikedProductsSliver() {
    if (_likedProductsArePrivate) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(IconlyLight.lock, size: 38, color: Colors.white38),
              ),
              const SizedBox(height: 20),
              Text(
                'Produits likés privés',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les produits likés de cet utilisateur\\nsont privés et non visibles.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white30),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    if (_likedProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(IconlyLight.heart, size: 60, color: Colors.white.withOpacity(0.35)),
              const SizedBox(height: 16),
              Text('Aucun produit liké',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 8),
              Text('Les produits likés de cet utilisateur apparaîtront ici',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _likedProducts.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SharedProductCard(
            product: _likedProducts[index],
            index: index,
            showWishlistButton: false,
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {`
);

fs.writeFileSync(file, content, 'utf8');
console.log('Done public profile rewrite');
