import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/url_utils.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../services/firestore_service.dart'; // 引入 Service

class AnnouncementDetailScreen extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    // 使用 StreamBuilder 监听该公告的实时变化（包括点赞数）
    return StreamBuilder<AnnouncementModel>(
      stream: FirestoreService.getAnnouncementStream(announcement.id),
      initialData: announcement, // 使用传入的数据作为初始数据，避免闪烁
      builder: (context, snapshot) {
        final currentData = snapshot.data ?? announcement;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Announcement Details'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // 每个人点赞次数不限制，直接调用
              FirestoreService.incrementAnnouncementLike(currentData.id);
            },
            icon: const Icon(Icons.thumb_up),
            label: Text('Like (${currentData.likeCount})'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80), // 为 FAB 留出空间
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片或图标区域
                if (isValidImageUrl(currentData.image))
                  CachedNetworkImage(
                    imageUrl: currentData.image!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 250,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
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
                    color: _getCategoryColor(currentData.category).withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(currentData.category),
                        size: 100,
                        color: _getCategoryColor(currentData.category),
                      ),
                    ),
                  ),

                // 内容区域
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 分类标签和置顶图标
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(currentData.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentData.categoryDisplay,
                              style: TextStyle(
                                color: _getCategoryColor(currentData.category),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (currentData.isPinned) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.push_pin,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 标题
                      Text(
                        currentData.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 摘要（如果有内容）
                      if (currentData.summary.isNotEmpty) ...[
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentData.summary,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 日期（移除了 Author）
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM dd, yyyy').format(currentData.publishedAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 优先级标签
                      if (currentData.priority != 'medium')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(currentData.priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPriorityIcon(currentData.priority),
                                size: 16,
                                color: _getPriorityColor(currentData.priority),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentData.priority.toUpperCase(),
                                style: TextStyle(
                                  color: _getPriorityColor(currentData.priority),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (currentData.priority != 'medium') const SizedBox(height: 24),

                      // 内容
                      Text(
                        'Content',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentData.content,
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
      },
    );
  }

  // 辅助函数保持不变
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'event': return Colors.purple;
      case 'maintenance': return Colors.orange;
      case 'notice': return Colors.blue;
      case 'facility': return Colors.green;
      case 'emergency': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'event': return Icons.event;
      case 'maintenance': return Icons.build;
      case 'notice': return Icons.notifications;
      case 'facility': return Icons.pool;
      case 'emergency': return Icons.warning;
      default: return Icons.info;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high': return Icons.priority_high;
      case 'medium': return Icons.remove;
      case 'low': return Icons.arrow_downward;
      default: return Icons.info;
    }
  }
}