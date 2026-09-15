import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class OfflineBannerWrapper extends StatefulWidget {
  final Widget child;

  const OfflineBannerWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _OfflineBannerWrapperState createState() => _OfflineBannerWrapperState();
}

class _OfflineBannerWrapperState extends State<OfflineBannerWrapper> {
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        if (mounted) setState(() => _isConnected = true);
      } else {
        // Double-check real internet before showing banner (prevents Simulator false-positive)
        final real = await _hasRealInternet();
        if (mounted) setState(() => _isConnected = real);
      }
    });
  }

  Future<bool> _hasRealInternet() async {
    try {
      final res = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 2));
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkInitialConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        if (mounted) setState(() => _isConnected = true);
      } else {
        final real = await _hasRealInternet();
        if (mounted) setState(() => _isConnected = real);
      }
    } catch (_) {
      if (mounted) setState(() => _isConnected = true);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isConnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Aucune connexion internet',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
