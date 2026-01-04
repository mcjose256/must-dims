import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
    }
  }
  
  runApp(
    const ProviderScope(
      child: DWMBIMSApp(),
    ),
  );
}

class DWMBIMSApp extends ConsumerWidget {
  const DWMBIMSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);  // ✅ Fixed!
    
    return MaterialApp.router(
      title: 'DWMBIMS - MUST',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }

  static final ThemeData _lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A4D68), // MUST deep blue
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A4D68),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
  );
}