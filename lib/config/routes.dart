import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/players/player_detail_screen.dart';
import '../screens/videos/video_detail_screen.dart';
import '../screens/tournaments/tournament_detail_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String playerDetail = '/players/detail';
  static const String videoDetail = '/videos/detail';
  static const String tournamentDetail = '/tournaments/detail';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
  };

  // Định tuyến động với tham số
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case playerDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (context) => PlayerDetailScreen(
                player: args != null ? args['player'] : null,
              ),
        );
      case videoDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (context) =>
                  VideoDetailScreen(video: args != null ? args['video'] : null),
        );
      case tournamentDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (context) => TournamentDetailScreen(
                tournament: args != null ? args['tournament'] : null,
              ),
        );
      default:
        return MaterialPageRoute(
          builder:
              (context) => const Scaffold(
                body: Center(child: Text('Không tìm thấy trang')),
              ),
        );
    }
  }
}
