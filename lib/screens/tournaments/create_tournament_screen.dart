import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../models/tournament.dart';
import '../../models/player.dart';
import '../../services/tournament_service.dart';
import '../../utils/constants.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({Key? key}) : super(key: key);

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  String _descriptionHtml = '';

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  TournamentType _tournamentType = TournamentType.singles;
  GenderRestriction _genderRestriction = GenderRestriction.mixed;
  int _numberOfTeams = 8;

  List<Player> _registeredPlayers = [];
  List<Player> _selectedPlayers = [];
  bool _isLoading = false;

  // Bước hiện tại trong quy trình tạo giải đấu
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadRegisteredPlayers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Tải danh sách người chơi đã đăng ký
  Future<void> _loadRegisteredPlayers() async {
    setState(() {
      _isLoading = true;
    });

    // Giả lập tải dữ liệu từ API
    await Future.delayed(const Duration(seconds: 1));

    // Tạo dữ liệu mẫu
    final registeredPlayers = List.generate(
      20,
      (index) => Player(
        id: index + 1,
        name: 'Người chơi ${index + 1}',
        sex: index % 2 == 0 ? 1 : 2, // 1: Nam, 2: Nữ
        phone: '090${1000000 + index}',
        email: 'player${index + 1}@example.com',
        hasPaid: index % 3 == 0,
        status:
            index % 5 == 0
                ? RegistrationStatus.pending
                : RegistrationStatus.approved,
      ),
    );

    setState(() {
      _registeredPlayers = registeredPlayers;
      _isLoading = false;
    });
  }

  void _navigateBack() {
    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      // Trong ứng dụng thực tế, bạn sẽ tải lên máy chủ và lấy URL
      // Ở đây chúng ta chỉ sử dụng tên file làm mẫu
      setState(() {
        _imageUrlController.text =
            'https://source.unsplash.com/random/800x600/?pickleball';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã chọn ảnh thành công')));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Chuyển đổi Quill Delta thành HTML
  String _convertDeltaToHtml() {
    // Đơn giản hóa, trong thực tế cần triển khai chuyển đổi chi tiết hơn
    final String plainText = _descriptionController.text;
    if (plainText.trim().isEmpty) {
      return '';
    }

    // Chuyển quill JSON về dạng HTML cơ bản
    final deltaJson = jsonEncode(_descriptionController.text);
    return '<div data-quill-delta="$deltaJson">$plainText</div>';
  }

  void _onStepContinue() async {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep++;
        });
      }
    } else if (_currentStep == 1) {
      _generateTeamsAndMatches();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      _navigateBack();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : _endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Đảm bảo ngày kết thúc không sớm hơn ngày bắt đầu
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Tạo các đội và cặp đấu ngẫu nhiên
  void _generateTeamsAndMatches() {
    final tournamentService = TournamentService();

    try {
      // Cho phép tạo giải đấu khi chưa đủ player
      List<Team> teams = [];
      if (_selectedPlayers.isNotEmpty) {
        teams = tournamentService.createTeamsFromPlayers(
          _selectedPlayers,
          _tournamentType,
          _numberOfTeams > _selectedPlayers.length
              ? (_selectedPlayers.length ~/
                  (_tournamentType == TournamentType.singles ? 1 : 2))
              : _numberOfTeams,
        );
      }

      final tournament = Tournament(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        name: _nameController.text,
        startDate: _startDate,
        endDate: _endDate,
        type: _tournamentType,
        genderRestriction: _genderRestriction,
        numberOfTeams: _numberOfTeams,
        teams: teams,
        status: TournamentStatus.preparing,
        imageUrl:
            _imageUrlController.text.isNotEmpty
                ? _imageUrlController.text
                : null,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
      );

      List<Match> matches = [];
      if (teams.isNotEmpty) {
        matches = tournamentService.generateRandomMatches(tournament, teams);
      }

      // Hiển thị màn hình xác nhận cặp đấu
      _showTournamentPreview(tournament, teams, matches);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  // Hiển thị preview trước khi tạo giải đấu
  void _showTournamentPreview(
    Tournament tournament,
    List<Team> teams,
    List<Match> matches,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận tạo giải đấu'),
            content: SizedBox(
              width: 400,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên giải đấu: ${tournament.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thời gian: ${_formatDate(tournament.startDate)} - ${_formatDate(tournament.endDate)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loại giải: ${tournament.type == TournamentType.singles ? 'Đấu đơn' : 'Đấu đôi'}',
                    ),
                    const SizedBox(height: 8),
                    Text('Số đội dự kiến: ${tournament.numberOfTeams}'),
                    const SizedBox(height: 8),
                    Text('Số đội đã đăng ký: ${teams.length}'),
                    const SizedBox(height: 16),

                    if (tournament.imageUrl != null) ...[
                      const Text(
                        'Ảnh giải đấu:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Image.network(
                        tournament.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (teams.isNotEmpty) ...[
                      const Text(
                        'Các đội tham gia:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          return ListTile(
                            title: Text(team.name),
                            subtitle: Text(
                              team.players.map((p) => p.name).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: CircleAvatar(child: Text('${index + 1}')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (matches.isNotEmpty) ...[
                      const Text(
                        'Cặp đấu vòng đầu tiên:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      match.team1.name,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Text(
                                    'VS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      match.team2.name,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      const Text(
                        'Chưa có cặp đấu nào. Các cặp đấu sẽ được tạo khi có đủ người chơi đăng ký.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
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
                  // Lưu giải đấu và quay lại màn hình chính
                  // Trong thực tế, gọi API để lưu
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã tạo giải đấu thành công')),
                  );
                },
                child: const Text('Tạo giải đấu'),
              ),
            ],
          ),
    );
  }

  // Chọn người chơi cho giải đấu
  bool _isPlayerSelected(Player player) {
    return _selectedPlayers.any((p) => p.id == player.id);
  }

  void _togglePlayerSelection(Player player) {
    setState(() {
      if (_isPlayerSelected(player)) {
        _selectedPlayers.removeWhere((p) => p.id == player.id);
      } else {
        _selectedPlayers.add(player);
      }
    });
  }

  Widget _buildGenderRestrictionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính tham gia:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        RadioListTile<GenderRestriction>(
          title: const Text('Nam'),
          value: GenderRestriction.male,
          groupValue: _genderRestriction,
          onChanged: (value) {
            setState(() {
              _genderRestriction = value!;
              // Lọc lại người chơi đã chọn theo giới hạn mới
              _selectedPlayers =
                  _selectedPlayers.where((p) => p.sex == 1).toList();
            });
          },
        ),
        RadioListTile<GenderRestriction>(
          title: const Text('Nữ'),
          value: GenderRestriction.female,
          groupValue: _genderRestriction,
          onChanged: (value) {
            setState(() {
              _genderRestriction = value!;
              // Lọc lại người chơi đã chọn theo giới hạn mới
              _selectedPlayers =
                  _selectedPlayers.where((p) => p.sex == 2).toList();
            });
          },
        ),
        RadioListTile<GenderRestriction>(
          title: const Text('Nam & Nữ'),
          value: GenderRestriction.mixed,
          groupValue: _genderRestriction,
          onChanged: (value) {
            setState(() {
              _genderRestriction = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTournamentInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên giải đấu',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập tên giải đấu';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Ảnh giải đấu',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Chọn ảnh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_imageUrlController.text.isNotEmpty) ...[
            const Text('Xem trước ảnh:'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageUrlController.text,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(child: Text('Không thể tải ảnh')),
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Mô tả giải đấu:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Nhập mô tả chi tiết về giải đấu...',
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context, true),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Ngày bắt đầu',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(_formatDate(_startDate)),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context, false),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Ngày kết thúc',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(_formatDate(_endDate)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loại giải đấu:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          RadioListTile<TournamentType>(
            title: const Text('Đấu đơn'),
            value: TournamentType.singles,
            groupValue: _tournamentType,
            onChanged: (value) {
              setState(() {
                _tournamentType = value!;
              });
            },
          ),
          RadioListTile<TournamentType>(
            title: const Text('Đấu đôi'),
            value: TournamentType.doubles,
            groupValue: _tournamentType,
            onChanged: (value) {
              setState(() {
                _tournamentType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildGenderRestrictionSelector(),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Số đội tham gia:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _numberOfTeams.toDouble(),
                min: 4,
                max: 32,
                divisions: 7,
                label: _numberOfTeams.toString(),
                onChanged: (value) {
                  setState(() {
                    _numberOfTeams = value.toInt();
                  });
                },
              ),
              Center(
                child: Text(
                  '$_numberOfTeams đội',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bước 2: Chọn người chơi
  Widget _buildSelectPlayersStep() {
    final filteredPlayers =
        _registeredPlayers
            .where((player) {
              // Lọc theo giới hạn giới tính
              if (_genderRestriction == GenderRestriction.male) {
                return player.sex == 1;
              } else if (_genderRestriction == GenderRestriction.female) {
                return player.sex == 2;
              }
              return true;
            })
            .where((player) => player.status == RegistrationStatus.approved)
            .toList();

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Người chơi đã chọn',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selectedPlayers.map((player) {
                        return Chip(
                          label: Text(player.name),
                          avatar: CircleAvatar(
                            backgroundColor:
                                player.sex == 1 ? Colors.blue : Colors.pink,
                            child: Text(
                              player.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _togglePlayerSelection(player),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: filteredPlayers.length,
            itemBuilder: (context, index) {
              final player = filteredPlayers[index];
              final isSelected = _isPlayerSelected(player);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) => _togglePlayerSelection(player),
                title: Text(player.name),
                subtitle: Text(player.email ?? ''),
                secondary: CircleAvatar(
                  backgroundColor:
                      player.sex == 1 ? Colors.blue[100] : Colors.pink[100],
                  child: Text(player.name.substring(0, 1).toUpperCase()),
                ),
                activeColor: Theme.of(context).primaryColor,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Có thể tạo giải đấu với số lượng người chơi ít hơn dự kiến. Các trận đấu sẽ được cập nhật khi có thêm người tham gia.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo giải đấu mới')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stepper(
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                            _currentStep == 1 ? 'Hoàn tất' : 'Tiếp theo',
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Quay lại'),
                        ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Thông tin'),
                    content: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(UIConstants.defaultPadding),
                      child: _buildTournamentInfoStep(),
                    ),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: const Text('Người chơi'),
                    content: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(UIConstants.defaultPadding),
                      height: 500,
                      child: _buildSelectPlayersStep(),
                    ),
                    isActive: _currentStep >= 1,
                  ),
                ],
              ),
    );
  }
}
