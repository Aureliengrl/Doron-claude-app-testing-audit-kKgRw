const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'lib', 'pages', 'new_pages', 'onboarding_gifts_result', 'onboarding_gifts_result_widget.dart');
let content = fs.readFileSync(filePath, 'latin1');

// 1. Add imports
content = content.replace(
  "import '/services/product_url_service.dart';",
  "import '/services/product_url_service.dart';\nimport '/services/claude_api_service.dart';\nimport '/services/amazon_affiliation_service.dart';"
);

// 2. Replace generation logic
const targetGen = `      // ?? Générer les cadeaux via ProductMatchingService
      final rawGifts = await ProductMatchingService.getPersonalizedProducts(
        userTags: profileForGeneration ?? {},
        count: 50,
        excludeProductIds: forceRefresh ? seenProductIds : null,
        filteringMode: "person",
      );`;

const newGen = `      // ?? NOUVELLE LOGIQUE : Générer les cadeaux via Claude API
      List<Map<String, dynamic>> rawGifts = [];
      
      final claudeIdeas = await ClaudeApiService.generateGiftIdeas(profileForGeneration ?? {});
      
      if (claudeIdeas.isNotEmpty) {
        for (var i = 0; i < claudeIdeas.length; i++) {
          final idea = claudeIdeas[i];
          rawGifts.add({
            'id': 'claude_' + DateTime.now().millisecondsSinceEpoch.toString() + '_' + i.toString(),
            'name': idea['name'] ?? 'Idée Cadeau',
            'brand': 'Recommandation IA',
            'price': idea['priceEstimate'] ?? 0,
            'image': 'https://firebasestorage.googleapis.com/v0/b/doron-2287f.appspot.com/o/doron_gift_placeholder.png?alt=media',
            'url': AmazonAffiliationService.getAffiliateUrl(null, searchQuery: idea['name'] ?? ''),
            '_matchScore': 99 - i,
            'description': idea['reason'] ?? '',
          });
        }
      }

      // Fallback sur le catalogue local
      if (rawGifts.isEmpty) {
        rawGifts = await ProductMatchingService.getPersonalizedProducts(
          userTags: profileForGeneration ?? {},
          count: 50,
          excludeProductIds: forceRefresh ? seenProductIds : null,
          filteringMode: "person",
        );
      }`;

content = content.replace(targetGen, newGen);

// 3. Replace product URL tagging
const targetUrl = `          // FIX-URL: ProductUrlService cherche buyLinks[0].url en priorité (vraie URL directe)
          'url': ProductUrlService.generateProductUrl(product),`;

const newUrl = `          'url': AmazonAffiliationService.getAffiliateUrl(ProductUrlService.generateProductUrl(product)),`;

content = content.replace(targetUrl, newUrl);

fs.writeFileSync(filePath, content, 'utf8');
console.log('Modifications Claude & Amazon terminées !');
