import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/pages/components/product/product_widget.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'open_ai_result_bottom_sheet_model.dart';
export 'open_ai_result_bottom_sheet_model.dart';

class OpenAiResultBottomSheetWidget extends StatefulWidget {
  const OpenAiResultBottomSheetWidget({
    super.key,
    required this.fetchedProducts,
  });

  final List<ProductsStruct>? fetchedProducts;

  @override
  State<OpenAiResultBottomSheetWidget> createState() =>
      _OpenAiResultBottomSheetWidgetState();
}

class _OpenAiResultBottomSheetWidgetState
    extends State<OpenAiResultBottomSheetWidget> {
  late OpenAiResultBottomSheetModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OpenAiResultBottomSheetModel());

    // On component load action.
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
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
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
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primary,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        context.safePop();
                      },
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: FlutterFlowTheme.of(context).secondaryBackground,
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
                          widget!.fetchedProducts!.map((e) => e).toList();

                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: List.generate(fetchedProducts.length,
                              (fetchedProductsIndex) {
                            final fetchedProductsItem =
                                fetchedProducts[fetchedProductsIndex];
                            return wrapWithModel(
                              model: _model.productModels.getModel(
                                fetchedProductsIndex.toString(),
                                fetchedProductsIndex,
                              ),
                              updateCallback: () => safeSetState(() {}),
                              child: ProductWidget(
                                key: Key(
                                  'Keyrs8_${fetchedProductsIndex.toString()}',
                                ),
                                isFvrt: _model.favouriteProducts
                                        .where((e) =>
                                            e.product == fetchedProductsItem)
                                        .toList()
                                        .firstOrNull !=
                                    null,
                                product: fetchedProductsItem,
                                fvrtCallback: () async {
                                  if ((_model.favouriteProducts
                                              .where((e) =>
                                                  e.product ==
                                                  fetchedProductsItem)
                                              .toList()
                                              .firstOrNull !=
                                          null) ==
                                      true) {
                                    await _model.favouriteProducts
                                        .where((e) =>
                                            e.product == fetchedProductsItem)
                                        .toList()
                                        .firstOrNull!
                                        .reference
                                        .delete();
                                    _model.removeFromFavouriteProducts(_model
                                        .favouriteProducts
                                        .where((e) =>
                                            e.product == fetchedProductsItem)
                                        .toList()
                                        .firstOrNull!);
                                    safeSetState(() {});
                                  } else {
                                    var favouritesRecordReference =
                                        FavouritesRecord.collection.doc();
                                    await favouritesRecordReference
                                        .set(createFavouritesRecordData(
                                      uid: currentUserReference,
                                      platform: "amazon",
                                      product: updateProductsStruct(
                                        fetchedProductsItem,
                                        clearUnsetFields: false,
                                        create: true,
                                      ),
                                    ));
                                    _model.newItem =
                                        FavouritesRecord.getDocumentFromData(
                                            createFavouritesRecordData(
                                              uid: currentUserReference,
                                              platform: "amazon",
                                              product: updateProductsStruct(
                                                fetchedProductsItem,
                                                clearUnsetFields: false,
                                                create: true,
                                              ),
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
    );
  }
}
