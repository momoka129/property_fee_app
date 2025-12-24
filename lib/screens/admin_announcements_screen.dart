import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../services/firestore_service.dart';
import 'create_edit_announcement_screen.dart';

class AdminAnnouncementsScreen extends StatelessWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: FirestoreService.announcementsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No announcements found.'));
          }
          // client-side sort: pinned -> priority (high>medium>low) -> publishedAt desc
          items.sort((a, b) {
            final aPinned = a.isPinned ? 1 : 0;
            final bPinned = b.isPinned ? 1 : 0;
            if (bPinned != aPinned) return bPinned - aPinned;
            int priorityValue(String p) {
              switch (p) {
                case 'high':
                  return 3;
                case 'medium':
                  return 2;
                case 'low':
                  return 1;
              }
              return 0;
            }
            final pDiff = priorityValue(b.priority) - priorityValue(a.priority);
            if (pDiff != 0) return pDiff;
            return b.publishedAt.compareTo(a.publishedAt);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final ann = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ann.isPinned ? const Icon(Icons.push_pin, color: Colors.orange) : null,
                  title: Text(ann.title),
                  subtitle: Text('${ann.categoryDisplay} • ${DateFormat('MMM dd, yyyy').format(ann.publishedAt)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                          onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateEditAnnouncementScreen(
                                isEdit: true,
                                announcementId: ann.id,
                                initialData: {
                                  'title': ann.title,
                                  'summary': '', // model doesn't have summary; leave blank
                                  'content': ann.content,
                                  'category': ann.category,
                                  'priority': ann.priority,
                                  'status': 'ongoing',
                                  'publishedAt': ann.publishedAt,
                                  'expireAt': null,
                                  'isPinned': ann.isPinned,
                                  'author': ann.author,
                                  'image': ann.image,
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Announcement'),
                                  content: const Text('Are you sure you want to delete this announcement?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                  ],
                                ),
                              ) ??
                              false;
                          if (confirmed) {
                            await FirestoreService.deleteAnnouncement(ann.id);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement deleted')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEditAnnouncementScreen(isEdit: false)),
          );
        },
      ),
    );
  }
}


