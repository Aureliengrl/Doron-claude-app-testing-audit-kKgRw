import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barre de recherche pour la page d'accueil
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final Color violetColor;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.violetColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 0.5,
          ),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher un cadeau, une marque...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.45),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.50),
              size: 22,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: Colors.white.withOpacity(0.50),
                    ),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick filters (Favoris, Livraison gratuite, etc.)
class QuickFiltersWidget extends StatelessWidget {
  final bool showOnlyFavorites;
  final Function(String) onToggleFilter;
  final Color violetColor;

  const QuickFiltersWidget({
    super.key,
    required this.showOnlyFavorites,
    required this.onToggleFilter,
    required this.violetColor,
  });

  @override
  Widget build(BuildContext context) {
    // Filtres désactivés (ne servent à rien)
    return const SizedBox.shrink();
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? violetColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? violetColor : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : violetColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : violetColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
