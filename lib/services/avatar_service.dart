import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

  /// 选择并保存头像图片
  static Future<String?> pickAndSaveAvatar(BuildContext context, String userId) async {
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

      // 获取应用文档目录
      final Directory appDir = await getApplicationDocumentsDirectory();

      // 创建avatars子目录
      final Directory avatarsDir = Directory(path.join(appDir.path, 'avatars'));
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      // 生成文件名：user_{userId}_{timestamp}.jpg
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'user_${userId}_$timestamp.jpg';
      final String filePath = path.join(avatarsDir.path, fileName);

      // 复制图片到目标位置
      await File(image.path).copy(filePath);

      return filePath;
    } catch (e) {
      debugPrint('Error picking/saving avatar: $e');
      return null;
    }
  }

  /// 验证图片文件是否存在
  static bool isValidAvatarPath(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return false;
    return File(avatarPath).existsSync();
  }
}
