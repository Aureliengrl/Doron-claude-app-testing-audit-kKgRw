const fs = require('fs');
const path = 'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart';
let content = fs.readFileSync(path, 'utf8');

const missingMethods = `
  void _onSearch(String query) {
    setState(() {
      _model.setSearchQuery(query);
      _model.products.clear();
    });
    _loadProducts();
  }

  void _onBrandSelected(String brandId) {
    if (_model.activeBrand == brandId) return;
    setState(() {
      _model.activeBrand = brandId;
      _model.products.clear();
    });
    _loadProducts();
  }
`;

if (!content.includes('void _onSearch(String query)')) {
  content = content.replace('Widget _buildCategories() {', missingMethods + '\n  Widget _buildCategories() {');
  fs.writeFileSync(path, content, 'utf8');
  console.log('Fixed missing methods.');
} else {
  console.log('Methods already fixed.');
}
