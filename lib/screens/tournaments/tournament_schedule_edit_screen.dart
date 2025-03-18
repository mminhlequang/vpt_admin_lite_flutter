import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tournament.dart';
import '../../utils/constants.dart';
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
  late List<Match> _matches;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tạo bản sao của danh sách trận đấu để tránh thay đổi trực tiếp trên dữ liệu ban đầu
    _matches = List.from(widget.tournament.matches);
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    // Trong ứng dụng thực tế, cần gọi API để lưu dữ liệu
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Giả lập thời gian gọi API

    // Tạo đối tượng Tournament mới với danh sách trận đấu đã cập nhật
    final updatedTournament = widget.tournament.copyWith(matches: _matches);

    setState(() {
      _isLoading = false;
    });

    // Gọi callback để truyền dữ liệu về màn hình cha
    widget.onSave(updatedTournament);

    // Quay về màn hình trước
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showEditMatchDialog(Match match, int index) async {
    final formKey = GlobalKey<FormState>();
    final DateTime scheduledTime = match.scheduledTime ?? DateTime.now();

    DateTime selectedDate = scheduledTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(scheduledTime);

    final TextEditingController dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(scheduledTime),
    );
    final TextEditingController timeController = TextEditingController(
      text: DateFormat('HH:mm').format(scheduledTime),
    );
    final TextEditingController courtController = TextEditingController(
      text: match.courtNumber ?? '',
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.team1.name,
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
                            match.team2.name,
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
                          firstDate: widget.tournament.startDate,
                          lastDate: widget.tournament.endDate,
                        );
                        if (pickedDate != null) {
                          selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          dateController.text = DateFormat(
                            'dd/MM/yyyy',
                          ).format(selectedDate);
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
                      controller: courtController,
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
                      team1: match.team1,
                      team2: match.team2,
                      score1: match.score1,
                      score2: match.score2,
                      status: match.status,
                      scheduledTime: selectedDate,
                      courtNumber: courtController.text,
                      winner: match.winner,
                    );

                    setState(() {
                      _matches[index] = updatedMatch;
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
    // Lọc trận đấu sắp tới (chưa diễn ra hoặc đang diễn ra)
    final upcomingMatches =
        _matches
            .where(
              (m) =>
                  m.status == MatchStatus.scheduled ||
                  m.status == MatchStatus.ongoing,
            )
            .toList();

    // Lọc trận đấu đã hoàn thành
    final completedMatches =
        _matches.where((m) => m.status == MatchStatus.completed).toList();

    return upcomingMatches.isEmpty && completedMatches.isEmpty
        ? _buildEmptyState()
        : _buildMatchList(upcomingMatches, completedMatches);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_tennis, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có trận đấu nào được lên lịch',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Trong ứng dụng thực tế, cần triển khai chức năng thêm trận đấu mới
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chức năng thêm trận đấu mới sẽ được triển khai sau',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm trận đấu mới'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(
    List<Match> upcomingMatches,
    List<Match> completedMatches,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcomingMatches.isNotEmpty) ...[
            const Text(
              'Trận đấu sắp tới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingMatches.length,
              itemBuilder: (context, index) {
                final match = upcomingMatches[index];
                final matchIndex = _matches.indexOf(match);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.team1.name,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            match.team2.name,
                            textAlign: TextAlign.left,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                'dd/MM/yyyy',
                              ).format(match.scheduledTime ?? DateTime.now()),
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
                              ).format(match.scheduledTime ?? DateTime.now()),
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
                              match.courtNumber ?? 'Chưa có sân',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.flag, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              match.status == MatchStatus.scheduled
                                  ? 'Chưa diễn ra'
                                  : 'Đang diễn ra',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditMatchDialog(match, matchIndex),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          if (completedMatches.isNotEmpty) ...[
            const Text(
              'Trận đấu đã hoàn thành',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedMatches.length,
              itemBuilder: (context, index) {
                final match = completedMatches[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.team1.name,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  match.winner?.id == match.team1.id
                                      ? Colors.green
                                      : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${match.score1} - ${match.score2}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            match.team2.name,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  match.winner?.id == match.team2.id
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
                                'dd/MM/yyyy',
                              ).format(match.scheduledTime ?? DateTime.now()),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              match.courtNumber ?? 'Không có sân',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Đã hoàn thành thì không cho phép chỉnh sửa
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                );
              },
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
