import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/url_utils.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/announcement_model.dart';
import '../routes.dart'; // 确保导入路由以跳转到详情

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  // 筛选状态
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';

  final List<String> _statusOptions = ['All', 'upcoming', 'ongoing', 'expired'];
  final List<String> _priorityOptions = ['All', 'high', 'medium', 'low'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Announcements'),
      ),
      body: Column(
        children: [
          // 筛选器区域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Status',
                    value: _selectedStatus,
                    items: _statusOptions,
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Priority',
                    value: _selectedPriority,
                    items: _priorityOptions,
                    onChanged: (val) => setState(() => _selectedPriority = val!),
                  ),
                ),
              ],
            ),
          ),

          // 列表区域
          Expanded(
            child: StreamBuilder<List<AnnouncementModel>>(
              stream: FirestoreService.announcementsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No announcements available.'));
                }

                // 在客户端执行筛选
                List<AnnouncementModel> announcements = snapshot.data!;

                if (_selectedStatus != 'All') {
                  announcements = announcements
                      .where((a) => a.status == _selectedStatus)
                      .toList();
                }

                if (_selectedPriority != 'All') {
                  announcements = announcements
                      .where((a) => a.priority == _selectedPriority)
                      .toList();
                }

                // 排序：置顶的公告排在前面，按发布时间倒序
                announcements.sort((a, b) {
                  // 置顶的优先级最高
                  if (a.isPinned && !b.isPinned) return -1;
                  if (!a.isPinned && b.isPinned) return 1;
                  // 同等置顶状态下，按发布时间倒序
                  return b.publishedAt.compareTo(a.publishedAt);
                });

                if (announcements.isEmpty) {
                  return const Center(child: Text('No announcements match filter.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      child: InkWell(
                        onTap: () {
                          // 跳转到详情页，传递对象（或者ID）
                          Navigator.pushNamed(
                            context,
                            AppRoutes.announcementDetail,
                            arguments: announcement,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isValidImageUrl(announcement.image))
                              CachedNetworkImage(
                                imageUrl: announcement.image!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            else
                              Container(
                                height: 160,
                                width: double.infinity,
                                color: _getCategoryColor(announcement.category).withOpacity(0.1),
                                child: Center(
                                  child: Icon(
                                    _getCategoryIcon(announcement.category),
                                    size: 60,
                                    color: _getCategoryColor(announcement.category),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(announcement.category).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          announcement.categoryDisplay,
                                          style: TextStyle(
                                            color: _getCategoryColor(announcement.category),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (announcement.isPinned) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.push_pin,
                                            size: 12,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      // 显示点赞数小图标（可选，既然要移除作者，这里放点赞挺好）
                                      Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${announcement.likeCount}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    announcement.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    announcement.content,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      // 移除了 Author 显示
                                      // 仅显示日期
                                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM dd').format(announcement.publishedAt),
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: items.map((String val) {
              return DropdownMenuItem(
                value: val,
                child: Text(val.toUpperCase(), style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

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
}