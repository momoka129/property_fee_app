import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/url_utils.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片或图标
            if (isValidImageUrl(announcement.image))
              CachedNetworkImage(
                imageUrl: announcement.image!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.error),
                ),
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                color: _getCategoryColor(announcement.category).withOpacity(0.1),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(announcement.category),
                    size: 100,
                    color: _getCategoryColor(announcement.category),
                  ),
                ),
              ),

            // 内容区域
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 分类标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(announcement.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      announcement.categoryDisplay,
                      style: TextStyle(
                        color: _getCategoryColor(announcement.category),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 标题
                  Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // 作者和日期
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        announcement.author,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM dd, yyyy').format(announcement.publishedAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 优先级标签
                  if (announcement.priority != 'medium')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(announcement.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(announcement.priority),
                            size: 16,
                            color: _getPriorityColor(announcement.priority),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            announcement.priority.toUpperCase(),
                            style: TextStyle(
                              color: _getPriorityColor(announcement.priority),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (announcement.priority != 'medium') const SizedBox(height: 24),

                  // 内容
                  Text(
                    'Content',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'event':
        return Colors.purple;
      case 'maintenance':
        return Colors.orange;
      case 'notice':
        return Colors.blue;
      case 'facility':
        return Colors.green;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'event':
        return Icons.event;
      case 'maintenance':
        return Icons.build;
      case 'notice':
        return Icons.notifications;
      case 'facility':
        return Icons.pool;
      case 'emergency':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.info;
    }
  }
}














