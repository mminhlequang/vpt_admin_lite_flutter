import 'player.dart';

class Team {
  int? id;
  String? uniqueId;
  String? name;
  int? registrationStatus;
  int? paymentStatus;
  String? paymentCode;
  String? registrationDate;
  int? packageId;
  Player? player1;
  Player? player2;

  Team({
    this.id,
    this.uniqueId,
    this.name,
    this.registrationStatus,
    this.paymentStatus,
    this.paymentCode,
    this.registrationDate,
    this.packageId,
    this.player1,
    this.player2,
  });

  Team.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    registrationStatus = json["registration_status"];
    paymentStatus = json["payment_status"];
    paymentCode = json["payment_code"];
    registrationDate = json["registration_date"];
    packageId = json["package_id"];
    player1 = json["player1"] == null ? null : Player.fromJson(json["player1"]);
    player2 = json["player2"] == null ? null : Player.fromJson(json["player2"]);
  }

  static List<Team> fromList(List<Map<String, dynamic>> list) {
    return list.map(Team.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["name"] = name;
    _data["registration_status"] = registrationStatus;
    _data["payment_status"] = paymentStatus;
    _data["payment_code"] = paymentCode;
    _data["registration_date"] = registrationDate;
    _data["package_id"] = packageId;
    if (player1 != null) {
      _data["player1"] = player1?.toJson();
    }
    if (player2 != null) {
      _data["player2"] = player2?.toJson();
    }
    return _data;
  }
}
