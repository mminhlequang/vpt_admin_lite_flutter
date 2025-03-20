import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../models/tournament.dart';
import '../../models/category.dart'; 
import '../../widgets/loading_indicator.dart';

class TournamentEditScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentEditScreen({Key? key, required this.tournament})
    : super(key: key);

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
  late int _tournamentType;
  late List<String> _genderRestriction;
  late int _numberOfTeams;
  late int _selectedCategoryId;
  late int _packageId;

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
      text: tournament.description ?? '',
    );
    _cityController = TextEditingController(text: tournament.city ?? '');
    _surfaceController = TextEditingController(text: tournament.surface ?? '');
    _prizeController = TextEditingController(
      text: tournament.prize?.toString() ?? '0',
    );
    _startDate = tournament.startDate;
    _endDate = tournament.endDate;
    _tournamentType = tournament.type;
    _genderRestriction =
        tournament.genderRestriction ?? ['male', 'female', 'mixed'];
    _numberOfTeams = tournament.numberOfTeams;
    _selectedCategoryId = tournament.categoryId ?? 1;
    _packageId = tournament.packageId ?? 1;
    _currentImageUrl = tournament.imageUrl;
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
      final dio = Dio();
      final response = await dio.get(
        'https://familyworld.xyz/api/tournament/get_categories',
        options: Options(headers: {
          'X-Api-Key': 'whC]#}Z:&IP-tm7&Po_>y5qxB:ZVe^aQ',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          final categoriesData = data['data'] as List;
          setState(() {
            _categories = categoriesData.map((item) => Category.fromJson(item)).toList();
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

      final dio = Dio();
      final formData = FormData.fromMap({
        'id': widget.tournament.id,
        'name': _nameController.text,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'city': _cityController.text,
        'surface': _surfaceController.text,
        'gender_restriction': _genderRestriction,
        'number_of_team': _numberOfTeams,
        'prize': prize,
        'package_id': _packageId,
        'content': _descriptionController.text,
        'type': _tournamentType,
        'category_id': _selectedCategoryId,
      });
      
      if (_avatarFile != null) {
        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(_avatarFile!.path),
          ),
        );
      } else if (_pickedBytes != null) {
        formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(_pickedBytes!, filename: 'avatar.jpg'),
          ),
        );
      }
      
      await dio.post(
        'https://familyworld.xyz/api/tournament/update',
        data: formData,
        options: Options(
          headers: {
            'X-Api-Key': 'whC]#}Z:&IP-tm7&Po_>y5qxB:ZVe^aQ',
          },
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
                      text: _formatDate(_startDate),
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
                      text: _formatDate(_endDate),
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
                          child: Image.network(
                            _currentImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
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
                    final selectedCategory = _categories.firstWhere(
                      (c) => c.id == value,
                      orElse:
                          () => Category(
                            id: 1,
                            name: '',
                            numberOfPlayer: 1,
                            sex: 0,
                          ),
                    );
                    _tournamentType = selectedCategory.numberOfPlayer;
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
            TextFormField(
              initialValue: _numberOfTeams.toString(),
              decoration: const InputDecoration(
                labelText: 'Số đội tham gia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số đội tham gia';
                }
                try {
                  final teams = int.parse(value);
                  if (teams <= 0) {
                    return 'Số đội phải lớn hơn 0';
                  }
                } catch (e) {
                  return 'Vui lòng nhập số hợp lệ';
                }
                return null;
              },
              onChanged: (value) {
                try {
                  _numberOfTeams = int.parse(value);
                } catch (e) {
                  // Xử lý lỗi nếu không thể chuyển đổi
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Giới tính cho phép tham gia:'),
            Wrap(
              spacing: 8.0,
              children: [
                FilterChip(
                  label: const Text('Nam'),
                  selected: _genderRestriction.contains('male'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _genderRestriction.add('male');
                      } else {
                        _genderRestriction.remove('male');
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Nữ'),
                  selected: _genderRestriction.contains('female'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _genderRestriction.add('female');
                      } else {
                        _genderRestriction.remove('female');
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Hỗn hợp'),
                  selected: _genderRestriction.contains('mixed'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _genderRestriction.add('mixed');
                      } else {
                        _genderRestriction.remove('mixed');
                      }
                    });
                  },
                ),
              ],
            ),
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
