class LiveVideo {
  final String id;
  final String title;
  final String imageUrl;
  final String videoUrl;
  final DateTime createdAt;
  final String? description;
  final bool isLive;

  LiveVideo({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.videoUrl,
    required this.createdAt,
    this.description,
    this.isLive = false,
  });

  // Tạo từ JSON
  factory LiveVideo.fromJson(Map<String, dynamic> json) {
    return LiveVideo(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
      isLive: json['isLive'] ?? false,
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'isLive': isLive,
    };
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  LiveVideo copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? videoUrl,
    DateTime? createdAt,
    String? description,
    bool? isLive,
  }) {
    return LiveVideo(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      isLive: isLive ?? this.isLive,
    );
  }
} 