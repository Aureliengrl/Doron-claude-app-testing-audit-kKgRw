const fs = require('fs');

// 1. index.dart
const indexPath = 'lib/index.dart';
let indexContent = fs.readFileSync(indexPath, 'utf8');
indexContent = indexContent.replace(
  "export '/pages/pages/favourites/favourites_widget.dart' show FavouritesWidget;",
  "// export '/pages/pages/favourites/favourites_widget.dart' show FavouritesWidget;"
);
indexContent = indexContent.replace(
  "export '/pages/tiktok_inspiration/tiktok_inspiration_page_widget.dart'\n    show TikTokInspirationPageWidget;",
  "// export '/pages/tiktok_inspiration/tiktok_inspiration_page_widget.dart'\n//    show TikTokInspirationPageWidget;"
);
indexContent = indexContent.replace(
  "export '/pages/ticket_payment/ticket_success_widget.dart'\n    show TicketSuccessWidget;",
  "// export '/pages/ticket_payment/ticket_success_widget.dart'\n//    show TicketSuccessWidget;"
);
indexContent = indexContent.replace(
  "export '/pages/liked_products/liked_products_page_widget.dart'\n    show LikedProductsPageWidget;",
  "// export '/pages/liked_products/liked_products_page_widget.dart'\n//    show LikedProductsPageWidget;"
);
fs.writeFileSync(indexPath, indexContent, 'utf8');

// 2. main.dart
const mainPath = 'lib/main.dart';
let mainContent = fs.readFileSync(mainPath, 'utf8');
mainContent = mainContent.replace(
  "import '/components/connection_required_dialog.dart';",
  "// import '/components/connection_required_dialog.dart';"
);
mainContent = mainContent.replace(
  "      TikTokInspirationPageWidget(),",
  "      Container(), // TikTokInspirationPageWidget replaced due to missing file"
);
fs.writeFileSync(mainPath, mainContent, 'utf8');

// 3. chat_list_page.dart (Multi-line replacement)
const chatPath = 'lib/pages/new_pages/chat/chat_list_page.dart';
let chatContent = fs.readFileSync(chatPath, 'utf8');
chatContent = chatContent.replace(
  "          child: CreateChatBottomSheet(\n            forceGroup: true,\n            suggestedGroupName: suggestion['title'] as String,\n          ),",
  "          child: Container(), /* bypassed CreateChatBottomSheet */"
);
fs.writeFileSync(chatPath, chatContent, 'utf8');

console.log('Final syntax round 3 fixes applied.');
