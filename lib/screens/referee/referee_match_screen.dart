import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import '../../models/models.dart';

class RefereeMatchScreen extends StatefulWidget {
  final String? matchId;
  final String? tournamentId;

  const RefereeMatchScreen({
    Key? key,
    this.matchId,
    this.tournamentId,
  }) : super(key: key);

  @override
  State<RefereeMatchScreen> createState() => _RefereeMatchScreenState();
}

class _RefereeMatchScreenState extends State<RefereeMatchScreen> {
  // Điểm số hiện tại
  int _team1Points = 0;
  int _team2Points = 0;
  int _currentSet = 2; // Hiệp đấu hiện tại

  // Lỗi
  bool _team1Fault = false;
  bool _team2Fault = false;

  // Đồng hồ bấm giờ
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = "00:00";

  // Trạng thái trận đấu
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fetchFetchInfos();
  }

  bool _isLoading = false;
  Tournament _tournament = Tournament();
  TournamentMatch _match = TournamentMatch();
  _fetchFetchInfos() async {
    setState(() {
      _isLoading = true;
    });

    final response = await appDioClient.get(
      '/tournament/detail',
      queryParameters: {"id": widget.tournamentId},
    );
    if (response.statusCode == 200) {
      setState(() {
        _tournament = Tournament.fromJson(response.data['data']);
        _tournament.rounds?.forEach((element) {
          element.matches?.forEach((match) {
            if (match.id?.toString() == widget.matchId) {
              _match = match;
            }
          });
        });
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final minutes = _stopwatch.elapsed.inMinutes;
        final seconds = _stopwatch.elapsed.inSeconds % 60;
        _elapsedTime =
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      });
    });
  }

  void _pauseTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void _toggleMatch() {
    setState(() {
      if (_isPlaying) {
        _pauseTimer();
      } else {
        _startTimer();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleFault(int teamIndex) {
    setState(() {
      if (teamIndex == 1) {
        _team1Fault = !_team1Fault;
      } else {
        _team2Fault = !_team2Fault;
      }
    });
  }

  void _updatePoints(int teamIndex, int points) {
    setState(() {
      if (teamIndex == 1) {
        _team1Points = points;
      } else {
        _team2Points = points;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_isLoading)return const Center(child: CircularProgressIndicator());
    final team1 = _match.team1;
    final team2 = _match.team2;

    // Giả sử team có player1 và player2 cho đôi
    final team1Player1 = team1?.name?.split(" & ").first ?? "Player 1";
    final team1Player2 =
        team1?.name?.contains(" & ") == true
            ? team1?.name?.split(" & ").last
            : "";

    final team2Player1 = team2?.name?.split(" & ").first ?? "Player 2";
    final team2Player2 =
        team2?.name?.contains(" & ") == true
            ? team2?.name?.split(" & ").last
            : "";

    return Scaffold(
      appBar: AppBar(
        title: const Text('THIẾT LẬP VỊ TRÍ ĐỨNG VÀ NGƯỜI GIAO BÓNG'),
        centerTitle: true,
      ),
      body:  Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hiển thị điểm số
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Đội 1
                      Expanded(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              child: Text(team1Player1[0]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              team1Player1,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (team1Player2?.isNotEmpty == true) Text(team1Player2!),
                          ],
                        ),
                      ),

                      // Điểm số giữa
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "$_team1Points",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text("-", style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 10),
                              Text(
                                "$_team2Points",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text("-", style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 10),
                              Text(
                                "$_currentSet",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _elapsedTime,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),

                      // Đội 2
                      Expanded(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              child: Text(team2Player1[0]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              team2Player1,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (team2Player2?.isNotEmpty == true) Text(team2Player2!),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hiển thị lỗi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => _toggleFault(1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                _team1Fault
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.cancel,
                            color:
                                _team1Fault
                                    ? Colors.red
                                    : Colors.grey.withOpacity(0.3),
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 80),
                      GestureDetector(
                        onTap: () => _toggleFault(2),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                _team2Fault
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.cancel,
                            color:
                                _team2Fault
                                    ? Colors.red
                                    : Colors.grey.withOpacity(0.3),
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Các nút điều khiển
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleMatch,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Tạm dừng' : 'Bắt đầu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 50),
                  ),
                ),

                const SizedBox(width: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    // Lưu kết quả trận đấu
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu kết quả'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Phần thiết lập vị trí và giao bóng
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thiết lập vị trí đứng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vị trí sân
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2,
                        children: [
                          // Các nút vị trí đội 1
                          _buildPositionButton('Trái trên', 1, 1),
                          _buildPositionButton('Phải trên', 1, 2),
                          _buildPositionButton('Trái dưới', 1, 3),
                          _buildPositionButton('Phải dưới', 1, 4),

                          // Các nút vị trí đội 2
                          _buildPositionButton('Trái trên', 2, 1),
                          _buildPositionButton('Phải trên', 2, 2),
                          _buildPositionButton('Trái dưới', 2, 3),
                          _buildPositionButton('Phải dưới', 2, 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionButton(
    String position,
    int teamIndex,
    int positionIndex,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Xử lý chọn vị trí
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đội ${teamIndex == 1 ? 'A' : 'B'} - $position',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Nhấn để chọn'),
            ],
          ),
        ),
      ),
    );
  }
}
