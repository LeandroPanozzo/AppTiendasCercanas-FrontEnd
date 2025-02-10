//mapa usado para agregar las direcciones de las tiendas y usuarios
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DireccionMapaScreen extends StatefulWidget {
  final String nombre;
  final String descripcion;
  final List<String> categorias;
  final List<String> diasAtencion;
  final TimeOfDay? horarioApertura;
  final TimeOfDay? horarioCierre;

  DireccionMapaScreen({
    required this.nombre,
    required this.descripcion,
    required this.categorias,
    required this.diasAtencion,
    this.horarioApertura,
    this.horarioCierre,
  });

  @override
  _DireccionMapaScreenState createState() => _DireccionMapaScreenState();
}

class _DireccionMapaScreenState extends State<DireccionMapaScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedPosition = LatLng(-34.6037, -58.3816);
  String _calle = "";
  String _numero = "";
  String _ciudad = "";
  String _provincia = "";
  TextEditingController _searchController = TextEditingController();

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

  Future<void> _getAddressFromLatLng(LatLng position) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1');
    final response = await http.get(url, headers: {
      'Accept-Charset': 'utf-8',
      'Accept': 'application/json',
    });

  if (response.statusCode == 200) {
      final result = json.decode(utf8.decode(response.bodyBytes));
      final address = result['address'];
      setState(() {
        _calle = normalizeText(address['road'] ?? "");
        _numero = address['house_number'] ?? "";
        _ciudad = normalizeText(address['city'] ?? address['town'] ?? address['village'] ?? "");
        _provincia = normalizeText(address['state'] ?? "");
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result.isNotEmpty) {
        final lat = double.parse(result[0]['lat']);
        final lon = double.parse(result[0]['lon']);
        final position = LatLng(lat, lon);
        setState(() => _selectedPosition = position);
        _mapController.move(position, 15.0);
        _getAddressFromLatLng(position);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontró la ubicación.')),
        );
      }
    }
  }

  

  void _confirmarDireccion() {
    if (_calle.isEmpty || _ciudad.isEmpty || _provincia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona una ubicación válida con todos los datos necesarios.')),
      );
      return;
    }

      print('Returning coordinates - Latitude: ${_selectedPosition.latitude}, Longitude: ${_selectedPosition.longitude}');


  Navigator.pop(context, {
      'direccion_calle': _calle,
      'direccion_numero': _numero,
      'ciudad': _ciudad,
      'provincia': _provincia,
      'coordenada_latitud': _selectedPosition.latitude,
      'coordenada_longitud': _selectedPosition.longitude,
    });
  }

 void _onMapTap(TapPosition tapPosition, LatLng position) {
    print('Map tapped at - Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    setState(() => _selectedPosition = position);
    _getAddressFromLatLng(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleccionar Dirección')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar dirección...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _searchLocation(value);
                      }
                    },
                  ),

                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _searchLocation(_searchController.text);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _selectedPosition,
                zoom: 15.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPosition,
                      builder: (ctx) => Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dirección Seleccionada:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Calle: $_calle ${_numero.isNotEmpty ? "N° $_numero" : ""}'),
                Text('Ciudad: $_ciudad'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _confirmarDireccion,
                  child: Text('Confirmar Dirección'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}