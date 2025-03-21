import 'package:flutter/material.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/player.dart';
import '../../widgets/player/player_list_item.dart';
import '../../utils/constants.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'player_detail_screen.dart';
import 'create_player_screen.dart';

Future<List<Player>> fetchPlayers() async {
  List<Player> playersList = [];
  // Gọi API thực tế để lấy danh sách người chơi
  final response = await appDioClient.get('player');

  if (response.statusCode == 200) {
    final data = json.decode(jsonEncode(response.data));

    // Chuyển đổi dữ liệu từ API thành danh sách Player
    if (data is List) {
      playersList = data.map((item) => Player.fromJson(item)).toList();
    } else if (data['data'] is List) {
      playersList =
          (data['data'] as List).map((item) => Player.fromJson(item)).toList();
    }

    return playersList;
  } else {
    print('Không thể tải dữ liệu từ API: ${response.statusCode}');
    return playersList;
  }
}

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

    _players = await fetchPlayers();
    setState(() {
      _isLoading = false;
    });
  }

  List<Player> _getFilteredPlayers() {
    final searchQuery = _searchController.text.toLowerCase();

    if (searchQuery.isEmpty) {
      return _players;
    }

    return _players.where((player) {
      return player.name?.toLowerCase().contains(searchQuery) ?? false ||
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
              // onApprove:
              //     () =>
              //         _updatePlayerStatus(player, RegistrationStatus.approved),
              // onReject:
              //     () =>
              //         _updatePlayerStatus(player, RegistrationStatus.rejected),
              // onTogglePaid: () => _togglePlayerPaidStatus(player),
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
    ).then((result) {
      // Nếu quay về từ màn hình chi tiết và có thay đổi (true)
      if (result == true) {
        _loadPlayers();
      }
    });
  }

   

  void _showAddPlayerDialog() {
    // Điều hướng đến màn hình tạo người chơi mới
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePlayerScreen()),
    ).then((result) {
      // Nếu tạo người chơi thành công, cập nhật lại danh sách
      if (result == true) {
        _loadPlayers();
      }
    });
  }
}
