import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FavouritesRecord extends FirestoreRecord {
  FavouritesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "uid" field.
  DocumentReference? _uid;
  DocumentReference? get uid => _uid;
  bool hasUid() => _uid != null;

  // "platform" field.
  String? _platform;
  String? get platform => _platform;
  bool hasPlatform() => _platform != null;

  // "product" field.
  ProductsStruct? _product;
  ProductsStruct get product => _product ?? ProductsStruct();
  bool hasProduct() => _product != null;

  // "TimeStamp" field.
  DateTime? _timeStamp;
  DateTime? get timeStamp => _timeStamp;
  bool hasTimeStamp() => _timeStamp != null;

  // "personId" field - ID de la personne (pour grouper les favoris par personne)
  String? _personId;
  String? get personId => _personId;
  bool hasPersonId() => _personId != null;

  void _initializeFields() {
    _uid = snapshotData['uid'] as DocumentReference?;
    _platform = snapshotData['platform'] as String?;
    _product = snapshotData['product'] is ProductsStruct
        ? snapshotData['product']
        : ProductsStruct.maybeFromMap(snapshotData['product']);
    _timeStamp = snapshotData['TimeStamp'] as DateTime?;
    _personId = snapshotData['personId'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Favourites');

  static Stream<FavouritesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => FavouritesRecord.fromSnapshot(s));

  static Future<FavouritesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => FavouritesRecord.fromSnapshot(s));

  static FavouritesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      FavouritesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static FavouritesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      FavouritesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'FavouritesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is FavouritesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createFavouritesRecordData({
  DocumentReference? uid,
  String? platform,
  ProductsStruct? product,
  DateTime? timeStamp,
  String? personId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'uid': uid,
      'platform': platform,
      'product': ProductsStruct().toMap(),
      'TimeStamp': timeStamp,
      'personId': personId,
    }.withoutNulls,
  );

  // Handle nested data for "product" field.
  addProductsStructData(firestoreData, product, 'product');

  return firestoreData;
}

class FavouritesRecordDocumentEquality implements Equality<FavouritesRecord> {
  const FavouritesRecordDocumentEquality();

  @override
  bool equals(FavouritesRecord? e1, FavouritesRecord? e2) {
    return e1?.uid == e2?.uid &&
        e1?.platform == e2?.platform &&
        e1?.product == e2?.product &&
        e1?.timeStamp == e2?.timeStamp &&
        e1?.personId == e2?.personId;
  }

  @override
  int hash(FavouritesRecord? e) => const ListEquality()
      .hash([e?.uid, e?.platform, e?.product, e?.timeStamp, e?.personId]);

  @override
  bool isValidKey(Object? o) => o is FavouritesRecord;
}
