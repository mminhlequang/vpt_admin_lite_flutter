import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/constants.dart';
import '../../models/video.dart';

class CreateVideoScreen extends StatefulWidget {
  const CreateVideoScreen({Key? key}) : super(key: key);

  @override
  State<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends State<CreateVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  String _selectedType = 'youtube';
  File? _thumbnailFile;
  XFile? _pickedImage;
  bool _isLoading = false;

  final List<String> _videoTypes = ['youtube', 'facebook', 'other'];

  @override
  void dispose() {
    _nameController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _thumbnailFile = kIsWeb ? null : File(image.path);
        _pickedImage = image;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh thumbnail')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Chuẩn bị dữ liệu để gửi - xử lý cả web và mobile
        FormData formData;

        if (kIsWeb) {
          // Trường hợp web
          List<int> imageBytes = await _pickedImage!.readAsBytes();
          String fileName = _pickedImage!.name;

          formData = FormData.fromMap({
            'name': _nameController.text,
            'type': _selectedType,
            'video': _videoUrlController.text,
            'avatar': MultipartFile.fromBytes(imageBytes, filename: fileName),
          });
        } else {
          // Trường hợp mobile
          formData = FormData.fromMap({
            'name': _nameController.text,
            'type': _selectedType,
            'video': _videoUrlController.text,
            'avatar': await MultipartFile.fromFile(
              _thumbnailFile!.path,
              filename: _thumbnailFile!.path.split('/').last,
            ),
          });
        }

        // Gửi request tạo video mới
        final response = await Dio().post(
          'https://familyworld.xyz/api/video/create',
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
            const SnackBar(content: Text('Tạo video mới thành công')),
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
        title: const Text('Thêm video mới'),
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
                      // Thumbnail video
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                              image:
                                  _thumbnailFile != null
                                      ? DecorationImage(
                                        image: FileImage(_thumbnailFile!),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                _thumbnailFile == null && _pickedImage == null
                                    ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Chọn ảnh thumbnail'),
                                        ],
                                      ),
                                    )
                                    : (kIsWeb && _pickedImage != null
                                        ? FutureBuilder<Uint8List>(
                                          future: _pickedImage!.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                    ConnectionState.done &&
                                                snapshot.hasData) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  image: DecorationImage(
                                                    image: MemoryImage(
                                                      snapshot.data!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                        )
                                        : null),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tên video
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên video *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên video';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Loại video
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Loại video',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedType,
                        items:
                            _videoTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedType = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Đường dẫn video
                      TextFormField(
                        controller: _videoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Đường dẫn video *',
                          hintText: 'Nhập URL video (YouTube, Facebook,...)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập đường dẫn video';
                          }
                          if (!value.startsWith('http')) {
                            return 'Đường dẫn phải bắt đầu bằng http:// hoặc https://';
                          }
                          return null;
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
                          child: const Text(
                            'TẠO VIDEO MỚI',
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
