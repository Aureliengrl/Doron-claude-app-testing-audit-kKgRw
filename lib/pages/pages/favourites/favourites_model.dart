import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/pages/components/loader/loader_widget.dart';
import '/pages/pages/components/product/product_widget.dart';
import '/pages/pages/empty_data/empty_data_widget.dart';
// import fav_widget.dart bypassed
import 'package:flutter/material.dart';

class FavouritesModel extends FlutterFlowModel<StatefulWidget> {
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

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in Favourites widget.
  List<FavouritesRecord>? favourite;
  // Model for loader component.
  late LoaderModel loaderModel;
  // Models for Product dynamic component.
  late FlutterFlowDynamicModels<ProductModel> productModels;
  // Model for emptyData component.
  late EmptyDataModel emptyDataModel;

  @override
  void initState(BuildContext context) {
    loaderModel = createModel(context, () => LoaderModel());
    productModels = FlutterFlowDynamicModels(() => ProductModel());
    emptyDataModel = createModel(context, () => EmptyDataModel());
  }

  @override
  void dispose() {
    loaderModel.dispose();
    productModels.dispose();
    emptyDataModel.dispose();
  }
}
