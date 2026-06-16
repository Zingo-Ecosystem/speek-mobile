import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/session.dart';
import 'screens/onboarding/splash_screen.dart';
import 'services/call_manager.dart';
import 'services/purchase_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
  // Restore any persisted session early so the splash can route correctly.
  Session.instance.load();
  PurchaseService.instance.init();
  // Ring the user on inbound calls from any screen.
  CallManager.instance.start();
  runApp(const SpeekApp());
}

class SpeekApp extends StatelessWidget {
  const SpeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Speek is dark-mode only, English only.
    return MaterialApp(
      title: 'Speek',
      debugShowCheckedModeBanner: false,
      navigatorKey: CallManager.instance.navigatorKey,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
