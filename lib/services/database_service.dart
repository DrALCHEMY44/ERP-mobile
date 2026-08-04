import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import '../generated/example.dart' as dc;

class DatabaseService {
  static Future<void> initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            //apiKey: 'AIzaSyBLz17gqjOspNDC-GNf3Nx1fbLhxcZUDBA',
            appId: '1:869525671507:android:da21d102e3b1c6765140a6',
            messagingSenderId: '869525671507',
            projectId: 'studio-8058744913-5a601',
          ),
        );
      }

      String host = 'localhost';
      if (!kIsWeb && Platform.isAndroid) {
        host = '10.0.2.2';
      }

      dc.ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, 9399);
      print('🔌 Firebase SQL Connect connected to emulator at $host:9399');
    } catch (e) {
      print('Firebase Init Error: $e');
    }
  }
}
