import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/mock_data.dart';
import '../models/user_model.dart';

class AppProvider with ChangeNotifier {
  UserModel? get currentUser => MockData.currentUser;

  // 更新用户信息
  void updateUser(UserModel? user) {
    if (user == null) {
      MockData.currentUser = null;
    } else {
      MockData.currentUser = user;
    }
    notifyListeners(); // 通知所有监听者更新
  }

  // 获取本地化的文本（保留此方法以兼容现有代码，但实际使用 tr() 方法）
  String getLocalizedText(String key) {
    return key.tr();
  }

}

