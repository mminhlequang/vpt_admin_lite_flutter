import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tournament.dart';
import '../../utils/constants.dart';
import '../../widgets/common/loading_overlay.dart';

class TournamentEditScreen extends StatefulWidget {
  final Tournament tournament;
  final Function(Tournament) onSave;

  const TournamentEditScreen({
    super.key,
    required this.tournament,
    required this.onSave,
  });

  @override
  State<TournamentEditScreen> createState() => _TournamentEditScreenState();
}

class _TournamentEditScreenState extends State<TournamentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _numberOfTeamsController;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TournamentType _tournamentType = TournamentType.singles;
  GenderRestriction _genderRestriction = GenderRestriction.mixed;
  TournamentStatus _status = TournamentStatus.preparing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.tournament.name);
    _startDate = widget.tournament.startDate;
    _endDate = widget.tournament.endDate;
    _startDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_startDate),
    );
    _endDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_endDate),
    );
    _imageUrlController = TextEditingController(
      text: widget.tournament.imageUrl,
    );
    _descriptionController = TextEditingController(
      text: widget.tournament.description,
    );
    _numberOfTeamsController = TextEditingController(
      text: widget.tournament.numberOfTeams.toString(),
    );
    _tournamentType = widget.tournament.type;
    _genderRestriction = widget.tournament.genderRestriction;
    _status = widget.tournament.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _numberOfTeamsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : _endDate;
    final DateTime firstDate =
        isStartDate
            ? DateTime.now().subtract(const Duration(days: 365))
            : _startDate;
    final DateTime lastDate =
        isStartDate ? _endDate : _startDate.add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(_startDate);

          // Nếu ngày kết thúc trước ngày bắt đầu, cập nhật ngày kết thúc
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
            _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate);
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate);
        }
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Tạo đối tượng Tournament mới từ dữ liệu đã nhập
      final updatedTournament = widget.tournament.copyWith(
        name: _nameController.text,
        startDate: _startDate,
        endDate: _endDate,
        type: _tournamentType,
        genderRestriction: _genderRestriction,
        numberOfTeams: int.parse(_numberOfTeamsController.text),
        status: _status,
        imageUrl:
            _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
      );

      // Trong ứng dụng thực tế, cần gọi API để lưu dữ liệu
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Giả lập thời gian gọi API

      setState(() {
        _isLoading = false;
      });

      // Gọi callback để truyền dữ liệu về màn hình cha
      widget.onSave(updatedTournament);

      // Quay về màn hình trước
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Chỉnh sửa giải đấu'),
            actions: [
              IconButton(
                onPressed: _save,
                icon: const Icon(Icons.save),
                tooltip: 'Lưu thay đổi',
              ),
            ],
          ),
          body: _buildForm(),
        ),
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildDateFields(),
            const SizedBox(height: 16),
            _buildTournamentTypeField(),
            const SizedBox(height: 16),
            _buildGenderRestrictionField(),
            const SizedBox(height: 16),
            _buildStatusField(),
            const SizedBox(height: 16),
            _buildNumberOfTeamsField(),
            const SizedBox(height: 16),
            _buildImageUrlField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Tên giải đấu',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.emoji_events),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập tên giải đấu';
        }
        return null;
      },
    );
  }

  Widget _buildDateFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _startDateController,
            decoration: const InputDecoration(
              labelText: 'Ngày bắt đầu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () => _selectDate(context, true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng chọn ngày bắt đầu';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _endDateController,
            decoration: const InputDecoration(
              labelText: 'Ngày kết thúc',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () => _selectDate(context, false),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng chọn ngày kết thúc';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentTypeField() {
    return DropdownButtonFormField<TournamentType>(
      value: _tournamentType,
      decoration: const InputDecoration(
        labelText: 'Loại giải đấu',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.sports_tennis),
      ),
      items: const [
        DropdownMenuItem(value: TournamentType.singles, child: Text('Đấu đơn')),
        DropdownMenuItem(value: TournamentType.doubles, child: Text('Đấu đôi')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _tournamentType = value;
          });
        }
      },
    );
  }

  Widget _buildGenderRestrictionField() {
    return DropdownButtonFormField<GenderRestriction>(
      value: _genderRestriction,
      decoration: const InputDecoration(
        labelText: 'Giới tính',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.people),
      ),
      items: const [
        DropdownMenuItem(value: GenderRestriction.male, child: Text('Nam')),
        DropdownMenuItem(value: GenderRestriction.female, child: Text('Nữ')),
        DropdownMenuItem(
          value: GenderRestriction.mixed,
          child: Text('Nam & Nữ'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _genderRestriction = value;
          });
        }
      },
    );
  }

  Widget _buildStatusField() {
    return DropdownButtonFormField<TournamentStatus>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'Trạng thái',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.flag),
      ),
      items: const [
        DropdownMenuItem(
          value: TournamentStatus.preparing,
          child: Text('Chuẩn bị'),
        ),
        DropdownMenuItem(
          value: TournamentStatus.ongoing,
          child: Text('Đang diễn ra'),
        ),
        DropdownMenuItem(
          value: TournamentStatus.completed,
          child: Text('Đã kết thúc'),
        ),
        DropdownMenuItem(
          value: TournamentStatus.cancelled,
          child: Text('Đã hủy'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _status = value;
          });
        }
      },
    );
  }

  Widget _buildNumberOfTeamsField() {
    return TextFormField(
      controller: _numberOfTeamsController,
      decoration: const InputDecoration(
        labelText: 'Số đội tham gia',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.group),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập số đội tham gia';
        }
        final number = int.tryParse(value);
        if (number == null || number <= 0) {
          return 'Số đội tham gia phải là số dương';
        }
        return null;
      },
    );
  }

  Widget _buildImageUrlField() {
    return TextFormField(
      controller: _imageUrlController,
      decoration: const InputDecoration(
        labelText: 'URL hình ảnh (tùy chọn)',
        hintText: 'Nhập URL hình ảnh cho giải đấu',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.image),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Mô tả giải đấu (tùy chọn)',
        hintText: 'Nhập mô tả chi tiết về giải đấu (hỗ trợ HTML)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Lưu thay đổi'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
