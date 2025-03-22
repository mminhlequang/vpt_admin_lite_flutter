import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/tournament.dart' hide Match, MatchStatus, Team;
import '../../models/round.dart';
import '../../models/match.dart' as match_model;
import '../../models/team.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_indicator.dart';

class MatchesScreen extends StatefulWidget {
  final Tournament tournament;
  final Round round;

  const MatchesScreen({Key? key, required this.tournament, required this.round})
    : super(key: key);

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController _stadiumController = TextEditingController();
  final TextEditingController _scheduledTimeController =
      TextEditingController();
  final TextEditingController _team1ScoreController = TextEditingController();
  final TextEditingController _team2ScoreController = TextEditingController();

  List<match_model.TournamentMatch> _matches = [];
  List<Team> _availableTeams = [];
  bool _isLoading = true;
  bool _isLoadingTeams = true;
  String _errorMessage = '';
  DateTime? _selectedScheduledTime;
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  match_model.MatchStatus _selectedStatus = match_model.MatchStatus.pending;

  final Map<match_model.MatchStatus, Color> statusColors = {
    match_model.MatchStatus.pending: Colors.grey,
    match_model.MatchStatus.ongoing: Colors.orange,
    match_model.MatchStatus.completed: Colors.green,
    match_model.MatchStatus.cancelled: Colors.red,
  };

  final Map<match_model.MatchStatus, String> statusTexts = {
    match_model.MatchStatus.pending: 'Chưa diễn ra',
    match_model.MatchStatus.ongoing: 'Đang diễn ra',
    match_model.MatchStatus.completed: 'Đã kết thúc',
    match_model.MatchStatus.cancelled: 'Đã hủy',
  };

  @override
  void initState() {
    super.initState();

    _loadMatches();
    _loadAvailableTeams();
  }

  @override
  void dispose() {
    _stadiumController.dispose();
    _scheduledTimeController.dispose();
    _team1ScoreController.dispose();
    _team2ScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await appDioClient.get(
        '/tournament/get_matches',
        queryParameters: {
          'tournament_id': widget.tournament.id,
          'round_id': widget.round.id,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          final matchesData = data['data'] as List;
          setState(() {
            _matches =
                matchesData
                    .map((match) => match_model.TournamentMatch.fromJson(match))
                    .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Không thể tải trận đấu';
            _isLoading = false;
            _matches = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi kết nối: ${response.statusCode}';
          _isLoading = false;
          _matches = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
        _matches = [];
      });
    }
  }

  Future<void> _loadAvailableTeams() async {
    setState(() {
      _isLoadingTeams = true;
    });

    try {
      final response = await appDioClient.get(
        '/tournament/get_teams',
        queryParameters: {'tournament_id': widget.tournament.id},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          final teamsData = data['data'] as List;
          setState(() {
            _availableTeams =
                teamsData.map((team) => Team.fromJson(team)).toList();
            _isLoadingTeams = false;
          });
        } else {
          setState(() {
            _isLoadingTeams = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Không thể tải danh sách đội'),
            ),
          );
        }
      } else {
        setState(() {
          _isLoadingTeams = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingTeams = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách đội: ${e.toString()}')),
      );
    }
  }

  Future<void> _showAddMatchDialog() async {
    _stadiumController.clear();
    _scheduledTimeController.clear();
    _selectedScheduledTime = null;
    _selectedTeam1 = null;
    _selectedTeam2 = null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thêm trận đấu mới'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<Team>(
                      decoration: const InputDecoration(
                        labelText: 'Đội 1',
                        hintText: 'Chọn đội 1',
                      ),
                      value: _selectedTeam1,
                      items:
                          _availableTeams.map((team) {
                            return DropdownMenuItem<Team>(
                              value: team,
                              child: Text(team.name ?? ''),
                            );
                          }).toList(),
                      onChanged: (Team? newValue) {
                        setState(() {
                          _selectedTeam1 = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Team>(
                      decoration: const InputDecoration(
                        labelText: 'Đội 2',
                        hintText: 'Chọn đội 2',
                      ),
                      value: _selectedTeam2,
                      items:
                          _availableTeams.map((team) {
                            return DropdownMenuItem<Team>(
                              value: team,
                              child: Text(team.name ?? ''),
                            );
                          }).toList(),
                      onChanged: (Team? newValue) {
                        setState(() {
                          _selectedTeam2 = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _stadiumController,
                      decoration: const InputDecoration(
                        labelText: 'Sân vận động',
                        hintText: 'Nhập tên sân vận động',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _scheduledTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Thời gian thi đấu',
                        hintText: 'Chọn thời gian',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedScheduledTime ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _selectedScheduledTime = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              _scheduledTimeController.text = DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(_selectedScheduledTime!);
                            });
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Thêm'),
              onPressed: () {
                if (_selectedTeam1 != null &&
                    _selectedTeam2 != null &&
                    _stadiumController.text.isNotEmpty &&
                    _selectedScheduledTime != null) {
                  if (_selectedTeam1!.id == _selectedTeam2!.id) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hai đội không thể giống nhau'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                  _createMatch();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin trận đấu'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createMatch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await appDioClient.post(
        '/tournament/create_match',
        data: {
          'round_id': widget.round.id,
          'team1_id': _selectedTeam1!.id,
          'team2_id': _selectedTeam2!.id,
          'stadium': _stadiumController.text,
          'scheduled_time': _selectedScheduledTime!.toIso8601String(),
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['status']) {
          _loadMatches();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm trận đấu thành công')),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Không thể tạo trận đấu';
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessage)));
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi kết nối: ${response.statusCode}';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage)));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: ${e.toString()}';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage)));
    }
  }

  Future<void> _showUpdateMatchDialog(match_model.TournamentMatch match) async {
    _team1ScoreController.text = match.team1Score?.toString() ?? '';
    _team2ScoreController.text = match.team2Score?.toString() ?? '';
    _selectedStatus = match.matchStatus!;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cập nhật kết quả trận đấu'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (match.team1 != null && match.team2 != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                match.team1!.name ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              'VS',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                match.team2!.name ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _team1ScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Điểm đội 1',
                              hintText: 'Nhập điểm',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _team2ScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Điểm đội 2',
                              hintText: 'Nhập điểm',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<match_model.MatchStatus>(
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái trận đấu',
                      ),
                      value: _selectedStatus,
                      items:
                          match_model.MatchStatus.values.map((status) {
                            return DropdownMenuItem<match_model.MatchStatus>(
                              value: status,
                              child: Text(statusTexts[status]!),
                            );
                          }).toList(),
                      onChanged: (match_model.MatchStatus? newValue) {
                        setState(() {
                          _selectedStatus = newValue!;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cập nhật'),
              onPressed: () {
                if (_selectedStatus == match_model.MatchStatus.completed) {
                  if (_team1ScoreController.text.isEmpty ||
                      _team2ScoreController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng nhập đầy đủ điểm số cho cả hai đội',
                        ),
                      ),
                    );
                    return;
                  }
                }
                Navigator.of(context).pop();
                _updateMatch(match);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateMatch(match_model.TournamentMatch match) async {
    setState(() {
      _isLoading = true;
    });

    int? team1Score =
        _team1ScoreController.text.isNotEmpty
            ? int.tryParse(_team1ScoreController.text)
            : null;
    int? team2Score =
        _team2ScoreController.text.isNotEmpty
            ? int.tryParse(_team2ScoreController.text)
            : null;

    int? winnerId;
    if (_selectedStatus == match_model.MatchStatus.completed &&
        team1Score != null &&
        team2Score != null) {
      if (team1Score > team2Score) {
        winnerId = match.team1!.id;
      } else if (team2Score > team1Score) {
        winnerId = match.team2!.id;
      }
      // Trường hợp hoà, winnerId = null
    }

    try {
      final response = await appDioClient.put(
        '/tournament/update_match',
        data: {
          'id': match.id,
          'match_status': _selectedStatus.toString().split('.').last,
          'team1_score': team1Score,
          'team2_score': team2Score,
          'winner_id': winnerId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          _loadMatches();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật trận đấu thành công')),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Không thể cập nhật trận đấu';
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessage)));
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi kết nối: ${response.statusCode}';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage)));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: ${e.toString()}';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage)));
    }
  }

  Future<void> _showDeleteMatchDialog(match_model.TournamentMatch match) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Bạn có chắc chắn muốn xóa trận đấu này không?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMatch(match.id ?? 0);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMatch(int matchId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await appDioClient.delete(
        '/tournament/delete_match',
        data: {'id': matchId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          _loadMatches();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa trận đấu thành công')),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Không thể xóa trận đấu';
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessage)));
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi kết nối: ${response.statusCode}';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage)));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: ${e.toString()}';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage)));
    }
  }

  Future<void> _showGenerateMatchesDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tạo trận đấu tự động'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Hệ thống sẽ tự động tạo các trận đấu ngẫu nhiên cho vòng đấu này.',
                ),
                SizedBox(height: 8),
                Text(
                  'Lưu ý: Điều này sẽ xóa tất cả các trận đấu hiện tại trong vòng đấu và tạo lại ngẫu nhiên.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Tạo'),
              onPressed: () {
                Navigator.of(context).pop();
                _generateRandomMatches();
              },
            ),
          ],
        );
      },
    );
  }

  //TODO:
  Future<void> _generateRandomMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await appDioClient.post(
        '/tournament/generate_matches',
        data: {'round_id': widget.round.id},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          _loadMatches();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo trận đấu tự động thành công')),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Không thể tạo trận đấu tự động';
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessage)));
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi kết nối: ${response.statusCode}';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage)));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: ${e.toString()}';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage)));
    }
  }

  Widget _buildMatchCard(match_model.TournamentMatch match) {
    final bool hasScores = match.team1Score != null && match.team2Score != null;
    final bool isCompleted =
        match.matchStatus == match_model.MatchStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColors[match.matchStatus]!.withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusColors[match.matchStatus]!,
                        ),
                      ),
                      child: Text(
                        statusTexts[match.matchStatus]!,
                        style: TextStyle(
                          color: statusColors[match.matchStatus],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                       match.scheduledTime ?? '' ,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match.team1?.name ?? 'Đội 1',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            hasScores ? '${match.team1Score}' : '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isCompleted ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isCompleted ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasScores ? '${match.team2Score}' : '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isCompleted ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match.team2?.name ?? 'Đội 2',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (match.stadium != null && match.stadium!.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.stadium!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                if (match.matchStatus == match_model.MatchStatus.completed &&
                    match.winner != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Người chiến thắng: ${match.winner?.name}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showUpdateMatchDialog(match),
                  icon: const Icon(Icons.score, size: 18),
                  label: const Text('Cập nhật kết quả'),
                ),
                TextButton.icon(
                  onPressed: () => _showDeleteMatchDialog(match),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trận đấu - ${widget.round.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loadMatches,
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Tạo tự động',
            onPressed: _showGenerateMatchesDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Đang tải trận đấu...')
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đã xảy ra lỗi:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadMatches,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
              : _matches.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có trận đấu nào',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tạo trận đấu mới hoặc tạo tự động',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddMatchDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm trận đấu'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _showGenerateMatchesDialog,
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Tạo tự động'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadMatches,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    return _buildMatchCard(match);
                  },
                ),
              ),
      floatingActionButton:
          _matches.isNotEmpty
              ? FloatingActionButton(
                onPressed: _showAddMatchDialog,
                tooltip: 'Thêm trận đấu',
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
