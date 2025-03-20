import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
  List<Team> _teams = [];
  List<TourPackage> _packages = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadTeams(), _loadPackages()]);
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://familyworld.xyz/api/tournament/get_teams',
        queryParameters: {'tournament_id': widget.tournamentId},
        options: Options(
          headers: {'X-Api-Key': 'whC]#}Z:&IP-tm7&Po_>y5qxB:ZVe^aQ'},
        ),
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
      final dio = Dio();
      final response = await dio.get(
        'https://familyworld.xyz/api/tournament/get_packages',
        queryParameters: {'tournament_id': widget.tournamentId},
        options: Options(
          headers: {'X-Api-Key': 'whC]#}Z:&IP-tm7&Po_>y5qxB:ZVe^aQ'},
        ),
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
            categoryId: 0,
            tourId: 0,
            price: 0,
          ),
    );
    return package.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đội tham gia - ${widget.tournamentName ?? ''}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_packages.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng thêm gói đăng ký trước')),
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
    if (_isLoading || _isLoadingPackages) {
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
                  _buildInfoRow('ID Người chơi 1', team.playerId1.toString()),
                if (team.playerId2 != null)
                  _buildInfoRow('ID Người chơi 2', team.playerId2.toString()),
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
    int playerId1 = 0;
    int? playerId2;
    int packageId = _packages.first.id;
    DateTime registrationDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm đội mới'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(height: 16),
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
                      packageId = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'ID Người chơi 1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập ID người chơi 1';
                      }
                      try {
                        final num = int.parse(value);
                        if (num <= 0) {
                          return 'ID phải lớn hơn 0';
                        }
                      } catch (e) {
                        return 'Vui lòng nhập ID hợp lệ';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      playerId1 = int.parse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'ID Người chơi 2 (tùy chọn cho đội đôi)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final num = int.parse(value);
                          if (num <= 0) {
                            return 'ID phải lớn hơn 0';
                          }
                        } catch (e) {
                          return 'Vui lòng nhập ID hợp lệ';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        playerId2 = int.parse(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái đăng ký',
                      border: OutlineInputBorder(),
                    ),
                    value: registrationStatus,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Chờ xác nhận')),
                      DropdownMenuItem(value: 1, child: Text('Đã xác nhận')),
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
                      DropdownMenuItem(value: 2, child: Text('Đã thanh toán')),
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
                  try {
                    final dio = Dio();
                    final response = await dio.post(
                      '${ApiConstants.baseUrl}/tournament/create_team',
                      data: {
                        'name': name,
                        'payment_status': paymentStatus,
                        'registration_status': registrationStatus,
                        'payment_code': paymentCode,
                        'tournament_id': widget.tournamentId,
                        'player_id1': playerId1,
                        'player_id2': playerId2,
                        'package_id': packageId,
                        'registration_date': registrationDate.toIso8601String(),
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
  }

  void _showEditTeamDialog(BuildContext context, Team team) {
    final formKey = GlobalKey<FormState>();
    String name = team.name;
    int paymentStatus = team.paymentStatus;
    int registrationStatus = team.registrationStatus;
    String? paymentCode = team.paymentCode;
    int playerId1 = team.playerId1 ?? 0;
    int? playerId2 = team.playerId2;
    int packageId = team.packageId ?? _packages.first.id;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa đội'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(height: 16),
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
                      packageId = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: playerId1.toString(),
                    decoration: const InputDecoration(
                      labelText: 'ID Người chơi 1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập ID người chơi 1';
                      }
                      try {
                        final num = int.parse(value);
                        if (num <= 0) {
                          return 'ID phải lớn hơn 0';
                        }
                      } catch (e) {
                        return 'Vui lòng nhập ID hợp lệ';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      playerId1 = int.parse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: playerId2?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'ID Người chơi 2 (tùy chọn cho đội đôi)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final num = int.parse(value);
                          if (num <= 0) {
                            return 'ID phải lớn hơn 0';
                          }
                        } catch (e) {
                          return 'Vui lòng nhập ID hợp lệ';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        playerId2 = int.parse(value);
                      } else {
                        playerId2 = null;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái đăng ký',
                      border: OutlineInputBorder(),
                    ),
                    value: registrationStatus,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Chờ xác nhận')),
                      DropdownMenuItem(value: 1, child: Text('Đã xác nhận')),
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
                      DropdownMenuItem(value: 2, child: Text('Đã thanh toán')),
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  // TODO: Implement API call to update team
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật thông tin đội')),
                  );
                  _loadTeams();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
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
              onPressed: () {
                // TODO: Implement API call to delete team
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Đã xóa đội')));
                _loadTeams();
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}
