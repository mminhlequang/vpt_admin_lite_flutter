import 'package:flutter/material.dart';
import 'package:internal_network/network_resources/resources.dart';
import 'package:vpt_admin_lite_flutter/config/routes.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import 'package:vpt_admin_lite_flutter/widgets/player/player_list_item.dart';
import '../../models/tournament.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_indicator.dart';
import 'create_tournament_screen.dart';
import 'tournament_edit_screen.dart';
import 'tournament_manager_screen.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({Key? key}) : super(key: key);

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List<Tournament> _tournaments = [];
  List<Tournament> _filteredTournaments = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final bool _isAdmin = true; // Đặt true để hiển thị chức năng quản lý

  @override
  void initState() {
    super.initState();
    _loadTournaments();

    _searchController.addListener(() {
      _filterTournaments(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await appDioClient.get('/tournament');

      if (response.data['status'] == true && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        final tournaments =
            data.map((json) => Tournament.fromJson(json)).toList();

        setState(() {
          _tournaments = tournaments;
          _filteredTournaments = tournaments;
          _isLoading = false;
        });
      } else {
        throw Exception(
          response.data['message'] ?? 'Không thể tải danh sách giải đấu',
        );
      }
    } catch (e) {
      print('Lỗi khi tải giải đấu: $e');
      if (e is DioException) {
        print('Loại lỗi Dio: ${e.type}');
        print('Thông báo lỗi Dio: ${e.message}');
        print('Phản hồi lỗi Dio: ${e.response?.data}');
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Không thể tải danh sách giải đấu: ${e.toString()}';
      });
    }
  }

  void _filterTournaments(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTournaments = _tournaments;
      });
    } else {
      setState(() {
        _filteredTournaments =
            _tournaments.where((tournament) {
              return tournament.name.toLowerCase().contains(
                query.toLowerCase(),
              );
            }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTournaments = _filteredTournaments;

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
                    ? const Center(child: LoadingIndicator())
                    : _hasError
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadTournaments,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
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
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => _navigateToTournamentDetail(tournament),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child:
                        tournament.imageUrl != null
                            ? Image.network(
                              correctUrlImage(tournament.imageUrl!),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.sports_tennis,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            )
                            : Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.sports_tennis,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                            ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16.0),
                            const SizedBox(width: 4.0),
                            Text(
                              '${_formatDate(tournament.startDate)} - ${_formatDate(tournament.endDate)}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        if (tournament.city != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16.0),
                              const SizedBox(width: 4.0),
                              Text(
                                tournament.city!,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            _buildTypeBadge(tournament.type),
                            const SizedBox(width: 8.0),
                            if (tournament.genderRestriction != null)
                              ..._buildGenderBadges(
                                tournament.genderRestriction!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              if (tournament.prize != null)
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 18.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'Giải thưởng: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(tournament.prize)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(tournament.status),
                  if (_isAdmin)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed:
                              () => _navigateToTournamentEdit(tournament),
                          tooltip: 'Chỉnh sửa giải đấu',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(tournament),
                          tooltip: 'Xóa giải đấu',
                        ),
                      ],
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
        color = Colors.blue;
        text = 'Đang chuẩn bị';
        break;
      case TournamentStatus.ongoing:
        color = Colors.green;
        text = 'Đang diễn ra';
        break;
      case TournamentStatus.completed:
        color = Colors.purple;
        text = 'Đã kết thúc';
        break;
      case TournamentStatus.cancelled:
        color = Colors.red;
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12.0)),
    );
  }

  Widget _buildTypeBadge(int type) {
    return Chip(
      label: Text(type == 1 ? 'Đấu đơn' : 'Đấu đôi'),
      backgroundColor: type == 1 ? Colors.purple[50] : Colors.indigo[50],
      padding: EdgeInsets.zero,
      labelStyle: TextStyle(
        color: type == 1 ? Colors.purple[700] : Colors.indigo[700],
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  List<Widget> _buildGenderBadges(List<String> genders) {
    List<Widget> badges = [];

    for (String gender in genders) {
      Color color;
      IconData icon;

      switch (gender.toLowerCase()) {
        case 'male':
          color = Colors.blue;
          icon = Icons.male;
          break;
        case 'female':
          color = Colors.pink;
          icon = Icons.female;
          break;
        case 'mixed':
        default:
          color = Colors.purple;
          icon = Icons.people;
          break;
      }

      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.0, color: color),
              const SizedBox(width: 2.0),
              Text(
                _getGenderText(gender),
                style: TextStyle(color: color, fontSize: 12.0),
              ),
            ],
          ),
        ),
      );
    }

    return badges;
  }

  String _getGenderText(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'mixed':
      default:
        return 'Nam/Nữ';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToCreateTournament() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
    ).then((result) {
      if (result == true) {
        _loadTournaments();
      }
    });
  }

  void _navigateToTournamentDetail(Tournament tournament) {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentDetail,
      arguments: tournament,
    );
  }

  void _navigateToTournamentEdit(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentEditScreen(tournament: tournament),
      ),
    ).then((result) {
      if (result == true) {
        _loadTournaments();
      }
    });
  }

  void _navigateToTournamentManager(Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentManagerScreen(tournament: tournament),
      ),
    ).then((_) => _loadTournaments());
  }

  void _showDeleteConfirmation(Tournament tournament) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa giải đấu "${tournament.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTournament(tournament);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTournament(Tournament tournament) async {
    try {
      // Hiển thị loading indicator
      setState(() {
        _isLoading = true;
      });

      // Gọi API trực tiếp để xóa giải đấu
      final response = await appDioClient.post('/tournament/delete_tournament', data: {'id': tournament.id});

      if (response.data['status'] != true) {
        throw Exception(response.data['message'] ?? 'Không thể xóa giải đấu');
      }

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa giải đấu thành công'),
          backgroundColor: Colors.green,
        ),
      );

      // Tải lại danh sách giải đấu
      _loadTournaments();
    } catch (e) {
      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa giải đấu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}
