import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // Provee la instancia de AuthService a toda la aplicación
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en el estado de autenticación de AuthService
    final authService = context.watch<AuthService>();

    return MaterialApp(
      title: 'Flutter Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Muestra LoginScreen si no está autenticado, o HomeScreen si sí lo está
      home: authService.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}