import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api_service.dart';
import 'direccion_mapa_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:html' as html;
import 'dart:typed_data';

class TiendaFormPage extends StatefulWidget {
  @override
  _TiendaFormPageState createState() => _TiendaFormPageState();
}

class _TiendaFormPageState extends State<TiendaFormPage> {
   final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController();
  final _picker = ImagePicker();
  File? _logoImage;
  String? _nombre;
  String? _selectedCategoria;
  String? _selectedDiasAtencion;
  String? _descripcion;
  String? _direccion;
  String? _ciudad;
  String? _provincia;
  String? _direccionCalle;
  String? _direccionNumero;
  String? _whatsapp;
  double? _latitud;
  double? _longitud;
  TimeOfDay? _horarioApertura;
  TimeOfDay? _horarioCierre;
  Set<String> _selectedMetodosPago = {};
  File? _logoImageFile;
  Uint8List? _webImage;
  String? _imageUrl;

  final List<String> _categorias = [
    "Restaurante", "Supermercado", "Ropa", "Tecnologia",
    "Belleza", "Deportes", "Veterinaria", "Salud",
    "Autopartes", "Construccion y Ferreteria", "Polirrubro", "Otros",
  ];

  final List<String> _diasAtencion = [
    "Lunes a Viernes",
    "Lunes a Sabado",
    "Todos los dias",
  ];

  final List<String> _allMetodosPago = [
    "efectivo", "debito", "credito", "transferencia_bancaria",
    "pago_movil", "qr", "monedero_electronico", "criptomoneda",
    "pasarela_en_linea", "cheque", "pagos_a_plazos", "vales",
    "contra_entrega", "debito_directo", "creditos_internos"
  ];

  String? _selectedCountry;  // Cambiar de String vacía a null
final Map<String, String> _countryCodes = {
  'Argentina': '+54',
  'México': '+52',
  'Brasil': '+55',
  'Chile': '+56',
  'Colombia': '+57',
  'Perú': '+51',
  'Ecuador': '+593',
  'Venezuela': '+58',
  'Estados Unidos': '+1',
  'Canadá': '+1',
  'Uruguay': '+598',
  'Paraguay': '+595',
  'Bolivia': '+591',
  'Costa Rica': '+506',
  'Panamá': '+507',
  'Guatemala': '+502',
};

  @override
void initState() {
  super.initState();
}

  @override
  void dispose() {
    _whatsappController.dispose();
    super.dispose();
  }

  String? _validarWhatsapp(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  
  String numeroLimpio = value.replaceAll(RegExp(r'[^\d+]'), '');
  
  // Validar según el país seleccionado
  switch (_selectedCountry) {
    case '+54': // Argentina
      // Formato: +54 9 área (2 o 3 dígitos) + número (8 o 7 dígitos) = total 10 dígitos
      if (!RegExp(r'^\+54\d{10}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +54911XXXXXXXX';
      }
      break;

    case '+52': // México
      // Formato: +52 1 área (2 o 3 dígitos) + número (7 u 8 dígitos) = total 10 dígitos
      if (!RegExp(r'^\+52\d{10}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +521XXXXXXXXXX';
      }
      break;

    case '+55': // Brasil
      // Formato: +55 DDD (2 dígitos) + número móvil (9 dígitos) = total 11 dígitos
      if (!RegExp(r'^\+55\d{11}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +55XXXXXXXXXXX';
      }
      break;

    case '+56': // Chile
      // Formato: +56 9 + número (8 dígitos) = total 9 dígitos
      if (!RegExp(r'^\+569\d{8}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +569XXXXXXXX';
      }
      break;

    case '+57': // Colombia
      // Formato: +57 área (3 dígitos) + número (7 dígitos) = total 10 dígitos
      if (!RegExp(r'^\+57\d{10}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +57XXXXXXXXXX';
      }
      break;

    case '+51': // Perú
      // Formato: +51 9 + número (8 dígitos) = total 9 dígitos
      if (!RegExp(r'^\+519\d{8}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +519XXXXXXXX';
      }
      break;

    case '+593': // Ecuador
      // Formato: +593 9 + número (8 dígitos) = total 9 dígitos
      if (!RegExp(r'^\+5939\d{8}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +5939XXXXXXXX';
      }
      break;

    case '+58': // Venezuela
      // Formato: +58 área (3 dígitos) + número (7 dígitos) = total 10 dígitos
      if (!RegExp(r'^\+58\d{10}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +58XXXXXXXXXX';
      }
      break;

    case '+1': // Estados Unidos y Canadá
      // Formato: +1 área (3 dígitos) + número (7 dígitos) = total 10 dígitos
      if (!RegExp(r'^\+1\d{10}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +1XXXXXXXXXX';
      }
      break;

    case '+598': // Uruguay
      // Formato: +598 9 + número (7 dígitos) = total 8 dígitos
      if (!RegExp(r'^\+5989\d{7}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +5989XXXXXXX';
      }
      break;

    case '+595': // Paraguay
      // Formato: +595 9 + número (8 dígitos) = total 9 dígitos
      if (!RegExp(r'^\+5959\d{8}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +5959XXXXXXXX';
      }
      break;

    case '+591': // Bolivia
      // Formato: +591 área (1 dígito) + número (8 dígitos) = total 9 dígitos
      if (!RegExp(r'^\+591\d{8}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +591XXXXXXXX';
      }
      break;

    case '+506': // Costa Rica
      // Formato: +506 + número (8 dígitos)
      if (!RegExp(r'^\+506\d{8}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +506XXXXXXXX';
      }
      break;

    case '+507': // Panamá
      // Formato: +507 + número (8 dígitos)
      if (!RegExp(r'^\+507\d{8}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +507XXXXXXXX';
      }
      break;

    case '+502': // Guatemala
      // Formato: +502 + número (8 dígitos)
      if (!RegExp(r'^\+502\d{8}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Ejemplo: +502XXXXXXXX';
      }
      break;

    default:
      // Validación genérica para otros países
      // Acepta códigos de país de 1 a 3 dígitos seguidos de al menos 8 dígitos
      if (!RegExp(r'^\+\d{1,3}\d{8,}$').hasMatch(numeroLimpio)) {
        return 'Formato inválido. Verifica el número ingresado';
      }
  }
  
  return null;
}

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // Manejo de imagen para Web
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageUrl = null;
          });
        } else {
          // Manejo de imagen para móvil
          setState(() {
            _logoImageFile = File(pickedFile.path);
            _imageUrl = null;
          });
        }
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar la imagen')),
      );
    }
  }

  Widget _buildImagePreview() {
    if (_webImage != null && kIsWeb) {
      return Image.memory(
        _webImage!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (_logoImageFile != null && !kIsWeb) {
      return Image.file(
        _logoImageFile!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (_imageUrl != null) {
      return Image.network(
        _imageUrl!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );
    } else {
      return Icon(
        Icons.store,
        size: 80,
        color: Colors.grey[400],
      );
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_horarioApertura == null || _horarioCierre == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor selecciona los horarios de apertura y cierre')),
        );
        return;
      }

      if (_direccion == null || _direccion!.isEmpty || _provincia == null || _provincia!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor selecciona una dirección completa')),
        );
        return;
      }

      if (_selectedMetodosPago.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor selecciona al menos un método de pago')),
        );
        return;
      }

      // Procesar el número de WhatsApp
      String numeroCompleto = _whatsapp ?? '';
      // En _submitForm(), modificar la parte donde se procesa el WhatsApp
      if (_whatsapp != null && _whatsapp!.isNotEmpty) {
        String numeroLimpio = _whatsapp!.replaceAll(RegExp(r'[^\d+]'), '');
        _whatsapp = numeroLimpio;
      }
      _whatsapp = numeroCompleto;
      try {
        // Preparar la imagen para el envío
        dynamic imageData;
        if (kIsWeb) {
          imageData = _webImage;
        } else {
          imageData = _logoImageFile;
        }
      
        await ApiService.enviarDatos(
          _nombre!,
          _selectedCategoria!,
          _selectedDiasAtencion!,
          _descripcion!,
          _ciudad!,
          _provincia!,
          _direccionCalle!,
          _direccionNumero!,
          _latitud!,
          _longitud!,
          _horarioApertura!,
          _horarioCierre!,
          _selectedMetodosPago.toList(),
          _whatsapp!,
          logoImage: _logoImage, // Agregar el logo
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datos enviados con éxito')),
        );
      } catch (e) {
        print("Error al enviar los datos: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar los datos: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarDireccion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DireccionMapaScreen(
          nombre: _nombre ?? '',
          descripcion: _descripcion ?? '',
          categorias: _categorias,
          diasAtencion: _diasAtencion,
          horarioApertura: _horarioApertura,
          horarioCierre: _horarioCierre,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _direccionCalle = result['direccion_calle'];
        _direccionNumero = result['direccion_numero'];
        _ciudad = result['ciudad'];
        _provincia = result['provincia'] ?? 'Buenos Aires';
        _latitud = result['coordenada_latitud'];
        _longitud = result['coordenada_longitud'];
        _direccion = '${_direccionCalle} ${_direccionNumero}, ${_ciudad}, ${_provincia}';
      });
    }
  }

  Future<void> _seleccionarHorarioApertura() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _horarioApertura) {
      setState(() {
        _horarioApertura = picked;
      });
    }
  }

  Future<void> _seleccionarHorarioCierre() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _horarioCierre) {
      setState(() {
        _horarioCierre = picked;
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      Navigator.pushReplacementNamed(context, '/welcome'); // para recargar el welcome page
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
        title: Text('Formulario Tienda'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Nombre",
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => _nombre = value,
                  validator: (value) =>
                      value == null || value.isEmpty ? "Por favor ingresa el nombre" : null,
                ),
                SizedBox(height: 16.0),
                  Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Logo de la tienda",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImagePreview(),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _logoImageFile != null || _webImage != null || _imageUrl != null 
                                      ? Icons.edit 
                                      : Icons.add_a_photo,
                                    color: Colors.white,
                                    size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Dirección",
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _direccion,
                        enabled: false,
                      ),
                    ),
                    SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: _seleccionarDireccion,
                      child: Text('Seleccionar'),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Descripción",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onSaved: (value) => _descripcion = value,
                  validator: (value) =>
                      value == null || value.isEmpty ? "Por favor ingresa la descripción" : null,
                ),
                SizedBox(height: 16.0),
                // Nuevo: Dropdown para selección de país
               DropdownButtonFormField<String>(
                value: null,  // Inicialmente null
                decoration: InputDecoration(
                  labelText: 'País',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                hint: Text('Seleccione un país'),  // Esto se mostrará cuando no hay selección
                items: _countryCodes.entries.map((entry) => DropdownMenuItem(
                  value: entry.value,
                  child: Text('${entry.key} (${entry.value})'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    if (value != null) {
                      _whatsappController.text = value;
                      _whatsappController.selection = TextSelection.fromPosition(
                        TextPosition(offset: value.length),
                      );
                    }
                  });
                },
              ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _whatsappController,
                  decoration: InputDecoration(
                    labelText: "WhatsApp",
                    hintText: _selectedCountry != null ? "${_selectedCountry}XXXXXXXXXX" : "Seleccione un país primero",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.whatsapp),
                    helperText: "Ingresa el número con código de área y número local (opcional)",
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: _selectedCountry != null,  // Deshabilitar si no hay país seleccionado
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty || _selectedCountry == null) {
                        return newValue;
                      }
                      if (newValue.text.length < (_selectedCountry?.length ?? 0)) {
                        return oldValue;
                      }
                      if (!newValue.text.startsWith(_selectedCountry!)) {
                        return oldValue;
                      }
                      return newValue;
                    }),
                  ],
                  onChanged: (value) {
                    if (_selectedCountry != null && value.isNotEmpty && 
                        value.length < _selectedCountry!.length) {
                      _whatsappController.text = _selectedCountry!;
                      _whatsappController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _whatsappController.text.length),
                      );
                    }
                  },
                  onSaved: (value) {
                    _whatsapp = (value?.isEmpty ?? true) ? null : value;
                  },
                  validator: _validarWhatsapp,
                ),
                SizedBox(height: 16.0),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Categoría",
                    border: OutlineInputBorder(),
                  ),
                  items: _categorias.map((categoria) => DropdownMenuItem(
                    value: categoria.toLowerCase(),
                    child: Text(categoria),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedCategoria = value),
                  validator: (value) =>
                      value == null ? "Por favor selecciona una categoría" : null,
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Días de Atención",
                    border: OutlineInputBorder(),
                  ),
                  items: _diasAtencion.map((dia) => DropdownMenuItem(
                    value: dia.toLowerCase().replaceAll(" ", "_"),
                    child: Text(dia),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedDiasAtencion = value),
                  validator: (value) =>
                      value == null ? "Por favor selecciona los días de atención" : null,
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Horario de Apertura: ${_horarioApertura?.format(context) ?? "No seleccionado"}"),
                    ElevatedButton(
                      onPressed: _seleccionarHorarioApertura,
                      child: Text('Seleccionar'),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Horario de Cierre: ${_horarioCierre?.format(context) ?? "No seleccionado"}"),
                    ElevatedButton(
                      onPressed: _seleccionarHorarioCierre,
                      child: Text('Seleccionar'),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Text("Métodos de Pago", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _allMetodosPago.map((metodo) {
                    return FilterChip(
                      label: Text(metodo.replaceAll('_', ' ').toUpperCase()),
                      selected: _selectedMetodosPago.contains(metodo),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMetodosPago.add(metodo);
                          } else {
                            _selectedMetodosPago.remove(metodo);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}