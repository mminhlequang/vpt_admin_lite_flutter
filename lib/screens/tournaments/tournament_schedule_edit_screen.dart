import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:internal_core/setup/app_utils.dart';
import 'package:intl/intl.dart';
import '../../models/tournament.dart';
import '../../models/round.dart';
import '../../models/match.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';
import '../../widgets/common/loading_overlay.dart';

class TournamentScheduleEditScreen extends StatefulWidget {
  final Tournament tournament;
  final Function(Tournament) onSave;

  const TournamentScheduleEditScreen({
    super.key,
    required this.tournament,
    required this.onSave,
  });

  @override
  State<TournamentScheduleEditScreen> createState() =>
      _TournamentScheduleEditScreenState();
}

class _TournamentScheduleEditScreenState
    extends State<TournamentScheduleEditScreen> {
  List<Round> _rounds = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRounds();
  }

  // Tải danh sách vòng đấu từ server
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
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi kết nối: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API để lưu dữ liệu các vòng đấu và trận đấu
      for (final round in _rounds) {
        // Trong thực tế, bạn sẽ gọi API để cập nhật từng vòng đấu
        await appDioClient.post(
          '/tournament/update_round',
          data: {
            'tournament_id': widget.tournament.id,
            'round_id': round.id,
            'matches': round.matches.map((m) => m.toJson()).toList(),
          },
        );
      }

      // Cập nhật giải đấu với dữ liệu mới
      final updatedTournament = widget.tournament;
      // Cập nhật danh sách rounds
      updatedTournament.rounds = _rounds;

      setState(() {
        _isLoading = false;
      });

      // Gọi callback để truyền dữ liệu về màn hình cha
      widget.onSave(updatedTournament);

      // Quay về màn hình trước
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi lưu dữ liệu: ${e.toString()}';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage)));
    }
  }

  Future<void> _showEditMatchDialog(
    Match match,
    Round round,
    int matchIndex,
  ) async {
    final formKey = GlobalKey<FormState>();
    final DateTime scheduledTime = match.scheduledTime;

    DateTime selectedDate = scheduledTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(scheduledTime);

    final TextEditingController dateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(scheduledTime),
    );
    final TextEditingController timeController = TextEditingController(
      text: DateFormat('HH:mm').format(scheduledTime),
    );
    final TextEditingController stadiumController = TextEditingController(
      text: match.stadium ?? '',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chỉnh sửa lịch thi đấu'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vòng đấu: ${round.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.team1?.name ?? 'TBD',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('VS'),
                        ),
                        Expanded(
                          child: Text(
                            match.team2?.name ?? 'TBD',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Ngày thi đấu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate:
                              string2DateTime(
                                widget.tournament.startDate ?? '',
                                format: 'dd-MM-yyyy',
                              ) ??
                              DateTime.now(),
                          lastDate:
                              string2DateTime(
                                widget.tournament.endDate ?? '',
                                format: 'dd-MM-yyyy',
                              ) ??
                              DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            dateController.text = DateFormat(
                              'dd-MM-yyyy',
                            ).format(selectedDate);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn ngày thi đấu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Giờ thi đấu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                            timeController.text = DateFormat(
                              'HH:mm',
                            ).format(selectedDate);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn giờ thi đấu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: stadiumController,
                      decoration: const InputDecoration(
                        labelText: 'Sân thi đấu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập sân thi đấu';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    // Cập nhật thông tin trận đấu
                    final updatedMatch = Match(
                      id: match.id,
                      roundId: match.roundId,
                      team1Id: match.team1Id,
                      team2Id: match.team2Id,
                      stadium: stadiumController.text,
                      scheduledTime: selectedDate,
                      matchStatus: match.matchStatus,
                      team1Score: match.team1Score,
                      team2Score: match.team2Score,
                      winnerId: match.winnerId,
                      team1: match.team1,
                      team2: match.team2,
                    );

                    setState(() {
                      final roundIndex = _rounds.indexOf(round);
                      if (roundIndex != -1) {
                        _rounds[roundIndex].matches[matchIndex] = updatedMatch;
                      }
                    });

                    Navigator.pop(context);
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Chỉnh sửa lịch thi đấu'),
            actions: [
              IconButton(
                onPressed: _save,
                icon: const Icon(Icons.save),
                tooltip: 'Lưu lịch thi đấu',
              ),
            ],
          ),
          body: _buildBody(),
        ),
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
      );
    }

    if (_rounds.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRoundsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_tennis, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có vòng đấu nào được tạo',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Chuyển hướng đến màn hình quản lý vòng đấu
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Vui lòng tạo vòng đấu trước khi chỉnh sửa lịch thi đấu',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tạo vòng đấu mới'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final round in _rounds) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            round.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd-MM-yyyy').format(round.startTime),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (round.matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Chưa có trận đấu nào trong vòng này',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: round.matches.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final match = round.matches[index];
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  match.team1?.name ?? 'TBD',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        match.winnerId == match.team1Id
                                            ? Colors.green
                                            : null,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child:
                                    match.matchStatus == MatchStatus.completed
                                        ? Text(
                                          '${match.team1Score ?? 0} - ${match.team2Score ?? 0}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                        : const Text(
                                          'VS',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                              ),
                              Expanded(
                                child: Text(
                                  match.team2?.name ?? 'TBD',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        match.winnerId == match.team2Id
                                            ? Colors.green
                                            : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'dd-MM-yyyy',
                                    ).format(match.scheduledTime),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'HH:mm',
                                    ).format(match.scheduledTime),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    match.stadium ?? 'Chưa có sân',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.flag,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    match.matchStatus == MatchStatus.pending
                                        ? 'Chưa diễn ra'
                                        : match.matchStatus ==
                                            MatchStatus.ongoing
                                        ? 'Đang diễn ra'
                                        : 'Đã kết thúc',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing:
                              match.matchStatus == MatchStatus.completed
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                  : IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        () => _showEditMatchDialog(
                                          match,
                                          round,
                                          index,
                                        ),
                                  ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Lưu lịch thi đấu'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
