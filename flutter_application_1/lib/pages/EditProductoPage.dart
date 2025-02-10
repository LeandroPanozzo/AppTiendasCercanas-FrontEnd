import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../auth_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class EditProductoPage extends StatefulWidget {
  final Map<String, dynamic> producto;

  const EditProductoPage({required this.producto, Key? key}) : super(key: key);

  @override
  State<EditProductoPage> createState() => _EditProductoPageState();
}

class _EditProductoPageState extends State<EditProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  File? _imageFile;
  Uint8List? _webImage;
  String? _imageUrl;
  late TextEditingController nombreController;
  late TextEditingController descripcionController;
  late TextEditingController precioController;
  late TextEditingController cantidadController;
  bool disponibilidad = true;
  bool esServicio = false;
  bool permiteReservas = true; // New field for reservation toggle
  double? precioOriginal;
  double? porcentajeDescuento;
  late TextEditingController promocionNxController;
  late TextEditingController promocionPorcentajeController;
  int? promocionUnidad;
  final List<DropdownMenuItem<int>> unidadesItems = List.generate(
    10,
    (index) => DropdownMenuItem(
      value: index + 1,
      child: Text('${index + 1}ª unidad'),
    ),
  );

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.producto['url_imagen'];
    nombreController = TextEditingController(text: widget.producto['nombre']);
    descripcionController = TextEditingController(text: widget.producto['descripcion']);
    precioController = TextEditingController(text: widget.producto['precio'].toString());
    cantidadController = TextEditingController(
      text: widget.producto['cantidad_disponible']?.toString() ?? ''
    );
    disponibilidad = widget.producto['disponibilidad'];
    esServicio = widget.producto['es_servicio'] ?? false;
    permiteReservas = widget.producto['permite_reservas'] ?? true; // Initialize permite_reservas
    precioOriginal = widget.producto['precio_original']?.toString().isEmpty ?? true
        ? null
        : double.tryParse(widget.producto['precio_original'].toString());
    porcentajeDescuento = widget.producto['porcentaje_descuento']?.toString().isEmpty ?? true
        ? null
        : double.tryParse(widget.producto['porcentaje_descuento'].toString());
    promocionNxController = TextEditingController(
      text: widget.producto['promocion_nx']?.toString() ?? ''
    );
    promocionPorcentajeController = TextEditingController(
      text: widget.producto['promocion_porcentaje']?.toString() ?? ''
    );
    promocionUnidad = widget.producto['promocion_unidad'];
  
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    precioController.dispose();
    cantidadController.dispose();
    promocionNxController.dispose();
    promocionPorcentajeController.dispose();
    super.dispose();
  }
 Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web
          var imageBytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = imageBytes;
            _imageFile = null;
          });
        } else {
          // For mobile platforms
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seleccionando imagen: $e')),
      );
    }
  }

  Future<void> actualizarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Prepare the request body
      var request = http.MultipartRequest(
        'PATCH', 
        Uri.parse('http://127.0.0.1:8000/productos/${widget.producto['id']}/'),
      );

      // Add authentication header
      request.headers['Authorization'] = 'Bearer ${AuthService.accessToken}';

      // Add text fields
      request.fields['nombre'] = nombreController.text;
      request.fields['descripcion'] = descripcionController.text;
      request.fields['precio'] = precioController.text;
      
      // Add other fields similar to previous implementation
      request.fields['cantidad_disponible'] = 
        (!esServicio && permiteReservas) ? cantidadController.text : '';
      request.fields['disponibilidad'] = disponibilidad.toString();
      request.fields['es_servicio'] = esServicio.toString();
      request.fields['permite_reservas'] = permiteReservas.toString();
      request.fields['promocion_nx'] = promocionNxController.text;
      request.fields['promocion_porcentaje'] = promocionPorcentajeController.text;
      request.fields['promocion_unidad'] = promocionUnidad?.toString() ?? '';

      // Add image if selected
      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imagen', _imageFile!.path)
        );
      } else if (_webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'imagen', 
            _webImage!, 
            filename: 'product_image.png'
          )
        );
      }

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        throw Exception('Error al actualizar el producto: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _webImage != null
                            ? Image.memory(_webImage!, fit: BoxFit.cover)
                            : _imageFile != null
                              ? Image.file(_imageFile!, fit: BoxFit.cover)
                              : _imageUrl != null
                                ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.edit, 
                            color: Colors.white, 
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo requerido';
                  if (double.tryParse(value) == null) return 'Ingrese un número válido';
                  if (double.parse(value) <= 0) return 'El precio debe ser mayor a 0';
                  return null;
                },
              ),
              if (precioOriginal != null && porcentajeDescuento! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Precio original: \$${precioOriginal!.toStringAsFixed(2)}\nDescuento: ${porcentajeDescuento!.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Promociones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              TextFormField(
                controller: promocionNxController,
                decoration: const InputDecoration(
                  labelText: 'Promoción NxM',
                  hintText: 'Ejemplo: 2x1, 3x2',
                  border: OutlineInputBorder(),
                  helperText: 'Deje vacío si no hay promoción',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final regex = RegExp(r'^\d+x\d+$');
                    if (!regex.hasMatch(value)) {
                      return 'Formato inválido. Use NxM (ejemplo: 2x1)';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: promocionPorcentajeController,
                      decoration: const InputDecoration(
                        labelText: 'Porcentaje de descuento',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                        helperText: 'Deje vacío si no hay descuento',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final numero = double.tryParse(value);
                          if (numero == null) return 'Ingrese un número válido';
                          if (numero <= 0 || numero > 100) {
                            return 'El porcentaje debe estar entre 0 y 100';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Aplicar descuento en',
                        border: OutlineInputBorder(),
                        helperText: 'Seleccione la unidad',
                      ),
                      items: unidadesItems,
                      value: promocionUnidad,
                      onChanged: (value) => setState(() => promocionUnidad = value),
                      validator: (value) {
                        if (promocionPorcentajeController.text.isNotEmpty && value == null) {
                          return 'Seleccione la unidad';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Es Servicio'),
                subtitle: Text(esServicio ? 'El producto es un servicio' : 'El producto es tangible'),
                value: esServicio,
                onChanged: (bool value) {
                  setState(() {
                    esServicio = value;
                    if (esServicio) {
                      permiteReservas = false;
                      cantidadController.clear();
                    }
                  });
                },
              ),
              
              // Add new SwitchListTile for permite_reservas
              if (!esServicio)
                SwitchListTile(
                  title: const Text('Permite Reservas'),
                  subtitle: Text(permiteReservas 
                    ? 'Los clientes pueden reservar este producto' 
                    : 'No se permiten reservas para este producto'),
                  value: permiteReservas,
                  onChanged: (bool value) {
                    setState(() {
                      permiteReservas = value;
                      if (!permiteReservas) {
                        cantidadController.clear();
                      }
                    });
                  },
                ),

              // Show cantidad_disponible field only if product allows reservations and is not a service
              if (!esServicio && permiteReservas) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad Disponible'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo requerido';
                    if (int.tryParse(value) == null) return 'Ingrese un número entero';
                    if (int.parse(value) < 0) return 'La cantidad no puede ser negativa';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Disponibilidad'),
                subtitle: Text(disponibilidad ? 'Producto disponible' : 'Producto no disponible'),
                value: disponibilidad,
                onChanged: (bool value) {
                  setState(() => disponibilidad = value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: actualizarProducto,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}