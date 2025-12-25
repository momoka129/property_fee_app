// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../routes.dart';

// 引入拆分后的模块
import 'home_tabs/dashboard_tab.dart';
import 'home_tabs/services_tab.dart';
import 'home_tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 可以在这里处理初始化逻辑
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用Consumer监听用户数据变化
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final currentUser = appProvider.currentUser;

        // 如果没有登录用户，跳转到登录页
        if (currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 构建页面列表，传入必要的参数
        final pages = [
          DashboardTab(user: currentUser, appProvider: appProvider),
          ServicesTab(appProvider: appProvider),
          ProfileTab(user: currentUser, appProvider: appProvider),
        ];

        return Scaffold(
          body: pages[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps),
                label: 'Services',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}