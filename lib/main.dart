import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/onboarding/splash_screen.dart';
import 'services/purchase_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
  PurchaseService.instance.init();
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
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
