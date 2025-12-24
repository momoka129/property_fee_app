import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_announcements_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/repairs_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/packages_screen.dart';
import 'screens/parking_screen.dart';
import 'screens/parking_screen_firebase.dart';
import 'screens/help_support_screen.dart';
import 'screens/about_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/admin_bills_screen.dart';
import 'screens/admin_repairs_screen.dart';
import 'screens/admin_parking_screen.dart';
import 'screens/manage_banks_screen.dart';
import 'screens/bank_transfer_screen.dart';
import 'models/bill_model.dart';
import 'screens/admin_packages_screen.dart';
import 'screens/notifications_screen.dart';
// route-only file; models are not required here

class AppRoutes {
  static const login = '/';
  static const register = '/register';
  static const home = '/home';
  static const adminHome = '/admin-home';
  static const bills = '/bills';
  static const repairs = '/repairs';
  static const announcements = '/announcements';
  static const adminAnnouncements = '/admin-announcements';
  static const createAnnouncement = '/admin-announcement-create';
  static const adminBills = '/admin-bills';
  static const adminRepairs = '/admin-repairs';
  static const adminParking = '/admin-parking';
  static const packages = '/packages';
  static const parking = '/parking';
  static const helpSupport = '/help-support';
  static const about = '/about';
  static const editProfile = '/edit-profile';
  static const changePassword = '/change-password';
  static const manageBanks = '/manage-banks';
  static const bankTransfer = '/bank-transfer';
  static const announcementDetail = '/announcement-detail';
  static const payment = '/payment';
  static const visitors = '/visitors';
  static const amenities = '/amenities';
  static const language = '/language';
  static const adminPackages = '/admin-packages';
  static const notifications = '/notifications';

  static Map<String, WidgetBuilder> map = {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),
    adminHome: (_) => const AdminHomeScreen(),
    bills: (_) => const BillsScreen(),
    repairs: (_) => const RepairsScreen(),
    announcements: (_) => const AnnouncementsScreen(),
    adminAnnouncements: (_) => const AdminAnnouncementsScreen(),
    adminBills: (_) => const AdminBillsScreen(),
    adminRepairs: (_) => const AdminRepairsScreen(),
    adminParking: (_) => const AdminParkingScreen(),
    createAnnouncement: (_) => const SizedBox.shrink(), // handled via MaterialPageRoute when opening with args
    packages: (_) => const PackagesScreen(),
    parking: (_) => const ParkingScreen(),
    helpSupport: (_) => const HelpSupportScreen(),
    about: (_) => const AboutScreen(),
    editProfile: (_) => const EditProfileScreen(),
    changePassword: (_) => const ChangePasswordScreen(),
    manageBanks: (_) => const ManageBanksScreen(),
    adminPackages: (_) => const AdminPackagesScreen(),
    notifications: (_) => const NotificationsScreen(),

    bankTransfer: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) return const SizedBox.shrink();
      return BankTransferScreen(
        bill: args['bill'] as BillModel,
        bills: args['bills'] as List<BillModel>?,
      );
    },
    visitors: (_) => Scaffold(
      appBar: AppBar(title: const Text('Visitors')),
      body: const Center(child: Text('Visitors feature coming soon')),
    ),
    amenities: (_) => Scaffold(
      appBar: AppBar(title: const Text('Amenities')),
      body: const Center(child: Text('Amenities feature coming soon')),
    ),
    language: (_) => Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: const Center(child: Text('Language settings coming soon')),
    ),
  };
}
