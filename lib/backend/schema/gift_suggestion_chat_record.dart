import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GiftSuggestionChatRecord extends FirestoreRecord {
  GiftSuggestionChatRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "Title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "Products" field.
  List<ProductsStruct>? _products;
  List<ProductsStruct> get products => _products ?? const [];
  bool hasProducts() => _products != null;

  // "UserId" field.
  DocumentReference? _userId;
  DocumentReference? get userId => _userId;
  bool hasUserId() => _userId != null;

  // "OpenAiResponses" field.
  List<OpenAiResponseStruct>? _openAiResponses;
  List<OpenAiResponseStruct> get openAiResponses =>
      _openAiResponses ?? const [];
  bool hasOpenAiResponses() => _openAiResponses != null;

  // "Timestamp" field.
  DateTime? _timestamp;
  DateTime? get timestamp => _timestamp;
  bool hasTimestamp() => _timestamp != null;

  void _initializeFields() {
    _title = snapshotData['Title'] as String?;
    _products = getStructList(
      snapshotData['Products'],
      ProductsStruct.fromMap,
    );
    _userId = snapshotData['UserId'] as DocumentReference?;
    _openAiResponses = getStructList(
      snapshotData['OpenAiResponses'],
      OpenAiResponseStruct.fromMap,
    );
    _timestamp = snapshotData['Timestamp'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('GiftSuggestionChat');

  static Stream<GiftSuggestionChatRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => GiftSuggestionChatRecord.fromSnapshot(s));

  static Future<GiftSuggestionChatRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => GiftSuggestionChatRecord.fromSnapshot(s));

  static GiftSuggestionChatRecord fromSnapshot(DocumentSnapshot snapshot) =>
      GiftSuggestionChatRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static GiftSuggestionChatRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      GiftSuggestionChatRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'GiftSuggestionChatRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is GiftSuggestionChatRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createGiftSuggestionChatRecordData({
  String? title,
  DocumentReference? userId,
  DateTime? timestamp,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'Title': title,
      'UserId': userId,
      'Timestamp': timestamp,
    }.withoutNulls,
  );

  return firestoreData;
}

class GiftSuggestionChatRecordDocumentEquality
    implements Equality<GiftSuggestionChatRecord> {
  const GiftSuggestionChatRecordDocumentEquality();

  @override
  bool equals(GiftSuggestionChatRecord? e1, GiftSuggestionChatRecord? e2) {
    const listEquality = ListEquality();
    return e1?.title == e2?.title &&
        listEquality.equals(e1?.products, e2?.products) &&
        e1?.userId == e2?.userId &&
        listEquality.equals(e1?.openAiResponses, e2?.openAiResponses) &&
        e1?.timestamp == e2?.timestamp;
  }

  @override
  int hash(GiftSuggestionChatRecord? e) => const ListEquality().hash(
      [e?.title, e?.products, e?.userId, e?.openAiResponses, e?.timestamp]);

  @override
  bool isValidKey(Object? o) => o is GiftSuggestionChatRecord;
}
