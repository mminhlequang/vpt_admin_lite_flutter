import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:internal_core/internal_core.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/tournament.dart';
import '../../models/category.dart';
import '../../widgets/loading_indicator.dart';

class TournamentEditScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentEditScreen({super.key, required this.tournament});

  @override
  State<TournamentEditScreen> createState() => _TournamentEditScreenState();
}

class _TournamentEditScreenState extends State<TournamentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _cityController;
  late TextEditingController _surfaceController;
  late TextEditingController _prizeController;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _genderRestriction;
  late int _numberOfTeams;
  late int _selectedCategoryId;
  late int _packageId;
  late TournamentStatus _status;
  File? _avatarFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  List<Category> _categories = [];
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategories();
  }

  void _initializeControllers() {
    final tournament = widget.tournament;
    _nameController = TextEditingController(text: tournament.name);
    _descriptionController = TextEditingController(
      text: tournament.content ?? '',
    );
    _cityController = TextEditingController(text: tournament.city ?? '');
    _surfaceController = TextEditingController(text: tournament.surface ?? '');
    _prizeController = TextEditingController(
      text: tournament.prize?.toString() ?? '0',
    );
    _genderRestriction = tournament.genderRestriction ?? 'mixed';
    _startDate =
        string2DateTime(tournament.startDate ?? '', format: 'yyyy-MM-dd') ??
        DateTime.now();
    _endDate =
        string2DateTime(tournament.endDate ?? '', format: 'yyyy-MM-dd') ??
        DateTime.now();
    _numberOfTeams = tournament.numberOfTeam ?? 0;
    _selectedCategoryId = tournament.category?.id ?? 1;
    _packageId = tournament.packages?.first.id ?? 1;
    _currentImageUrl = tournament.avatar;
    _status = tournament.status ?? TournamentStatus.preparing;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _surfaceController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  // Tải danh sách danh mục
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await appDioClient.get('/tournament/get_categories');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          final categoriesData = data['data'] as List;
          setState(() {
            _categories =
                categoriesData.map((item) => Category.fromJson(item)).toList();
            _isLoadingCategories = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Không thể tải danh mục');
        }
      } else {
        throw Exception('Lỗi kết nối: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh mục: ${e.toString()}')),
        );
      }
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

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _avatarFile = kIsWeb ? null : File(result.files.first.path!);
        _pickedBytes = kIsWeb ? result.files.first.bytes : null;
        _currentImageUrl = null; // Xóa URL hiện tại vì sẽ sử dụng file mới
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã chọn ảnh thành công')));
    }
  }

  Future<void> _updateTournament() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double prize = 0;
      try {
        prize = double.parse(_prizeController.text);
      } catch (e) {
        // Xử lý lỗi nếu không thể chuyển đổi
      }

      final formData = FormData.fromMap({
        'id': widget.tournament.id,
        'name': _nameController.text,
        'start_date': _startDate.formatDate(formatType: 'yyyy-MM-dd'),
        'end_date': _endDate.formatDate(formatType: 'yyyy-MM-dd'),
        'city': _cityController.text,
        'surface': _surfaceController.text,
        'gender_restriction': _genderRestriction,
        'number_of_team': _numberOfTeams,
        'prize': prize,
        'package_id': _packageId,
        'content': _descriptionController.text,
        'category_id': _selectedCategoryId,
        'status': _status.name,
      });

      if (_avatarFile != null) {
        formData.files.add(
          MapEntry('avatar', await MultipartFile.fromFile(_avatarFile!.path)),
        );
      } else if (_pickedBytes != null) {
        formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(_pickedBytes!, filename: 'avatar.jpg'),
          ),
        );
      }

      await appDioClient.post(
        '/tournament/update',
        data: formData,
        options: Options(
          headers: {'X-Api-Key': 'whC]#}Z:&IP-tm7&Po_>y5qxB:ZVe^aQ'},
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật giải đấu thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa giải đấu'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _updateTournament,
            icon: const Icon(Icons.save),
            label: const Text('Lưu'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body:
          _isLoadingCategories
              ? const Center(child: LoadingIndicator())
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildLocationSection(),
            const SizedBox(height: 24),
            _buildConfigurationSection(),
            const SizedBox(height: 24),
            _buildDescriptionSection(),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateTournament,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.sports_tennis),
                label: Text(_isLoading ? 'Đang xử lý...' : 'Cập nhật giải đấu'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên giải đấu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
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
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Ngày bắt đầu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _startDate.formatDate(),
                    ),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Ngày kết thúc',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _endDate.formatDate(),
                    ),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child:
                    _avatarFile != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            _avatarFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                        : _pickedBytes != null && kIsWeb
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            _pickedBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                        : _currentImageUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: WidgetAppImage(
                            imageUrl: _currentImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                             
                          ),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate, size: 50),
                            SizedBox(height: 8),
                            Text('Chọn ảnh giải đấu'),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa điểm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Thành phố',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập thành phố';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _surfaceController,
              decoration: const InputDecoration(
                labelText: 'Bề mặt sân',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_tennis),
                hintText: 'Ví dụ: hard, clay, grass',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập bề mặt sân';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cấu hình giải đấu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Danh mục',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              value: _selectedCategoryId,
              items:
                  _categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Vui lòng chọn danh mục';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prizeController,
              decoration: const InputDecoration(
                labelText: 'Tiền thưởng (VNĐ)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tiền thưởng';
                }
                try {
                  final prize = double.parse(value);
                  if (prize < 0) {
                    return 'Tiền thưởng không được âm';
                  }
                } catch (e) {
                  return 'Vui lòng nhập số hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _numberOfTeams,
              decoration: const InputDecoration(
                labelText: 'Số đội tham gia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              items:
                  [4, 8, 16, 32, 64, 128].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value đội'),
                    );
                  }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'Vui lòng chọn số đội tham gia';
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _numberOfTeams = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TournamentStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checklist),
              ),
              items:
                  TournamentStatus.values.map((TournamentStatus value) {
                    return DropdownMenuItem<TournamentStatus>(
                      value: value,
                      child: Text(value.name),
                    );
                  }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'Vui lòng chọn trạng thái';
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // const Text('Giới tính cho phép tham gia:'),
            // SegmentedButton<String>(
            //   segments: const [
            //     ButtonSegment<String>(value: 'male', label: Text('Nam')),
            //     ButtonSegment<String>(value: 'female', label: Text('Nữ')),
            //     ButtonSegment<String>(value: 'mixed', label: Text('Hỗn hợp')),
            //   ],
            //   selected: {_genderRestriction},
            //   onSelectionChanged: (Set<String> newSelection) {
            //     setState(() {
            //       _genderRestriction = newSelection.first;
            //     });
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mô tả giải đấu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}
