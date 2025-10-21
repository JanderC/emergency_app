import 'package:flutter/material.dart';
import 'package:app_emergency/services/auth_service.dart';
import 'package:app_emergency/screens/login_screen.dart';
import 'package:app_emergency/screens/user/user_dashboard.dart';
import 'package:app_emergency/screens/firefighter/firefighter_dashboard.dart';
import 'package:app_emergency/utils/shared_prefs.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  await SharedPrefs.init();
  
  // Creamos una instancia de AuthService aquí
  final authService = AuthService();
  final isLoggedIn = await authService.tryAutoLogin();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
      ],
      child: MyApp(
        isLoggedIn: isLoggedIn,
        isBombero: authService.isBombero,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isBombero;
  
  const MyApp({
    super.key, 
    required this.isLoggedIn, 
    required this.isBombero
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Emergencias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red,
          secondary: Colors.amber,
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn
          ? isBombero
              ? const FirefighterDashboard()
              : const UserDashboard()
          : const LoginScreen(),
    );
  }
}