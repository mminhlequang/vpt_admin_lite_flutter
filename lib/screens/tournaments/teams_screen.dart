import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vpt_admin_lite_flutter/models/category.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/player.dart';
import '../../models/team.dart';
import '../../models/tour_package.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_indicator.dart';

class TeamsScreen extends StatefulWidget {
  final int tournamentId;
  final String? tournamentName;

  const TeamsScreen({Key? key, required this.tournamentId, this.tournamentName})
    : super(key: key);

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  bool _isLoading = true;
  bool _isLoadingPackages = true;
  bool _isLoadingPlayers = true;
  List<Team> _teams = [];
  List<TourPackage> _packages = [];
  List<Player> _players = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadTeams(), _loadPackages(), _loadPlayers()]);
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoadingPlayers = true;
    });

    try {
      final response = await appDioClient.get('/player');

      final List<Player> players =
          (response.data['data'] as List)
              .map((playerJson) => Player.fromJson(playerJson))
              .toList();

      setState(() {
        _players = players;
        _isLoadingPlayers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlayers = false;
      });
    }
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await appDioClient.get(
        '/tournament/get_teams',
        queryParameters: {'tournament_id': widget.tournamentId},
      );

      final List<Team> teams =
          (response.data['data'] as List)
              .map((teamJson) => Team.fromJson(teamJson))
              .toList();

      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách đội: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoadingPackages = true;
    });

    try {
      final response = await appDioClient.get(
        '/tournament/get_packages',
        queryParameters: {'tournament_id': widget.tournamentId},
      );

      final List<dynamic> packagesData = response.data['data'] as List;
      final packages =
          packagesData
              .map((packageJson) => TourPackage.fromJson(packageJson))
              .toList();

      setState(() {
        _packages = packages;
        _isLoadingPackages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPackages = false;
      });
    }
  }

  String _getRegistrationStatusText(int status) {
    switch (status) {
      case 0:
        return 'Chờ xác nhận';
      case 1:
        return 'Đã xác nhận';
      case 2:
        return 'Từ chối';
      default:
        return 'Không xác định';
    }
  }

  Color _getRegistrationStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(int status) {
    switch (status) {
      case 0:
        return 'Chưa thanh toán';
      case 1:
        return 'Đang xử lý';
      case 2:
        return 'Đã thanh toán';
      case 3:
        return 'Thanh toán thất bại';
      default:
        return 'Không xác định';
    }
  }

  Color _getPaymentStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPackageName(int packageId) {
    final package = _packages.firstWhere(
      (p) => p.id == packageId,
      orElse:
          () => TourPackage(
            id: -1,
            name: 'Không tìm thấy',
            category: Category(
              id: 0,
              name: 'Không tìm thấy',
              numberOfPlayer: 0,
              sex: 0,
            ),
            tourId: 0,
            price: 0,
          ),
    );
    return package.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_packages.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng thêm gói đăng ký trước')),
            );
            return;
          }
          if (_players.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không có người chơi nào trong hệ thống'),
              ),
            );
            return;
          }
          _showAddTeamDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isLoadingPackages || _isLoadingPlayers) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTeams, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return const Center(child: Text('Chưa có đội nào tham gia'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      itemCount: _teams.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final team = _teams[index];
        return Card(
          elevation: 2,
          child: ListTile(
            title: Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (team.packageId != null)
                  Text('Gói đăng ký: ${_getPackageName(team.packageId!)}'),
                if (team.registrationDate != null)
                  Text('Ngày đăng ký: ${_formatDate(team.registrationDate!)}'),
                Text(
                  'Trạng thái đăng ký: ${_getRegistrationStatusText(team.registrationStatus)}',
                  style: TextStyle(
                    color: _getRegistrationStatusColor(team.registrationStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Trạng thái thanh toán: ${_getPaymentStatusText(team.paymentStatus)}',
                  style: TextStyle(
                    color: _getPaymentStatusColor(team.paymentStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _showEditTeamDialog(context, team);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteTeamDialog(context, team);
                  },
                ),
              ],
            ),
            onTap: () {
              _showTeamDetailsDialog(context, team);
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getPlayerNameById(int playerId) {
    final player = _players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => Player(id: -1, name: 'Không tìm thấy'),
    );
    return player.name;
  }

  void _showTeamDetailsDialog(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(team.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('ID', team.id),
                if (team.packageId != null)
                  _buildInfoRow(
                    'Gói đăng ký',
                    _getPackageName(team.packageId!),
                  ),
                if (team.registrationDate != null)
                  _buildInfoRow(
                    'Ngày đăng ký',
                    _formatDate(team.registrationDate!),
                  ),
                _buildInfoRow(
                  'Trạng thái đăng ký',
                  _getRegistrationStatusText(team.registrationStatus),
                  textColor: _getRegistrationStatusColor(
                    team.registrationStatus,
                  ),
                ),
                _buildInfoRow(
                  'Trạng thái thanh toán',
                  _getPaymentStatusText(team.paymentStatus),
                  textColor: _getPaymentStatusColor(team.paymentStatus),
                ),
                if (team.paymentCode != null)
                  _buildInfoRow('Mã thanh toán', team.paymentCode!),
                if (team.playerId1 != null)
                  _buildInfoRow(
                    'Người chơi 1',
                    _getPlayerNameById(team.playerId1!),
                  ),
                if (team.playerId2 != null)
                  _buildInfoRow(
                    'Người chơi 2',
                    _getPlayerNameById(team.playerId2!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(color: textColor))),
        ],
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    int paymentStatus = 0;
    int registrationStatus = 0;
    String? paymentCode;
    int? playerId1;
    int? playerId2;
    int packageId = _packages.first.id;
    DateTime registrationDate = DateTime.now();

    // Xác định số lượng người chơi của gói đăng ký đầu tiên
    bool isSinglePlayer = _packages.first.category?.numberOfPlayer == 1;

    // Hàm cập nhật lại gói đăng ký và số lượng người chơi
    void updatePackage(int newPackageId) {
      final selectedPackage = _packages.firstWhere((p) => p.id == newPackageId);
      isSinglePlayer = selectedPackage.category?.numberOfPlayer == 1;
      // Nếu chuyển từ gói đôi sang gói đơn, reset người chơi 2
      if (isSinglePlayer) {
        playerId2 = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm đội mới'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hiển thị trường tên đội nếu không phải gói đơn
                      if (!isSinglePlayer)
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Tên đội',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập tên đội';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            name = value!;
                          },
                        ),
                      if (!isSinglePlayer) const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Gói đăng ký',
                          border: OutlineInputBorder(),
                        ),
                        value: packageId,
                        items:
                            _packages.map((package) {
                              return DropdownMenuItem<int>(
                                value: package.id,
                                child: Text(package.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              packageId = value;
                              updatePackage(value);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(
                          labelText: 'Người chơi 1',
                          border: OutlineInputBorder(),
                        ),
                        value: playerId1,
                        items:
                            _players.map((player) {
                              return DropdownMenuItem<int?>(
                                value: player.id,
                                child: Text(player.name),
                              );
                            }).toList(),
                        validator: (value) {
                          if (value == null) {
                            return 'Vui lòng chọn người chơi 1';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            playerId1 = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Hiển thị trường người chơi 2 nếu không phải gói đơn
                      if (!isSinglePlayer)
                        DropdownButtonFormField<int?>(
                          decoration: const InputDecoration(
                            labelText: 'Người chơi 2',
                            border: OutlineInputBorder(),
                          ),
                          value: playerId2,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('-- Không chọn --'),
                            ),
                            ..._players.map((player) {
                              return DropdownMenuItem<int?>(
                                value: player.id,
                                child: Text(player.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              playerId2 = value;
                            });
                          },
                        ),
                      if (!isSinglePlayer) const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái đăng ký',
                          border: OutlineInputBorder(),
                        ),
                        value: registrationStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Chờ xác nhận'),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Đã xác nhận'),
                          ),
                          DropdownMenuItem(value: 2, child: Text('Từ chối')),
                        ],
                        onChanged: (value) {
                          registrationStatus = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái thanh toán',
                          border: OutlineInputBorder(),
                        ),
                        value: paymentStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Chưa thanh toán'),
                          ),
                          DropdownMenuItem(value: 1, child: Text('Đang xử lý')),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Đã thanh toán'),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('Thanh toán thất bại'),
                          ),
                        ],
                        onChanged: (value) {
                          paymentStatus = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Mã thanh toán (tùy chọn)',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            paymentCode = value;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      // Nếu là gói đơn, sử dụng tên người chơi làm tên đội
                      if (isSinglePlayer && playerId1 != null) {
                        final player = _players.firstWhere(
                          (p) => p.id == playerId1,
                          orElse: () => Player(id: -1, name: 'Không tìm thấy'),
                        );
                        name = player.name;
                      }

                      try {
                        final response = await appDioClient.post(
                          '/tournament/create_team',
                          data: {
                            'name': name,
                            'payment_status': paymentStatus,
                            'registration_status': registrationStatus,
                            'payment_code': paymentCode,
                            'tournament_id': widget.tournamentId,
                            'player_id1': playerId1,
                            'player_id2': playerId2,
                            'package_id': packageId,
                            'registration_date':
                                registrationDate.toIso8601String(),
                          },
                          options: Options(
                            headers: {'X-Api-Key': ApiConstants.apiKey},
                          ),
                        );

                        if (response.statusCode != 200 ||
                            response.data['status'] != true) {
                          throw Exception(
                            response.data['message'] ?? 'Không thể tạo đội',
                          );
                        }

                        if (!mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm đội mới')),
                        );
                        _loadTeams();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTeamDialog(BuildContext context, Team team) {
    final formKey = GlobalKey<FormState>();
    String name = team.name;
    int paymentStatus = team.paymentStatus;
    int registrationStatus = team.registrationStatus;
    String? paymentCode = team.paymentCode;
    int? playerId1 = team.playerId1;
    int? playerId2 = team.playerId2;
    int packageId = team.packageId ?? _packages.first.id;

    // Xác định số lượng người chơi của gói đăng ký hiện tại
    final currentPackage = _packages.firstWhere(
      (p) => p.id == packageId,
      orElse: () => _packages.first,
    );
    bool isSinglePlayer = currentPackage.category?.numberOfPlayer == 1;

    // Hàm cập nhật lại gói đăng ký và số lượng người chơi
    void updatePackage(int newPackageId) {
      final selectedPackage = _packages.firstWhere((p) => p.id == newPackageId);
      isSinglePlayer = selectedPackage.category?.numberOfPlayer == 1;
      // Nếu chuyển từ gói đôi sang gói đơn, reset người chơi 2
      if (isSinglePlayer) {
        playerId2 = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chỉnh sửa đội'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hiển thị trường tên đội nếu không phải gói đơn
                      if (!isSinglePlayer)
                        TextFormField(
                          initialValue: name,
                          decoration: const InputDecoration(
                            labelText: 'Tên đội',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập tên đội';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            name = value!;
                          },
                        ),
                      if (!isSinglePlayer) const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Gói đăng ký',
                          border: OutlineInputBorder(),
                        ),
                        value: packageId,
                        items:
                            _packages.map((package) {
                              return DropdownMenuItem<int>(
                                value: package.id,
                                child: Text(package.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              packageId = value;
                              updatePackage(value);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        decoration: const InputDecoration(
                          labelText: 'Người chơi 1',
                          border: OutlineInputBorder(),
                        ),
                        value: playerId1,
                        items:
                            _players.map((player) {
                              return DropdownMenuItem<int?>(
                                value: player.id,
                                child: Text(player.name),
                              );
                            }).toList(),
                        validator: (value) {
                          if (value == null) {
                            return 'Vui lòng chọn người chơi 1';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            playerId1 = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Hiển thị trường người chơi 2 nếu không phải gói đơn
                      if (!isSinglePlayer)
                        DropdownButtonFormField<int?>(
                          decoration: const InputDecoration(
                            labelText: 'Người chơi 2',
                            border: OutlineInputBorder(),
                          ),
                          value: playerId2,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('-- Không chọn --'),
                            ),
                            ..._players.map((player) {
                              return DropdownMenuItem<int?>(
                                value: player.id,
                                child: Text(player.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              playerId2 = value;
                            });
                          },
                        ),
                      if (!isSinglePlayer) const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái đăng ký',
                          border: OutlineInputBorder(),
                        ),
                        value: registrationStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Chờ xác nhận'),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Đã xác nhận'),
                          ),
                          DropdownMenuItem(value: 2, child: Text('Từ chối')),
                        ],
                        onChanged: (value) {
                          registrationStatus = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái thanh toán',
                          border: OutlineInputBorder(),
                        ),
                        value: paymentStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Chưa thanh toán'),
                          ),
                          DropdownMenuItem(value: 1, child: Text('Đang xử lý')),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Đã thanh toán'),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('Thanh toán thất bại'),
                          ),
                        ],
                        onChanged: (value) {
                          paymentStatus = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: paymentCode ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Mã thanh toán (tùy chọn)',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            paymentCode = value;
                          } else {
                            paymentCode = null;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      // Nếu là gói đơn, sử dụng tên người chơi làm tên đội
                      if (isSinglePlayer && playerId1 != null) {
                        final player = _players.firstWhere(
                          (p) => p.id == playerId1,
                          orElse: () => Player(id: -1, name: 'Không tìm thấy'),
                        );
                        name = player.name;
                      }

                      try {
                        final response = await appDioClient.post(
                          '/tournament/update_team',
                          data: {
                            'id': team.id,
                            'name': name,
                            'payment_status': paymentStatus,
                            'registration_status': registrationStatus,
                            'payment_code': paymentCode,
                            'tournament_id': widget.tournamentId,
                            'player_id1': playerId1,
                            'player_id2': playerId2,
                            'package_id': packageId,
                          },
                          options: Options(
                            headers: {'X-Api-Key': ApiConstants.apiKey},
                          ),
                        );

                        if (response.statusCode != 200 ||
                            response.data['status'] != true) {
                          throw Exception(
                            response.data['message'] ??
                                'Không thể cập nhật đội',
                          );
                        }

                        if (!mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã cập nhật thông tin đội'),
                          ),
                        );
                        _loadTeams();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteTeamDialog(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa đội "${team.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final response = await appDioClient.post(
                    '/tournament/delete_team',
                    data: {'id': team.id, 'tournament_id': widget.tournamentId},
                    options: Options(
                      headers: {'X-Api-Key': ApiConstants.apiKey},
                    ),
                  );

                  if (response.statusCode != 200 ||
                      response.data['status'] != true) {
                    throw Exception(
                      response.data['message'] ?? 'Không thể xóa đội',
                    );
                  }

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Đã xóa đội')));
                  _loadTeams();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}
