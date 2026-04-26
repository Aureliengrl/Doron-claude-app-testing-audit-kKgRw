import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  bool _firstTime = true;
  bool get firstTime => _firstTime;
  set firstTime(bool value) {
    _firstTime = value;
  }

  /// Showing Intial Products in HomePage
  List<ProductsStruct> _HomeProducts = [];
  List<ProductsStruct> get HomeProducts => _HomeProducts;
  set HomeProducts(List<ProductsStruct> value) {
    _HomeProducts = value;
  }

  void addToHomeProducts(ProductsStruct value) {
    HomeProducts.add(value);
  }

  void removeFromHomeProducts(ProductsStruct value) {
    HomeProducts.remove(value);
  }

  void removeAtIndexFromHomeProducts(int index) {
    HomeProducts.removeAt(index);
  }

  void updateHomeProductsAtIndex(
    int index,
    ProductsStruct Function(ProductsStruct) updateFn,
  ) {
    HomeProducts[index] = updateFn(_HomeProducts[index]);
  }

  void insertAtIndexInHomeProducts(int index, ProductsStruct value) {
    HomeProducts.insert(index, value);
  }

  bool _needsRefresh = false;
  bool get needsRefresh => _needsRefresh;
  set needsRefresh(bool value) {
    _needsRefresh = value;
  }
}
