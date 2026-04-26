import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/pages/components/product/product_widget.dart';
import 'open_ai_result_bottom_sheet_widget.dart'
    show OpenAiResultBottomSheetWidget;
import 'package:flutter/material.dart';

class OpenAiResultBottomSheetModel
    extends FlutterFlowModel<OpenAiResultBottomSheetWidget> {
  ///  Local state fields for this component.

  List<FavouritesRecord> favouriteProducts = [];
  void addToFavouriteProducts(FavouritesRecord item) =>
      favouriteProducts.add(item);
  void removeFromFavouriteProducts(FavouritesRecord item) =>
      favouriteProducts.remove(item);
  void removeAtIndexFromFavouriteProducts(int index) =>
      favouriteProducts.removeAt(index);
  void insertAtIndexInFavouriteProducts(int index, FavouritesRecord item) =>
      favouriteProducts.insert(index, item);
  void updateFavouriteProductsAtIndex(
          int index, Function(FavouritesRecord) updateFn) =>
      favouriteProducts[index] = updateFn(favouriteProducts[index]);

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Firestore Query - Query a collection] action in OpenAiResultBottomSheet widget.
  List<FavouritesRecord>? fetchFvrtProducts;
  // Models for Product dynamic component.
  late FlutterFlowDynamicModels<ProductModel> productModels;
  // Stores action output result for [Backend Call - Create Document] action in Product widget.
  FavouritesRecord? newItem;

  @override
  void initState(BuildContext context) {
    productModels = FlutterFlowDynamicModels(() => ProductModel());
  }

  @override
  void dispose() {
    productModels.dispose();
  }
}
