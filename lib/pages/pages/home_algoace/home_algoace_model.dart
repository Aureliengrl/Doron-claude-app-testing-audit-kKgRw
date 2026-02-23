import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/pages/components/loader/loader_widget.dart';
import '/pages/pages/components/product/product_widget.dart';
import '/pages/pages/empty_data/empty_data_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'home_algoace_widget.dart' show HomeAlgoaceWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeAlgoaceModel extends FlutterFlowModel<HomeAlgoaceWidget> {
  ///  Local state fields for this page.

  List<ProductsStruct> searchedProducts = [];
  void addToSearchedProducts(ProductsStruct item) => searchedProducts.add(item);
  void removeFromSearchedProducts(ProductsStruct item) =>
      searchedProducts.remove(item);
  void removeAtIndexFromSearchedProducts(int index) =>
      searchedProducts.removeAt(index);
  void insertAtIndexInSearchedProducts(int index, ProductsStruct item) =>
      searchedProducts.insert(index, item);
  void updateSearchedProductsAtIndex(
          int index, Function(ProductsStruct) updateFn) =>
      searchedProducts[index] = updateFn(searchedProducts[index]);

  bool toggleSearchProduct = false;

  bool loader = true;

  int? counter = 0;

  List<FavouritesRecord> favouritesList = [];
  void addToFavouritesList(FavouritesRecord item) => favouritesList.add(item);
  void removeFromFavouritesList(FavouritesRecord item) =>
      favouritesList.remove(item);
  void removeAtIndexFromFavouritesList(int index) =>
      favouritesList.removeAt(index);
  void insertAtIndexInFavouritesList(int index, FavouritesRecord item) =>
      favouritesList.insert(index, item);
  void updateFavouritesListAtIndex(
          int index, Function(FavouritesRecord) updateFn) =>
      favouritesList[index] = updateFn(favouritesList[index]);

  int loopCounter = 0;

  ProductsStruct? eachProduct;
  void updateEachProductStruct(Function(ProductsStruct) updateFn) {
    updateFn(eachProduct ??= ProductsStruct());
  }

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in HomeAlgoace widget.
  List<FavouritesRecord>? favourite;
  // Stores action output result for [Backend Call - API (Amazon Api Search and Discounts)] action in HomeAlgoace widget.
  ApiCallResponse? apiAmazon;
  // Stores action output result for [Backend Call - API (Sephora)] action in HomeAlgoace widget.
  ApiCallResponse? sephora;
  // Stores action output result for [Backend Call - API (Ikea)] action in HomeAlgoace widget.
  ApiCallResponse? ikeaOnPageLoad;
  // Stores action output result for [Backend Call - API (Zara)] action in HomeAlgoace widget.
  ApiCallResponse? apiResultb92;
  // State field(s) for search widget.
  FocusNode? searchFocusNode;
  TextEditingController? searchTextController;
  String? Function(BuildContext, String?)? searchTextControllerValidator;
  // Stores action output result for [Backend Call - API (Amazon Api Search and Discounts)] action in search widget.
  ApiCallResponse? searchedOutputCopy;
  // Stores action output result for [Backend Call - API (Sephora)] action in search widget.
  ApiCallResponse? seporaOnChange;
  // Stores action output result for [Backend Call - API (Ikea)] action in search widget.
  ApiCallResponse? ikeaOnChange;
  // Stores action output result for [Backend Call - API (Amazon Api Search and Discounts)] action in Icon widget.
  ApiCallResponse? searchedOutput;
  // Stores action output result for [Backend Call - API (Sephora)] action in Icon widget.
  ApiCallResponse? seporaOnSubmit;
  // Stores action output result for [Backend Call - API (Ikea)] action in Icon widget.
  ApiCallResponse? ikeaOnSubmit;
  // Model for loader component.
  late LoaderModel loaderModel;
  // Models for Product dynamic component.
  late FlutterFlowDynamicModels<ProductModel> productModels1;
  // Stores action output result for [Backend Call - Create Document] action in Product widget.
  FavouritesRecord? newItemSearched;
  // Model for emptyData component.
  late EmptyDataModel emptyDataModel1;
  // Models for Product dynamic component.
  late FlutterFlowDynamicModels<ProductModel> productModels2;
  // Stores action output result for [Backend Call - Create Document] action in Product widget.
  FavouritesRecord? newItem;
  // Model for emptyData component.
  late EmptyDataModel emptyDataModel2;

  @override
  void initState(BuildContext context) {
    loaderModel = createModel(context, () => LoaderModel());
    productModels1 = FlutterFlowDynamicModels(() => ProductModel());
    emptyDataModel1 = createModel(context, () => EmptyDataModel());
    productModels2 = FlutterFlowDynamicModels(() => ProductModel());
    emptyDataModel2 = createModel(context, () => EmptyDataModel());
  }

  @override
  void dispose() {
    searchFocusNode?.dispose();
    searchTextController?.dispose();

    loaderModel.dispose();
    productModels1.dispose();
    emptyDataModel1.dispose();
    productModels2.dispose();
    emptyDataModel2.dispose();
  }
}
