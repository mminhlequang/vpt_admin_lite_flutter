import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import 'dart:typed_data';
import '../../models/tournament.dart';
import '../../models/player.dart';
import '../../models/category.dart';
import '../../widgets/loading_indicator.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({Key? key}) : super(key: key);

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  String? _surface;
  final _prizeController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  int _numberOfTeams = 8;
  File? _avatarFile;
  Category? _selectedCategory;

  List<Category> _categories = [];
  bool _isLoadingCategories = false;
  bool _isCreating = false;
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _prizeController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
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
          final categories =
              categoriesData.map((item) => Category.fromJson(item)).toList();

          setState(() {
            _categories = categories;
            if (categories.isNotEmpty) {
              _selectedCategory = categories.first;
            }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh mục: ${e.toString()}')),
      );
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
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã chọn ảnh thành công')));
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

  // Tạo giải đấu mới
  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      double prize = 0;
      try {
        prize = double.parse(_prizeController.text);
      } catch (e) {
        // Xử lý lỗi nếu không thể chuyển đổi
      }
      final formData = FormData.fromMap({
        'name': _nameController.text,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'city': _cityController.text,
        'surface': _surface,
        'number_of_team': _numberOfTeams,
        'prize': prize,
        'content': _descriptionController.text,
        'category_id': _selectedCategory?.id,
        'status': TournamentStatus.preparing.name,
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

      await appDioClient.post('/tournament/create', data: formData);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo giải đấu thành công')),
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
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo giải đấu mới'),
        actions: [
          TextButton.icon(
            onPressed: _createTournament,
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
                onPressed: _isCreating ? null : _createTournament,
                icon:
                    _isCreating
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.sports_tennis),
                label: Text(_isCreating ? 'Đang xử lý...' : 'Tạo giải đấu'),
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
    return Column(
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
                controller: TextEditingController(text: _formatDate(_endDate)),
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
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
                            child: Image.file(_avatarFile!, fit: BoxFit.cover),
                          )
                          : _pickedBytes != null && kIsWeb
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.memory(
                              _pickedBytes!,
                              fit: BoxFit.cover,
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
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
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
        DropdownButtonFormField<String>(
          value: _surface,
          decoration: const InputDecoration(
            labelText: 'Bề mặt sân',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.sports_tennis),
          ),
          items: const [
            DropdownMenuItem(value: 'hard', child: Text('Sân cứng (Hard)')),
            DropdownMenuItem(value: 'clay', child: Text('Sân đất nện (Clay)')),
            DropdownMenuItem(value: 'grass', child: Text('Sân cỏ (Grass)')),
            DropdownMenuItem(value: 'carpet', child: Text('Sân thảm (Carpet)')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _surface = value;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn bề mặt sân';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return Column(
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
          value: _selectedCategory?.id,
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
                _selectedCategory = _categories.firstWhere(
                  (c) => c.id == value,
                  orElse:
                      () =>
                          Category(id: 1, name: '', numberOfPlayer: 1, sex: 0),
                );
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
        // const SizedBox(height: 16),
        // const Text('Giới tính cho phép tham gia:'),
        // Wrap(
        //   spacing: 8.0,
        //   children: [
        //     FilterChip(
        //       label: const Text('Nam'),
        //       selected: _genderRestriction.contains('male'),
        //       onSelected: (selected) {
        //         setState(() {
        //           if (selected) {
        //             _genderRestriction.add('male');
        //           } else {
        //             _genderRestriction.remove('male');
        //           }
        //         });
        //       },
        //     ),
        //     FilterChip(
        //       label: const Text('Nữ'),
        //       selected: _genderRestriction.contains('female'),
        //       onSelected: (selected) {
        //         setState(() {
        //           if (selected) {
        //             _genderRestriction.add('female');
        //           } else {
        //             _genderRestriction.remove('female');
        //           }
        //         });
        //       },
        //     ),
        //     FilterChip(
        //       label: const Text('Hỗn hợp'),
        //       selected: _genderRestriction.contains('mixed'),
        //       onSelected: (selected) {
        //         setState(() {
        //           if (selected) {
        //             _genderRestriction.add('mixed');
        //           } else {
        //             _genderRestriction.remove('mixed');
        //           }
        //         });
        //       },
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
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
          maxLines: 16,
          minLines: 8,
        ),

        // Container(
        //   height: 480,
        //   decoration: BoxDecoration(
        //     border: Border.all(color: Colors.grey),
        //     borderRadius: BorderRadius.circular(4),
        //   ),
        //   child: Column(
        //     children: [
        //       QuillSimpleToolbar(
        //         controller: _descriptionController,
        //         config: const QuillSimpleToolbarConfig(toolbarSize: 20),
        //       ),
        //       Expanded(
        //         child: Padding(
        //           padding: const EdgeInsets.symmetric(horizontal: 16),
        //           child: QuillEditor.basic(
        //             controller: _descriptionController,
        //             config: const QuillEditorConfig(),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
