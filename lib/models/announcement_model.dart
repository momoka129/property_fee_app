class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String category; // 'event', 'maintenance', 'notice', 'facility', 'emergency'
  final String priority; // 'low', 'medium', 'high'
  final String? image;
  final DateTime publishedAt;
  final String author;
  final bool isPinned;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.priority = 'medium',
    this.image,
    required this.publishedAt,
    required this.author,
    this.isPinned = false,
  });

  /// Create model from Firestore map (handles Timestamp, int (ms), ISO string, DateTime).
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
      // Firestore Timestamp or other types with toDate()
      try {
        parsedPublishedAt = (rawPublishedAt as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedPublishedAt = DateTime.now();
      }
    }

    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'notice',
      priority: map['priority'] ?? 'medium',
      image: map['image'] as String?,
      publishedAt: parsedPublishedAt,
      author: map['author'] ?? 'Management',
      isPinned: map['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'image': image,
      'publishedAt': publishedAt.toIso8601String(),
      'author': author,
      'isPinned': isPinned,
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










