import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GiftsRecord extends FirestoreRecord {
  GiftsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "brand" field.
  String? _brand;
  String get brand => _brand ?? '';
  bool hasBrand() => _brand != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.0;
  bool hasPrice() => _price != null;

  // "url" field.
  String? _url;
  String get url => _url ?? '';
  bool hasUrl() => _url != null;

  // "image" field.
  String? _image;
  String get image => _image ?? '';
  bool hasImage() => _image != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "categories" field.
  List<String>? _categories;
  List<String> get categories => _categories ?? const [];
  bool hasCategories() => _categories != null;

  // "tags" field.
  List<String>? _tags;
  List<String> get tags => _tags ?? const [];
  bool hasTags() => _tags != null;

  // "popularity" field.
  int? _popularity;
  int get popularity => _popularity ?? 0;
  bool hasPopularity() => _popularity != null;

  // "source" field.
  String? _source;
  String get source => _source ?? '';
  bool hasSource() => _source != null;

  // "active" field.
  bool? _active;
  bool get active => _active ?? true;
  bool hasActive() => _active != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "product_photo" field.
  String? _productPhoto;
  String get productPhoto => _productPhoto ?? '';
  bool hasProductPhoto() => _productPhoto != null;

  // "product_title" field.
  String? _productTitle;
  String get productTitle => _productTitle ?? '';
  bool hasProductTitle() => _productTitle != null;

  // "product_url" field.
  String? _productUrl;
  String get productUrl => _productUrl ?? '';
  bool hasProductUrl() => _productUrl != null;

  // "product_price" field.
  String? _productPrice;
  String get productPrice => _productPrice ?? '';
  bool hasProductPrice() => _productPrice != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _brand = snapshotData['brand'] as String?;
    _price = castToType<double>(snapshotData['price']);
    _url = snapshotData['url'] as String?;
    _image = snapshotData['image'] as String?;
    _description = snapshotData['description'] as String?;
    _categories = getDataList(snapshotData['categories']);
    _tags = getDataList(snapshotData['tags']);
    _popularity = castToType<int>(snapshotData['popularity']);
    _source = snapshotData['source'] as String?;
    _active = snapshotData['active'] as bool?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _productPhoto = snapshotData['product_photo'] as String?;
    _productTitle = snapshotData['product_title'] as String?;
    _productUrl = snapshotData['product_url'] as String?;
    _productPrice = snapshotData['product_price'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('gifts');

  static Stream<GiftsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => GiftsRecord.fromSnapshot(s));

  static Future<GiftsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => GiftsRecord.fromSnapshot(s));

  static GiftsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      GiftsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static GiftsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      GiftsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'GiftsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is GiftsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createGiftsRecordData({
  String? name,
  String? brand,
  double? price,
  String? url,
  String? image,
  String? description,
  int? popularity,
  String? source,
  bool? active,
  DateTime? createdAt,
  String? productPhoto,
  String? productTitle,
  String? productUrl,
  String? productPrice,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'brand': brand,
      'price': price,
      'url': url,
      'image': image,
      'description': description,
      'popularity': popularity,
      'source': source,
      'active': active,
      'created_at': createdAt,
      'product_photo': productPhoto,
      'product_title': productTitle,
      'product_url': productUrl,
      'product_price': productPrice,
    }.withoutNulls,
  );

  return firestoreData;
}

class GiftsRecordDocumentEquality implements Equality<GiftsRecord> {
  const GiftsRecordDocumentEquality();

  @override
  bool equals(GiftsRecord? e1, GiftsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.name == e2?.name &&
        e1?.brand == e2?.brand &&
        e1?.price == e2?.price &&
        e1?.url == e2?.url &&
        e1?.image == e2?.image &&
        e1?.description == e2?.description &&
        listEquality.equals(e1?.categories, e2?.categories) &&
        listEquality.equals(e1?.tags, e2?.tags) &&
        e1?.popularity == e2?.popularity &&
        e1?.source == e2?.source &&
        e1?.active == e2?.active &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(GiftsRecord? e) => const ListEquality().hash([
        e?.name,
        e?.brand,
        e?.price,
        e?.url,
        e?.image,
        e?.description,
        e?.categories,
        e?.tags,
        e?.popularity,
        e?.source,
        e?.active,
        e?.createdAt
      ]);

  @override
  bool isValidKey(Object? o) => o is GiftsRecord;
}
