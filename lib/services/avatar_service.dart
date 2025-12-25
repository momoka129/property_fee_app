import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AvatarService {
  static final ImagePicker _picker = ImagePicker();

  /// 选择图片来源
  static Future<ImageSource?> _selectImageSource(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择图片来源'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  /// 选择并上传头像图片到Firebase Storage
  static Future<String?> pickAndUploadAvatar(BuildContext context, String userId) async {
    try {
      // 选择图片来源
      final ImageSource? source = await _selectImageSource(context);
      if (source == null) return null;

      // 选择图片
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return null;

      // 显示上传进度
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading avatar...')),
        );
      }

      // 生成文件名：avatars/user_{userId}_{timestamp}.jpg
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'user_${userId}_$timestamp.jpg';
      final String storagePath = 'avatars/$fileName';

      // 上传到Firebase Storage
      final Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 等待上传完成
      final TaskSnapshot snapshot = await uploadTask;

      // 获取下载URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 显示成功消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar uploaded')),
        );
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');

      // 显示错误消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: ${e.toString()}')),
        );
      }

      return null;
    }
  }

  /// 选择并保存头像图片到本地（向后兼容）
  @deprecated
  static Future<String?> pickAndSaveAvatar(BuildContext context, String userId) async {
    return await pickAndUploadAvatar(context, userId);
  }

  /// 验证头像URL是否有效
  static bool isValidAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return false;

    // 检查是否是Firebase Storage URL或网络URL
    return avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');
  }

  /// 验证图片文件是否存在（本地文件，向后兼容）
  @deprecated
  static bool isValidAvatarPath(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return false;

    // 如果是本地文件路径，检查文件是否存在
    if (!avatarPath.startsWith('http')) {
      return File(avatarPath).existsSync();
    }

    // 如果是网络URL，直接认为是有效的
    return true;
  }
}
