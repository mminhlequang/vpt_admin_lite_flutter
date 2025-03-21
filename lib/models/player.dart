
class Player {
  int? id;
  String? name;
  String? avatar;
  String? email;
  String? phone;
  int? height;
  int? weight;
  dynamic paddle;
  String? plays;
  String? backHand;
  dynamic turnedPro;
  String? birthPlace;
  String? birthDate;
  int? age;
  String? bio;
  int? sex;
  dynamic linkTwitter;
  dynamic linkFacebook;
  dynamic linkInstagram;
  dynamic linkYoutube;
  int? active;

  Player({this.id, this.name, this.avatar, this.email, this.phone, this.height, this.weight, this.paddle, this.plays, this.backHand, this.turnedPro, this.birthPlace, this.birthDate, this.age, this.bio, this.sex, this.linkTwitter, this.linkFacebook, this.linkInstagram, this.linkYoutube, this.active});

  Player.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    avatar = json["avatar"];
    email = json["email"];
    phone = json["phone"];
    height = json["height"];
    weight = json["weight"];
    paddle = json["paddle"];
    plays = json["plays"];
    backHand = json["back_hand"];
    turnedPro = json["turned_pro"];
    birthPlace = json["birth_place"];
    birthDate = json["birth_date"];
    age = json["age"];
    bio = json["bio"];
    sex = json["sex"];
    linkTwitter = json["link_twitter"];
    linkFacebook = json["link_facebook"];
    linkInstagram = json["link_instagram"];
    linkYoutube = json["link_youtube"];
    active = json["active"];
  }

  static List<Player> fromList(List<Map<String, dynamic>> list) {
    return list.map(Player.fromJson).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["name"] = name;
    _data["avatar"] = avatar;
    _data["email"] = email;
    _data["phone"] = phone;
    _data["height"] = height;
    _data["weight"] = weight;
    _data["paddle"] = paddle;
    _data["plays"] = plays;
    _data["back_hand"] = backHand;
    _data["turned_pro"] = turnedPro;
    _data["birth_place"] = birthPlace;
    _data["birth_date"] = birthDate;
    _data["age"] = age;
    _data["bio"] = bio;
    _data["sex"] = sex;
    _data["link_twitter"] = linkTwitter;
    _data["link_facebook"] = linkFacebook;
    _data["link_instagram"] = linkInstagram;
    _data["link_youtube"] = linkYoutube;
    _data["active"] = active;
    return _data;
  }
}