import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/responsive_app_frame.dart';
import 'core/storage/local_storage.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await Hive.initFlutter();
  await LocalStorage.init();
  ApiClient.init();

  runApp(const ProviderScope(child: EnterpriseRestaurantApp()));
}

class EnterpriseRestaurantApp extends ConsumerWidget {
  const EnterpriseRestaurantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Enterprise Restaurant Automation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          ThemeMode.light, // Change to system or dark based on preference
      routerConfig: router,
      builder: (context, child) => DesktopAppFrame(child: child),
    );
  }
}
