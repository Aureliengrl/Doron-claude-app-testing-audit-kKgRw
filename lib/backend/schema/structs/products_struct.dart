// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProductsStruct extends FFFirebaseStruct {
  ProductsStruct({
    String? productTitle,
    String? productPrice,
    String? productUrl,
    String? productOriginalPrice,
    String? productStarRating,
    String? productPhoto,
    int? productNumRatings,
    String? platform,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _productTitle = productTitle,
        _productPrice = productPrice,
        _productUrl = productUrl,
        _productOriginalPrice = productOriginalPrice,
        _productStarRating = productStarRating,
        _productPhoto = productPhoto,
        _productNumRatings = productNumRatings,
        _platform = platform,
        super(firestoreUtilData);

  // "product_title" field.
  String? _productTitle;
  String get productTitle => _productTitle ?? '';
  set productTitle(String? val) => _productTitle = val;

  bool hasProductTitle() => _productTitle != null;

  // "product_price" field.
  String? _productPrice;
  String get productPrice => _productPrice ?? '';
  set productPrice(String? val) => _productPrice = val;

  bool hasProductPrice() => _productPrice != null;

  // "product_url" field.
  String? _productUrl;
  String get productUrl => _productUrl ?? '';
  set productUrl(String? val) => _productUrl = val;

  bool hasProductUrl() => _productUrl != null;

  // "product_original_price" field.
  String? _productOriginalPrice;
  String get productOriginalPrice => _productOriginalPrice ?? '';
  set productOriginalPrice(String? val) => _productOriginalPrice = val;

  bool hasProductOriginalPrice() => _productOriginalPrice != null;

  // "product_star_rating" field.
  String? _productStarRating;
  String get productStarRating => _productStarRating ?? '';
  set productStarRating(String? val) => _productStarRating = val;

  bool hasProductStarRating() => _productStarRating != null;

  // "product_photo" field.
  String? _productPhoto;
  String get productPhoto => _productPhoto ?? '';
  set productPhoto(String? val) => _productPhoto = val;

  bool hasProductPhoto() => _productPhoto != null;

  // "product_num_ratings" field.
  int? _productNumRatings;
  int get productNumRatings => _productNumRatings ?? 0;
  set productNumRatings(int? val) => _productNumRatings = val;

  void incrementProductNumRatings(int amount) =>
      productNumRatings = productNumRatings + amount;

  bool hasProductNumRatings() => _productNumRatings != null;

  // "platform" field.
  String? _platform;
  String get platform => _platform ?? '';
  set platform(String? val) => _platform = val;

  bool hasPlatform() => _platform != null;

  static ProductsStruct fromMap(Map<String, dynamic> data) => ProductsStruct(
        productTitle: data['product_title'] as String?,
        productPrice: data['product_price'] as String?,
        productUrl: data['product_url'] as String?,
        productOriginalPrice: data['product_original_price'] as String?,
        productStarRating: data['product_star_rating'] as String?,
        productPhoto: data['product_photo'] as String?,
        productNumRatings: castToType<int>(data['product_num_ratings']),
        platform: data['platform'] as String?,
      );

  static ProductsStruct? maybeFromMap(dynamic data) =>
      data is Map ? ProductsStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'product_title': _productTitle,
        'product_price': _productPrice,
        'product_url': _productUrl,
        'product_original_price': _productOriginalPrice,
        'product_star_rating': _productStarRating,
        'product_photo': _productPhoto,
        'product_num_ratings': _productNumRatings,
        'platform': _platform,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'product_title': serializeParam(
          _productTitle,
          ParamType.String,
        ),
        'product_price': serializeParam(
          _productPrice,
          ParamType.String,
        ),
        'product_url': serializeParam(
          _productUrl,
          ParamType.String,
        ),
        'product_original_price': serializeParam(
          _productOriginalPrice,
          ParamType.String,
        ),
        'product_star_rating': serializeParam(
          _productStarRating,
          ParamType.String,
        ),
        'product_photo': serializeParam(
          _productPhoto,
          ParamType.String,
        ),
        'product_num_ratings': serializeParam(
          _productNumRatings,
          ParamType.int,
        ),
        'platform': serializeParam(
          _platform,
          ParamType.String,
        ),
      }.withoutNulls;

  static ProductsStruct fromSerializableMap(Map<String, dynamic> data) =>
      ProductsStruct(
        productTitle: deserializeParam(
          data['product_title'],
          ParamType.String,
          false,
        ),
        productPrice: deserializeParam(
          data['product_price'],
          ParamType.String,
          false,
        ),
        productUrl: deserializeParam(
          data['product_url'],
          ParamType.String,
          false,
        ),
        productOriginalPrice: deserializeParam(
          data['product_original_price'],
          ParamType.String,
          false,
        ),
        productStarRating: deserializeParam(
          data['product_star_rating'],
          ParamType.String,
          false,
        ),
        productPhoto: deserializeParam(
          data['product_photo'],
          ParamType.String,
          false,
        ),
        productNumRatings: deserializeParam(
          data['product_num_ratings'],
          ParamType.int,
          false,
        ),
        platform: deserializeParam(
          data['platform'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ProductsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProductsStruct &&
        productTitle == other.productTitle &&
        productPrice == other.productPrice &&
        productUrl == other.productUrl &&
        productOriginalPrice == other.productOriginalPrice &&
        productStarRating == other.productStarRating &&
        productPhoto == other.productPhoto &&
        productNumRatings == other.productNumRatings &&
        platform == other.platform;
  }

  @override
  int get hashCode => const ListEquality().hash([
        productTitle,
        productPrice,
        productUrl,
        productOriginalPrice,
        productStarRating,
        productPhoto,
        productNumRatings,
        platform
      ]);
}

ProductsStruct createProductsStruct({
  String? productTitle,
  String? productPrice,
  String? productUrl,
  String? productOriginalPrice,
  String? productStarRating,
  String? productPhoto,
  int? productNumRatings,
  String? platform,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ProductsStruct(
      productTitle: productTitle,
      productPrice: productPrice,
      productUrl: productUrl,
      productOriginalPrice: productOriginalPrice,
      productStarRating: productStarRating,
      productPhoto: productPhoto,
      productNumRatings: productNumRatings,
      platform: platform,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ProductsStruct? updateProductsStruct(
  ProductsStruct? products, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    products
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addProductsStructData(
  Map<String, dynamic> firestoreData,
  ProductsStruct? products,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (products == null) {
    return;
  }
  if (products.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && products.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final productsData = getProductsFirestoreData(products, forFieldValue);
  final nestedData = productsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = products.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getProductsFirestoreData(
  ProductsStruct? products, [
  bool forFieldValue = false,
]) {
  if (products == null) {
    return {};
  }
  final firestoreData = mapToFirestore(products.toMap());

  // Add any Firestore field values
  products.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getProductsListFirestoreData(
  List<ProductsStruct>? productss,
) =>
    productss?.map((e) => getProductsFirestoreData(e, true)).toList() ?? [];
