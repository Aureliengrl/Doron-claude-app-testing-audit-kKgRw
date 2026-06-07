const fs = require('fs');
const path = 'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart';
let content = fs.readFileSync(path, 'utf8');

// 1. Import ClaudeApiService
if (!content.includes('claude_api_service.dart')) {
  content = content.replace("import '/services/firebase_data_service.dart';", "import '/services/firebase_data_service.dart';\nimport '/services/claude_api_service.dart';");
}

// 2. Call Claude API in _loadProducts
const loadProductsInjection = `
      // Extraire et stocker le prénom
      final firstName = userProfileTags?['firstName'] as String? ?? '';
      _model.setFirstName(firstName);

      // --- NOUVEAU: CHARGEMENT IA CLAUDE ---
      if (_model.personalizedBrands.isEmpty && userProfileTags != null) {
        _model.isBrandsLoading = true;
        _model.isEventsLoading = true;
        
        final ageStr = userProfileTags['age']?.toString() ?? '25';
        final int age = parseInt(ageStr) ?? 25;
        
        final interestsRaw = userProfileTags['interests'] ?? userProfileTags['domains'] ?? [];
        final List<String> domains = (interestsRaw as List).map((e) => e.toString()).toList();

        // Paralléliser l'appel à Claude API
        Future.wait([
          ClaudeApiService.generatePersonalizedBrands(age, domains),
          ClaudeApiService.generateUpcomingEvents(age, domains),
        ]).then((results) {
          if (mounted) {
            setState(() {
              _model.personalizedBrands = results[0] as List<String>;
              _model.personalizedEvents = results[1] as List<String>;
              _model.isBrandsLoading = false;
              _model.isEventsLoading = false;
            });
          }
        });
      }
      // ------------------------------------
`;

const oldLoadProducts = `      // Extraire et stocker le prénom
      final firstName = userProfileTags?['firstName'] as String? ?? '';
      _model.setFirstName(firstName);`;

if (content.includes(oldLoadProducts) && !content.includes('NOUVEAU: CHARGEMENT IA CLAUDE')) {
  content = content.replace(oldLoadProducts, loadProductsInjection);
}

// Need to fix parseInt in Dart: it's int.tryParse
content = content.replace('parseInt(ageStr)', 'int.tryParse(ageStr)');

// 3. Update the layout in build()
// Remove _buildPriceFilters()
// Replace BrandFiltersWidget with _buildBrandsFilters()
// Replace the search bar wrapping

const oldSearchBar = `              // Barre de recherche
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  controller: _searchController,
                  onChanged: (val) {
                    _model.searchQuery = val;
                    // Debounce recherche
                  },
                  onSubmitted: (val) {
                    _onSearch(val);
                  },
                  onClear: () {
                    _onSearch('');
                  },
                ),
              ),`;

const newSearchBar = `              // Barre de recherche avec icône Prix
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBarWidget(
                          controller: _searchController,
                          onChanged: (val) {
                            _model.searchQuery = val;
                          },
                          onSubmitted: (val) {
                            _onSearch(val);
                          },
                          onClear: () {
                            _onSearch('');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Option A: Bouton Prix à côté de la recherche
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white70),
                          onPressed: _showPriceFilterModal,
                          tooltip: 'Filtrer par prix',
                        ),
                      ),
                    ],
                  ),
                ),
              ),`;
if (content.includes('child: SearchBarWidget(') && !content.includes('_showPriceFilterModal')) {
  // Regex to match the search bar block
  content = content.replace(/SliverToBoxAdapter\(\s*child:\s*SearchBarWidget\([\s\S]*?,\s*\),\s*\),/m, newSearchBar);
}

const oldFilters = `              // Catégories
              SliverToBoxAdapter(child: _buildCategories()),

              // Espace uniforme (16px) entre chaque bloc de filtres
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Filtres par marques
              SliverToBoxAdapter(
                child: BrandFiltersWidget(
                  activeBrandId: _model.activeBrand,
                  onBrandSelected: _onBrandSelected,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Filtres par prix
              SliverToBoxAdapter(child: _buildPriceFilters()),`;

const newFilters = `              // Ligne 1: Catégories (Intention)
              SliverToBoxAdapter(child: _buildCategories()),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Ligne 2: Marques (Personnalisées)
              SliverToBoxAdapter(child: _buildBrandsFilters()),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Ligne 3: Événements (Personnalisés)
              SliverToBoxAdapter(child: _buildEventsFilters()),`;

if (content.includes('SliverToBoxAdapter(child: _buildPriceFilters())')) {
  content = content.replace(oldFilters, newFilters);
}

// 4. Add _buildBrandsFilters, _buildEventsFilters, and _showPriceFilterModal
const newMethods = `
  Widget _buildBrandsFilters() {
    if (_model.isBrandsLoading) {
      return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2))));
    }
    
    final brands = _model.personalizedBrands.isNotEmpty ? _model.personalizedBrands : ['Nike', 'Sephora', 'Zara', 'Apple', 'LEGO'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text('Marques pour toi', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildPill(
                  label: 'Toutes les marques',
                  isActive: _model.activeBrand == 'all',
                  onTap: () => _onBrandSelected('all'),
                );
              }
              final brand = brands[index - 1];
              return _buildPill(
                label: brand,
                isActive: _model.activeBrand == brand,
                onTap: () => _onBrandSelected(brand),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventsFilters() {
    if (_model.isEventsLoading) {
      return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2))));
    }
    
    final events = _model.personalizedEvents.isNotEmpty ? _model.personalizedEvents : ['🎄 Noël', '🎂 Anniversaire', '💝 St Valentin'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text('Événements', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildPill(
                label: event,
                isActive: _model.searchQuery == event,
                onTap: () => _onSearch(event),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPriceFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtrer par Prix', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _model.priceFilters.map((priceFilter) {
                  final isActive = _model.activePriceFilter == priceFilter['id'];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (_model.activePriceFilter != priceFilter['id']) {
                        setState(() {
                          _model.activePriceFilter = priceFilter['id'] as String;
                          _model.products.clear();
                        });
                        _loadProducts();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF8A2BE2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? const Color(0xFF8A2BE2) : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        priceFilter['name'] as String,
                        style: GoogleFonts.poppins(
                          color: isActive ? Colors.white : Colors.white70,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
`;

if (!content.includes('_buildBrandsFilters()')) {
  // Insert new methods before _buildCategories
  content = content.replace('Widget _buildCategories() {', newMethods + '\n  Widget _buildCategories() {');
}

// 5. _buildPill is used inside new methods, we need to create it if it doesn't exist or use the existing logic
// Wait, _buildCategories uses:
/*
  Widget _buildCategoryChip(Map<String, String> category, bool isActive) {
*/
// Let's create _buildPill generically
const buildPill = `
  Widget _buildPill({required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8A2BE2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFF8A2BE2) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF8A2BE2).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
`;

if (!content.includes('_buildPill({')) {
  content = content.replace('Widget _buildBrandsFilters() {', buildPill + '\n  Widget _buildBrandsFilters() {');
}

fs.writeFileSync(path, content, 'utf8');
console.log('home_pinterest_widget updated successfully.');
