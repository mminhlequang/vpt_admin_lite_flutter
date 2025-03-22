import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vpt_admin_lite_flutter/models/tournament.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/tour_package.dart';
import '../../models/tournament.dart' as tournament_model;
import '../../models/category.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_indicator.dart';
import 'package:intl/intl.dart';

class PackagesScreen extends StatefulWidget {
  final Tournament tournament;
  final VoidCallback fetchCallback;
  const PackagesScreen({
    super.key,
    required this.tournament,
    required this.fetchCallback,
  });

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  List<TourPackage> get _packages => widget.tournament.packages ?? [];
  List<Category> get _categories => [widget.tournament.category!];
  String? _errorMessage;

  String _getStatusText(int enable) {
    return enable == 1 ? 'Đang kích hoạt' : 'Đã tắt';
  }

  Color _getStatusColor(int enable) {
    return enable == 1 ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton:
          _packages.isNotEmpty
              ? null
              : FloatingActionButton(
                onPressed: () {
                  if (_categories.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng thêm danh mục trước'),
                      ),
                    );
                    return;
                  }
                  _showAddPackageDialog(context);
                },
                child: const Icon(Icons.add),
              ),
    );
  }

  Widget _buildBody() {
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
              onPressed: widget.fetchCallback,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_packages.isEmpty) {
      return const Center(child: Text('Chưa có gói đăng ký nào'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      itemCount: _packages.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final package = _packages[index];
        return Card(
          elevation: 2,
          child: ListTile(
            title: Text(
              package.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(package.price ?? 0)}',
                ),
                Text('Danh mục: ${package.category?.name ?? 'Không tìm thấy'}'),
                Text(
                  'Trạng thái: ${_getStatusText(package.enable)}',
                  style: TextStyle(
                    color: _getStatusColor(package.enable),
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
                    _showEditPackageDialog(context, package);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeletePackageDialog(context, package);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPackageDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    int categoryId = _categories.first.id;
    double price = 0;
    int enable = 1;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm gói đăng ký mới'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tên gói',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên gói';
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
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(),
                    ),
                    value: categoryId,
                    items:
                        _categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      categoryId = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Giá (VNĐ)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá';
                      }
                      try {
                        final num = double.parse(value);
                        if (num <= 0) {
                          return 'Giá phải lớn hơn 0';
                        }
                      } catch (e) {
                        return 'Vui lòng nhập giá hợp lệ';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      price = double.parse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    value: enable,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Kích hoạt')),
                      DropdownMenuItem(value: 0, child: Text('Tắt')),
                    ],
                    onChanged: (value) {
                      enable = value!;
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
                    final response = await appDioClient.post(
                      '/tournament/create_packages',
                      data: {
                        'name': name,
                        'enable': enable,
                        'tour_id': widget.tournament.id,
                        'category_id': categoryId,
                        'price': price,
                      },
                    );

                    if (response.statusCode != 200 ||
                        response.data['status'] != true) {
                      throw Exception(
                        response.data['message'] ?? 'Không thể tạo gói đăng ký',
                      );
                    }

                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm gói đăng ký mới')),
                    );
                    widget.fetchCallback();
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

  void _showEditPackageDialog(BuildContext context, TourPackage package) {
    final formKey = GlobalKey<FormState>();
    String name = package.name;
    int? categoryId = package.category?.id;
    double price = package.price?.toDouble() ?? 0;
    int enable = package.enable;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa gói đăng ký'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Tên gói',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên gói';
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
                      labelText: 'Danh mục',
                      border: OutlineInputBorder(),
                    ),
                    value: categoryId,
                    items:
                        _categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      categoryId = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: price.toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: 'Giá (VNĐ)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá';
                      }
                      try {
                        final num = double.parse(value);
                        if (num <= 0) {
                          return 'Giá phải lớn hơn 0';
                        }
                      } catch (e) {
                        return 'Vui lòng nhập giá hợp lệ';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      price = double.parse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    value: enable,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Kích hoạt')),
                      DropdownMenuItem(value: 0, child: Text('Tắt')),
                    ],
                    onChanged: (value) {
                      enable = value!;
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
                  // TODO: Implement API call to update package
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật gói đăng ký')),
                  );
                  widget.fetchCallback();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePackageDialog(BuildContext context, TourPackage package) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa gói "${package.name}"?'),
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
                // TODO: Implement API call to delete package
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa gói đăng ký')),
                );
                widget.fetchCallback();
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }
}
