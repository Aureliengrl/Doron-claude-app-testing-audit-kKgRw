const fs = require('fs');
const path = require('path');

function createDummy(filePath, className, isStateful = true) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  
  let content = `import 'package:flutter/material.dart';\n\n`;
  
  if (className === 'showConnectionRequiredDialog') {
    content += `void showConnectionRequiredDialog(BuildContext context) {}\n`;
  } else {
    if (isStateful) {
      content += `class ${className} extends StatefulWidget {\n  const ${className}({Key? key, this.forceGroup, this.suggestedGroupName, this.product, this.profile}) : super(key: key);\n  final dynamic forceGroup;\n  final dynamic suggestedGroupName;\n  final dynamic product;\n  final dynamic profile;\n  @override\n  State<${className}> createState() => _${className}State();\n  static void show(BuildContext context, dynamic product) {}\n}\n\nclass _${className}State extends State<${className}> {\n  @override\n  Widget build(BuildContext context) => const SizedBox.shrink();\n}\n`;
    } else {
      content += `class ${className} extends StatelessWidget {\n  const ${className}({Key? key}) : super(key: key);\n  @override\n  Widget build(BuildContext context) => const SizedBox.shrink();\n}\n`;
    }
  }
  
  fs.writeFileSync(filePath, content, 'utf8');
}

// 1. connection_required_dialog
createDummy('lib/components/connection_required_dialog.dart', 'showConnectionRequiredDialog');

// 2. wishlist_picker_sheet
createDummy('lib/components/wishlist_picker_sheet.dart', 'WishlistPickerSheet');

// 3. tiktok_inspiration_page_widget
createDummy('lib/pages/tiktok_inspiration/tiktok_inspiration_page_widget.dart', 'TikTokInspirationPageWidget');

// 4. ticket_success_widget
createDummy('lib/pages/ticket_payment/ticket_success_widget.dart', 'TicketSuccessWidget');

// 5. liked_products_page_widget
createDummy('lib/pages/liked_products/liked_products_page_widget.dart', 'LikedProductsPageWidget');

// 6. create_chat_bottom_sheet
createDummy('lib/pages/new_pages/chat/create_chat_bottom_sheet.dart', 'CreateChatBottomSheet');

// We also need to uncomment the imports we commented out in previous steps to let them resolve!
function uncommentImports(filePath) {
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    content = content.replace(/\/\/ import /g, "import ");
    content = content.replace(/\/\/ export /g, "export ");
    content = content.replace(/\/\/ show /g, "show ");
    fs.writeFileSync(filePath, content, 'utf8');
  }
}

uncommentImports('lib/index.dart');
uncommentImports('lib/components/product_detail_modal.dart');
uncommentImports('lib/components/shared_product_card.dart');
uncommentImports('lib/pages/new_pages/chat/chat_list_page.dart');

console.log('Dummy files created to resolve missing dependencies.');
