// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OpenAiResponseStruct extends FFFirebaseStruct {
  OpenAiResponseStruct({
    String? followupquestion,
    String? finalproductquery,
    String? usersAnswer,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _followupquestion = followupquestion,
        _finalproductquery = finalproductquery,
        _usersAnswer = usersAnswer,
        super(firestoreUtilData);

  // "followupquestion" field.
  String? _followupquestion;
  String get followupquestion => _followupquestion ?? '';
  set followupquestion(String? val) => _followupquestion = val;

  bool hasFollowupquestion() => _followupquestion != null;

  // "finalproductquery" field.
  String? _finalproductquery;
  String get finalproductquery => _finalproductquery ?? '';
  set finalproductquery(String? val) => _finalproductquery = val;

  bool hasFinalproductquery() => _finalproductquery != null;

  // "usersAnswer" field.
  String? _usersAnswer;
  String get usersAnswer => _usersAnswer ?? '';
  set usersAnswer(String? val) => _usersAnswer = val;

  bool hasUsersAnswer() => _usersAnswer != null;

  static OpenAiResponseStruct fromMap(Map<String, dynamic> data) =>
      OpenAiResponseStruct(
        followupquestion: data['followupquestion'] as String?,
        finalproductquery: data['finalproductquery'] as String?,
        usersAnswer: data['usersAnswer'] as String?,
      );

  static OpenAiResponseStruct? maybeFromMap(dynamic data) => data is Map
      ? OpenAiResponseStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'followupquestion': _followupquestion,
        'finalproductquery': _finalproductquery,
        'usersAnswer': _usersAnswer,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'followupquestion': serializeParam(
          _followupquestion,
          ParamType.String,
        ),
        'finalproductquery': serializeParam(
          _finalproductquery,
          ParamType.String,
        ),
        'usersAnswer': serializeParam(
          _usersAnswer,
          ParamType.String,
        ),
      }.withoutNulls;

  static OpenAiResponseStruct fromSerializableMap(Map<String, dynamic> data) =>
      OpenAiResponseStruct(
        followupquestion: deserializeParam(
          data['followupquestion'],
          ParamType.String,
          false,
        ),
        finalproductquery: deserializeParam(
          data['finalproductquery'],
          ParamType.String,
          false,
        ),
        usersAnswer: deserializeParam(
          data['usersAnswer'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'OpenAiResponseStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is OpenAiResponseStruct &&
        followupquestion == other.followupquestion &&
        finalproductquery == other.finalproductquery &&
        usersAnswer == other.usersAnswer;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([followupquestion, finalproductquery, usersAnswer]);
}

OpenAiResponseStruct createOpenAiResponseStruct({
  String? followupquestion,
  String? finalproductquery,
  String? usersAnswer,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    OpenAiResponseStruct(
      followupquestion: followupquestion,
      finalproductquery: finalproductquery,
      usersAnswer: usersAnswer,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

OpenAiResponseStruct? updateOpenAiResponseStruct(
  OpenAiResponseStruct? openAiResponse, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    openAiResponse
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addOpenAiResponseStructData(
  Map<String, dynamic> firestoreData,
  OpenAiResponseStruct? openAiResponse,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (openAiResponse == null) {
    return;
  }
  if (openAiResponse.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && openAiResponse.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final openAiResponseData =
      getOpenAiResponseFirestoreData(openAiResponse, forFieldValue);
  final nestedData =
      openAiResponseData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = openAiResponse.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getOpenAiResponseFirestoreData(
  OpenAiResponseStruct? openAiResponse, [
  bool forFieldValue = false,
]) {
  if (openAiResponse == null) {
    return {};
  }
  final firestoreData = mapToFirestore(openAiResponse.toMap());

  // Add any Firestore field values
  openAiResponse.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getOpenAiResponseListFirestoreData(
  List<OpenAiResponseStruct>? openAiResponses,
) =>
    openAiResponses
        ?.map((e) => getOpenAiResponseFirestoreData(e, true))
        .toList() ??
    [];
