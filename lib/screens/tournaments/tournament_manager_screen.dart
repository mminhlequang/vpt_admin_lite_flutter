import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import 'categories_screen.dart';
import 'packages_screen.dart';
import 'teams_screen.dart';

class TournamentManagerScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentManagerScreen({Key? key, required this.tournament})
    : super(key: key);

  @override
  State<TournamentManagerScreen> createState() =>
      _TournamentManagerScreenState();
}

class _TournamentManagerScreenState extends State<TournamentManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý: ${widget.tournament.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gói đăng ký'),
            Tab(text: 'Đội tham gia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Màn hình quản lý danh mục
          // const CategoriesScreen(),

          // Màn hình quản lý gói đăng ký
          PackagesScreen(
            tournamentId: widget.tournament.id,
            tournamentName: widget.tournament.name,
          ),

          // Màn hình quản lý đội tham gia
          TeamsScreen(
            tournamentId: widget.tournament.id,
            tournamentName: widget.tournament.name,
          ),
        ],
      ),
    );
  }
}
