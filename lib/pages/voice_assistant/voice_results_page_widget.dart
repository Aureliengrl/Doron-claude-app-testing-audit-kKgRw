import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:doron/components/cached_image.dart';
import 'package:doron/components/skeleton_loader.dart';
import 'package:doron/components/liquid_glass.dart';
import '/services/firebase_data_service.dart';
import '/services/product_url_service.dart';
import 'voice_results_page_model.dart';

class VoiceResultsPageWidget extends StatefulWidget {
  final Map<String, dynamic> analysis;
  final String transcript;

  const VoiceResultsPageWidget({
    Key? key,
    required this.analysis,
    required this.transcript,
  }) : super(key: key);

  @override
  State<VoiceResultsPageWidget> createState() => _VoiceResultsPageWidgetState();
}

class _VoiceResultsPageWidgetState extends State<VoiceResultsPageWidget> {
  late VoiceResultsPageModel _model;

  @override
  void initState() {
    super.initState();
    _model = VoiceResultsPageModel();
    _model.initialize(
      analysis: widget.analysis,
      transcript: widget.transcript,
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Scaffold(
        backgroundColor: LiquidGlassTokens.pageDark,
        appBar: AppBar(
          backgroundColor: const Color(0x991A0035),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Retourner à la page de recherche
              context.go('/search-page');
            },
          ),
          title: const Text(
            'Suggestions Vocales',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Consumer<VoiceResultsPageModel>(
          builder: (context, model, _) {
            return CustomScrollView(
              slivers: [
                // Header avec résumé
                SliverToBoxAdapter(
                  child: Container(
                    color: const Color(0xFF062248),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icône succès
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analyse réussie !',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Voici ce que j\'ai compris',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Résumé
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            model.summary,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bouton sauvegarder et générer
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // 1. Créer la personne avec les tags de l'analyse vocale
                              if (model.analysis != null) {
                                try {
                                  AppLogger.debug('🎯 Création personne depuis assistant vocal...', 'Debug');

                                  // Extraire les informations de l'analyse
                                  final analysis = model.analysis!;
                                  final personTags = {
                                    'name': analysis['recipientName'] ?? 'Sans nom',
                                    'gender': analysis['gender'],
                                    'recipient': analysis['recipientType'] ?? 'une personne',
                                    'budget': (analysis['budget']?['max'] ?? 50).toDouble(),
                                    'recipientAge': analysis['age']?.toString() ?? analysis['ageRange'] ?? '25',
                                    'recipientHobbies': analysis['hobbies'] ?? [],
                                    'recipientPersonality': analysis['personality'] ?? '',
                                    'occasion': analysis['occasion'] ?? 'sans occasion',
                                    'recipientStyle': analysis['style'] ?? '',
                                    'preferredCategories': analysis['preferredCategories'] ?? [],
                                    'interests': analysis['interests'] ?? [],
                                  };

                                  // Créer la personne avec isPendingFirstGen=true
                                  final personId = await FirebaseDataService.createPerson(
                                    tags: personTags,
                                    isPendingFirstGen: true,
                                  );

                                  AppLogger.debug('✅ Personne cre: $personId', 'Debug');

                                  if (mounted) {
                                    // 2. Rediriger vers la page de génération
                                    AppLogger.debug('🚀 Redirection vers génération pour personne: $personId', 'Debug');
                                    context.go('/onboarding-gifts-result?personId=$personId');
                                  }
                                } catch (e) {
                                  AppLogger.debug('❌ Erreur création personne: $e', 'Debug');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Erreur lors de la création. Réessayez.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.card_giftcard, size: 20),
                            label: const Text(
                              'Générer les cadeaux',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B9D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Titre de la section produits
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      model.isGeneratingProducts
                          ? 'Génération de suggestions...'
                          : 'Suggestions de cadeaux',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Grille de produits ou état de chargement/erreur
                if (model.hasError)
                  SliverToBoxAdapter(
                    child: _buildErrorState(model),
                  )
                else if (model.isGeneratingProducts)
                  // FIX: Utiliser SliverProductGridSkeleton au lieu de ProductGridSkeleton
                  // ProductGridSkeleton retourne un GridView (pas un Sliver) → CRASH
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverProductGridSkeleton(itemCount: 12),
                  )
                else if (model.products.isEmpty)
                  // FIX CRASH: Vérification si la liste est vide
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Aucun produit trouvé',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // FIX CRASH: Try-catch pour capturer erreurs du builder
                          try {
                            // Vérifier bounds
                            if (index < 0 || index >= model.products.length) {
                              AppLogger.debug('❌ [VOICE] Index out of bounds: $index / ${model.products.length}', 'Debug');
                              return Container(
                                color: Colors.red.shade100,
                                child: const Center(child: Text('Index Error')),
                              );
                            }

                            final product = model.products[index];
                            return _buildProductCard(product, context);
                          } catch (e, stackTrace) {
                            AppLogger.debug('❌ [VOICE] CRASH dans builder: $e', 'Debug');
                            AppLogger.debug('   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}', 'Debug');
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: Text(
                                  'Erreur: ${e.toString().substring(0, e.toString().length > 50 ? 50 : e.toString().length)}',
                                  style: const TextStyle(color: Colors.red, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                        },
                        childCount: model.products.length,
                      ),
                    ),
                  ),

                // Espace en bas
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, BuildContext context) {
    // FIX CRASH: Extraire les valeurs avec sécurité maximale
    final String productName = (product['name'] ?? 'Produit').toString();
    final String productBrand = (product['brand'] ?? '').toString();
    final String productImage = (product['image'] ?? '').toString();

    // Prix: conversion sécurisée
    String productPrice;
    final priceRaw = product['price'];
    if (priceRaw is int) {
      productPrice = '$priceRaw';
    } else if (priceRaw is double) {
      productPrice = '${priceRaw.toInt()}';
    } else if (priceRaw is String) {
      productPrice = priceRaw.replaceAll('€', '');
    } else {
      productPrice = '0';
    }

    // Match score: conversion sécurisée
    int matchScore;
    final matchRaw = product['match'];
    if (matchRaw is int) {
      matchScore = matchRaw;
    } else if (matchRaw is double) {
      matchScore = matchRaw.toInt();
    } else {
      matchScore = 85;
    }

    return GestureDetector(
      onTap: () async {
        // Navigation vers les détails du produit
        try {
          final url = ProductUrlService.generateProductUrl(product);
          if (url.isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              AppLogger.debug('❌ Cannot launch URL: $url', 'Debug');
            }
          }
        } catch (e) {
          AppLogger.debug('❌ Error launching URL: $e', 'Debug');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.06)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - FIX: Utiliser variable sécurisée
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: ProductImage(
                imageUrl: productImage,
                height: 180,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),

            // Contenu - FIX: Utiliser variables sécurisées
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match score - FIX: utiliser variable sécurisée
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B9D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconlyBold.heart,
                            size: 12,
                            color: Color(0xFFFF6B9D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$matchScore% Match',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: Color(0xFFFF6B9D),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Nom du produit - FIX: utiliser variable sécurisée
                    Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),

                    const Spacer(),

                    // Prix et marque - FIX: utiliser variables sécurisées
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productPrice == '0' || productPrice.isEmpty
                              ? 'Prix non renseigné'
                              : '${productPrice}€',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: Color(0xFFFF6B9D),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (productBrand.isNotEmpty)
                          Flexible(
                            child: Text(
                              productBrand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(VoiceResultsPageModel model) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: const Icon(
              IconlyLight.danger,
              size: 40,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            model.errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF062248),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              model.retry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
