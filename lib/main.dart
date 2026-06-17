import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'screens/onboarding/splash_screen.dart';
import 'services/call_manager.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
  // Restore any persisted session early so the splash can route correctly.
  Session.instance.load();
  NotificationService.instance.init();
  PurchaseService.instance.init();
  CallManager.instance.start();
  ApiClient.onUnauthenticated = () {
    debugPrint("Calling event");
    CallManager.instance.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  };
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
