import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (no-op if not configured)
  try {
    await Firebase.initializeApp();
    await PushService.instance.init();
  } catch (_) {
    // Firebase not configured yet — push notifications disabled
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAF8F5),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: BingoalsApp(),
    ),
  );
}
