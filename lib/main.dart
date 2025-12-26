import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'routes.dart';
import 'providers/app_provider.dart';
import 'screens/announcement_detail_screen.dart';
import 'screens/payment_screen.dart';
import 'models/announcement_model.dart';
import 'models/bill_model.dart';
import 'services/data_migration_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Stripe
  Stripe.publishableKey = 'pk_test_51SiB7S9Y9Dc98NLd8oSIMOoKj83KtADaQuGf24ClyjoVmg6teHglsdRHQaZlsn9tVi1QhhMkSEZ9dNPUYW2iVqqE009QlibYjC'; // 您的 Stripe 公钥
  await Stripe.instance.applySettings();

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

      // 同步头像数据到Firebase
      try {
        debugPrint('Starting avatar data sync...');
        await DataMigrationService.syncUserAvatarsToFirebase();
        final status = await DataMigrationService.getAvatarSyncStatus();
        debugPrint('Avatar sync completed. Status: $status');
      } catch (e) {
        debugPrint('Avatar sync failed: $e');
      }
    }
  } catch (e, st) {
    // 打印错误但继续运行，避免应用卡在原生启动页
    debugPrint('Firebase.initializeApp failed: $e\n$st');
  }

  
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PropertyFeeApp());
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
