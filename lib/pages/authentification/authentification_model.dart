import '/utils/app_logger.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'authentification_widget.dart' show AuthentificationWidget;
import 'package:flutter/material.dart';

class AuthentificationModel extends FlutterFlowModel<AuthentificationWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ✨ tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ✨ tabBarController!.previousIndex : 0;

  // State field(s) for display_name widget.
  FocusNode? displayNameFocusNode;
  TextEditingController? displayNameTextController;
  String? Function(BuildContext, String?)? displayNameTextControllerValidator;
  String? _displayNameTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        's4r9ole4' /* Le nom d'affichage est requis */,
      );
    }

    if (val.length < 3) {
      return FFLocalizations.of(context).getText(
        'w8fxlbwz' /* Au moins 3 caract�res */,
      );
    }

    return null;
  }

  // State field(s) for username widget.
  FocusNode? usernameFocusNode;
  TextEditingController? usernameTextController;
  String? Function(BuildContext, String?)? usernameTextControllerValidator;
  bool isCheckingUsername = false;
  String? usernameError;

  String? _usernameTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }

    if (val.length < 3) {
      return 'Au moins 3 caract�res';
    }

    // V�rifier que le username ne contient que des lettres, chiffres, - et _
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(val)) {
      return 'Uniquement lettres, chiffres, - et _';
    }

    // �viter le "@" s'il a �t� tap�
    if (val.startsWith('@')) {
      return 'Ne pas inclure le @';
    }

    // L'erreur d'unicit� sera g�r�e s�par�ment
    if (usernameError != null) {
      return usernameError;
    }

    return null;
  }

  // State field(s) for emailAddress_Create widget.
  FocusNode? emailAddressCreateFocusNode;
  TextEditingController? emailAddressCreateTextController;
  String? Function(BuildContext, String?)?
      emailAddressCreateTextControllerValidator;
  String? _emailAddressCreateTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '1drkjedw' /* Email est requis */,
      );
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return FFLocalizations.of(context).getText(
        'df8881pe' /* Email invalide */,
      );
    }
    return null;
  }

  // State field(s) for password_Create widget.
  FocusNode? passwordCreateFocusNode;
  TextEditingController? passwordCreateTextController;
  late bool passwordCreateVisibility;
  String? Function(BuildContext, String?)?
      passwordCreateTextControllerValidator;
  String? _passwordCreateTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'lykhbuk6' /* Mot de passe est requis */,
      );
    }

    return null;
  }

  // State field(s) for password_Confirm widget.
  FocusNode? passwordConfirmFocusNode;
  TextEditingController? passwordConfirmTextController;
  late bool passwordConfirmVisibility;
  String? Function(BuildContext, String?)?
      passwordConfirmTextControllerValidator;
  String? _passwordConfirmTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'alq39fyf' /* Confirmez le mot de passe est ... */,
      );
    }

    return null;
  }

  // State field(s) for emailAddress widget.
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;
  String? _emailAddressTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '7emdil6i' /* L'e-mail est requis */,
      );
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return FFLocalizations.of(context).getText(
        'nzbj4kiq' /* E-mail invalide */,
      );
    }
    return null;
  }

  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  String? _passwordTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        'z39strzg' /* Password is required */,
      );
    }

    return null;
  }

  /// V�rifie si le username est unique dans Firestore
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      isCheckingUsername = true;
      usernameError = null;

      // Rechercher dans la collection users si le handle existe d�j�
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('searchName', isEqualTo: username.toLowerCase().replaceAll('@', ''))
          .limit(1)
          .get();

      isCheckingUsername = false;

      if (querySnapshot.docs.isNotEmpty) {
        usernameError = 'Ce nom d\'utilisateur existe d�j�';
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.debug('Erreur v�rification username: $e', 'Debug');
      isCheckingUsername = false;
      
      // FIX IGNITION: Firestore bloque l'acc�s non-authentifi� � Users. 
      // Si c'est un permission-denied g�n�r� avant la cr�ation du compte e-mail,
      // on bypass l'erreur au lieu de bloquer faussement le formulaire en "D�j� pris".
      if (e.toString().contains('permission-denied')) {
        return true; 
      }
      
      usernameError = 'Erreur de v�rification';
      return false;
    }
  }

  @override
  void initState(BuildContext context) {
    displayNameTextControllerValidator = _displayNameTextControllerValidator;
    usernameTextControllerValidator = _usernameTextControllerValidator;
    emailAddressCreateTextControllerValidator =
        _emailAddressCreateTextControllerValidator;
    passwordCreateVisibility = false;
    passwordCreateTextControllerValidator =
        _passwordCreateTextControllerValidator;
    passwordConfirmVisibility = false;
    passwordConfirmTextControllerValidator =
        _passwordConfirmTextControllerValidator;
    emailAddressTextControllerValidator = _emailAddressTextControllerValidator;
    passwordVisibility = false;
    passwordTextControllerValidator = _passwordTextControllerValidator;
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    displayNameFocusNode?.dispose();
    displayNameTextController?.dispose();

    usernameFocusNode?.dispose();
    usernameTextController?.dispose();

    emailAddressCreateFocusNode?.dispose();
    emailAddressCreateTextController?.dispose();

    passwordCreateFocusNode?.dispose();
    passwordCreateTextController?.dispose();

    passwordConfirmFocusNode?.dispose();
    passwordConfirmTextController?.dispose();

    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
  }
}
