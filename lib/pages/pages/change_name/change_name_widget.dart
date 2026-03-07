import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/services/firebase_data_service.dart';
import '/services/user_search_service.dart';
import 'change_name_model.dart';
export 'change_name_model.dart';

class ChangeNameWidget extends StatefulWidget {
  const ChangeNameWidget({super.key});

  @override
  State<ChangeNameWidget> createState() => _ChangeNameWidgetState();
}

class _ChangeNameWidgetState extends State<ChangeNameWidget> {
  late ChangeNameModel _model;

  bool _isLoading = true;

  @override
  void setState(VoidCallback callback) {
    if (mounted) {
      super.setState(callback);
      _model.onUpdate();
    }
  }

  Future<void> _loadData() async {
    final profile = await FirebaseDataService.loadUserProfile();
    if (mounted) {
      setState(() {
        _model.bioController ??= TextEditingController(text: profile?['bio'] as String? ?? '');
        _model.bioFocusNode ??= FocusNode();

        _model.handleController ??= TextEditingController(text: profile?['handle'] as String? ?? '');
        _model.handleFocusNode ??= FocusNode();

        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChangeNameModel());

    _model.textController ??= TextEditingController(text: currentUserDisplayName);
    _model.textFieldFocusNode ??= FocusNode();

    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF1A0035).withOpacity(0.96), const Color(0xFF0A0014).withOpacity(0.98)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0.0),
          bottomRight: Radius.circular(0.0),
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20.0, 8.0, 20.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(
              thickness: 3.0,
              indent: 150.0,
              endIndent: 150.0,
              color: FlutterFlowTheme.of(context).primaryBackground,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 16.0, 0.0),
                    child: Text(
                      FFLocalizations.of(context).getText(
                        '94z2e6d2' /* Changer le nom */,
                      ),
                      style:
                          FlutterFlowTheme.of(context).headlineMedium.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontStyle,
                              ),
                    ),
                  ),
                ),
              ],
            ),
            Form(
              key: _model.formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: AuthUserStreamWidget(
                builder: (context) => _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2))) 
                    : Column(
                  children: [
                    // --- NOM D'AFFICHAGE ---
                    Align(alignment: Alignment.centerLeft, child: Text("Nom d'affichage", style: TextStyle(color: Colors.white54, fontSize: 12))),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _model.textController,
                        focusNode: _model.textFieldFocusNode,
                        autofocus: false,
                        obscureText: false,
                        decoration: _buildInputDecoration(context, 'Nom d\'affichage'),
                        style: _buildInputStyle(context),
                        cursorColor: FlutterFlowTheme.of(context).primaryText,
                        validator: _model.textControllerValidator.asValidator(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // --- USERNAME ---
                    Align(alignment: Alignment.centerLeft, child: Text("Nom d'utilisateur (@)", style: TextStyle(color: Colors.white54, fontSize: 12))),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _model.handleController,
                        focusNode: _model.handleFocusNode,
                        autofocus: false,
                        obscureText: false,
                        decoration: _buildInputDecoration(context, 'ex: jean_dupont'),
                        style: _buildInputStyle(context),
                        cursorColor: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // --- BIO ---
                    Align(alignment: Alignment.centerLeft, child: Text("Biographie", style: TextStyle(color: Colors.white54, fontSize: 12))),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _model.bioController,
                        focusNode: _model.bioFocusNode,
                        autofocus: false,
                        obscureText: false,
                        maxLines: 4,
                        decoration: _buildInputDecoration(context, 'Parlez un peu de vous...'),
                        style: _buildInputStyle(context),
                        cursorColor: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: FFButtonWidget(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    text: FFLocalizations.of(context).getText(
                      'f0pr4sri' /* Annuler */,
                    ),
                    options: FFButtonOptions(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          12.0, 20.0, 12.0, 20.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      textStyle:
                          FlutterFlowTheme.of(context).labelMedium.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                      elevation: 2.0,
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                Expanded(
                  child: FFButtonWidget(
                    onPressed: () async {
                      if (_model.formKey.currentState == null ||
                          !_model.formKey.currentState!.validate()) {
                        return;
                      }

                      final handleRaw = _model.handleController?.text.replaceAll('@', '');
                      
                      // Check uniqueness if handle is chosen
                      if (handleRaw != null && handleRaw.isNotEmpty) {
                        try {
                          final isAvailable = await UserSearchService.isHandleAvailable(handleRaw);
                          if (!isAvailable) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Ce nom d'utilisateur est d\u00E9j\u00E0 pris."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Erreur lors de la v\u00E9rification du nom d'utilisateur."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                      }

                      final updateData = createUsersRecordData(displayName: _model.textController.text);
                      if (handleRaw != null && handleRaw.isNotEmpty) {
                        updateData['handle'] = handleRaw;
                        updateData['searchName'] = handleRaw.toLowerCase();
                      }
                      updateData['bio'] = _model.bioController?.text;

                      await currentUserReference!.update(updateData);
                      Navigator.pop(context);
                    },
                    text: FFLocalizations.of(context).getText(
                      'ulhryxaj' /* Enregistrer les modifications */,
                    ),
                    options: FFButtonOptions(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          12.0, 20.0, 12.0, 20.0),
                      iconPadding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.lexendDeca(
                                  fontWeight: FontWeight.normal,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                fontSize: 16.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.normal,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                      elevation: 2.0,
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ].divide(SizedBox(width: 5.0)),
            ),
          ].divide(SizedBox(height: 20.0)),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.normal),
            letterSpacing: 0.0,
          ),
      hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.normal),
            letterSpacing: 0.0,
          ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).secondary, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0x00000000), width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).error, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: FlutterFlowTheme.of(context).error, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
    );
  }

  TextStyle _buildInputStyle(BuildContext context) {
    return FlutterFlowTheme.of(context).bodyMedium.override(
          font: GoogleFonts.inter(fontWeight: FontWeight.normal),
          letterSpacing: 0.0,
        );
  }
}
