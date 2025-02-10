import 'package:flutter/material.dart';
import '../api_service.dart';
import 'direccion_mapa_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
class EditTiendaPage extends StatefulWidget {
  final Map<String, dynamic> tienda;

  const EditTiendaPage({Key? key, required this.tienda}) : super(key: key);

  @override
  _EditTiendaPageState createState() => _EditTiendaPageState();
}

class _EditTiendaPageState extends State<EditTiendaPage> {
  final _formKey = GlobalKey<FormState>();
  final _whatsappController = TextEditingController();
  final _picker = ImagePicker();
  Set<String> _selectedMetodosPago = <String>{};  // Inicializar como un Set vacío
  File? _logoImageFile;
  Uint8List? _webImage;
  String? _imageUrl;
  late String? _whatsapp;
  late String? _nombre;
  late String? _selectedCategoria;
  late String? _selectedDiasAtencion;
  late String? _descripcion;
  late String? _direccion;
  late String? _ciudad;
  late String? _provincia;
  late String? _direccionCalle;
  late String? _direccionNumero;
  late double? _latitud;
  late double? _longitud;
  TimeOfDay? _horarioApertura;
  TimeOfDay? _horarioCierre;

  final List<String> _allMetodosPago = [
    "efectivo", "debito", "credito", "transferencia_bancaria",
    "pago_movil", "qr", "monedero_electronico", "criptomoneda",
    "pasarela_en_linea", "cheque", "pagos_a_plazos", "vales",
    "contra_entrega", "debito_directo", "creditos_internos"
  ];

  Map<String, String> _metodosLabels = {
    "efectivo": "Efectivo",
    "debito": "Débito",
    "credito": "Crédito",
    "transferencia_bancaria": "Transferencia Bancaria",
    "pago_movil": "Pago Móvil",
    "qr": "Código QR",
    "monedero_electronico": "Monedero Electrónico",
    "criptomoneda": "Criptomoneda",
    "pasarela_en_linea": "Pasarela de Pago en Línea",
    "cheque": "Cheque",
    "pagos_a_plazos": "Pagos a Plazos",
    "vales": "Vales/Tarjetas de Regalo",
    "contra_entrega": "Pago contra Entrega",
    "debito_directo": "Débito Directo",
    "creditos_internos": "Créditos Internos/Monedas Virtuales"
  };

  final List<Map<String, String>> _categorias = [
    {"value": "restaurante", "label": "Restaurante"},
    {"value": "supermercado", "label": "Supermercado"},
    {"value": "ropa", "label": "Ropa"},
    {"value": "tecnologia", "label": "Tecnologia"},
    {"value": "belleza", "label": "Belleza"},
    {"value": "deportes", "label": "Deportes"},
    {"value": "veterinaria", "label": "Veterinaria"},
    {"value": "salud", "label": "Salud"},
    {"value": "autopartes", "label": "Autopartes"},
    {"value": "construccion_y_ferreteria", "label": "Construccion y Ferreteria"},
    {"value": "polirrubro", "label": "Polirrubro"},
    {"value": "otros", "label": "Otros"},
  ];

  final List<Map<String, String>> _diasAtencion = [
    {"value": "lunes_a_viernes", "label": "Lunes a Viernes"},
    {"value": "lunes_a_sabado", "label": "Lunes a Sabado"},
    {"value": "todos_los_dias", "label": "Todos los dias"},
  ];

  String _selectedCountry = '+54';
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

  // Función para normalizar texto con caracteres especiales
  String normalizeText(String text) {
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

    // Modificar la función de validación de WhatsApp
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
    @override
  void dispose() {
    _whatsappController.dispose();
    super.dispose();
  }

 @override
void initState() {
  super.initState();
  _cargarDatosTienda();
}

Future<void> _cargarDatosTienda() async {
  try {
    print('Datos iniciales de la tienda:');
    print(widget.tienda);
    
    final tiendaCompleta = await ApiService.obtenerTienda(widget.tienda['id']);
    print('Datos completos de la tienda:');
    print(tiendaCompleta);

    setState(() {
        // Cambiar logo_url por url_logo
        _imageUrl = tiendaCompleta['url_logo'];
        print('Logo URL: $_imageUrl');
        
        _whatsapp = tiendaCompleta['whatsapp'];
        if (_whatsapp != null) {
          final countryCode = _countryCodes.entries
              .firstWhere(
                (entry) => _whatsapp!.startsWith(entry.value),
                orElse: () => MapEntry('Argentina', '+54'),
              );
          _selectedCountry = countryCode.value;
          _whatsappController.text = _whatsapp ?? countryCode.value;
        } else {
          _whatsappController.text = '+54';
        }
      _whatsappController.text = _whatsapp ?? '';
      _nombre = normalizeText(tiendaCompleta['nombre'] ?? '');
      
      _selectedCategoria = _categorias.firstWhere(
        (cat) => cat["value"] == tiendaCompleta['categoria']?.toString(),
        orElse: () => _categorias.first,
      )["value"];
      
      _selectedDiasAtencion = _diasAtencion.firstWhere(
        (dia) => dia["value"] == tiendaCompleta['dias_atencion']?.toString(),
        orElse: () => _diasAtencion.first,
      )["value"];
      
      _descripcion = normalizeText(tiendaCompleta['descripcion'] ?? '');
      _ciudad = normalizeText(tiendaCompleta['ciudad'] ?? '');
      _provincia = normalizeText(tiendaCompleta['provincia'] ?? '');
      _direccionCalle = normalizeText(tiendaCompleta['direccion_calle'] ?? '');
      _direccionNumero = tiendaCompleta['direccion_numero']?.toString() ?? '';
      _latitud = tiendaCompleta['coordenada_latitud'];
      _longitud = tiendaCompleta['coordenada_longitud'];
      
      // Updated payment methods loading
      _selectedMetodosPago.clear();
      final paymentMethodFields = [
        "efectivo", "debito", "credito", "transferencia_bancaria",
        "pago_movil", "qr", "monedero_electronico", "criptomoneda",
        "pasarela_en_linea", "cheque", "pagos_a_plazos", "vales",
        "contra_entrega", "debito_directo", "creditos_internos"
      ];

      paymentMethodFields.forEach((method) {
        if (tiendaCompleta[method] == true) {
          _selectedMetodosPago.add(method);
        }
      });

      _direccion = '${_direccionCalle} ${_direccionNumero}, ${_ciudad}, ${_provincia}';

      if (tiendaCompleta['horario_apertura'] != null) {
        final apertura = tiendaCompleta['horario_apertura'].split(':');
        _horarioApertura = TimeOfDay(
          hour: int.parse(apertura[0]),
          minute: int.parse(apertura[1]),
        );
      }

      if (tiendaCompleta['horario_cierre'] != null) {
        final cierre = tiendaCompleta['horario_cierre'].split(':');
        _horarioCierre = TimeOfDay(
          hour: int.parse(cierre[0]),
          minute: int.parse(cierre[1]),
        );
      }

      _validateDiasAtencion();
      _validateCategoria();
    });
  } catch (e) {
    print("Error al cargar datos de la tienda: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos completos de la tienda')),
      );
    }
  }
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
      setState(() {
        if (kIsWeb) {
          // Manejo de imagen para Web
          pickedFile.readAsBytes().then((bytes) {
            setState(() {
              _webImage = bytes;
              _imageUrl = null;
            });
          });
        } else {
          // Manejo de imagen para móvil
          _logoImageFile = File(pickedFile.path);
          _imageUrl = null;
        }
      });
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
  } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
    return Image.network(
      _imageUrl!,
      width: 200,
      height: 200,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / 
                  loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        return Container(
          width: 200,
          height: 200,
          color: Colors.grey[200],
          child: Icon(
            Icons.store,
            size: 80,
            color: Colors.grey[400],
          ),
        );
      },
    );
  } else {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey[200],
      child: Icon(
        Icons.store,
        size: 80,
        color: Colors.grey[400],
      ),
    );
  }
}
  void _validateDiasAtencion() {
    final isValid = _diasAtencion.any((dia) => dia["value"] == _selectedDiasAtencion);
    if (!isValid) {
      setState(() {
        _selectedDiasAtencion = _diasAtencion.first["value"];
      });
    }
  }

  void _validateCategoria() {
    final isValid = _categorias.any((cat) => cat["value"] == _selectedCategoria);
    if (!isValid) {
      setState(() {
        _selectedCategoria = _categorias.first["value"];
      });
    }
  }
  

  Future<void> _seleccionarDireccion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DireccionMapaScreen(
          nombre: normalizeText(_nombre ?? ''),
          descripcion: normalizeText(_descripcion ?? ''),
          categorias: _categorias.map((c) => normalizeText(c["label"]!)).toList(),
          diasAtencion: _diasAtencion.map((d) => normalizeText(d["label"]!)).toList(),
          horarioApertura: _horarioApertura,
          horarioCierre: _horarioCierre,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _direccionCalle = normalizeText(result['direccion_calle'] ?? '');
        _direccionNumero = result['direccion_numero']?.toString() ?? '';
        _ciudad = normalizeText(result['ciudad'] ?? '');
        _provincia = normalizeText(result['provincia'] ?? '');
        _latitud = result['coordenada_latitud'];
        _longitud = result['coordenada_longitud'];
        _direccion = '${_direccionCalle} ${_direccionNumero}, ${_ciudad}, ${_provincia}';
      });
    }
  }

  Future<void> _seleccionarHorarioApertura() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horarioApertura ?? TimeOfDay.now(),
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
      initialTime: _horarioCierre ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _horarioCierre) {
      setState(() {
        _horarioCierre = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic> camposNulos = {
      'Nombre': _nombre,
      'Categoría': _selectedCategoria,
      'Días de Atención': _selectedDiasAtencion,
      'Descripción': _descripcion,
      'Ciudad': _ciudad,
      'Provincia': _provincia,
      'Dirección Calle': _direccionCalle,
      'Dirección Número': _direccionNumero,
      'Latitud': _latitud,
      'Longitud': _longitud,
      'Horario Apertura': _horarioApertura,
      'Horario Cierre': _horarioCierre,
    };

      List<String> camposNulosEncontrados = [];
      camposNulos.forEach((campo, valor) {
        if (valor == null) {
          camposNulosEncontrados.add(normalizeText(campo));
        }
      });

      if (camposNulosEncontrados.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Los siguientes campos son requeridos: ${camposNulosEncontrados.join(", ")}'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      try {
      // Preparar la imagen para el envío
      dynamic logoImage;
      if (kIsWeb) {
        logoImage = _webImage;
      } else {
        logoImage = _logoImageFile;
      }

      await ApiService.actualizarTienda(
  widget.tienda['id'],
  normalizeText(_nombre!),
  _selectedCategoria!,
  _selectedDiasAtencion!,
  normalizeText(_descripcion!),
  normalizeText(_ciudad!),
  normalizeText(_provincia!),
  normalizeText(_direccionCalle!),
  _direccionNumero!,
  _latitud!,
  _longitud!,
  _horarioApertura!,
  _horarioCierre!,
  _selectedMetodosPago.toList(),
  _whatsapp ?? '',
  logoImage: kIsWeb ? _webImage : _logoImageFile,
);
        print('Selected Payment Methods: $_selectedMetodosPago');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tienda actualizada con éxito')),
          
        );
        Navigator.pop(context, true);
      } catch (e) {
        print("Error al actualizar la tienda: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la tienda: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Tienda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              initialValue: _nombre,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              onSaved: (value) => _nombre = value,
            ),
            SizedBox(height: 16),
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
            SizedBox(height: 16),

            TextFormField(
              initialValue: _descripcion,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              onSaved: (value) => _descripcion = value,
            ),

            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: InputDecoration(
                labelText: 'País',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: _countryCodes.entries.map((entry) => DropdownMenuItem(
                value: entry.value,
                child: Text('${entry.key} (${entry.value})'),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value!;
                  _whatsappController.text = value;
                  _whatsappController.selection = TextSelection.fromPosition(
                    TextPosition(offset: value.length),
                  );
                });
              },
            ),
            SizedBox(height: 16),
              TextFormField(
                controller: _whatsappController,
                decoration: InputDecoration(
                  labelText: "WhatsApp",
                  hintText: "${_selectedCountry}XXXXXXXXXX",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.whatsapp),
                  helperText: "Ingresa el número con código de área y número local (opcional)",
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    // Si el campo está vacío, permitirlo
                    if (newValue.text.isEmpty) {
                      return newValue;
                    }
                    // Si tiene contenido, aplicar las validaciones normales
                    if (newValue.text.length < _selectedCountry.length) {
                      return oldValue;
                    }
                    if (!newValue.text.startsWith(_selectedCountry)) {
                      return oldValue;
                    }
                    return newValue;
                  }),
                ],
                onChanged: (value) {
                  // Solo aplicar la lógica del código de país si el campo no está vacío
                  if (value.isNotEmpty && value.length < _selectedCountry.length) {
                    _whatsappController.text = _selectedCountry;
                    _whatsappController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _whatsappController.text.length),
                    );
                  }
                },
                onSaved: (value) {
                  // Si el valor está vacío, guardar null o cadena vacía
                  _whatsapp = (value?.isEmpty ?? true) ? null : value!.replaceAll(RegExp(r'[^\d+]'), '');
                },
                validator: (value) {
                  // Si está vacío, es válido
                  if (value?.isEmpty ?? true) {
                    return null;
                  }
                  // Si tiene contenido, validar el formato
                  return _validarWhatsapp(value);
                },
              ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _direccion,
                    decoration: InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder(),
                    ),
                    enabled: false,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _seleccionarDireccion,
                  child: Text('Seleccionar'),
                ),
              ],
            ),
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCategoria,
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: _categorias.map((cat) => DropdownMenuItem(
                value: cat['value'],
                child: Text(cat['label']!),
              )).toList(),
              onChanged: (value) => setState(() => _selectedCategoria = value),
              validator: (value) => value == null ? 'Campo requerido' : null,
            ),
            SizedBox(height: 16),

            

            DropdownButtonFormField<String>(
              value: _selectedDiasAtencion,
              decoration: InputDecoration(
                labelText: 'Días de Atención',
                border: OutlineInputBorder(),
              ),
              items: _diasAtencion.map((dia) => DropdownMenuItem(
                value: dia['value'],
                child: Text(dia['label']!),
              )).toList(),
              onChanged: (value) => setState(() => _selectedDiasAtencion = value),
              validator: (value) => value == null ? 'Campo requerido' : null,
            ),
            SizedBox(height: 16),

            Text(
              'Horarios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text('Apertura: ${_horarioApertura?.format(context) ?? "No seleccionado"}'),
                ),
                ElevatedButton(
                  onPressed: _seleccionarHorarioApertura,
                  child: Text('Seleccionar'),
                ),
              ],
            ),
            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text('Cierre: ${_horarioCierre?.format(context) ?? "No seleccionado"}'),
                ),
                ElevatedButton(
                  onPressed: _seleccionarHorarioCierre,
                  child: Text('Seleccionar'),
                ),
              ],
            ),
            SizedBox(height: 16),

            Text(
              'Métodos de Pago',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allMetodosPago.map((metodo) => FilterChip(
                label: Text(_metodosLabels[metodo] ?? metodo),
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
              )).toList(),
            ),
            SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitForm,
              child: Text('Guardar Cambios'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}