import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pickleball Tournament Admin',
      theme: AppTheme.lightTheme,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
    );
  }
}
