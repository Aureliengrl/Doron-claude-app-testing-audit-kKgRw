import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/pages/components/text_field_with_heading/text_field_with_heading_widget.dart';
import 'gift_generator_widget.dart' show GiftGeneratorWidget;
import 'package:flutter/material.dart';

class GiftGeneratorModel extends FlutterFlowModel<GiftGeneratorWidget> {
  ///  Local state fields for this page.

  List<String> interests = [];
  void addToInterests(String item) => interests.add(item);
  void removeFromInterests(String item) => interests.remove(item);
  void removeAtIndexFromInterests(int index) => interests.removeAt(index);
  void insertAtIndexInInterests(int index, String item) =>
      interests.insert(index, item);
  void updateInterestsAtIndex(int index, Function(String) updateFn) =>
      interests[index] = updateFn(interests[index]);

  ContentStruct? query;
  void updateQueryStruct(Function(ContentStruct) updateFn) {
    updateFn(query ??= ContentStruct());
  }

  double? min = 0.0;

  double? max = 0.0;

  List<ProductsStruct> dummyProducts = [];
  void addToDummyProducts(ProductsStruct item) => dummyProducts.add(item);
  void removeFromDummyProducts(ProductsStruct item) =>
      dummyProducts.remove(item);
  void removeAtIndexFromDummyProducts(int index) =>
      dummyProducts.removeAt(index);
  void insertAtIndexInDummyProducts(int index, ProductsStruct item) =>
      dummyProducts.insert(index, item);
  void updateDummyProductsAtIndex(
          int index, Function(ProductsStruct) updateFn) =>
      dummyProducts[index] = updateFn(dummyProducts[index]);

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for relation.
  late TextFieldWithHeadingModel relationModel;
  // Model for age.
  late TextFieldWithHeadingModel ageModel;
  // State field(s) for min widget.
  FocusNode? minFocusNode;
  TextEditingController? minTextController;
  String? Function(BuildContext, String?)? minTextControllerValidator;
  String? _minTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'u927yqcf' /* min is required */,
      );
    }

    return null;
  }

  // State field(s) for max widget.
  FocusNode? maxFocusNode;
  TextEditingController? maxTextController;
  String? Function(BuildContext, String?)? maxTextControllerValidator;
  String? _maxTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'uijhcuxh' /* max is required */,
      );
    }

    return null;
  }

  // State field(s) for interests widget.
  FocusNode? interestsFocusNode;
  TextEditingController? interestsTextController;
  String? Function(BuildContext, String?)? interestsTextControllerValidator;
  // Stores action output result for [Custom Action - contentToString] action in Button widget.
  String? stringQuerry;
  // Stores action output result for [Backend Call - API (OpenAi ChatGPT  Algoace)] action in Button widget.
  ApiCallResponse? apiResponse;
  // Stores action output result for [Backend Call - API (Amazon Api for OpenAI)] action in Button widget.
  ApiCallResponse? apiResultoga;

  @override
  void initState(BuildContext context) {
    relationModel = createModel(context, () => TextFieldWithHeadingModel());
    ageModel = createModel(context, () => TextFieldWithHeadingModel());
    minTextControllerValidator = _minTextControllerValidator;
    maxTextControllerValidator = _maxTextControllerValidator;
    relationModel.textControllerValidator = _formTextFieldValidator1;
    ageModel.textControllerValidator = _formTextFieldValidator2;
  }

  @override
  void dispose() {
    relationModel.dispose();
    ageModel.dispose();
    minFocusNode?.dispose();
    minTextController?.dispose();

    maxFocusNode?.dispose();
    maxTextController?.dispose();

    interestsFocusNode?.dispose();
    interestsTextController?.dispose();
  }

  /// Additional helper methods.

  String? _formTextFieldValidator1(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'wxtrcnv3' /* hintText is required */,
      );
    }

    return null;
  }

  String? _formTextFieldValidator2(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'hxd2gc0u' /* hintText is required */,
      );
    }

    return null;
  }
}
