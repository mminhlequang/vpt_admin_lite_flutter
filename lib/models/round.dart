import 'models.dart';

class Round {
  int? id;
  String? name;
  String? startTime;
  List<TournamentMatch>? matches;

  Round({this.id, this.name, this.startTime, this.matches});

  Round.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    startTime = json["start_time"];
    matches =
        json["matches"] is List
            ? List<TournamentMatch>.from(
              json["matches"].map((x) => TournamentMatch.fromJson(x)),
            )
            : null;
  }

  static List<Round> fromList(List<Map<String, dynamic>> list) {
    return list.map(Round.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["name"] = name;
    _data["start_time"] = startTime;
    if (matches != null) {
      _data["matches"] = matches!.map((e) => e.toJson()).toList();
    }
    return _data;
  }
}
