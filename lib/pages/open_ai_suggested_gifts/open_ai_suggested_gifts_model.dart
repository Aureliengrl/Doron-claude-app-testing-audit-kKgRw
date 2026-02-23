import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/pages/components/product/product_widget.dart';
import 'dart:ui';
import 'open_ai_suggested_gifts_widget.dart' show OpenAiSuggestedGiftsWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OpenAiSuggestedGiftsModel
    extends FlutterFlowModel<OpenAiSuggestedGiftsWidget> {
  ///  Local state fields for this page.

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

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in openAiSuggestedGifts widget.
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
