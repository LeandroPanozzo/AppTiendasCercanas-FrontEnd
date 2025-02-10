import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    try {
      final result = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );
      
      // Guardar el token en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', result['access']);
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión exitoso')),
      );
      
      // Redirigir a la página principal después del login
      Navigator.pushReplacementNamed(context, '/welcome');
    } catch (error) {
      // Si ocurre un error, muestra el mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  final FocusNode _focusNode = FocusNode();

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Iniciar Sesión')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            focusNode: _focusNode,
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Usuario'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () {
              _focusNode.requestFocus();  // Asegura que el campo de texto esté enfocado
              _login();
            },
            child: Text('Iniciar Sesión'),
          ),
        ],
      ),
    ),
  );
}

}
