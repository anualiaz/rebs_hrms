import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:provider/provider.dart';
import 'data/app_database.dart';
import 'data/app_api.dart';
import 'data/app_repository.dart';
import 'state/app_state.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  await database.open();
  final api = HrmsApi(baseUrl: const String.fromEnvironment(
    'API_URL', defaultValue: 'http://192.168.1.5:3000',
  ));
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(HrmsRepository(database, api))..initialize(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilPlusInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'REBS HRMS',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2457C5)),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF5F7FB),
              cardTheme: const CardThemeData(elevation: 0, color: Colors.white),
            ),
            home: const HomePage(),
          );
        }
    );
  }
}


