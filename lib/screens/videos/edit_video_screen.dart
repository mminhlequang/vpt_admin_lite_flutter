import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vpt_admin_lite_flutter/widgets/player/player_list_item.dart';
import '../../utils/constants.dart';
import '../../models/video.dart';

class EditVideoScreen extends StatefulWidget {
  final Video video;

  const EditVideoScreen({Key? key, required this.video}) : super(key: key);

  @override
  State<EditVideoScreen> createState() => _EditVideoScreenState();
}

class _EditVideoScreenState extends State<EditVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _videoUrlController;
  late String _selectedType;
  File? _thumbnailFile;
  XFile? _pickedImage;
  bool _isLoading = false;
  String? _thumbnailUrl;

  final List<String> _videoTypes = ['youtube', 'facebook', 'other'];

  @override
  void initState() {
    super.initState();
    // Khởi tạo các controller với dữ liệu của video hiện tại
    _nameController = TextEditingController(text: widget.video.name);
    _videoUrlController = TextEditingController(text: widget.video.video);
    _selectedType = widget.video.type;
    _thumbnailUrl = widget.video.avatar;
  }

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
      setState(() {
        _isLoading = true;
      });

      try {
        // Chuẩn bị FormData để gửi
        final Map<String, dynamic> formFields = {
          'id': widget.video.id.toString(),
          'name': _nameController.text,
          'type': _selectedType,
          'video': _videoUrlController.text,
        };

        FormData formData = FormData.fromMap(formFields);

        // Thêm ảnh mới nếu người dùng đã chọn
        if (_pickedImage != null) {
          if (kIsWeb) {
            // Xử lý cho web
            List<int> imageBytes = await _pickedImage!.readAsBytes();
            String fileName = _pickedImage!.name;

            formData.files.add(
              MapEntry(
                'avatar',
                MultipartFile.fromBytes(imageBytes, filename: fileName),
              ),
            );
          } else {
            // Xử lý cho mobile
            formData.files.add(
              MapEntry(
                'avatar',
                await MultipartFile.fromFile(
                  _thumbnailFile!.path,
                  filename: _thumbnailFile!.path.split('/').last,
                ),
              ),
            );
          }
        }

        // Gửi request cập nhật video
        final response = await Dio().post(
          'https://familyworld.xyz/api/video/update',
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
          Navigator.pop(
            context,
            true,
          ); // Trả về true để biết đã cập nhật thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật video thành công')),
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
        title: const Text('Chỉnh sửa video'),
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
                                      : (_thumbnailUrl != null &&
                                              _thumbnailUrl!.isNotEmpty
                                          ? DecorationImage(
                                            image: NetworkImage(
                                              correctUrlImage(_thumbnailUrl)),
                                            fit: BoxFit.cover,
                                          )
                                          : null),
                            ),
                            child:
                                (_thumbnailFile == null &&
                                        _pickedImage == null &&
                                        (_thumbnailUrl == null ||
                                            _thumbnailUrl!.isEmpty))
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

                      // Nút cập nhật
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(elevation: 2),
                          child: const Text(
                            'LƯU THAY ĐỔI',
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
