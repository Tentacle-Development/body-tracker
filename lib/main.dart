import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create provider immediately
  final appProvider = AppProvider();
  
  // Trigger background initializations without awaiting
  _initAsyncServices(appProvider);
  
  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const MyApp(),
    ),
  );
}

Future<void> _initAsyncServices(AppProvider provider) async {
  // Initialize Firebase in background
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  
  // Initialize notifications
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
  
  // Initialize data
  await provider.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Body Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
