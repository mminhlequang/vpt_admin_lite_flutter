import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vpt_admin_lite_flutter/internal_setup.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'screens/referee/referee_match_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  internalSetup();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      title: 'Pickleball Tournament Admin',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}

final GoRouter appRouter = GoRouter(
  // initialLocation: '/referee/match/8/17',
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/referee/match/:tournamentId/:matchId',
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'];
        final tournamentId = state.pathParameters['tournamentId'];
        return RefereeMatchScreen(matchId: matchId, tournamentId: tournamentId);
      },
    ),
  ],
  errorBuilder:
      (context, state) =>
          Scaffold(body: Center(child: Text('Không tìm thấy trang'))),
);
