import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/pages/components/product/product_widget.dart';
import '/services/firebase_data_service.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'open_ai_suggested_gifts_model.dart';
export 'open_ai_suggested_gifts_model.dart';

class OpenAiSuggestedGiftsWidget extends StatefulWidget {
  const OpenAiSuggestedGiftsWidget({
    super.key,
    required this.fetchproducts,
  });

  final List<ProductsStruct>? fetchproducts;

  static String routeName = 'openAiSuggestedGifts';
  static String routePath = '/openAiSuggestedGifts';

  @override
  State<OpenAiSuggestedGiftsWidget> createState() =>
      _OpenAiSuggestedGiftsWidgetState();
}

class _OpenAiSuggestedGiftsWidgetState
    extends State<OpenAiSuggestedGiftsWidget> {
  late OpenAiSuggestedGiftsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OpenAiSuggestedGiftsModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.fetchFvrtProducts = await queryFavouritesRecordOnce(
        queryBuilder: (favouritesRecord) => favouritesRecord.where(
          'uid',
          isEqualTo: currentUserReference,
        ),
      );
      _model.favouriteProducts =
          _model.fetchFvrtProducts!.toList().cast<FavouritesRecord>();
      safeSetState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Align(
          alignment: AlignmentDirectional(0.0, 1.0),
          child: Container(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 1.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.0, 60.0, 20.0, 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 5.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.safePop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            size: 20.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(),
                      child: Builder(
                        builder: (context) {
                          final fetchedProducts =
                              widget!.fetchproducts!.map((e) => e).toList();

                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: List.generate(fetchedProducts.length,
                                  (fetchedProductsIndex) {
                                final fetchedProductsItem =
                                    fetchedProducts[fetchedProductsIndex];
                                return FutureBuilder<ApiCallResponse>(
                                  future: ZaraCall.call(),
                                  builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (!snapshot.hasData) {
                                      return Center(
                                        child: SizedBox(
                                          width: 50.0,
                                          height: 50.0,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    final productZaraResponse = snapshot.data!;

                                    return wrapWithModel(
                                      model: _model.productModels.getModel(
                                        fetchedProductsIndex.toString(),
                                        fetchedProductsIndex,
                                      ),
                                      updateCallback: () => safeSetState(() {}),
                                      child: ProductWidget(
                                        key: Key(
                                          'Keyp38_${fetchedProductsIndex.toString()}',
                                        ),
                                        isFvrt: _model.favouriteProducts
                                                .where((e) =>
                                                    e.product ==
                                                    fetchedProductsItem)
                                                .toList()
                                                .firstOrNull !=
                                            null,
                                        product: fetchedProductsItem,
                                        fvrtCallback: () async {
                                          // Stocker le résultat pour éviter les requêtes multiples
                                          final existingFavourite = _model.favouriteProducts
                                              .where((e) => e.product == fetchedProductsItem)
                                              .toList()
                                              .firstOrNull;

                                          if (existingFavourite != null) {
                                            await existingFavourite.reference.delete();
                                            _model.removeFromFavouriteProducts(existingFavourite);
                                            safeSetState(() {});
                                          } else {
                                            // Récupérer le personId du contexte actuel
                                            final personId = await FirebaseDataService.getCurrentPersonContext();

                                            var favouritesRecordReference =
                                                FavouritesRecord.collection
                                                    .doc();
                                            await favouritesRecordReference
                                                .set(createFavouritesRecordData(
                                              uid: currentUserReference,
                                              platform: "amazon",
                                              product: updateProductsStruct(
                                                fetchedProductsItem,
                                                clearUnsetFields: false,
                                                create: true,
                                              ),
                                              timeStamp: getCurrentTimestamp,
                                              personId: personId, // Ajout du personId
                                            ));
                                            _model.newItem = FavouritesRecord
                                                .getDocumentFromData(
                                                    createFavouritesRecordData(
                                                      uid: currentUserReference,
                                                      platform:
                                                          "amazon",
                                                      product:
                                                          updateProductsStruct(
                                                        fetchedProductsItem,
                                                        clearUnsetFields: false,
                                                        create: true,
                                                      ),
                                                      timeStamp:
                                                          getCurrentTimestamp,
                                                      personId: personId, // Ajout du personId
                                                    ),
                                                    favouritesRecordReference);
                                            _model.addToFavouriteProducts(
                                                _model.newItem!);
                                            safeSetState(() {});
                                          }

                                          safeSetState(() {});
                                        },
                                      ),
                                    );
                                  },
                                );
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
