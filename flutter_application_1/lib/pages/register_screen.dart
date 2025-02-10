import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../profile_service.dart';
import 'direccion_mapa_screen.dart';
import 'dart:convert';


class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService authService = AuthService();
  final ProfileService profileService = ProfileService();

  // Text Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _calleController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _provinciaController = TextEditingController();
  
  double? _latitud;
  double? _longitud;

  Future<void> _seleccionarDireccion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DireccionMapaScreen(
          nombre: '',
          descripcion: '',
          categorias: [],
          diasAtencion: [],
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _calleController.text = result['direccion_calle'];
        _numeroController.text = result['direccion_numero'];
        _ciudadController.text = result['ciudad'];
        _provinciaController.text = result['provincia'];
        _latitud = result['coordenada_latitud'];
        _longitud = result['coordenada_longitud'];
      });
    }
  }

  String normalizeText(String text) {
    try {
      String decoded = utf8.decode(utf8.encode(text));
      decoded = decoded
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã¡', 'á')
        .replaceAll('Ã­', 'í')
        .replaceAll('Ã³', 'ó')
        .replaceAll('Ãº', 'ú')
        .replaceAll('Ã±', 'ñ')
        .replaceAll('Ã', 'Á');
      return decoded;
    } catch (e) {
      return text
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã¡', 'á')
        .replaceAll('Ã­', 'í')
        .replaceAll('Ã³', 'ó')
        .replaceAll('Ãº', 'ú')
        .replaceAll('Ã±', 'ñ')
        .replaceAll('Ã', 'Á');
    }
  }

void register() async {
  if (_formKey.currentState!.validate()) {
    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor complete todos los campos')),
        );
        return;
      }

      final response = await authService.register(
        username,
        email,
        password,
      );

      // Si no tenemos token después del registro/login, hacemos login manualmente
      if (AuthService.accessToken == null) {
        try {
          await authService.login(username, password);
        } catch (loginError) {
          print('Error en login después de registro: $loginError');
        }
      }

      // Si tenemos token después de todo el proceso
      if (AuthService.accessToken != null) {
        try {
          final profileResponse = await profileService.updateUserProfile({
            'user': {
                'first_name': _nombreController.text,
                'last_name': _apellidoController.text,
            },
            'direccion_calle': _calleController.text,
            'direccion_numero': _numeroController.text,
            'ciudad': _ciudadController.text,
            'provincia': _provinciaController.text,
            'coordenada_latitud': _latitud,
            'coordenada_longitud': _longitud,
        });
          
          print('Profile update successful: $profileResponse'); // Add debug logging
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registro exitoso')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } catch (profileError) {
          print('Profile update error: $profileError'); // Add debug logging
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el perfil: $profileError')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario creado. Por favor inicie sesión.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (e.toString().contains('ya existe')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El usuario ya existe')),
        );
      } else if (e.toString().contains('correo electrónico')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Este correo electrónico ya está en uso.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error durante el registro: $e')),
        );
      }
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Usuario'),
                validator: (value) => value!.isEmpty ? 'Usuario requerido' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value!.isEmpty || !value.contains('@') ? 'Email inválido' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirmar Contraseña'),
                obscureText: true,
                validator: (value) =>
                    value != _passwordController.text ? 'Las contraseñas no coinciden' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ingrese su nombre',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _apellidoController,
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  hintText: 'Ingrese su apellido',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su apellido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _calleController,
                      decoration: InputDecoration(labelText: 'Dirección'),
                      enabled: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor seleccione una dirección';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _seleccionarDireccion,
                    child: Text('Seleccionar'),
                  ),
                ],
              ),
              TextFormField(
                controller: _ciudadController,
                decoration: InputDecoration(labelText: 'Ciudad'),
                enabled: false,
              ),
              TextFormField(
                controller: _provinciaController,
                decoration: InputDecoration(labelText: 'Provincia'),
                enabled: false,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: register,
                  child: Text('Registrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _ciudadController.dispose();
    _provinciaController.dispose();
    super.dispose();
  }
}