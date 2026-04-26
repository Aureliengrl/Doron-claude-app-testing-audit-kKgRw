import '/flutter_flow/flutter_flow_util.dart';
import 'change_name_widget.dart' show ChangeNameWidget;
import 'package:flutter/material.dart';

class ChangeNameModel extends FlutterFlowModel<ChangeNameWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  
  FocusNode? bioFocusNode;
  TextEditingController? bioController;
  
  FocusNode? handleFocusNode;
  TextEditingController? handleController;

  String? Function(BuildContext, String?)? textControllerValidator;
  String? _textControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'yqcmjjjl' /* Le nom d’affichage est requis */,
      );
    }

    if (val.length < 3) {
      return FFLocalizations.of(context).getText(
        'lm5wnana' /* au moins 3 caractères sont req... */,
      );
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    textControllerValidator = _textControllerValidator;
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    bioFocusNode?.dispose();
    bioController?.dispose();

    handleFocusNode?.dispose();
    handleController?.dispose();
  }
}
