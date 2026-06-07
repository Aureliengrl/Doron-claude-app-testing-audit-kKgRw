import '/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class FFDevEnvironmentValues {
  static const String currentEnvironment = 'Production';
  static const String environmentValuesPath =
      'assets/environment_values/environment.json';

  static final FFDevEnvironmentValues _instance =
      FFDevEnvironmentValues._internal();

  factory FFDevEnvironmentValues() {
    return _instance;
  }

  FFDevEnvironmentValues._internal();

  Future<void> initialize() async {
    try {
      final String response =
          await rootBundle.loadString(environmentValuesPath);
      final data = await json.decode(response);
      _openAiApiKey = data['openAiApiKey'] ?? '';
      _rapidApiKey = data['rapidApiKey'] ?? '';
      _rapidApiSephoraKey = data['rapidApiSephoraKey'] ?? '';
    } catch (e) {
      AppLogger.debug('Error loading environment values: $e', 'Debug');
    }
  }

  String _openAiApiKey = '';
  String get openAiApiKey => _openAiApiKey;

  String _rapidApiKey = '';
  String get rapidApiKey => _rapidApiKey;

  String _rapidApiSephoraKey = '';
  String get rapidApiSephoraKey => _rapidApiSephoraKey;
}
