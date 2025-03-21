import 'category.dart';
import 'round.dart';
import 'team.dart';
import 'tour_package.dart';

class Tournament {
  int? id;
  String? name;
  String? avatar;
  String? city;
  int? type;
  List<TourPackage>? packages;

  int? numberOfTeam;
  String? genderRestriction;
  Category? category;
  String? startDate;
  String? endDate;
  dynamic drawSize;
  String? surface;
  int? prize;
  int? totalPrize;
  dynamic website;
  dynamic ticket;
  dynamic profile;
  dynamic linkFb;
  dynamic linkInstagram;
  dynamic linkTwitter;
  String? content;

  List<Team>? teams;
  List<Round>? rounds;

  Tournament({
    this.id,
    this.name,
    this.avatar,
    this.city,
    this.type,
    this.packages,
    this.numberOfTeam,
    this.genderRestriction,
    this.category,
    this.startDate,
    this.endDate,
    this.drawSize,
    this.surface,
    this.prize,
    this.totalPrize,
    this.website,
    this.ticket,
    this.profile,
    this.linkFb,
    this.linkInstagram,
    this.linkTwitter,
    this.content,
    this.teams,
    this.rounds,
  });

  Tournament.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    avatar = json["avatar"];
    city = json["city"];
    type = json["type"];
    packages =
        json["packages"] == null
            ? null
            : (json["packages"] as List)
                .map((e) => TourPackage.fromJson(e))
                .toList();
    numberOfTeam = json["number_of_team"];
    genderRestriction = json["gender_restriction"];
    category =
        json["category"] == null ? null : Category.fromJson(json["category"]);
    startDate = json["start_date"];
    endDate = json["end_date"];
    drawSize = json["draw_size"];
    surface = json["surface"];
    prize = json["prize"];
    totalPrize = json["total_prize"];
    website = json["website"];
    ticket = json["ticket"];
    profile = json["profile"];
    linkFb = json["link_fb"];
    linkInstagram = json["link_instagram"];
    linkTwitter = json["link_twitter"];
    content = json["content"];
    teams =
        json["teams"] == null
            ? []
            : json["teams"].map((e) => Team.fromJson(e)).toList();
    rounds =
        json["rounds"] == null
            ? []
            : json["rounds"].map((e) => Round.fromJson(e)).toList();
  }

  static List<Tournament> fromList(List<Map<String, dynamic>> list) {
    return list.map(Tournament.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["name"] = name;
    _data["avatar"] = avatar;
    _data["city"] = city;
    _data["type"] = type;
    if (packages != null) {
      _data["packages"] = packages?.map((e) => e.toJson()).toList();
    }
    _data["number_of_team"] = numberOfTeam;
    _data["gender_restriction"] = genderRestriction;
    if (category != null) {
      _data["category"] = category?.toJson();
    }
    _data["start_date"] = startDate;
    _data["end_date"] = endDate;
    _data["draw_size"] = drawSize;
    _data["surface"] = surface;
    _data["prize"] = prize;
    _data["total_prize"] = totalPrize;
    _data["website"] = website;
    _data["ticket"] = ticket;
    _data["profile"] = profile;
    _data["link_fb"] = linkFb;
    _data["link_instagram"] = linkInstagram;
    _data["link_twitter"] = linkTwitter;
    _data["content"] = content;
    _data["teams"] = teams?.map((e) => e.toJson()).toList();
    _data["rounds"] = rounds?.map((e) => e.toJson()).toList();
    return _data;
  }
}

enum TournamentStatus { preparing, ongoing, completed, cancelled }
