const fs = require('fs');
const path = 'lib/pages/new_pages/home_pinterest/home_pinterest_model.dart';
let content = fs.readFileSync(path, 'utf8');

const newVariables = `
  // AI Personalization
  List<String> personalizedBrands = [];
  List<String> personalizedEvents = [];
  bool isBrandsLoading = false;
  bool isEventsLoading = false;
`;

if (!content.includes('personalizedBrands')) {
  content = content.replace('String? errorDetails;', 'String? errorDetails;\n' + newVariables);
  fs.writeFileSync(path, content, 'utf8');
  console.log('Model updated successfully.');
} else {
  console.log('Model already updated.');
}
