import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../widgets/player/player_list_item.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'player_detail_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({Key? key}) : super(key: key);

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Player> _players = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API thực tế để lấy danh sách người chơi
      final response = await Dio().get(
        'https://familyworld.xyz/api/player',
        options: Options(
          headers: {
            'accept': '*/*',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, Content-Type, Accept, Authorization',
          'cors-mode': 'no-cors',
          "content-type": "application/json",
        },)
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.data);

        // Chuyển đổi dữ liệu từ API thành danh sách Player
        List<Player> playersList = [];
        if (data is List) {
          playersList = data.map((item) => Player.fromJson(item)).toList();
        } else if (data['data'] is List) {
          playersList =
              (data['data'] as List)
                  .map((item) => Player.fromJson(item))
                  .toList();
        }

        setState(() {
          _players = playersList;
          _isLoading = false;
        });
      } else {
        throw Exception('Không thể tải dữ liệu từ API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách người chơi: $e')),
      );
    }
  }

  List<Player> _getFilteredPlayers() {
    final searchQuery = _searchController.text.toLowerCase();

    if (searchQuery.isEmpty) {
      return _players;
    }

    return _players.where((player) {
      return player.name.toLowerCase().contains(searchQuery) ||
          (player.email?.toLowerCase().contains(searchQuery) ?? false) ||
          (player.phone?.contains(searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người chơi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm người chơi',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(child: _buildPlayerList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlayerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlayerList() {
    final filteredPlayers = _getFilteredPlayers();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredPlayers.isEmpty) {
      return const Center(child: Text('Không có người chơi nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadPlayers,
      child: ListView.builder(
        itemCount: filteredPlayers.length,
        itemBuilder: (context, index) {
          final player = filteredPlayers[index];
          return GestureDetector(
            onTap: () => _navigateToPlayerDetail(player),
            child: PlayerListItem(
              player: player,
              onApprove:
                  () =>
                      _updatePlayerStatus(player, RegistrationStatus.approved),
              onReject:
                  () =>
                      _updatePlayerStatus(player, RegistrationStatus.rejected),
              onTogglePaid: () => _togglePlayerPaidStatus(player),
            ),
          );
        },
      ),
    );
  }

  void _navigateToPlayerDetail(Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailScreen(player: player),
      ),
    );
  }

  void _updatePlayerStatus(Player player, RegistrationStatus status) {
    // Trong thực tế, gọi API để cập nhật trạng thái
    setState(() {
      final index = _players.indexWhere((p) => p.id == player.id);
      if (index != -1) {
        _players[index] = player.copyWith(status: status);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cập nhật trạng thái thành ${status == RegistrationStatus.approved ? 'Đã duyệt' : 'Từ chối'}',
        ),
      ),
    );
  }

  void _togglePlayerPaidStatus(Player player) {
    // Trong thực tế, gọi API để cập nhật trạng thái thanh toán
    setState(() {
      final index = _players.indexWhere((p) => p.id == player.id);
      if (index != -1) {
        _players[index] = player.copyWith(hasPaid: !player.hasPaid);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cập nhật trạng thái thanh toán thành ${player.hasPaid ? 'Chưa thanh toán' : 'Đã thanh toán'}',
        ),
      ),
    );
  }

  void _showAddPlayerDialog() {
    // Hiển thị dialog thêm người chơi mới
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thêm người chơi mới'),
            content: const Text('Chức năng này sẽ được triển khai sau'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }
}
