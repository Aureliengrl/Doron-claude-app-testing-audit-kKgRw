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

createDummy('lib/components/connection_required_dialog.dart', 'showConnectionRequiredDialog');
createDummy('lib/components/wishlist_picker_sheet.dart', 'WishlistPickerSheet');
createDummy('lib/pages/tiktok_inspiration/tiktok_inspiration_page_widget.dart', 'TikTokInspirationPageWidget');
createDummy('lib/pages/ticket_payment/ticket_success_widget.dart', 'TicketSuccessWidget');
createDummy('lib/pages/liked_products/liked_products_page_widget.dart', 'LikedProductsPageWidget');
createDummy('lib/pages/new_pages/chat/create_chat_bottom_sheet.dart', 'CreateChatBottomSheet');
createDummy('lib/pages/pages/favourites/favourites_widget.dart', 'FavouritesWidget');

console.log('Dummy files created to resolve missing dependencies.');
