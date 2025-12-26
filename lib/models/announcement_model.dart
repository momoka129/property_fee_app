class AnnouncementModel {
  final String id;
  final String title;
  final String summary; // 公告摘要
  final String content;
  final String category; // 'event', 'maintenance', 'notice', 'facility', 'emergency'
  final String priority; // 'low', 'medium', 'high'
  final String status;   // 'upcoming', 'ongoing', 'expired'
  final DateTime? expireAt;
  final String? image;
  final DateTime publishedAt;
  final String author;
  final bool isPinned;
  final int likeCount; // 新增点赞数

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.summary, // 必需的摘要字段
    required this.content,
    required this.category,
    this.priority = 'medium',
    this.status = 'upcoming', // 默认为 upcoming
    this.expireAt,
    this.image,
    required this.publishedAt,
    required this.author,
    this.isPinned = false,
    this.likeCount = 0, // 默认为 0
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    dynamic rawPublishedAt = map['publishedAt'];
    DateTime parsedPublishedAt;
    if (rawPublishedAt == null) {
      parsedPublishedAt = DateTime.now();
    } else if (rawPublishedAt is DateTime) {
      parsedPublishedAt = rawPublishedAt;
    } else if (rawPublishedAt is int) {
      parsedPublishedAt = DateTime.fromMillisecondsSinceEpoch(rawPublishedAt);
    } else if (rawPublishedAt is String) {
      parsedPublishedAt = DateTime.tryParse(rawPublishedAt) ?? DateTime.now();
    } else {
      try {
        parsedPublishedAt = (rawPublishedAt as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedPublishedAt = DateTime.now();
      }
    }

    // parse expireAt similarly to publishedAt (support DateTime, Timestamp, int, String)
    dynamic rawExpireAt = map['expireAt'];
    DateTime? parsedExpireAt;
    if (rawExpireAt == null) {
      parsedExpireAt = null;
    } else if (rawExpireAt is DateTime) {
      parsedExpireAt = rawExpireAt;
    } else if (rawExpireAt is int) {
      parsedExpireAt = DateTime.fromMillisecondsSinceEpoch(rawExpireAt);
    } else if (rawExpireAt is String) {
      parsedExpireAt = DateTime.tryParse(rawExpireAt);
    } else {
      try {
        parsedExpireAt = (rawExpireAt as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedExpireAt = null;
      }
    }

    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      summary: map['summary'] ?? '', // 读取摘要字段
      content: map['content'] ?? '',
      category: map['category'] ?? 'notice',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'upcoming', // 读取 status
      image: map['image'] as String?,
      expireAt: parsedExpireAt,
      publishedAt: parsedPublishedAt,
      author: map['author'] ?? 'Management',
      isPinned: map['isPinned'] ?? false,
      likeCount: map['likeCount'] ?? 0, // 读取 likeCount
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary, // 包含摘要字段
      'content': content,
      'category': category,
      'priority': priority,
      'status': status,
      'image': image,
      'publishedAt': publishedAt.toIso8601String(),
      'expireAt': expireAt?.toIso8601String(),
      'author': author,
      'isPinned': isPinned,
      'likeCount': likeCount,
    };
  }

  String get categoryDisplay {
    switch (category) {
      case 'event':
        return 'Event';
      case 'maintenance':
        return 'Maintenance';
      case 'notice':
        return 'Notice';
      case 'facility':
        return 'Facility';
      case 'emergency':
        return 'Emergency';
      default:
        return category;
    }
  }
}