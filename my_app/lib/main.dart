import 'package:flutter/material.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:my_app/pages/drawer/admin_page.dart';
import 'package:my_app/pages/auth/login_page.dart';
import 'package:my_app/pages/auth/register_page.dart';
import 'package:my_app/widgets/main_scaffold.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (_) => AppTheme()..load(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wuthering Waves',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(), 
      routes: {
        '/login' : (context) => const LoginPage(),
        '/home' : (context) => const MainScaffold(),
        '/register': (context) => const RegisterPage(),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}