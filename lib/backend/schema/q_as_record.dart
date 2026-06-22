import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class QAsRecord extends FirestoreRecord {
  QAsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "Question" field.
  String? _question;
  String get question => _question ?? '';
  bool hasQuestion() => _question != null;

  // "Answer" field.
  String? _answer;
  String get answer => _answer ?? '';
  bool hasAnswer() => _answer != null;

  // "TimeStamp" field.
  DateTime? _timeStamp;
  DateTime? get timeStamp => _timeStamp;
  bool hasTimeStamp() => _timeStamp != null;

  void _initializeFields() {
    _question = snapshotData['Question'] as String?;
    _answer = snapshotData['Answer'] as String?;
    _timeStamp = snapshotData['TimeStamp'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('QAs');

  static Stream<QAsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => QAsRecord.fromSnapshot(s));

  static Future<QAsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => QAsRecord.fromSnapshot(s));

  static QAsRecord fromSnapshot(DocumentSnapshot snapshot) => QAsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static QAsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      QAsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'QAsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is QAsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createQAsRecordData({
  String? question,
  String? answer,
  DateTime? timeStamp,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'Question': question,
      'Answer': answer,
      'TimeStamp': timeStamp,
    }.withoutNulls,
  );

  return firestoreData;
}

class QAsRecordDocumentEquality implements Equality<QAsRecord> {
  const QAsRecordDocumentEquality();

  @override
  bool equals(QAsRecord? e1, QAsRecord? e2) {
    return e1?.question == e2?.question &&
        e1?.answer == e2?.answer &&
        e1?.timeStamp == e2?.timeStamp;
  }

  @override
  int hash(QAsRecord? e) =>
      const ListEquality().hash([e?.question, e?.answer, e?.timeStamp]);

  @override
  bool isValidKey(Object? o) => o is QAsRecord;
}
