import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../auth_service.dart';

class AddProductoPage extends StatefulWidget {
  final int tiendaId;

  const AddProductoPage({required this.tiendaId, Key? key}) : super(key: key);

  @override
  State<AddProductoPage> createState() => _AddProductoPageState();
}

class _AddProductoPageState extends State<AddProductoPage> {
  final _formKey = GlobalKey<FormState>();
  String nombre = '';
  String descripcion = '';
  double precio = 0.0;
  bool disponibilidad = true;
  bool esServicio = false;
  bool permiteReservas = true; // New field for reservation toggle
  int? cantidadDisponible;
  XFile? _imageFile;
  Uint8List? webImageBytes;
  String? currentImageUrl;
  bool isUploading = false;
  // Nuevas variables para promociones
  String? promocionNx;
  double? promocionPorcentaje;
  int? promocionUnidad;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
      if (kIsWeb) {
        webImageBytes = await pickedFile.readAsBytes();
      }
    }
  }

  // Lista de opciones para unidades
  final List<DropdownMenuItem<int>> unidadesItems = List.generate(
    10,
    (index) => DropdownMenuItem(
      value: index + 1,
      child: Text('${index + 1}ª unidad'),
    ),
  );

  Future<void> _removeImage() async {
    setState(() {
      _imageFile = null;
      webImageBytes = null;
      currentImageUrl = null;
    });
  }

  Future<void> agregarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => isUploading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/productos/'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${AuthService.accessToken}',
      });

      request.fields.addAll({
        'tienda_id': widget.tiendaId.toString(),
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio.toString(),
        'disponibilidad': disponibilidad.toString(),
        'es_servicio': esServicio.toString(),
        'permite_reservas': permiteReservas.toString(), // Add permite_reservas field
        'categoria': 'default_category',
        'estado_publicacion': 'active',
      });

      // Only include cantidad_disponible if the product allows reservations and is not a service
      if (!esServicio && permiteReservas && cantidadDisponible != null) {
        request.fields['cantidad_disponible'] = cantidadDisponible.toString();
      }
      // Agregar campos de promociones
      if (promocionNx != null && promocionNx!.isNotEmpty) {
        request.fields['promocion_nx'] = promocionNx!;
      }
      if (promocionPorcentaje != null && promocionUnidad != null) {
        request.fields['promocion_porcentaje'] = promocionPorcentaje.toString();
        request.fields['promocion_unidad'] = promocionUnidad.toString();
      }
      if (_imageFile != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'imagen',
            webImageBytes!,
            filename: _imageFile!.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'imagen',
            _imageFile!.path,
          ));
        }
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agregado con éxito')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Error al agregar el producto: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<Widget> _buildImagePreview() async {
    if (_imageFile != null) {
      if (kIsWeb) {
        return Image.memory(
          webImageBytes!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(_imageFile!.path),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } else if (currentImageUrl != null) {
      return Image.network(
        currentImageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox.shrink();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Agregar Producto'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    FutureBuilder<Widget>(
                      future: _buildImagePreview(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return const Text('Error al cargar la imagen');
                        }
                        return snapshot.data ?? const SizedBox.shrink();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Seleccionar Imagen'),
                        ),
                        if (_imageFile != null)
                          ElevatedButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar Imagen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'El nombre es obligatorio' : null,
              onSaved: (value) => nombre = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'La descripción es obligatoria' : null,
              onSaved: (value) => descripcion = value!,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'El precio es obligatorio';
                if (double.tryParse(value) == null) return 'Ingrese un número válido';
                if (double.parse(value) <= 0) return 'El precio debe ser mayor a 0';
                return null;
              },
              onSaved: (value) => precio = double.parse(value!),
            ),
            const SizedBox(height: 16),
            // Sección de Promociones
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
              onSaved: (value) => promocionNx = value?.isEmpty ?? true ? null : value,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
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
                    onSaved: (value) => promocionPorcentaje = 
                      value?.isEmpty ?? true ? null : double.parse(value!),
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
                      if (promocionPorcentaje != null && value == null) {
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
              onChanged: (value) => setState(() {
                esServicio = value;
                if (esServicio) {
                  permiteReservas = false;
                  cantidadDisponible = null;
                }
              }),
            ),
            if (!esServicio)
              SwitchListTile(
                title: const Text('Permite Reservas'),
                subtitle: Text(permiteReservas 
                  ? 'Los clientes pueden reservar este producto' 
                  : 'No se permiten reservas para este producto'),
                value: permiteReservas,
                onChanged: (value) => setState(() {
                  permiteReservas = value;
                  if (!permiteReservas) {
                    cantidadDisponible = null;
                  }
                }),
              ),
            const SizedBox(height: 16),
            if (!esServicio && permiteReservas)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cantidad Disponible',
                  border: OutlineInputBorder(),
                  helperText: 'Ingrese la cantidad de productos disponibles',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'La cantidad es obligatoria';
                  if (int.tryParse(value) == null) return 'Ingrese un número entero';
                  if (int.parse(value) < 0) return 'La cantidad no puede ser negativa';
                  return null;
                },
                onSaved: (value) => cantidadDisponible = int.parse(value!),
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Disponibilidad'),
              subtitle: Text(disponibilidad ? 'Producto disponible' : 'Producto no disponible'),
              value: disponibilidad,
              onChanged: (value) => setState(() => disponibilidad = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isUploading ? null : agregarProducto,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar Producto'),
            ),
          ],
        ),
      ),
    ),
  );
}
}