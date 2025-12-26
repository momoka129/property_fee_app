import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../services/firestore_service.dart';
import 'create_edit_announcement_screen.dart';
import '../widgets/glass_container.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final Color bgGradientStart = const Color(0xFFF3F4F6);
  final Color bgGradientEnd = const Color(0xFFE5E7EB);
  final Color cardColor = Colors.white;
  final BorderRadius kCardRadius = BorderRadius.circular(20);
  final List<BoxShadow> kCardShadow = [
    BoxShadow(
      color: const Color(0xFF1F2937).withOpacity(0.06),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildAnnouncementList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEditAnnouncementScreen(isEdit: false)));
        },
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 4,
        icon: const Icon(Icons.campaign_outlined, color: Colors.white),
        label: const Text('Post News', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: kCardShadow),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Announcements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList() {
    return StreamBuilder<List<AnnouncementModel>>(
      stream: FirestoreService.announcementsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), Text('No announcements posted', style: TextStyle(color: Colors.grey[500]))]));

        items.sort((a, b) {
          final aPinned = a.isPinned ? 1 : 0; final bPinned = b.isPinned ? 1 : 0;
          if (bPinned != aPinned) return bPinned - aPinned;
          int priorityValue(String p) { switch (p) { case 'high': return 3; case 'medium': return 2; case 'low': return 1; } return 0; }
          final pDiff = priorityValue(b.priority) - priorityValue(a.priority);
          if (pDiff != 0) return pDiff;
          return b.publishedAt.compareTo(a.publishedAt);
        });

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildAnnouncementCard(items[index]),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel ann) {
    final theme = _getCategoryTheme(ann.category);
    final dateDay = DateFormat('dd').format(ann.publishedAt);
    final dateMonth = DateFormat('MMM').format(ann.publishedAt);

    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: kCardRadius, boxShadow: kCardShadow),
      child: ClipRRect(
        borderRadius: kCardRadius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 70,
                decoration: BoxDecoration(color: theme.color.withOpacity(0.1), border: Border(right: BorderSide(color: theme.color.withOpacity(0.2)))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(dateDay, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.color)), Text(dateMonth.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.color.withOpacity(0.8)))]),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: theme.color, borderRadius: BorderRadius.circular(6)), child: Text(ann.categoryDisplay, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                        const Spacer(),
                        if (ann.isPinned) const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.push_pin, size: 16, color: Colors.orange)),
                        if (ann.priority == 'high') Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(4)), child: const Text('URGENT', style: TextStyle(fontSize: 8, color: Colors.red, fontWeight: FontWeight.bold))),
                      ]),
                      const SizedBox(height: 10),
                      Text(ann.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      if (ann.content.isNotEmpty) Text(ann.content, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        _buildActionButton(icon: Icons.edit_outlined, color: Colors.blue, onTap: () => _navigateToEdit(ann)),
                        const SizedBox(width: 8),
                        _buildActionButton(icon: Icons.delete_outline, color: Colors.red, onTap: () => _confirmDelete(ann)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color)),
    );
  }

  _CategoryTheme _getCategoryTheme(String category) {
    switch (category.toLowerCase()) {
      case 'event': return _CategoryTheme(color: const Color(0xFF8B5CF6));
      case 'maintenance': return _CategoryTheme(color: const Color(0xFFF97316));
      case 'news': return _CategoryTheme(color: const Color(0xFF3B82F6));
      case 'alert': case 'emergency': return _CategoryTheme(color: const Color(0xFFEF4444));
      default: return _CategoryTheme(color: const Color(0xFF10B981));
    }
  }

  void _navigateToEdit(AnnouncementModel ann) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditAnnouncementScreen(
          isEdit: true,
          announcementId: ann.id,
          initialData: {
            'title': ann.title,
            'summary': ann.summary,
            'content': ann.content,
            'category': ann.category,
            'priority': ann.priority,
            'status': ann.status,
            'publishedAt': ann.publishedAt,
            // pass the actual expireAt from the model (may be null)
            'expireAt': (ann as dynamic).expireAt,
            'isPinned': ann.isPinned,
            'author': ann.author,
            'image': ann.image,
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(AnnouncementModel ann) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          opacity: 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever_rounded, size: 32, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text("Delete Announcement", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("This action implies permanent deletion.", style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel"))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red, elevation: 0), onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete"))),
              ]),
            ],
          ),
        ),
      ),
    ) ?? false;

    if (confirmed) {
      await FirestoreService.deleteAnnouncement(ann.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement deleted'), backgroundColor: Colors.red));
    }
  }
}

class _CategoryTheme {
  final Color color;
  _CategoryTheme({required this.color});
}