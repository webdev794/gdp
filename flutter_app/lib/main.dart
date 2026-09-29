import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/branding_service.dart';
import 'services/review_service.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BrandingService.init();
  await ApiService.initSession();
  await ApiService.refreshUser();
  await ReviewService.init();
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tudee Shopping Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(), // App opens on Home Page first!
    );
  }
}
