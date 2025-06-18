// frontend/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Importa la pantalla de login para el logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _protectedData = 'Cargando datos protegidos...';

  @override
  void initState() {
    super.initState();
    // Llamar a la API protegida al iniciar la pantalla
    _fetchProtectedData();
  }

  Future<void> _fetchProtectedData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final data = await authService.getProtectedData();
    setState(() {
      _protectedData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
              // Navegar de vuelta a la pantalla de login
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      drawer: Drawer( // El "riel de opciones"
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.dashboard,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Menú Principal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  Text(
                    authService.currentUser?.username ?? 'Invitado',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Ver Datos Protegidos'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                _fetchProtectedData(); // Refrescar datos protegidos
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refrescando datos protegidos...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                // Puedes navegar a otra pantalla de "Acerca de"
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Información de la App')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Has iniciado sesión exitosamente!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Mensaje de la API protegida:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                _protectedData,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}