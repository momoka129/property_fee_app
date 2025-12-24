import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app_theme.dart';
import 'routes.dart';
import 'providers/app_provider.dart';
import 'screens/announcement_detail_screen.dart';
import 'screens/payment_screen.dart';
import 'models/announcement_model.dart';
import 'models/bill_model.dart';
import 'services/data_migration_service.dart';
 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  // 使用超时和错误处理，防止初始化在网络或配置问题时无限等待
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));

    // 迁移账单数据到Firestore（仅在开发/测试时执行）
    if (kDebugMode) {
      try {
        final hasExistingData = await DataMigrationService.hasExistingBills();
        if (!hasExistingData) {
          await DataMigrationService.migrateBillsToFirestore();
        } else {
          debugPrint('Bills data already exists in Firestore, skipping migration');
        }
      } catch (e) {
        debugPrint('Data migration failed: $e');
      }
    }
  } catch (e, st) {
    // 打印错误但继续运行，避免应用卡在原生启动页
    debugPrint('Firebase.initializeApp failed: $e\n$st');
  }

  // 初始化 easy_localization（带超时）
  try {
    await EasyLocalization.ensureInitialized().timeout(const Duration(seconds: 5));
  } catch (e, st) {
    debugPrint('EasyLocalization.ensureInitialized failed: $e\n$st');
  }
  
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh'), Locale('ms')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const PropertyFeeApp(),
    ),
  );
}

class PropertyFeeApp extends StatelessWidget {
  const PropertyFeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'Smart Property',
            theme: AppTheme.light(),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routes: AppRoutes.map,
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.announcementDetail) {
                final announcement = settings.arguments as AnnouncementModel;
                return MaterialPageRoute(
                  builder: (_) => AnnouncementDetailScreen(announcement: announcement),
                );
              }
              if (settings.name == AppRoutes.payment) {
                final args = settings.arguments;
                if (args is BillModel) {
                  return MaterialPageRoute(
                    builder: (_) => PaymentScreen(bill: args),
                  );
                } else if (args is Map<String, dynamic>) {
                  return MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      bill: args['bill'] as BillModel,
                      bills: args['bills'] as List<BillModel>?,
                    ),
                  );
                }
              }
              return null;
            },
            initialRoute: AppRoutes.login,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
