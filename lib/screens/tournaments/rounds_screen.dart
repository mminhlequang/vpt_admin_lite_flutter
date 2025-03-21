import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/round.dart';
import '../../models/tournament.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_indicator.dart';
import 'matches_screen.dart';

class RoundsScreen extends StatefulWidget {
  final Tournament tournament;

  const RoundsScreen({Key? key, required this.tournament}) : super(key: key);

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
    _roundNameController.text = round.name;
    _selectedStartTime = round.startTime;
    _startTimeController.text = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(round.startTime);

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
                  _updateRound(round.id);
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
                _deleteRound(round.id);
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
                              round.name,
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
                                      'Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(round.startTime)}',
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
                                      'Số trận: ${round.matches.length}',
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
