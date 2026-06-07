const fs = require('fs');
const path = 'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart';
let content = fs.readFileSync(path, 'utf8');

const regex = /onSubmitted:\s*\([\s\S]*?\},\n/m;
if (content.match(regex)) {
  content = content.replace(regex, '');
  fs.writeFileSync(path, content, 'utf8');
  console.log('Fixed onSubmitted issue.');
} else {
  console.log('onSubmitted not found or already fixed.');
}
