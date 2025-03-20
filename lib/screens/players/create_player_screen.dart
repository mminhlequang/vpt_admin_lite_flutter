import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../models/player.dart';

class CreatePlayerScreen extends StatefulWidget {
  const CreatePlayerScreen({Key? key}) : super(key: key);

  @override
  State<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends State<CreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();

  String _backHand = 'Left-Handed';
  String _plays = 'Left-Handed';
  File? _avatarFile;
  XFile? _pickedImage;
  DateTime? _selectedDate;
  bool _isLoading = false;

  final List<String> _handOptions = [
    'Left-Handed',
    'Right-Handed',
    'Two-Handed',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _avatarFile = kIsWeb ? null : File(image.path);
        _pickedImage = image;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh đại diện')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Chuẩn bị FormData để gửi
        FormData formData;

        if (kIsWeb) {
          // Trường hợp web
          List<int> imageBytes = await _pickedImage!.readAsBytes();
          String fileName = _pickedImage!.name;

          formData = FormData.fromMap({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'height': _heightController.text,
            'weight': _weightController.text,
            'birth_date': _birthDateController.text,
            'birth_place': _birthPlaceController.text,
            'back_hand': _backHand,
            'plays': _plays,
            'avatar': MultipartFile.fromBytes(imageBytes, filename: fileName),
          });
        } else {
          // Trường hợp mobile
          formData = FormData.fromMap({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'height': _heightController.text,
            'weight': _weightController.text,
            'birth_date': _birthDateController.text,
            'birth_place': _birthPlaceController.text,
            'back_hand': _backHand,
            'plays': _plays,
            'avatar': await MultipartFile.fromFile(
              _avatarFile!.path,
              filename: _avatarFile!.path.split('/').last,
            ),
          });
        }

        // Gửi request tạo player mới
        final response = await Dio().post(
          'https://familyworld.xyz/api/player/create',
          data: formData,
          options: Options(
            headers: {
              'X-Api-Key': 'whC]#}Z:&IP-tm7&Po_>y5qxB:ZVe^aQ',
              'X-CSRF-TOKEN': '4QrpOUUwy4IAZbaqCUgfxqUktr4ctaalFFQwP4wa',
              'accept': '*/*',
            },
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Nếu thành công
          Navigator.pop(context, true); // Trả về true để biết đã tạo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo người chơi mới thành công')),
          );
        } else {
          // Nếu có lỗi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.statusMessage}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      } finally {
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
        title: const Text('Tạo người chơi mới'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(UIConstants.defaultPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh đại diện
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                _avatarFile != null
                                    ? FileImage(_avatarFile!)
                                    : null,
                            child:
                                _avatarFile == null && _pickedImage == null
                                    ? const Icon(Icons.add_a_photo, size: 40)
                                    : (kIsWeb && _pickedImage != null
                                        ? FutureBuilder<Uint8List>(
                                          future: _pickedImage!.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: MemoryImage(
                                                      snapshot.data!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const CircularProgressIndicator();
                                          },
                                        )
                                        : null),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Thông tin cơ bản
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          // Kiểm tra định dạng email
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Chiều cao và cân nặng
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                labelText: 'Chiều cao (cm) *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nhập chiều cao';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Cân nặng (kg) *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nhập cân nặng';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ngày sinh và nơi sinh
                      TextFormField(
                        controller: _birthDateController,
                        decoration: const InputDecoration(
                          labelText: 'Ngày sinh *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn ngày sinh';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _birthPlaceController,
                        decoration: const InputDecoration(
                          labelText: 'Nơi sinh *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập nơi sinh';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Thông tin kỹ thuật
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tay thuận (Back Hand)',
                          border: OutlineInputBorder(),
                        ),
                        value: _backHand,
                        items:
                            _handOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _backHand = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Kiểu chơi (Plays)',
                          border: OutlineInputBorder(),
                        ),
                        value: _plays,
                        items:
                            _handOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _plays = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Nút tạo
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(elevation: 2),
                          child: Text(
                            'TẠO NGƯỜI CHƠI MỚI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
