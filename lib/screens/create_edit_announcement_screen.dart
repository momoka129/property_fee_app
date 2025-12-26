import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';

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
  String? _imageUrl;
  bool _uploadingImage = false;

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
      // parse publishedAt supporting DateTime, int (ms), String, or Timestamp
      final rawPub = init['publishedAt'];
      if (rawPub == null) {
        _publishedAt = DateTime.now();
      } else if (rawPub is DateTime) {
        _publishedAt = rawPub;
      } else if (rawPub is int) {
        _publishedAt = DateTime.fromMillisecondsSinceEpoch(rawPub);
      } else if (rawPub is String) {
        _publishedAt = DateTime.tryParse(rawPub) ?? DateTime.now();
      } else {
        try {
          _publishedAt = (rawPub as dynamic).toDate() as DateTime;
        } catch (_) {
          _publishedAt = DateTime.now();
        }
      }

      // parse expireAt similarly
      final rawExp = init['expireAt'];
      if (rawExp == null) {
        _expireAt = null;
      } else if (rawExp is DateTime) {
        _expireAt = rawExp;
      } else if (rawExp is int) {
        _expireAt = DateTime.fromMillisecondsSinceEpoch(rawExp);
      } else if (rawExp is String) {
        _expireAt = DateTime.tryParse(rawExp);
      } else {
        try {
          _expireAt = (rawExp as dynamic).toDate() as DateTime;
        } catch (_) {
          _expireAt = null;
        }
      }
      _pinned = init['isPinned'] ?? false;
      // preload existing image if editing
      if (init['image'] != null) {
        _imageUrl = init['image'].toString();
      }
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

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
      if (picked == null) return;
      await _uploadImage(picked);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _uploadImage(XFile picked) async {
    setState(() {
      _uploadingImage = true;
    });
    try {
      final file = File(picked.path);
      final fileName = 'announcements/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(file);
      await uploadTask.whenComplete(() {});
      final url = await ref.getDownloadURL();
      setState(() {
        _imageUrl = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
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
      'image': _imageUrl,
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Summary'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Summary is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
              ),
              const SizedBox(height: 12),
              // Image picker / preview
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Image', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  if (_imageUrl != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(_imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(onPressed: _uploadingImage ? null : _pickImage, icon: const Icon(Icons.edit), label: const Text('Change')),
                            const SizedBox(width: 8),
                            TextButton.icon(onPressed: _removeImage, icon: const Icon(Icons.delete), label: const Text('Remove')),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _uploadingImage ? null : _pickImage,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Choose Image'),
                        ),
                        const SizedBox(width: 12),
                        if (_uploadingImage) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                ],
              ),
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


