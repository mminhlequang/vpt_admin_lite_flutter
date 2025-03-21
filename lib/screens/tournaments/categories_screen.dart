import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/category.dart'; 
import '../../utils/constants.dart';
import '../../widgets/loading_indicator.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<Category> _categories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await appDioClient.get('/tournament/get_categories');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status']) {
          final categoriesData = data['data'] as List;
          setState(() {
            _categories = categoriesData.map((item) => Category.fromJson(item)).toList();
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Không thể tải danh mục');
        }
      } else {
        throw Exception('Không thể tải danh mục: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh mục: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getSexText(int sex) {
    switch (sex) {
      case 0:
        return 'Nam';
      case 1:
        return 'Nữ';
      case 2:
        return 'Hỗn hợp';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(child: Text('Chưa có danh mục nào'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      itemCount: _categories.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          elevation: 2,
          child: ListTile(
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số người chơi: ${category.numberOfPlayer}'),
                Text('Giới tính: ${_getSexText(category.sex)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _showEditCategoryDialog(context, category);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteCategoryDialog(context, category);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    int numberOfPlayer = 1;
    int sex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tên danh mục',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên danh mục';
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
                      labelText: 'Số người chơi',
                      border: OutlineInputBorder(),
                    ),
                    value: numberOfPlayer,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 người (Đơn)')),
                      DropdownMenuItem(value: 2, child: Text('2 người (Đôi)')),
                    ],
                    onChanged: (value) {
                      numberOfPlayer = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Giới tính',
                      border: OutlineInputBorder(),
                    ),
                    value: sex,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Nam')),
                      DropdownMenuItem(value: 1, child: Text('Nữ')),
                      DropdownMenuItem(value: 2, child: Text('Hỗn hợp')),
                    ],
                    onChanged: (value) {
                      sex = value!;
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
                  // TODO: Implement API call to create category
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm danh mục mới')),
                  );
                  _loadCategories();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final formKey = GlobalKey<FormState>();
    String name = category.name;
    int numberOfPlayer = category.numberOfPlayer;
    int sex = category.sex;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa danh mục'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Tên danh mục',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên danh mục';
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
                      labelText: 'Số người chơi',
                      border: OutlineInputBorder(),
                    ),
                    value: numberOfPlayer,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 người (Đơn)')),
                      DropdownMenuItem(value: 2, child: Text('2 người (Đôi)')),
                    ],
                    onChanged: (value) {
                      numberOfPlayer = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Giới tính',
                      border: OutlineInputBorder(),
                    ),
                    value: sex,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Nam')),
                      DropdownMenuItem(value: 1, child: Text('Nữ')),
                      DropdownMenuItem(value: 2, child: Text('Hỗn hợp')),
                    ],
                    onChanged: (value) {
                      sex = value!;
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
                  // TODO: Implement API call to update category
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật danh mục')),
                  );
                  _loadCategories();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?',
          ),
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
                // TODO: Implement API call to delete category
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa danh mục')),
                );
                _loadCategories();
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}
