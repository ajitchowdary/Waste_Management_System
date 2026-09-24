import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  // Auto-detect the right URL:
  // - Chrome/Web/Windows: http://localhost:5000/api
  // - Android Emulator: http://10.0.2.2:5000/api
  // - Real Physical Phone: http://<YOUR_COMPUTER_WIFI_IP>:5000/api
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  static String baseUrl = defaultBaseUrl;

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    dio.options.baseUrl = newUrl;
  }
}
