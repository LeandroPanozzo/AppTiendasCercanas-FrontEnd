import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/custom_scaffold.dart';
import 'pages/login_page.dart';
import 'pages/register_screen.dart';
import 'pages/tienda_form_page.dart';
import 'pages/mis_tiendas_page.dart';
import 'pages/profile_page.dart';
import 'pages/welcomePage.dart';
import 'pages/MisReservasScreen.dart';
import 'pages/NotificacionesPage.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initializeTokens();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Negocio App',
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => const HomePage(),
        '/registrar_tiendas': (context) => TiendaFormPage(),
        '/mis_tiendas': (context) => const MisTiendasPage(),
        '/profile': (context) => const ProfilePage(),
        '/welcome': (context) => const WelcomePage(),
        '/mis_reservas': (context) => const MisReservasScreen(),
        '/notificaciones': (context) => const NotificacionesPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isAuth = AuthService.isAuthenticated();
    if (mounted) {
      setState(() {
        isLoggedIn = isAuth;
      });
    }
  }

  Future<void> _logout() async {
    // Primero realizamos el logout en AuthService
    await AuthService.logout();
    
    if (mounted) {
      // Actualizamos el estado antes de la navegación
      setState(() {
        isLoggedIn = false;
      });
      
      // Mostramos el mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada correctamente')),
      );
    }
  }
  Widget _buildLoginButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login').then((_) {
              _checkLoginStatus();
            });
          },
          child: const Text('Iniciar Sesión'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/register').then((_) {
              _checkLoginStatus();
            });
          },
          child: const Text('Registrarse'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Negocio App',
      isLoggedIn: isLoggedIn,
      onLogout: _logout,
      body: Center(
        child: isLoggedIn
            ? const Text('Bienvenido a Negocio App')
            : _buildLoginButtons(),
      ),
    );
  }
}