import 'package:flutter/material.dart';
import '../profile_service.dart';
import 'direccion_mapa_screen.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _calleController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _rangoBusquedaController = TextEditingController();
  final TextEditingController _provinciaController = TextEditingController();
  double? _latitud;
  double? _longitud;

  // Función para normalizar texto con caracteres especiales
  String normalizeText(String text) {
  // Primero intentamos decodificar como UTF-8
  try {
    // Decodifica la cadena si está en UTF-8
    String decoded = utf8.decode(utf8.encode(text));
    
    // Reemplaza secuencias específicas que puedan haber quedado
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
    // Si falla la decodificación UTF-8, aplicamos reemplazos directos
    return text
      .replaceAll('Ã©', 'é')
      .replaceAll('Ã¡', 'á')
      .replaceAll('Ã­', 'í')
      .replaceAll('Ã³', 'ó')
      .replaceAll('Ãº', 'ú')
      .replaceAll('Ã±', 'ñ')
      .replaceAll('Ã', 'Á')
      .replaceAll('&aacute;', 'á')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&iacute;', 'í')
      .replaceAll('&oacute;', 'ó')
      .replaceAll('&uacute;', 'ú')
      .replaceAll('&ntilde;', 'ñ');
  }
}

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Update the loadProfile method
  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();
      setState(() {
        _nombreController.text = profile['user']['first_name'] ?? '';
        _apellidoController.text = profile['user']['last_name'] ?? '';
        _calleController.text = normalizeText(profile['direccion_calle'] ?? '');
        _numeroController.text = profile['direccion_numero'] ?? '';
        _ciudadController.text = normalizeText(profile['ciudad'] ?? '');
        _provinciaController.text = normalizeText(profile['provincia'] ?? '');
        _rangoBusquedaController.text = profile['rango_busqueda_km']?.toString() ?? '10';
        _latitud = profile['coordenada_latitud'];
        _longitud = profile['coordenada_longitud'];
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el perfil: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

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
        _calleController.text = normalizeText(result['direccion_calle']);
        _numeroController.text = result['direccion_numero'];
        _ciudadController.text = normalizeText(result['ciudad']);
        _provinciaController.text = normalizeText(result['provincia']);
        _latitud = result['coordenada_latitud'];
        _longitud = result['coordenada_longitud'];
      });
    }
  }

  // Update the updateProfile method
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Update user data first
        await _profileService.updateUserProfile({
          'first_name': _nombreController.text,
          'last_name': _apellidoController.text,
        });

        // Then update profile data
        await _profileService.updateUserProfile({
          'direccion_calle': _calleController.text,
          'direccion_numero': _numeroController.text,
          'ciudad': _ciudadController.text,
          'provincia': _provinciaController.text,
          'rango_busqueda_km': double.parse(_rangoBusquedaController.text),
          'coordenada_latitud': _latitud,
          'coordenada_longitud': _longitud,
        });

        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/welcome'); //para regargar el welcome page
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/welcome');
            },
          ),
          title: const Text('Mi Perfil'),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _updateProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ingrese su nombre',
                ),
                enabled: _isEditing,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  hintText: 'Ingrese su apellido',
                ),
                enabled: _isEditing,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _calleController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      enabled: false,
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _seleccionarDireccion,
                      child: const Text('Seleccionar'),
                    ),
                  ],
                ],
              ),
              TextFormField(
                controller: _ciudadController,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                enabled: false,
              ),
              TextFormField(
                controller: _provinciaController,
                decoration: const InputDecoration(labelText: 'Provincia'),
                enabled: false,
              ),
              TextFormField(
                controller: _rangoBusquedaController,
                decoration: const InputDecoration(
                  labelText: 'Rango de búsqueda (km)',
                  hintText: 'Ingrese el rango en kilómetros',
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un rango de búsqueda';
                  }
                  try {
                    double.parse(value);
                    return null;
                  } catch (e) {
                    return 'Por favor ingrese un número válido';
                  }
                },
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text('Guardar cambios'),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _ciudadController.dispose();
    _rangoBusquedaController.dispose();
    _provinciaController.dispose();
    super.dispose();
  }
}