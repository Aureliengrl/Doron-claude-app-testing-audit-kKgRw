const fs = require('fs');

// 1. product_detail_modal.dart
const productDetailPath = 'lib/components/product_detail_modal.dart';
if (fs.existsSync(productDetailPath)) {
  let content = fs.readFileSync(productDetailPath, 'utf8');
  content = content.replace(/import '\/components\/connection_required_dialog\.dart';/g, "// import connection_required_dialog");
  content = content.replace(/showConnectionRequiredDialog\(context\);/g, "// showConnectionRequiredDialog(context);");
  fs.writeFileSync(productDetailPath, content, 'utf8');
}

// 2. shared_product_card.dart
const sharedProductCardPath = 'lib/components/shared_product_card.dart';
if (fs.existsSync(sharedProductCardPath)) {
  let content = fs.readFileSync(sharedProductCardPath, 'utf8');
  content = content.replace(/import '\/components\/wishlist_picker_sheet\.dart';/g, "// import wishlist_picker_sheet");
  content = content.replace(/WishlistPickerSheet\.show\(context, widget\.product\);/g, "// WishlistPickerSheet.show(context, widget.product);");
  fs.writeFileSync(sharedProductCardPath, content, 'utf8');
}

// 3. index.dart
const indexPath = 'lib/index.dart';
if (fs.existsSync(indexPath)) {
  let content = fs.readFileSync(indexPath, 'utf8');
  content = content.replace(/export '\/pages\/tiktok_inspiration\/tiktok_inspiration_page_widget\.dart'/g, "// export tiktok");
  content = content.replace(/export '\/pages\/ticket_payment\/ticket_success_widget\.dart'/g, "// export ticket");
  content = content.replace(/export '\/pages\/liked_products\/liked_products_page_widget\.dart'/g, "// export liked_products");
  fs.writeFileSync(indexPath, content, 'utf8');
}

// 4. chat_list_page.dart
const chatListPath = 'lib/pages/new_pages/chat/chat_list_page.dart';
if (fs.existsSync(chatListPath)) {
  let content = fs.readFileSync(chatListPath, 'utf8');
  content = content.replace(/child:\s*CreateChatBottomSheet\([\s\S]*?\),/g, "child: Container(), /* bypassed */");
  fs.writeFileSync(chatListPath, content, 'utf8');
}

console.log('Final fixes round 4 applied.');
