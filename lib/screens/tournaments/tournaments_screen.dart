import 'package:flutter/material.dart';
import 'package:vpt_admin_lite_flutter/config/routes.dart';
import '../../models/tournament.dart';
import '../../utils/constants.dart';
import 'create_tournament_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({Key? key}) : super(key: key);

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List<Tournament> _tournaments = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
    });

    // Giả lập tải dữ liệu từ API
    await Future.delayed(const Duration(seconds: 1));

    // Tạo dữ liệu mẫu
    final mockTournaments = [
      Tournament(
        id: 1,
        name: 'Giải Pickleball Mùa Xuân 2023',
        startDate: DateTime(2023, 3, 15),
        endDate: DateTime(2023, 3, 20),
        type: TournamentType.singles,
        genderRestriction: GenderRestriction.mixed,
        numberOfTeams: 16,
        status: TournamentStatus.completed,
      ),
      Tournament(
        id: 2,
        name: 'Giải Pickleball Mùa Hè 2023',
        startDate: DateTime(2023, 7, 1),
        endDate: DateTime(2023, 7, 10),
        type: TournamentType.doubles,
        genderRestriction: GenderRestriction.male,
        numberOfTeams: 8,
        status: TournamentStatus.ongoing,
      ),
      Tournament(
        id: 3,
        name: 'Giải Pickleball Mùa Thu 2023',
        startDate: DateTime(2023, 9, 15),
        endDate: DateTime(2023, 9, 25),
        type: TournamentType.doubles,
        genderRestriction: GenderRestriction.female,
        numberOfTeams: 12,
        status: TournamentStatus.preparing,
      ),
    ];

    setState(() {
      _tournaments = mockTournaments;
      _isLoading = false;
    });
  }

  List<Tournament> _getFilteredTournaments() {
    final searchQuery = _searchController.text.toLowerCase();

    if (searchQuery.isEmpty) return _tournaments;

    return _tournaments.where((tournament) {
      return tournament.name.toLowerCase().contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTournaments = _getFilteredTournaments();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Giải Đấu')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm giải đấu',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTournaments.isEmpty
                    ? const Center(child: Text('Không có giải đấu nào'))
                    : RefreshIndicator(
                      onRefresh: _loadTournaments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(
                          UIConstants.defaultPadding,
                        ),
                        itemCount: filteredTournaments.length,
                        itemBuilder: (context, index) {
                          return _buildTournamentCard(
                            filteredTournaments[index],
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTournament,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToTournamentDetail(tournament),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _buildStatusBadge(tournament.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(tournament.startDate)} - ${_formatDate(tournament.endDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeBadge(tournament.type),
                  const SizedBox(width: 8),
                  _buildGenderBadge(tournament.genderRestriction),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${tournament.numberOfTeams} đội'),
                    backgroundColor: Colors.blue[50],
                    padding: EdgeInsets.zero,
                    labelStyle: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _navigateToTournamentDetail(tournament),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Chi tiết'),
                  ),
                  const SizedBox(width: 8),
                  if (tournament.status == TournamentStatus.preparing)
                    TextButton.icon(
                      onPressed: () => _navigateToEditTournament(tournament),
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    late Color color;
    late String text;

    switch (status) {
      case TournamentStatus.preparing:
        color = Colors.orange;
        text = 'Chuẩn bị';
        break;
      case TournamentStatus.ongoing:
        color = Colors.green;
        text = 'Đang diễn ra';
        break;
      case TournamentStatus.completed:
        color = Colors.blue;
        text = 'Đã kết thúc';
        break;
      case TournamentStatus.cancelled:
        color = Colors.red;
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(TournamentType type) {
    return Chip(
      label: Text(type == TournamentType.singles ? 'Đấu đơn' : 'Đấu đôi'),
      backgroundColor:
          type == TournamentType.singles
              ? Colors.purple[50]
              : Colors.indigo[50],
      padding: EdgeInsets.zero,
      labelStyle: TextStyle(
        color:
            type == TournamentType.singles
                ? Colors.purple[700]
                : Colors.indigo[700],
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildGenderBadge(GenderRestriction gender) {
    late Color color;
    late String text;

    switch (gender) {
      case GenderRestriction.male:
        color = Colors.blue;
        text = 'Nam';
        break;
      case GenderRestriction.female:
        color = Colors.pink;
        text = 'Nữ';
        break;
      case GenderRestriction.mixed:
        color = Colors.teal;
        text = 'Nam & Nữ';
        break;
    }

    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      padding: EdgeInsets.zero,
      labelStyle: TextStyle(color: color, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToCreateTournament() {
    // Điều hướng đến màn hình tạo giải đấu mới
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
    ).then((_) => _loadTournaments());
  }

  void _navigateToTournamentDetail(Tournament tournament) {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentDetail,
      arguments: tournament.toJson(),
    );
  }

  void _navigateToEditTournament(Tournament tournament) {
    // Điều hướng đến màn hình chỉnh sửa giải đấu
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chỉnh sửa giải đấu'),
            content: const SizedBox(
              width: 400,
              child: Text('Chức năng chỉnh sửa sẽ được triển khai sau'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }
}
