import 'package:flutter/material.dart';
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


}

