import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/pages/components/loader/loader_widget.dart';
import '/pages/pages/components/product/product_widget.dart';
import '/pages/pages/empty_data/empty_data_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_algoace_model.dart';
export 'home_algoace_model.dart';

class HomeAlgoaceWidget extends StatefulWidget {
  const HomeAlgoaceWidget({super.key});

  static String routeName = 'HomeAlgoace';
  static String routePath = '/homeAlgoace';

  @override
  State<HomeAlgoaceWidget> createState() => _HomeAlgoaceWidgetState();
}

class _HomeAlgoaceWidgetState extends State<HomeAlgoaceWidget>
    with TickerProviderStateMixin {
  late HomeAlgoaceModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeAlgoaceModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.loader = true;
      safeSetState(() {});
      _model.favourite = await queryFavouritesRecordOnce(
        queryBuilder: (favouritesRecord) => favouritesRecord.where(
          'uid',
          isEqualTo: currentUserReference,
        ),
      );
      _model.favouritesList =
          _model.favourite!.toList().cast<FavouritesRecord>();
      safeSetState(() {});
      if (FFAppState().firstTime) {
        _model.apiAmazon = await AmazonApiSearchAndDiscountsCall.call(
          query: ' ',
          country:
              FFLocalizations.of(context).languageCode == 'en' ? 'us' : 'fr',
        );

        if ((_model.apiAmazon?.succeeded ?? true)) {
          FFAppState().HomeProducts =
              AmazonApiSearchAndDiscountsCall.productsList(
            (_model.apiAmazon?.jsonBody ?? ''),
          )!
                  .toList()
                  .cast<ProductsStruct>();
          FFAppState().firstTime = false;
          safeSetState(() {});
        }
        _model.sephora = await SephoraCall.call(
          search: 'BEST_SELLING',
        );

        if ((_model.sephora?.succeeded ?? true)) {
          while (SephoraCall.productLink(
                (_model.sephora?.jsonBody ?? ''),
              )!
                  .length >
              _model.loopCounter) {
            FFAppState().addToHomeProducts(ProductsStruct(
              productTitle: (SephoraCall.description(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          null &&
                      (SephoraCall.description(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          ''
                  ? (SephoraCall.description(
                      (_model.sephora?.jsonBody ?? ''),
                    )?.elementAtOrNull(_model.loopCounter))
                  : '',
              productPrice: (SephoraCall.price(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          null &&
                      (SephoraCall.price(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          ''
                  ? (SephoraCall.price(
                      (_model.sephora?.jsonBody ?? ''),
                    )?.elementAtOrNull(_model.loopCounter))
                  : '',
              productUrl: (SephoraCall.productLink(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          null &&
                      (SephoraCall.productLink(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          ''
                  ? (SephoraCall.productLink(
                      (_model.sephora?.jsonBody ?? ''),
                    )?.elementAtOrNull(_model.loopCounter))
                  : '',
              productOriginalPrice: (SephoraCall.price(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          null &&
                      (SephoraCall.price(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          ''
                  ? (SephoraCall.price(
                      (_model.sephora?.jsonBody ?? ''),
                    )?.elementAtOrNull(_model.loopCounter))
                  : '',
              productStarRating: (SephoraCall.rating(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          null &&
                      (SephoraCall.rating(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          ''
                  ? (SephoraCall.rating(
                      (_model.sephora?.jsonBody ?? ''),
                    )?.elementAtOrNull(_model.loopCounter))
                  : '',
              productPhoto: (SephoraCall.imgLink(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          null &&
                      (SephoraCall.imgLink(
                            (_model.sephora?.jsonBody ?? ''),
                          )?.elementAtOrNull(_model.loopCounter)) !=
                          ''
                  ? (SephoraCall.imgLink(
                      (_model.sephora?.jsonBody ?? ''),
                    )?.elementAtOrNull(_model.loopCounter))
                  : '',
              productNumRatings: (int.parse(((SephoraCall.totalReviews(
                        (_model.sephora?.jsonBody ?? ''),
                      )!
                          .elementAtOrNull(_model.loopCounter))!))) !=
                      null
                  ? (int.parse(((SephoraCall.totalReviews(
                      (_model.sephora?.jsonBody ?? ''),
                    )!
                      .elementAtOrNull(_model.loopCounter))!)))
                  : 0,
              platform: "sephora",
            ));
            _model.loopCounter = _model.loopCounter + 1;
          }
        }
        _model.loopCounter = _model.loopCounter + 0;
        safeSetState(() {});
        _model.ikeaOnPageLoad = await IkeaCall.call(
          keyword: ' gift',
          languageCode:
              FFLocalizations.of(context).languageCode == 'en' ? 'en' : 'fr',
          countryCode:
              FFLocalizations.of(context).languageCode == 'en' ? 'us' : 'fr',
        );

        if ((_model.ikeaOnPageLoad?.succeeded ?? true)) {
          while (IkeaCall.producttitle(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )!
                  .length >
              _model.loopCounter) {
            FFAppState().addToHomeProducts(ProductsStruct(
              productTitle: IkeaCall.producttitle(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )?.elementAtOrNull(_model.loopCounter),
              productPrice: '${(IkeaCall.currency(
                    (_model.ikeaOnPageLoad?.jsonBody ?? ''),
                  )?.elementAtOrNull(_model.loopCounter)) == 'USD' ? '\$' : '€'}${(IkeaCall.productprice(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )?.elementAtOrNull(_model.loopCounter))?.toString()}',
              productUrl: IkeaCall.producturl(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )?.elementAtOrNull(_model.loopCounter),
              productPhoto: IkeaCall.productphoto(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )?.elementAtOrNull(_model.loopCounter),
              platform: "ikea",
            ));
            _model.loopCounter = _model.loopCounter + 1;
          }
        }
        _model.loopCounter = _model.loopCounter + 0;
        _model.apiResultb92 = await ZaraCall.call();

        if ((_model.apiResultb92?.succeeded ?? true)) {
          while (IkeaCall.producttitle(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )!
                  .length >
              _model.loopCounter) {
            FFAppState().addToHomeProducts(ProductsStruct(
              productTitle: IkeaCall.producttitle(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )?.elementAtOrNull(_model.loopCounter),
              productPrice: '${(IkeaCall.currency(
                    (_model.ikeaOnPageLoad?.jsonBody ?? ''),
                  )?.elementAtOrNull(_model.loopCounter)) == 'USD' ? '\$' : '€'}${(IkeaCall.productprice(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )?.elementAtOrNull(_model.loopCounter))?.toString()}',
              productUrl: IkeaCall.producturl(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )?.elementAtOrNull(_model.loopCounter),
              productPhoto: IkeaCall.productphoto(
                (_model.ikeaOnPageLoad?.jsonBody ?? ''),
              )?.elementAtOrNull(_model.loopCounter),
              platform: "ikea",
            ));
            _model.loopCounter = _model.loopCounter + 1;
          }
        }
        _model.loopCounter = _model.loopCounter + 0;
        FFAppState().HomeProducts = functions
            .productsShuffling(FFAppState().HomeProducts.toList())!
            .toList()
            .cast<ProductsStruct>();
        safeSetState(() {});
      }
      _model.loader = false;
    });

    _model.searchTextController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();

    animationsMap.addAll({
      'textOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: Offset(50.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: Offset(50.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'textFieldOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: Offset(50.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'conditionalBuilderOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: Offset(50.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'productOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: Offset(50.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'productOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 800.0.ms,
            begin: Offset(50.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
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
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: Container(
          decoration: BoxDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height * 0.15,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    topLeft: Radius.circular(0.0),
                    topRight: Radius.circular(0.0),
                  ),
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 60.0, 20.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional(0.0, -1.0),
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'oo49mhxh' /* DORÕN */,
                          ),
                          textAlign: TextAlign.start,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    fontSize: 20.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ).animateOnPageLoad(
                            animationsMap['textOnPageLoadAnimation1']!),
                      ),
                      Align(
                        alignment: AlignmentDirectional(0.0, -1.0),
                        child: Text(
                          FFLocalizations.of(context).getText(
                            'm9f7q8vx' /* Offres et recherche */,
                          ),
                          textAlign: TextAlign.center,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w300,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    fontSize: 13.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w300,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ).animateOnPageLoad(
                            animationsMap['textOnPageLoadAnimation2']!),
                      ),
                    ].divide(SizedBox(height: 10.0)),
                  ),
                ),
              ),
              Stack(
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 20.0, 12.0),
                    child: Container(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _model.searchTextController,
                        focusNode: _model.searchFocusNode,
                        onChanged: (_) => EasyDebounce.debounce(
                          '_model.searchTextController',
                          Duration(milliseconds: 2000),
                          () async {
                            _model.loader = true;
                            _model.loopCounter = 0;
                            _model.toggleSearchProduct = true;
                            safeSetState(() {});
                            _model.searchedOutputCopy =
                                await AmazonApiSearchAndDiscountsCall.call(
                              query: _model.searchTextController.text,
                              country:
                                  FFLocalizations.of(context).languageCode ==
                                          'en'
                                      ? 'us'
                                      : 'fr',
                            );

                            if ((_model.searchedOutputCopy?.succeeded ??
                                true)) {
                              _model.toggleSearchProduct = true;
                              _model.searchedProducts =
                                  AmazonApiSearchAndDiscountsCall.productsList(
                                (_model.searchedOutputCopy?.jsonBody ?? ''),
                              )!
                                      .toList()
                                      .cast<ProductsStruct>();
                            }
                            _model.seporaOnChange = await SephoraCall.call(
                              search: _model.searchTextController.text,
                            );

                            if ((_model.seporaOnChange?.succeeded ?? true)) {
                              while ((SephoraCall.productLink(
                                            (_model.seporaOnChange?.jsonBody ??
                                                ''),
                                          )!
                                              .length <=
                                          15
                                      ? SephoraCall.productLink(
                                          (_model.seporaOnChange?.jsonBody ??
                                              ''),
                                        )!
                                          .length
                                      : 15) >
                                  _model.loopCounter) {
                                _model.addToSearchedProducts(ProductsStruct(
                                  productTitle: SephoraCall.description(
                                    (_model.seporaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  productPrice: SephoraCall.price(
                                    (_model.seporaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  productUrl: SephoraCall.productLink(
                                    (_model.seporaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  productOriginalPrice: SephoraCall.price(
                                    (_model.seporaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  productStarRating: SephoraCall.rating(
                                    (_model.seporaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  productPhoto: SephoraCall.imgLink(
                                    (_model.seporaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  productNumRatings: int.parse(
                                      ((SephoraCall.totalReviews(
                                    (_model.seporaOnChange?.jsonBody ?? ''),
                                  )!
                                          .elementAtOrNull(
                                              _model.loopCounter))!)),
                                  platform: "sephora",
                                ));
                                _model.loopCounter = _model.loopCounter + 1;
                              }
                              _model.loopCounter = 0;
                            }
                            _model.ikeaOnChange = await IkeaCall.call(
                              keyword: _model.searchTextController.text,
                              languageCode:
                                  FFLocalizations.of(context).languageCode ==
                                          'en'
                                      ? 'en'
                                      : 'fr',
                              countryCode:
                                  FFLocalizations.of(context).languageCode ==
                                          'en'
                                      ? 'us'
                                      : 'fr',
                            );

                            if ((_model.ikeaOnChange?.succeeded ?? true)) {
                              while ((IkeaCall.producttitle(
                                            (_model.ikeaOnChange?.jsonBody ??
                                                ''),
                                          )!
                                              .length <=
                                          15
                                      ? IkeaCall.producttitle(
                                          (_model.ikeaOnChange?.jsonBody ?? ''),
                                        )!
                                          .length
                                      : 15) >
                                  _model.loopCounter) {
                                _model.addToSearchedProducts(ProductsStruct(
                                  productTitle: IkeaCall.producttitle(
                                    (_model.ikeaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  productPrice: '${(IkeaCall.currency(
                                        (_model.ikeaOnChange?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter)) == 'USD' ? '\$' : '€'}${(IkeaCall.productprice(
                                    (_model.ikeaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter))?.toString()}',
                                  productUrl: IkeaCall.producturl(
                                    (_model.ikeaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  productOriginalPrice: '${(IkeaCall.currency(
                                        (_model.ikeaOnChange?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter)) == 'USD' ? '\$' : '€'}${(IkeaCall.productprice(
                                    (_model.ikeaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter))?.toString()}',
                                  productPhoto: IkeaCall.productphoto(
                                    (_model.ikeaOnChange?.jsonBody ?? ''),
                                  )?.elementAtOrNull(_model.loopCounter),
                                  platform: "ikea",
                                ));
                                _model.loopCounter = _model.loopCounter + 1;
                              }
                            }
                            _model.searchedProducts = functions
                                .productsShuffling(
                                    _model.searchedProducts.toList())!
                                .toList()
                                .cast<ProductsStruct>();
                            _model.loopCounter = 0;
                            _model.loader = false;
                            safeSetState(() {});

                            safeSetState(() {});
                          },
                        ),
                        autofocus: false,
                        textInputAction: TextInputAction.search,
                        obscureText: false,
                        decoration: InputDecoration(
                          isDense: true,
                          labelStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                          hintText: FFLocalizations.of(context).getText(
                            '9d4ox1fe' /* Recherche */,
                          ),
                          hintStyle:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).primaryText,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).primaryText,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                        cursorColor: FlutterFlowTheme.of(context).primaryText,
                        validator: _model.searchTextControllerValidator
                            .asValidator(context),
                      ),
                    ).animateOnPageLoad(
                        animationsMap['textFieldOnPageLoadAnimation']!),
                  ),
                  Align(
                    alignment: AlignmentDirectional(1.0, 1.0),
                    child: Builder(
                      builder: (context) {
                        if (!_model.toggleSearchProduct) {
                          return Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 30.0, 30.0, 0.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                _model.loader = true;
                                _model.loopCounter = 0;
                                _model.toggleSearchProduct = true;
                                safeSetState(() {});
                                _model.searchedOutput =
                                    await AmazonApiSearchAndDiscountsCall.call(
                                  query: _model.searchTextController.text,
                                  country: FFLocalizations.of(context)
                                              .languageCode ==
                                          'en'
                                      ? 'us'
                                      : 'fr',
                                );

                                if ((_model.searchedOutput?.succeeded ??
                                    true)) {
                                  _model.toggleSearchProduct = true;
                                  _model.searchedProducts =
                                      AmazonApiSearchAndDiscountsCall
                                              .productsList(
                                    (_model.searchedOutput?.jsonBody ?? ''),
                                  )!
                                          .toList()
                                          .cast<ProductsStruct>();
                                }
                                _model.seporaOnSubmit = await SephoraCall.call(
                                  search: _model.searchTextController.text,
                                );

                                if ((_model.seporaOnSubmit?.succeeded ??
                                    true)) {
                                  while ((SephoraCall.totalReviews(
                                                (_model.seporaOnSubmit
                                                        ?.jsonBody ??
                                                    ''),
                                              )!
                                                  .length <=
                                              15
                                          ? SephoraCall.totalReviews(
                                              (_model.seporaOnSubmit
                                                      ?.jsonBody ??
                                                  ''),
                                            )!
                                              .length
                                          : 15) >
                                      _model.loopCounter) {
                                    _model.addToSearchedProducts(ProductsStruct(
                                      productTitle: SephoraCall.description(
                                        (_model.seporaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      productPrice: SephoraCall.price(
                                        (_model.seporaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      productUrl: SephoraCall.productLink(
                                        (_model.seporaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      productOriginalPrice: SephoraCall.price(
                                        (_model.seporaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      productStarRating: SephoraCall.rating(
                                        (_model.seporaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      productPhoto: SephoraCall.imgLink(
                                        (_model.seporaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      productNumRatings: int.parse(
                                          ((SephoraCall.totalReviews(
                                        (_model.seporaOnSubmit?.jsonBody ?? ''),
                                      )!
                                              .elementAtOrNull(
                                                  _model.loopCounter))!)),
                                    ));
                                    _model.loopCounter = _model.loopCounter + 1;
                                  }
                                  _model.loopCounter = 0;
                                }
                                _model.ikeaOnSubmit = await IkeaCall.call(
                                  keyword: _model.searchTextController.text,
                                  languageCode: FFLocalizations.of(context)
                                              .languageCode ==
                                          'en'
                                      ? 'en'
                                      : 'fr',
                                  countryCode: FFLocalizations.of(context)
                                              .languageCode ==
                                          'en'
                                      ? 'us'
                                      : 'fr',
                                );

                                if ((_model.ikeaOnSubmit?.succeeded ?? true)) {
                                  while ((IkeaCall.currency(
                                                (_model.ikeaOnSubmit
                                                        ?.jsonBody ??
                                                    ''),
                                              )!
                                                  .length <=
                                              15
                                          ? IkeaCall.currency(
                                              (_model.ikeaOnSubmit?.jsonBody ??
                                                  ''),
                                            )!
                                              .length
                                          : 15) >
                                      _model.loopCounter) {
                                    _model.addToSearchedProducts(ProductsStruct(
                                      productTitle: IkeaCall.producttitle(
                                        (_model.ikeaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      productPrice: '${(IkeaCall.currency(
                                            (_model.ikeaOnSubmit?.jsonBody ??
                                                ''),
                                          )?.elementAtOrNull(_model.loopCounter)) == 'USD' ? '\$' : '€'}${(IkeaCall.productprice(
                                        (_model.ikeaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter))?.toString()}',
                                      productUrl: IkeaCall.producturl(
                                        (_model.ikeaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      productOriginalPrice: '${(IkeaCall.currency(
                                            (_model.ikeaOnSubmit?.jsonBody ??
                                                ''),
                                          )?.elementAtOrNull(_model.loopCounter)) == 'USD' ? '\$' : '€'}${(IkeaCall.productprice(
                                        (_model.ikeaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter))?.toString()}',
                                      productPhoto: IkeaCall.productphoto(
                                        (_model.ikeaOnSubmit?.jsonBody ?? ''),
                                      )?.elementAtOrNull(_model.loopCounter),
                                      platform: "ikea",
                                    ));
                                    _model.loopCounter = _model.loopCounter + 1;
                                  }
                                }
                                safeSetState(() {
                                  _model.searchTextController?.clear();
                                });
                                _model.searchedProducts = functions
                                    .productsShuffling(
                                        _model.searchedProducts.toList())!
                                    .toList()
                                    .cast<ProductsStruct>();
                                _model.loopCounter = 0;
                                _model.loader = false;
                                safeSetState(() {});

                                safeSetState(() {});
                              },
                              child: Icon(
                                Icons.search_sharp,
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context).primaryText,
                                size: 24.0,
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 30.0, 30.0, 0.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                _model.toggleSearchProduct = false;
                                _model.searchedProducts = [];
                                _model.loader = false;
                                safeSetState(() {});
                                safeSetState(() {
                                  _model.searchTextController?.clear();
                                });
                              },
                              child: Icon(
                                Icons.cancel_rounded,
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? FlutterFlowTheme.of(context).primary
                                    : FlutterFlowTheme.of(context).primaryText,
                                size: 24.0,
                              ),
                            ),
                          );
                        }
                      },
                    ).animateOnPageLoad(animationsMap[
                        'conditionalBuilderOnPageLoadAnimation']!),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  child: Builder(
                    builder: (context) {
                      if (_model.loader) {
                        return wrapWithModel(
                          model: _model.loaderModel,
                          updateCallback: () => safeSetState(() {}),
                          child: LoaderWidget(),
                        );
                      } else if (_model.toggleSearchProduct) {
                        return Builder(
                          builder: (context) {
                            if (_model.searchedProducts.isNotEmpty) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    20.0, 0.0, 20.0, 0.0),
                                child: Builder(
                                  builder: (context) {
                                    final searchProducts = _model
                                        .searchedProducts
                                        .map((e) => e)
                                        .toList();

                                    return SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children:
                                            List.generate(searchProducts.length,
                                                (searchProductsIndex) {
                                          final searchProductsItem =
                                              searchProducts[
                                                  searchProductsIndex];
                                          return wrapWithModel(
                                            model:
                                                _model.productModels1.getModel(
                                              searchProductsIndex.toString(),
                                              searchProductsIndex,
                                            ),
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: ProductWidget(
                                              key: Key(
                                                'Key7b6_${searchProductsIndex.toString()}',
                                              ),
                                              isFvrt: _model.favouritesList
                                                      .where((e) =>
                                                          e.product ==
                                                          searchProductsItem)
                                                      .toList()
                                                      .firstOrNull !=
                                                  null,
                                              product: searchProductsItem,
                                              fvrtCallback: () async {
                                                if (_model.favouritesList
                                                        .where((e) =>
                                                            e.product ==
                                                            searchProductsItem)
                                                        .toList()
                                                        .firstOrNull !=
                                                    null) {
                                                  await _model.favouritesList
                                                      .where((e) =>
                                                          e.product ==
                                                          searchProductsItem)
                                                      .toList()
                                                      .firstOrNull!
                                                      .reference
                                                      .delete();
                                                  _model.removeFromFavouritesList(
                                                      _model.favouritesList
                                                          .where((e) =>
                                                              e.product ==
                                                              searchProductsItem)
                                                          .toList()
                                                          .firstOrNull!);
                                                  safeSetState(() {});
                                                } else {
                                                  var favouritesRecordReference =
                                                      FavouritesRecord
                                                          .collection
                                                          .doc();
                                                  await favouritesRecordReference
                                                      .set(
                                                          createFavouritesRecordData(
                                                    uid: currentUserReference,
                                                    platform: "amazon",
                                                    product:
                                                        updateProductsStruct(
                                                      searchProductsItem,
                                                      clearUnsetFields: false,
                                                      create: true,
                                                    ),
                                                    timeStamp:
                                                        getCurrentTimestamp,
                                                  ));
                                                  _model.newItemSearched =
                                                      FavouritesRecord
                                                          .getDocumentFromData(
                                                              createFavouritesRecordData(
                                                                uid:
                                                                    currentUserReference,
                                                                platform:
                                                                    "amazon",
                                                                product:
                                                                    updateProductsStruct(
                                                                  searchProductsItem,
                                                                  clearUnsetFields:
                                                                      false,
                                                                  create: true,
                                                                ),
                                                                timeStamp:
                                                                    getCurrentTimestamp,
                                                              ),
                                                              favouritesRecordReference);
                                                  _model.addToFavouritesList(
                                                      _model.newItemSearched!);
                                                  safeSetState(() {});
                                                }

                                                safeSetState(() {});
                                              },
                                            ),
                                          ).animateOnPageLoad(animationsMap[
                                              'productOnPageLoadAnimation1']!);
                                        }),
                                      ),
                                    );
                                  },
                                ),
                              );
                            } else {
                              return wrapWithModel(
                                model: _model.emptyDataModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: EmptyDataWidget(),
                              );
                            }
                          },
                        );
                      } else {
                        return Builder(
                          builder: (context) {
                            if (FFAppState().HomeProducts.isNotEmpty) {
                              return Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    20.0, 0.0, 20.0, 0.0),
                                child: Builder(
                                  builder: (context) {
                                    final intialiProductList = FFAppState()
                                        .HomeProducts
                                        .map((e) => e)
                                        .toList();

                                    return SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: List.generate(
                                            intialiProductList.length,
                                            (intialiProductListIndex) {
                                          final intialiProductListItem =
                                              intialiProductList[
                                                  intialiProductListIndex];
                                          return FutureBuilder<ApiCallResponse>(
                                            future: ZaraCall.call(),
                                            builder: (context, snapshot) {
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 50.0,
                                                    height: 50.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              final productZaraResponse =
                                                  snapshot.data!;

                                              return wrapWithModel(
                                                model: _model.productModels2
                                                    .getModel(
                                                  intialiProductListItem
                                                      .productUrl,
                                                  intialiProductListIndex,
                                                ),
                                                updateCallback: () =>
                                                    safeSetState(() {}),
                                                child: ProductWidget(
                                                  key: Key(
                                                    'Keystc_${intialiProductListItem.productUrl}',
                                                  ),
                                                  isFvrt: _model.favouritesList
                                                          .where((e) =>
                                                              e.product ==
                                                              intialiProductListItem)
                                                          .toList()
                                                          .firstOrNull !=
                                                      null,
                                                  product:
                                                      intialiProductListItem,
                                                  fvrtCallback: () async {
                                                    if (_model.favouritesList
                                                            .where((e) =>
                                                                e.product ==
                                                                intialiProductListItem)
                                                            .toList()
                                                            .firstOrNull !=
                                                        null) {
                                                      await _model
                                                          .favouritesList
                                                          .where((e) =>
                                                              e.product ==
                                                              intialiProductListItem)
                                                          .toList()
                                                          .firstOrNull!
                                                          .reference
                                                          .delete();
                                                      _model.removeFromFavouritesList(
                                                          _model.favouritesList
                                                              .where((e) =>
                                                                  e.product ==
                                                                  intialiProductListItem)
                                                              .toList()
                                                              .firstOrNull!);
                                                      safeSetState(() {});
                                                    } else {
                                                      var favouritesRecordReference =
                                                          FavouritesRecord
                                                              .collection
                                                              .doc();
                                                      await favouritesRecordReference
                                                          .set(
                                                              createFavouritesRecordData(
                                                        uid:
                                                            currentUserReference,
                                                        platform: intialiProductListItem
                                                                    .platform !=
                                                                null
                                                            ? intialiProductListItem
                                                                .platform
                                                            : "amazon",
                                                        product:
                                                            updateProductsStruct(
                                                          intialiProductListItem,
                                                          clearUnsetFields:
                                                              false,
                                                          create: true,
                                                        ),
                                                        timeStamp:
                                                            getCurrentTimestamp,
                                                      ));
                                                      _model.newItem = FavouritesRecord
                                                          .getDocumentFromData(
                                                              createFavouritesRecordData(
                                                                uid:
                                                                    currentUserReference,
                                                                platform: intialiProductListItem
                                                                            .platform !=
                                                                        null
                                                                    ? intialiProductListItem
                                                                        .platform
                                                                    : "amazon",
                                                                product:
                                                                    updateProductsStruct(
                                                                  intialiProductListItem,
                                                                  clearUnsetFields:
                                                                      false,
                                                                  create: true,
                                                                ),
                                                                timeStamp:
                                                                    getCurrentTimestamp,
                                                              ),
                                                              favouritesRecordReference);
                                                      _model
                                                          .addToFavouritesList(
                                                              _model.newItem!);
                                                      safeSetState(() {});
                                                    }

                                                    safeSetState(() {});
                                                  },
                                                ),
                                              ).animateOnPageLoad(animationsMap[
                                                  'productOnPageLoadAnimation2']!);
                                            },
                                          );
                                        }),
                                      ),
                                    );
                                  },
                                ),
                              );
                            } else {
                              return wrapWithModel(
                                model: _model.emptyDataModel2,
                                updateCallback: () => safeSetState(() {}),
                                child: EmptyDataWidget(),
                              );
                            }
                          },
                        );
                      }
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
