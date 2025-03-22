import 'models.dart';

enum MatchStatus {
  pending, // Chưa diễn ra
  ongoing, // Đang diễn ra
  completed, // Đã kết thúc
  cancelled, // Đã hủy
}

class TournamentMatch {
  int? id;
  Round? round;
  String? stadium;
  String? scheduledTime;
  MatchStatus? matchStatus;
  int? team1Score;
  int? team2Score;
  Team? team1;
  Team? team2;

  Team? get winner =>
      team1Score == null || team2Score == null
          ? null
          : team1Score! > team2Score!
          ? team1
          : team2;

  TournamentMatch({
    this.id,
    this.round,
    this.stadium,
    this.scheduledTime,
    this.matchStatus,
    this.team1Score,
    this.team2Score,
    this.team1,
    this.team2,
  });

  TournamentMatch.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    round = json["round"] == null ? null : Round.fromJson(json["round"]);
    stadium = json["stadium"];
    scheduledTime = json["scheduled_time"];
    matchStatus =
        json["match_status"] == null
            ? null
            : MatchStatus.values.byName(json["match_status"]);
    team1Score = json["team1_score"];
    team2Score = json["team2_score"];
    team1 = json["team1"] == null ? null : Team.fromJson(json["team1"]);
    team2 = json["team2"] == null ? null : Team.fromJson(json["team2"]);
  }

  static List<TournamentMatch> fromList(List<Map<String, dynamic>> list) {
    return list.map(TournamentMatch.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["round"] = round?.toJson();
    _data["stadium"] = stadium;
    _data["scheduled_time"] = scheduledTime;
    _data["match_status"] = matchStatus?.name;
    _data["team1_score"] = team1Score;
    _data["team2_score"] = team2Score;
    if (team1 != null) {
      _data["team1"] = team1?.toJson();
    }
    if (team2 != null) {
      _data["team2"] = team2?.toJson();
    }
    return _data;
  }
}
