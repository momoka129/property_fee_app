import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_container.dart'; // 引入 GlassContainer

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

  // 背景渐变
  final Color bgGradientStart = const Color(0xFFF3F4F6);
  final Color bgGradientEnd = const Color(0xFFE5E7EB);

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

  // ... _pickPublishedAt, _pickExpireAt, _pickImage, _uploadImage, _removeImage 方法保持不变 ...
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Announcement' : 'Create Announcement', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: GlassContainer(
              opacity: 0.8,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration('Title', Icons.title),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _summaryController,
                      decoration: _buildInputDecoration('Summary', Icons.short_text),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Summary is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: _buildInputDecoration('Content', Icons.article_outlined),
                      maxLines: 6,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Image Picker Section
                    const Text('Featured Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_imageUrl != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(onPressed: _uploadingImage ? null : _pickImage, icon: const Icon(Icons.edit, color: Colors.blue)),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(onPressed: _removeImage, icon: const Icon(Icons.delete, color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _uploadingImage ? null : _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                          ),
                          child: _uploadingImage
                              ? const Center(child: CircularProgressIndicator())
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text('Tap to upload image', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // --- 修改开始：改为垂直排列，防止宽度溢出 ---
                    DropdownButtonFormField<String>(
                      value: _category,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _category = v ?? _category),
                      decoration: _buildInputDecoration('Category', Icons.category_outlined),
                      isExpanded: true, // 确保文字过长时自动截断或换行，防止内部溢出
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _priority,
                      items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _priority = v ?? _priority),
                      decoration: _buildInputDecoration('Priority', Icons.flag_outlined),
                      isExpanded: true,
                    ),
                    // --- 修改结束 ---

                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _status = v ?? _status),
                      decoration: _buildInputDecoration('Status', Icons.info_outline),
                    ),
                    const SizedBox(height: 24),

                    // --- 同样建议优化：日期选择器也改为垂直排列，避免潜在溢出 ---
                    InkWell(
                      onTap: _pickPublishedAt,
                      child: InputDecorator(
                        decoration: _buildInputDecoration('Published At', Icons.calendar_today),
                        child: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(_publishedAt),
                            style: const TextStyle(fontSize: 15, color: Colors.black87)
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _pickExpireAt,
                      child: InputDecorator(
                        decoration: _buildInputDecoration('Expires At (Optional)', Icons.event_busy),
                        child: Text(
                            _expireAt == null ? 'Never' : DateFormat('yyyy-MM-dd HH:mm').format(_expireAt!),
                            style: const TextStyle(fontSize: 15, color: Colors.black87)
                        ),
                      ),
                    ),
                    // -----------------------------------------------------

                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pin to Top', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Show this at the top of the list'),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.push_pin, color: Colors.orange),
                      ),
                      value: _pinned,
                      onChanged: (v) => setState(() => _pinned = v),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _submit,
                        child: Text(
                          widget.isEdit ? 'Update Announcement' : 'Publish Announcement',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
    );
  }
}