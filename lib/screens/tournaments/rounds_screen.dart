import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:vpt_admin_lite_flutter/models/models.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/round.dart';
import '../../models/tournament.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_indicator.dart';
import 'matches_screen.dart';

class RoundsScreen extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback fetchTournament;

  const RoundsScreen({
    Key? key,
    required this.tournament,
    required this.fetchTournament,
  }) : super(key: key);

  @override
  _RoundsScreenState createState() => _RoundsScreenState();
}

class _RoundsScreenState extends State<RoundsScreen> {
  final TextEditingController _roundNameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();

  List<Round> _rounds = [];
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime? _selectedStartTime;

  @override
  void initState() {
    super.initState();

    _loadRounds();
  }

  @override
  void dispose() {
    _roundNameController.dispose();
    _startTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadRounds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await appDioClient.get(
        '/tournament/get_rounds',
        queryParameters: {'tournament_id': widget.tournament.id},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          final roundsData = data['data'] as List;
          setState(() {
            _rounds = roundsData.map((round) => Round.fromJson(round)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Không thể tải vòng đấu';
            _isLoading = false;
            _rounds = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi kết nối: ${response.statusCode}';
          _isLoading = false;
          _rounds = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
        _rounds = [];
      });
    }
  }

  _generateRoundAutomatically() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Kiểm tra xem đã đủ số đội chưa
      if ((widget.tournament.teams?.length ?? 0) <
          (widget.tournament.numberOfTeam ?? 0)) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Chưa đủ số đội tham gia để tạo vòng đấu';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage)));
        return;
      }

      // Xác định xem đang tạo vòng đầu tiên hay vòng tiếp theo
      bool isFirstRound = _rounds.isEmpty;

      if (isFirstRound) {
        // Tạo vòng đấu đầu tiên
        await _createFirstRound();
      } else {
        // Kiểm tra vòng đấu cuối cùng đã hoàn thành chưa
        Round lastRound = _rounds.last;
        bool canCreateNextRound = await _checkCanCreateNextRound(lastRound);

        if (canCreateNextRound) {
          await _createNextRound(lastRound);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Vòng đấu hiện tại chưa hoàn thành hoặc không đủ đội thắng để tạo vòng tiếp theo';
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessage)));
        }
      }

      _loadRounds(); // Tải lại danh sách vòng đấu sau khi cập nhật

      widget.fetchTournament();
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

  Future<void> _createFirstRound() async {
    // Lấy danh sách đội tham gia
    final teams = widget.tournament.teams ?? [];
    if (teams.isEmpty) return;

    // Tạo vòng đấu đầu tiên
    final roundName = _determineRoundName(
      widget.tournament.numberOfTeam ?? teams.length,
    );
    final response = await appDioClient.post(
      '/tournament/create_round',
      data: {
        'tournament_id': widget.tournament.id,
        'name': roundName,
        'start_time': DateTime.now()
            .add(const Duration(days: 7))
            .toString()
            .substring(0, 16),
      },
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Không thể tạo vòng đấu: ${response.statusCode}');
    }

    final roundData = response.data;
    if (!roundData['status']) {
      throw Exception(roundData['message'] ?? 'Không thể tạo vòng đấu');
    }

    // Lấy ID của vòng đấu mới tạo
    final roundId = roundData['data']['id'];

    // Tạo các trận đấu cho vòng này
    await _createMatchesForFirstRound(roundId, teams);
  }

  String _determineRoundName(int numberOfTeams) {
    if (numberOfTeams <= 2) return 'Chung kết';
    if (numberOfTeams <= 4) return 'Bán kết';
    if (numberOfTeams <= 8) return 'Tứ kết';
    if (numberOfTeams <= 16) return 'Vòng 1/8';
    if (numberOfTeams <= 32) return 'Vòng 1/16';
    if (numberOfTeams <= 64) return 'Vòng 1/32';
    return 'Vòng loại';
  }

  Future<void> _createMatchesForFirstRound(
    int roundId,
    List<dynamic> teams,
  ) async {
    // Xáo trộn danh sách đội ngẫu nhiên để tạo cặp đấu
    teams.shuffle();

    for (int i = 0; i < teams.length; i += 2) {
      if (i + 1 >= teams.length) break; // Bỏ qua nếu số lẻ đội

      final team1 = teams[i];
      final team2 = teams[i + 1];

      // Tạo trận đấu cho cặp đội này
      final scheduledTime = DateTime.now().add(Duration(days: 7, hours: i));
      await appDioClient.post(
        '/tournament/create_match',
        data: {
          'round_id': roundId,
          'team1_id': team1.id,
          'team2_id': team2.id,
          'stadium': 'Sân ${i ~/ 2 + 1}',
          'match_status': 'pending',
          'scheduled_time': scheduledTime.toString().substring(0, 16),
        },
      );
    }
  }

  Future<bool> _checkCanCreateNextRound(Round lastRound) async {
    // Kiểm tra xem tất cả các trận trong vòng cuối cùng đã hoàn thành chưa
    if (lastRound.matches == null || lastRound.matches!.isEmpty) {
      return false;
    }

    bool allCompleted = true;
    final winningTeamIds = <int>[];

    for (var match in lastRound.matches!) {
      if (match.matchStatus != MatchStatus.completed) {
        allCompleted = false;
        break;
      }

      // Thu thập ID của các đội thắng
      if (match.winner != null) {
        winningTeamIds.add(match.winner!.id!);
      }
    }

    // Cần ít nhất 2 đội thắng để tạo vòng tiếp theo
    return allCompleted && winningTeamIds.length >= 2;
  }

  Future<void> _createNextRound(Round lastRound) async {
    // Thu thập ID của các đội thắng từ vòng trước
    final winningTeamIds = <int>[];

    for (var match in lastRound.matches!) {
      if (match.winner != null) {
        winningTeamIds.add(match.winner!.id!);
      }
    }

    // Tạo vòng đấu mới
    final roundName = _determineRoundName(winningTeamIds.length);
    final response = await appDioClient.post(
      '/tournament/create_round',
      data: {
        'tournament_id': widget.tournament.id,
        'name': roundName,
        'start_time': DateTime.now()
            .add(const Duration(days: 7))
            .toString()
            .substring(0, 16),
      },
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Không thể tạo vòng đấu: ${response.statusCode}');
    }

    final roundData = response.data;
    if (!roundData['status']) {
      throw Exception(roundData['message'] ?? 'Không thể tạo vòng đấu');
    }

    // Lấy ID của vòng đấu mới tạo
    final roundId = roundData['data']['id'];

    // Tạo các trận đấu cho vòng này dựa trên các đội thắng
    await _createMatchesForNextRound(roundId, winningTeamIds);
  }

  Future<void> _createMatchesForNextRound(
    int roundId,
    List<int> winningTeamIds,
  ) async {
    // Xáo trộn danh sách đội thắng để tạo cặp đấu
    winningTeamIds.shuffle();

    for (int i = 0; i < winningTeamIds.length; i += 2) {
      if (i + 1 >= winningTeamIds.length) break; // Bỏ qua nếu số lẻ đội

      final team1Id = winningTeamIds[i];
      final team2Id = winningTeamIds[i + 1];

      // Tạo trận đấu cho cặp đội này
      final scheduledTime = DateTime.now().add(Duration(days: 7, hours: i));
      await appDioClient.post(
        '/tournament/create_match',
        data: {
          'round_id': roundId,
          'team1_id': team1Id,
          'team2_id': team2Id,
          'stadium': 'Sân ${i ~/ 2 + 1}',
          'match_status': 'pending',
          'scheduled_time': scheduledTime.toString().substring(0, 16),
        },
      );
    }
  }

  Future<void> _showAddRoundDialog() async {
    _roundNameController.clear();
    _startTimeController.clear();
    _selectedStartTime = null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thêm vòng đấu mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _roundNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên vòng đấu',
                    hintText: 'Vòng loại, Tứ kết, Bán kết, Chung kết...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian bắt đầu',
                    hintText: 'Chọn ngày bắt đầu',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedStartTime ?? DateTime.now(),
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
                          _selectedStartTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          _startTimeController.text = DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(_selectedStartTime!);
                        });
                      }
                    }
                  },
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
              child: const Text('Thêm'),
              onPressed: () {
                if (_roundNameController.text.isNotEmpty &&
                    _selectedStartTime != null) {
                  Navigator.of(context).pop();
                  _createRound();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin vòng đấu'),
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

  Future<void> _createRound() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await appDioClient.post(
        '/tournament/create_round',
        data: {
          'tournament_id': widget.tournament.id,
          'name': _roundNameController.text,
          'start_time': DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_selectedStartTime!),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          _loadRounds();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm vòng đấu thành công')),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Không thể tạo vòng đấu';
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

  Future<void> _showEditRoundDialog(Round round) async {
    _roundNameController.text = round.name ?? '';
    _selectedStartTime =
        round.startTime != null ? DateTime.parse(round.startTime!) : null;
    _startTimeController.text =
        round.startTime != null
            ? DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(DateTime.parse(round.startTime!))
            : '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa vòng đấu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _roundNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên vòng đấu',
                    hintText: 'Vòng loại, Tứ kết, Bán kết, Chung kết...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian bắt đầu',
                    hintText: 'Chọn ngày bắt đầu',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedStartTime ?? DateTime.now(),
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
                          _selectedStartTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          _startTimeController.text = DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(_selectedStartTime!);
                        });
                      }
                    }
                  },
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
              child: const Text('Lưu'),
              onPressed: () {
                if (_roundNameController.text.isNotEmpty &&
                    _selectedStartTime != null) {
                  Navigator.of(context).pop();
                  _updateRound(round.id ?? 0);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin vòng đấu'),
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

  Future<void> _updateRound(int roundId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await appDioClient.post(
        '/tournament/update_round',
        data: {
          'id': roundId,
          'name': _roundNameController.text,
          'tournament_id': widget.tournament.id,
          'start_time': DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_selectedStartTime!),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          _loadRounds();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật vòng đấu thành công')),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Không thể cập nhật vòng đấu';
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

  Future<void> _showDeleteRoundDialog(Round round) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Bạn có chắc chắn muốn xóa vòng đấu "${round.name}" không?',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lưu ý: Tất cả trận đấu thuộc vòng này cũng sẽ bị xóa.',
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
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRound(round.id ?? 0);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRound(int roundId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await appDioClient.delete(
        '/tournament/delete_round',
        data: {'id': roundId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          _loadRounds();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa vòng đấu thành công')),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Không thể xóa vòng đấu';
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

  void _navigateToMatchesScreen(Round round) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                MatchesScreen(tournament: widget.tournament, round: round),
      ),
    ).then((_) => _loadRounds());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vòng đấu - ${widget.tournament.name}')),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Đang tải vòng đấu...')
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
                      onPressed: _loadRounds,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
              : _rounds.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Số đội đã đăng ký: ${widget.tournament.teams?.length ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                        Text("   /   "),
                        Text(
                          'Số đội cần có: ${widget.tournament.numberOfTeam ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Icon(
                      Icons.sports_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có vòng đấu nào',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thêm vòng đấu mới để bắt đầu',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddRoundDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm vòng đấu mới'),
                    ),
                    if ((widget.tournament.teams?.length ?? 0) >=
                        (widget.tournament.numberOfTeam ?? 0)) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _generateRoundAutomatically,
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo tự động'),
                      ),
                    ],
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadRounds,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _rounds.length,
                  itemBuilder: (context, index) {
                    final round = _rounds[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              round.name ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Bắt đầu: ${round.startTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(round.startTime!)) : ''}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.sports_soccer,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Số trận: ${round.matches?.length ?? 0}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showEditRoundDialog(round),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Sửa'),
                                ),
                                TextButton.icon(
                                  onPressed:
                                      () => _showDeleteRoundDialog(round),
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _navigateToMatchesScreen(round),
                                  icon: const Icon(
                                    Icons.sports_soccer,
                                    size: 18,
                                  ),
                                  label: const Text('Quản lý trận đấu'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton:
          _rounds.isNotEmpty
              ? FloatingActionButton(
                onPressed: _showAddRoundDialog,
                tooltip: 'Thêm vòng đấu',
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
