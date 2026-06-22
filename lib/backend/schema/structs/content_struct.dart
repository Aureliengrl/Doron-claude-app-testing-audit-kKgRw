// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ContentStruct extends FFFirebaseStruct {
  ContentStruct({
    String? giftrecipient,
    String? budget,
    int? age,
    List<String>? interests,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _giftrecipient = giftrecipient,
        _budget = budget,
        _age = age,
        _interests = interests,
        super(firestoreUtilData);

  // "Giftrecipient" field.
  String? _giftrecipient;
  String get giftrecipient => _giftrecipient ?? '';
  set giftrecipient(String? val) => _giftrecipient = val;

  bool hasGiftrecipient() => _giftrecipient != null;

  // "Budget" field.
  String? _budget;
  String get budget => _budget ?? '';
  set budget(String? val) => _budget = val;

  bool hasBudget() => _budget != null;

  // "age" field.
  int? _age;
  int get age => _age ?? 0;
  set age(int? val) => _age = val;

  void incrementAge(int amount) => age = age + amount;

  bool hasAge() => _age != null;

  // "Interests" field.
  List<String>? _interests;
  List<String> get interests => _interests ?? const [];
  set interests(List<String>? val) => _interests = val;

  void updateInterests(Function(List<String>) updateFn) {
    updateFn(_interests ??= []);
  }

  bool hasInterests() => _interests != null;

  static ContentStruct fromMap(Map<String, dynamic> data) => ContentStruct(
        giftrecipient: data['Giftrecipient'] as String?,
        budget: data['Budget'] as String?,
        age: castToType<int>(data['age']),
        interests: getDataList(data['Interests']),
      );

  static ContentStruct? maybeFromMap(dynamic data) =>
      data is Map ? ContentStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'Giftrecipient': _giftrecipient,
        'Budget': _budget,
        'age': _age,
        'Interests': _interests,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'Giftrecipient': serializeParam(
          _giftrecipient,
          ParamType.String,
        ),
        'Budget': serializeParam(
          _budget,
          ParamType.String,
        ),
        'age': serializeParam(
          _age,
          ParamType.int,
        ),
        'Interests': serializeParam(
          _interests,
          ParamType.String,
          isList: true,
        ),
      }.withoutNulls;

  static ContentStruct fromSerializableMap(Map<String, dynamic> data) =>
      ContentStruct(
        giftrecipient: deserializeParam(
          data['Giftrecipient'],
          ParamType.String,
          false,
        ),
        budget: deserializeParam(
          data['Budget'],
          ParamType.String,
          false,
        ),
        age: deserializeParam(
          data['age'],
          ParamType.int,
          false,
        ),
        interests: deserializeParam<String>(
          data['Interests'],
          ParamType.String,
          true,
        ),
      );

  @override
  String toString() => 'ContentStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is ContentStruct &&
        giftrecipient == other.giftrecipient &&
        budget == other.budget &&
        age == other.age &&
        listEquality.equals(interests, other.interests);
  }

  @override
  int get hashCode =>
      const ListEquality().hash([giftrecipient, budget, age, interests]);
}

ContentStruct createContentStruct({
  String? giftrecipient,
  String? budget,
  int? age,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ContentStruct(
      giftrecipient: giftrecipient,
      budget: budget,
      age: age,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ContentStruct? updateContentStruct(
  ContentStruct? content, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    content
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addContentStructData(
  Map<String, dynamic> firestoreData,
  ContentStruct? content,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (content == null) {
    return;
  }
  if (content.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && content.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final contentData = getContentFirestoreData(content, forFieldValue);
  final nestedData = contentData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = content.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getContentFirestoreData(
  ContentStruct? content, [
  bool forFieldValue = false,
]) {
  if (content == null) {
    return {};
  }
  final firestoreData = mapToFirestore(content.toMap());

  // Add any Firestore field values
  content.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getContentListFirestoreData(
  List<ContentStruct>? contents,
) =>
    contents?.map((e) => getContentFirestoreData(e, true)).toList() ?? [];
