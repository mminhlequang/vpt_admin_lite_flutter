import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../players/players_screen.dart';
import '../tournaments/tournaments_screen.dart';
import '../videos/videos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TournamentsScreen(),
    const PlayersScreen(),
    const VideosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Giải đấu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Người chơi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: 'Video'),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
 