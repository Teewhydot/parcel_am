import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/routes.dart';
import 'core/routes/getx_route_module.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TravelLink',
      theme: AppTheme.lightTheme,
      initialRoute: Routes.initial,
      getPages: GetXRouteModule.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
