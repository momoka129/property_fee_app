import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import '../widgets/keyboard_text_field.dart';

class CreateEditAnnouncementScreen extends StatefulWidget {
  final bool isEdit;
  final String? announcementId;
  final Map<String, dynamic>? initialData;

  const CreateEditAnnouncementScreen({
    super.key,
    required this.isEdit,
    this.announcementId,
    this.initialData,
  });

  @override
  State<CreateEditAnnouncementScreen> createState() => _CreateEditAnnouncementScreenState();
}

class _CreateEditAnnouncementScreenState extends State<CreateEditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();

  String _category = 'maintenance';
  String _priority = 'medium';
  String _status = 'upcoming';
  DateTime _publishedAt = DateTime.now();
  DateTime? _expireAt;
  bool _pinned = false;

  static const categories = ['maintenance', 'billing', 'security', 'event', 'policy', 'emergency'];
  static const priorities = ['low', 'medium', 'high'];
  static const statuses = ['upcoming', 'ongoing', 'expired'];

  @override
  void initState() {
    super.initState();
    final init = widget.initialData;
    if (init != null) {
      _titleController.text = init['title'] ?? '';
      _summaryController.text = init['summary'] ?? '';
      _contentController.text = init['content'] ?? '';
      _category = init['category'] ?? _category;
      _priority = init['priority'] ?? _priority;
      _status = init['status'] ?? _status;
      _publishedAt = init['publishedAt'] is DateTime ? init['publishedAt'] as DateTime : DateTime.now();
      _expireAt = init['expireAt'] is DateTime ? init['expireAt'] as DateTime : null;
      _pinned = init['isPinned'] ?? false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPublishedAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_publishedAt));
    if (time == null) return;
    setState(() {
      _publishedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickExpireAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expireAt ?? _publishedAt.add(const Duration(days: 1)),
      firstDate: _publishedAt,
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 23, minute: 59));
    if (time == null) return;
    setState(() {
      _expireAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // expireAt must be null or > publishedAt
    if (_expireAt != null && !_expireAt!.isAfter(_publishedAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expire time must be after published time')));
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;
    final authorName = currentUser?.name ?? currentUser?.email ?? 'Management';

    final data = {
      'title': _titleController.text.trim(),
      'summary': _summaryController.text.trim(),
      'content': _contentController.text.trim(),
      'category': _category,
      'priority': _priority,
      'status': _status,
      'publishedAt': _publishedAt,
      'expireAt': _expireAt,
      'author': authorName,
      'isPinned': _pinned,
      'image': null,
    };

    try {
      if (widget.isEdit && widget.announcementId != null) {
        await FirestoreService.updateAnnouncement(widget.announcementId!, data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement updated')));
      } else {
        await FirestoreService.createAnnouncement(data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement created')));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Announcement' : 'Create Announcement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyboardTextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              KeyboardTextField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Summary'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Summary is required' : null,
              ),
              const SizedBox(height: 12),
              KeyboardTextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v ?? _category),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setState(() => _priority = v ?? _priority),
                      decoration: const InputDecoration(labelText: 'Priority'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickPublishedAt,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Published At'),
                        child: Text(DateFormat('yyyy-MM-dd HH:mm').format(_publishedAt)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickExpireAt,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Expire At (optional)'),
                        child: Text(_expireAt == null ? 'Not set' : DateFormat('yyyy-MM-dd HH:mm').format(_expireAt!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Pinned'),
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.isEdit ? 'Update' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


