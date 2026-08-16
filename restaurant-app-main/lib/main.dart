import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/hospitality_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalStorage.init();
  ApiClient.init();
  runApp(const ProviderScope(child: RestaurantApp()));
}

class RestaurantApp extends ConsumerWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Restaurant App',
      debugShowCheckedModeBanner: false,
      theme: HospitalityTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
