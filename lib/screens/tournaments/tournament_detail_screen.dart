import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../../utils/constants.dart';
import '../../widgets/tournament/tournament_info_tab.dart';
import '../../widgets/tournament/tournament_matches_tab.dart';
import 'tournament_edit_screen.dart';
import 'tournament_schedule_edit_screen.dart';
import 'tournament_manager_screen.dart';
import 'package:dio/dio.dart';
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
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _tabController = TabController(length: 3, vsync: this);
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
          _tournament = _tournament.copyWith(
            name: '${_tournament.name} (Đã cập nhật)',
            type: _tournament.type, // Giữ nguyên loại
          );
        });
      }
    });
  }

  // Xuất lịch thi đấu
  void _exportSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng xuất lịch sẽ được triển khai sau'),
      ),
    );
  }

  // Chỉnh sửa lịch thi đấu
  Future<void> _editSchedule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TournamentScheduleEditScreen(
              tournament: _tournament,
              onSave: (updatedTournament) {
                setState(() {
                  _tournament = updatedTournament;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật lịch thi đấu')),
                );
              },
            ),
      ),
    );

    if (result != null) {
      setState(() {
        _tournament = result;
      });
    }
  }

  // Cập nhật kết quả trận đấu
  void _updateMatchResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng cập nhật kết quả sẽ được triển khai sau'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa',
            onPressed: () => _editTournament(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Quản lý',
            onPressed: () => _openTournamentManager(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Vòng đấu'),
            Tab(text: 'Trận đấu'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  // Sử dụng widget TournamentInfoTab cho tab thông tin
                  TournamentInfoTab(
                    tournament: _tournament,
                    onEdit: _editTournament,
                    onExportSchedule: _exportSchedule,
                  ),
                  // Tab quản lý vòng đấu
                  _buildRoundsTab(),
                  // Sử dụng widget TournamentMatchesTab cho tab trận đấu
                  TournamentMatchesTab(
                    tournament: _tournament,
                    onUpdateResults: _updateMatchResults,
                    onEditSchedule: _editSchedule,
                  ),
                ],
              ),
    );
  }

  // Mở màn hình quản lý giải đấu
  void _openTournamentManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentManagerScreen(tournament: _tournament),
      ),
    );
  }

  Widget _buildRoundsTab() {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.access_time, size: 48, color: Colors.indigo),
                  const SizedBox(height: 16),
                  Text(
                    'Quản lý vòng đấu',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tổ chức các vòng đấu, phân chia trận đấu và theo dõi tiến độ giải',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToRoundsScreen,
                    icon: const Icon(Icons.sports),
                    label: const Text('Quản lý vòng đấu'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Lưu ý khi quản lý vòng đấu:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRoundsInfoList(),
        ],
      ),
    );
  }

  Widget _buildRoundsInfoList() {
    final tips = [
      'Thiết lập các vòng đấu khác nhau như vòng loại, tứ kết, bán kết và chung kết',
      'Phân chia và sắp xếp các trận đấu trong mỗi vòng',
      'Cập nhật kết quả và theo dõi tiến độ của các trận đấu',
      'Tạo trận đấu tự động hoặc thủ công từ các đội tham gia',
      'Tạo lịch trình cho các trận đấu với thời gian và địa điểm cụ thể',
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tips[index],
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToRoundsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoundsScreen(tournament: _tournament),
      ),
    );
  }
}
