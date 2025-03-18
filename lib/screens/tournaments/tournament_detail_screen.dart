import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:vpt_admin_lite_flutter/widgets/player/player_list_item.dart';
import '../../models/tournament.dart';
import '../../models/player.dart';
import '../../utils/constants.dart';
import '../../widgets/tournament/tournament_info_tab.dart';
import '../../widgets/tournament/tournament_matches_tab.dart';
import 'tournament_edit_screen.dart';
import 'tournament_schedule_edit_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final Tournament? tournament;

  const TournamentDetailScreen({Key? key, this.tournament}) : super(key: key);

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Tournament _tournament;
  bool _isLoading = false;
  // Danh sách người chơi có sẵn trong hệ thống (giả lập)
  List<Player> _availablePlayers = [];
  // Danh sách người chơi đã đăng ký
  List<Player> _registeredPlayers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.tournament != null) {
      _tournament = widget.tournament!;
    } else {
      _loadTournamentData();
    }
    _loadAvailablePlayers();
    _loadRegisteredPlayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Tải danh sách người chơi có sẵn trong hệ thống
  Future<void> _loadAvailablePlayers() async {
    // Giả lập dữ liệu
    _availablePlayers = List.generate(
      20,
      (index) => Player(
        id: index + 10, // Đảm bảo không trùng với ID người chơi hiện tại
        name: 'Người chơi mới ${index + 1}',
        sex: index % 2 == 0 ? 1 : 2,
        phone: '090${1000000 + index * 2}',
        email: 'newplayer${index + 1}@example.com',
        hasPaid: index % 3 == 0,
        status: RegistrationStatus.approved,
      ),
    );
  }

  // Tải danh sách người chơi đã đăng ký
  Future<void> _loadRegisteredPlayers() async {
    // Trong thực tế, gọi API để lấy danh sách người chơi đã đăng ký
    // Giả lập dữ liệu
    _registeredPlayers = [
      Player(
        id: 5,
        name: 'Hoàng Văn E',
        sex: 1,
        phone: '0909998877',
        email: 'hoangvane@example.com',
        hasPaid: true,
        status: RegistrationStatus.approved,
        registrationDate: DateTime.now().subtract(const Duration(days: 5)),
        height: 178,
        weight: 72,
        total_win: 12,
        total_lose: 8,
      ),
      Player(
        id: 6,
        name: 'Nguyễn Thị F',
        sex: 2,
        phone: '0901234666',
        email: 'nguyenthif@example.com',
        hasPaid: false,
        status: RegistrationStatus.pending,
        registrationDate: DateTime.now().subtract(const Duration(days: 3)),
        height: 165,
        weight: 55,
        total_win: 7,
        total_lose: 9,
      ),
    ];
  }

  // Lấy danh sách người chơi chưa tham gia giải đấu
  List<Player> _getUnregisteredPlayers() {
    // Lấy tất cả ID người chơi đã tham gia
    final registeredPlayerIds = <int>{};
    for (final team in _tournament.teams) {
      for (final player in team.players) {
        registeredPlayerIds.add(player.id);
      }
    }

    // Lọc danh sách người chơi chưa tham gia
    return _availablePlayers
        .where((player) => !registeredPlayerIds.contains(player.id))
        .toList();
  }

  // Hiển thị dialog thêm người chơi
  Future<void> _showAddPlayerDialog() async {
    final unregisteredPlayers = _getUnregisteredPlayers();
    final selectedPlayers = <Player>[];

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Thêm người chơi'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn người chơi để thêm vào giải đấu:'),
                      const SizedBox(height: 8),

                      // Hiện thị số người chơi đã chọn
                      Text(
                        'Đã chọn: ${selectedPlayers.length} người chơi',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Danh sách người chơi chưa tham gia
                      Expanded(
                        child:
                            unregisteredPlayers.isEmpty
                                ? const Center(
                                  child: Text(
                                    'Không có người chơi nào khả dụng',
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: unregisteredPlayers.length,
                                  itemBuilder: (context, index) {
                                    final player = unregisteredPlayers[index];
                                    final isSelected = selectedPlayers.contains(
                                      player,
                                    );

                                    return CheckboxListTile(
                                      title: Text(player.name),
                                      subtitle: Text(player.email ?? ""),
                                      secondary: CircleAvatar(
                                        backgroundColor:
                                            player.sex == 1
                                                ? Colors.blue[100]
                                                : Colors.pink[100],
                                        child: Text(
                                          player.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                        ),
                                      ),
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedPlayers.add(player);
                                          } else {
                                            selectedPlayers.remove(player);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedPlayers.isEmpty
                            ? null
                            : () {
                              _addPlayersToTournament(selectedPlayers);
                              Navigator.pop(context);
                            },
                    child: const Text('Thêm'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Thêm người chơi vào giải đấu
  void _addPlayersToTournament(List<Player> players) {
    if (players.isEmpty) return;

    // Trong ứng dụng thực tế, cần gọi API để thêm người chơi
    // Giả lập: Tạo đội mới hoặc thêm vào đội hiện có tùy theo loại giải đấu
    setState(() {
      if (_tournament.type == TournamentType.singles) {
        // Với giải đấu đơn, mỗi người chơi là một đội
        for (final player in players) {
          final newTeam = Team(
            id: 'team_${DateTime.now().millisecondsSinceEpoch}_${player.id}',
            name: player.name,
            players: [player],
          );
          _tournament = _tournament.copyWith(
            teams: [..._tournament.teams, newTeam],
          );
        }
      } else {
        // Với giải đấu đôi, ghép cặp người chơi thành đội
        // Nếu số lượng người chơi lẻ, người cuối cùng sẽ chờ ghép cặp sau
        for (int i = 0; i < players.length - 1; i += 2) {
          if (i + 1 < players.length) {
            final player1 = players[i];
            final player2 = players[i + 1];
            final newTeam = Team(
              id:
                  'team_${DateTime.now().millisecondsSinceEpoch}_${player1.id}_${player2.id}',
              name: '${player1.name} & ${player2.name}',
              players: [player1, player2],
            );
            _tournament = _tournament.copyWith(
              teams: [..._tournament.teams, newTeam],
            );
          }
        }

        // Nếu số lượng người chơi lẻ, tạo một đội chỉ có một người
        if (players.length % 2 != 0) {
          final player = players.last;
          final newTeam = Team(
            id: 'team_${DateTime.now().millisecondsSinceEpoch}_${player.id}',
            name: '${player.name} (Chờ ghép cặp)',
            players: [player],
          );
          _tournament = _tournament.copyWith(
            teams: [..._tournament.teams, newTeam],
          );
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${players.length} người chơi vào giải đấu'),
      ),
    );
  }

  Future<void> _loadTournamentData() async {
    setState(() {
      _isLoading = true;
    });

    // Giả lập tải dữ liệu từ API
    await Future.delayed(const Duration(seconds: 1));

    // Tạo dữ liệu mẫu
    final team1 = Team(
      id: 'team_1',
      name: 'Nguyễn A & Trần B',
      players: [
        Player(
          id: 1,
          name: 'Nguyễn Văn A',
          sex: 1,
          phone: '0901234567',
          email: 'nguyenvana@example.com',
          hasPaid: true,
          status: RegistrationStatus.approved,
        ),
        Player(
          id: 2,
          name: 'Trần Thị B',
          sex: 2,
          phone: '0907654321',
          email: 'tranthib@example.com',
          hasPaid: true,
          status: RegistrationStatus.approved,
        ),
      ],
    );

    final team2 = Team(
      id: 'team_2',
      name: 'Lê C & Phạm D',
      players: [
        Player(
          id: 3,
          name: 'Lê Văn C',
          sex: 1,
          phone: '0909876543',
          email: 'levanc@example.com',
          hasPaid: true,
          status: RegistrationStatus.approved,
        ),
        Player(
          id: 4,
          name: 'Phạm Thị D',
          sex: 2,
          phone: '0901122334',
          email: 'phamthid@example.com',
          hasPaid: true,
          status: RegistrationStatus.approved,
        ),
      ],
    );

    final team3 = Team(
      id: 'team_3',
      name: 'Hoàng E & Ngô F',
      players: [
        Player(
          id: 5,
          name: 'Hoàng Văn E',
          sex: 1,
          phone: '0909998877',
          email: 'hoangvane@example.com',
          hasPaid: true,
          status: RegistrationStatus.approved,
        ),
        Player(
          id: 6,
          name: 'Ngô Thị F',
          sex: 2,
          phone: '0901234666',
          email: 'ngothif@example.com',
          hasPaid: true,
          status: RegistrationStatus.approved,
        ),
      ],
    );

    final team4 = Team(
      id: 'team_4',
      name: 'Trương G & Vũ H',
      players: [
        Player(
          id: 7,
          name: 'Trương Văn G',
          sex: 1,
          phone: '0901234888',
          email: 'truongg@example.com',
          hasPaid: true,
          status: RegistrationStatus.approved,
        ),
        Player(
          id: 8,
          name: 'Vũ Thị H',
          sex: 2,
          phone: '0901234999',
          email: 'vuh@example.com',
          hasPaid: true,
          status: RegistrationStatus.approved,
        ),
      ],
    );

    // Tạo các trận đấu
    final match1 = Match(
      id: 'match_1',
      team1: team1,
      team2: team2,
      score1: 21,
      score2: 18,
      status: MatchStatus.completed,
      scheduledTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      courtNumber: 'Sân 1',
      winner: team1,
    );

    final match2 = Match(
      id: 'match_2',
      team1: team3,
      team2: team4,
      score1: 19,
      score2: 21,
      status: MatchStatus.completed,
      scheduledTime: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      courtNumber: 'Sân 2',
      winner: team4,
    );

    final match3 = Match(
      id: 'match_3',
      team1: team1,
      team2: team4,
      status: MatchStatus.scheduled,
      scheduledTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      courtNumber: 'Sân 1',
    );

    final tournament = Tournament(
      id: 2,
      name: 'Giải Pickleball Mùa Hè 2023',
      startDate: DateTime(2023, 7, 1),
      endDate: DateTime(2023, 7, 10),
      type: TournamentType.doubles,
      genderRestriction: GenderRestriction.mixed,
      numberOfTeams: 4,
      teams: [team1, team2, team3, team4],
      matches: [match1, match2, match3],
      status: TournamentStatus.ongoing,
      imageUrl: 'https://source.unsplash.com/random/800x600/?pickleball',
      description: '''
        <h2>Giải Pickleball Mùa Hè 2023</h2>
        <p>Chào mừng bạn đến với <strong>Giải Pickleball Mùa Hè 2023</strong>! Đây là giải đấu thường niên được tổ chức bởi CLB Pickleball Việt Nam.</p>
        <h3>Thông tin chi tiết</h3>
        <ul>
          <li>Thời gian: 01/07/2023 - 10/07/2023</li>
          <li>Địa điểm: Trung tâm thể thao Quận 1, TP. Hồ Chí Minh</li>
          <li>Hạng mục thi đấu: Đôi nam nữ</li>
        </ul>
        <h3>Giải thưởng</h3>
        <ol>
          <li>Giải nhất: 10.000.000 VNĐ + Cup + Huy chương Vàng</li>
          <li>Giải nhì: 5.000.000 VNĐ + Huy chương Bạc</li>
          <li>Giải ba: 3.000.000 VNĐ + Huy chương Đồng</li>
        </ol>
        <p><em>Mọi thông tin chi tiết vui lòng liên hệ BTC qua hotline: 0901234567</em></p>
      ''',
    );

    setState(() {
      _tournament = tournament;
      _isLoading = false;
    });
  }

  // Chỉnh sửa thông tin giải đấu
  Future<void> _editTournament() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TournamentEditScreen(
              tournament: _tournament,
              onSave: (updatedTournament) {
                setState(() {
                  _tournament = updatedTournament;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật thông tin giải đấu'),
                  ),
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
        title: const Text('Chi tiết giải đấu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Trận đấu'),
            Tab(text: 'Đội'),
            Tab(text: 'Đăng ký'),
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
                  // Sử dụng widget TournamentMatchesTab cho tab trận đấu
                  TournamentMatchesTab(
                    tournament: _tournament,
                    onUpdateResults: _updateMatchResults,
                    onEditSchedule: _editSchedule,
                  ),
                  _buildTeamsTab(),
                  _buildRegistrationTab(),
                ],
              ),
    );
  }

  Widget _buildTeamsTab() {
    // Tính toán tổng số người chơi
    final totalPlayers = _tournament.teams.fold<int>(
      0,
      (sum, team) => sum + team.players.length,
    );

    return Column(
      children: [
        // Header với thông tin tổng quan và nút thêm người chơi
        Container(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng số đội: ${_tournament.teams.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng số người chơi: $totalPlayers',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_tournament.status == TournamentStatus.preparing ||
                      _tournament.status == TournamentStatus.ongoing)
                    ElevatedButton.icon(
                      onPressed: _showAddPlayerDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Thêm người chơi'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],
          ),
        ),

        // Danh sách đội
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.defaultPadding,
              vertical: UIConstants.defaultPadding / 2,
            ),
            itemCount: _tournament.teams.length,
            itemBuilder: (context, index) {
              final team = _tournament.teams[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Text('${index + 1}')),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Số thành viên: ${team.players.length}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Thành viên',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: team.players.length,
                        itemBuilder: (context, playerIndex) {
                          final player = team.players[playerIndex];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  player.sex == 1
                                      ? Colors.blue[100]
                                      : Colors.pink[100],
                              child: Text(
                                player.name.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(player.name),
                            subtitle: Text(player.email ?? ''),
                            trailing: Icon(
                              player.sex == 1 ? Icons.male : Icons.female,
                              color:
                                  player.sex == 1 ? Colors.blue : Colors.pink,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab đăng ký giải đấu
  Widget _buildRegistrationTab() {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRegistrationHeader(),
          const SizedBox(height: 16),
          _buildRegistrationActions(),
          const SizedBox(height: 24),
          Expanded(child: _buildRegisteredPlayersListView()),
        ],
      ),
    );
  }

  Widget _buildRegistrationHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.app_registration, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Đăng ký tham gia ${_tournament.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thời hạn: ${_formatDate(_tournament.startDate.subtract(const Duration(days: 1)))}',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatCard(
                  'Đã đăng ký',
                  _registeredPlayers.length.toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Đã duyệt',
                  _registeredPlayers
                      .where((p) => p.status == RegistrationStatus.approved)
                      .length
                      .toString(),
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Chờ duyệt',
                  _registeredPlayers
                      .where((p) => p.status == RegistrationStatus.pending)
                      .length
                      .toString(),
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationActions() {
    final bool isRegistrationOpen =
        _tournament.status == TournamentStatus.preparing ||
        _tournament.status == TournamentStatus.ongoing;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isRegistrationOpen ? _showAddPlayerDialog : null,
            icon: const Icon(Icons.person_add),
            label: const Text('Thêm người chơi mới'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                isRegistrationOpen ? _showRegisterExistingPlayerDialog : null,
            icon: const Icon(Icons.how_to_reg),
            label: const Text('Đăng ký người chơi có sẵn'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredPlayersListView() {
    if (_registeredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có người chơi nào đăng ký',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _registeredPlayers.length,
      itemBuilder: (context, index) {
        final player = _registeredPlayers[index];
        return PlayerListItem(
          player: player,
          showDetailedInfo: true,
          onApprove:
              player.status == RegistrationStatus.pending
                  ? () => _updatePlayerRegistrationStatus(
                    player,
                    RegistrationStatus.approved,
                  )
                  : null,
          onReject:
              player.status == RegistrationStatus.pending
                  ? () => _updatePlayerRegistrationStatus(
                    player,
                    RegistrationStatus.rejected,
                  )
                  : null,
          onTogglePaid:
              player.status == RegistrationStatus.approved
                  ? () => _togglePlayerPaidStatus(player)
                  : null,
        );
      },
    );
  }

  void _updatePlayerRegistrationStatus(
    Player player,
    RegistrationStatus status,
  ) {
    // Trong thực tế, gọi API để cập nhật trạng thái
    setState(() {
      final index = _registeredPlayers.indexWhere((p) => p.id == player.id);
      if (index != -1) {
        _registeredPlayers[index] = player.copyWith(status: status);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cập nhật trạng thái đăng ký thành ${status == RegistrationStatus.approved ? 'Đã duyệt' : 'Từ chối'}',
        ),
      ),
    );
  }

  void _togglePlayerPaidStatus(Player player) {
    // Trong thực tế, gọi API để cập nhật trạng thái thanh toán
    setState(() {
      final index = _registeredPlayers.indexWhere((p) => p.id == player.id);
      if (index != -1) {
        _registeredPlayers[index] = player.copyWith(hasPaid: !player.hasPaid);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cập nhật trạng thái thanh toán thành ${player.hasPaid ? 'Chưa thanh toán' : 'Đã thanh toán'}',
        ),
      ),
    );
  }

  void _showRegisterExistingPlayerDialog() {
    // Lấy ID người chơi đã đăng ký
    final registeredPlayerIds = _registeredPlayers.map((p) => p.id).toSet();

    // Lọc danh sách người chơi chưa đăng ký
    final unregisteredPlayers =
        _availablePlayers
            .where((player) => !registeredPlayerIds.contains(player.id))
            .toList();

    if (unregisteredPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có người chơi nào khả dụng để đăng ký'),
        ),
      );
      return;
    }

    final selectedPlayers = <Player>[];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Đăng ký người chơi có sẵn'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn người chơi để đăng ký:'),
                      const SizedBox(height: 8),
                      Text(
                        'Đã chọn: ${selectedPlayers.length} người chơi',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: unregisteredPlayers.length,
                          itemBuilder: (context, index) {
                            final player = unregisteredPlayers[index];
                            final isSelected = selectedPlayers.contains(player);

                            return CheckboxListTile(
                              title: Text(player.name),
                              subtitle: Text(player.email ?? ''),
                              secondary: CircleAvatar(
                                backgroundImage:
                                    player.avatar != null
                                        ? NetworkImage(player.avatar!)
                                        : null,
                                backgroundColor:
                                    player.sex == 1
                                        ? Colors.blue[100]
                                        : Colors.pink[100],
                                child:
                                    player.avatar == null
                                        ? Text(
                                          player.name.isNotEmpty
                                              ? player.name
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : '?',
                                        )
                                        : null,
                              ),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedPlayers.add(player);
                                  } else {
                                    selectedPlayers.remove(player);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedPlayers.isEmpty
                            ? null
                            : () {
                              _registerPlayers(selectedPlayers);
                              Navigator.pop(context);
                            },
                    child: const Text('Đăng ký'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _registerPlayers(List<Player> players) {
    if (players.isEmpty) return;

    // Trong thực tế, gọi API để đăng ký người chơi
    setState(() {
      for (final player in players) {
        // Thêm người chơi với trạng thái pending
        final registeredPlayer = player.copyWith(
          status: RegistrationStatus.pending,
          registrationDate: DateTime.now(),
        );

        _registeredPlayers.add(registeredPlayer);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã đăng ký ${players.length} người chơi mới')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
