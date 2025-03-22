import 'package:flutter/material.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/tournament.dart';
import '../../utils/constants.dart';
import '../../widgets/tournament/tournament_info_tab.dart';
import '../../widgets/tournament/tournament_matches_tab.dart';
import 'matches_screen.dart';
import 'packages_screen.dart';
import 'teams_screen.dart';
import 'tournament_edit_screen.dart';
import 'rounds_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailScreen({Key? key, required this.tournament})
    : super(key: key);

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Tournament _tournament = widget.tournament;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchFetchInfos();
  }

  _fetchFetchInfos() async {
    setState(() {
      _isLoading = true;
    });

    final response = await appDioClient.get(
      '/tournament/detail',
      queryParameters: {"id": widget.tournament.id},
    );
    if (response.statusCode == 200) {
      setState(() {
        _tournament = Tournament.fromJson(response.data['data']);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Chỉnh sửa thông tin giải đấu
  void _editTournament() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentEditScreen(tournament: _tournament),
      ),
    ).then((result) {
      // Nếu có thay đổi, cập nhật giải đấu
      if (result == true) {
        // Trong thực tế, gọi API để lấy dữ liệu mới
        setState(() {
          // Giả lập cập nhật với dữ liệu mẫu

          _tournament.name = '${_tournament.name} (Đã cập nhật)';
        });
        _fetchFetchInfos();
      }
    });
  }
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament.name ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Chỉnh sửa',
            onPressed: () => _editTournament(),
          ),
        ],
        bottom:
            _isLoading
                ? null
                : TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Thông tin'),
                    Tab(text: 'Trận đấu'),
                    Tab(text: 'Gói đăng ký'),
                    Tab(text: 'Đội tham gia'),
                  ],
                ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _tabController,
                children: [
                  // Sử dụng widget TournamentInfoTab cho tab thông tin
                  TournamentInfoTab(
                    tournament: _tournament,
                    onEdit: _editTournament,
                    fetchTournament: _fetchFetchInfos,
                  ),

                  // Sử dụng widget TournamentMatchesTab cho tab trận đấu
                  TournamentMatchesTab(
                    tournament: _tournament,
                    onUpdateResults: (match) {
                      showUpdateMatchDialog(
                        match: match,
                        context: context,
                        onLoading:
                            (value) => setState(() => _isLoading = value),
                        onUpdate: () => _fetchFetchInfos(),
                      );
                    },
                    fetchTournament: _fetchFetchInfos,
                  ),
                  PackagesScreen(
                    tournament: _tournament,
                    fetchCallback: _fetchFetchInfos,
                  ),

                  // Màn hình quản lý đội tham gia
                  TeamsScreen(
                    tournament: _tournament,
                    fetchCallback: _fetchFetchInfos,
                  ),
                ],
              ),
    );
  }
}
