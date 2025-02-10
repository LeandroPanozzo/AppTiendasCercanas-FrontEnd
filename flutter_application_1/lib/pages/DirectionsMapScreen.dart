//en donde mostrara en el mapa el camino para ir desde la ubicacion del usuario a la tienda

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectionsMapScreen extends StatefulWidget {
  final String storeName;
  final double destinationLat;
  final double destinationLng;

  const DirectionsMapScreen({
    Key? key,
    required this.storeName,
    required this.destinationLat,
    required this.destinationLng,
  }) : super(key: key);

  @override
  _DirectionsMapScreenState createState() => _DirectionsMapScreenState();
}

class _DirectionsMapScreenState extends State<DirectionsMapScreen> {
  LatLng? _userLocation;
  bool _isLoading = true;
  String _error = '';
  List<LatLng> _routePoints = [];
  String _distance = '';
  String _duration = '';
  late MapController _mapController;
  LatLngBounds? _bounds;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  // Función para calcular los límites de la ruta
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    // Agregar un margen del 10% alrededor de los límites
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permisos de ubicación denegados';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Los permisos de ubicación están permanentemente denegados';
      }

      final Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      await _getRoute();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _getRoute() async {
    if (_userLocation == null) return;

    try {
      final response = await http.get(Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_userLocation!.longitude},${_userLocation!.latitude};'
        '${widget.destinationLng},${widget.destinationLat}'
        '?overview=full&geometries=geojson'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        
        final geometry = route['geometry']['coordinates'] as List;
        final points = geometry.map((point) {
          return LatLng(point[1], point[0]);
        }).toList();

        final distance = route['distance'] as num;
        final duration = route['duration'] as num;
        
        setState(() {
          _routePoints = points;
          _distance = '${(distance / 1000).toStringAsFixed(1)} km';
          _duration = '${(duration / 60).toStringAsFixed(0)} min';
          
          // Calcular los límites incluyendo la ubicación del usuario y el destino
          List<LatLng> allPoints = [
            _userLocation!,
            LatLng(widget.destinationLat, widget.destinationLng),
            ..._routePoints,
          ];
          _bounds = _calculateBounds(allPoints);
        });

        // Ajustar el mapa para mostrar toda la ruta
        await Future.delayed(const Duration(milliseconds: 100));
        if (_bounds != null) {
          _mapController.fitBounds(
            _bounds!,
            options: const FitBoundsOptions(
              padding: EdgeInsets.all(50.0),
            ),
          );
        }
      }
    } catch (e) {
      print('Error al obtener la ruta: $e');
    }
  }

  void _openInGoogleMaps() async {
    if (_userLocation == null) return;

    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${_userLocation!.latitude},${_userLocation!.longitude}'
        '&destination=${widget.destinationLat},${widget.destinationLng}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cómo llegar a ${widget.storeName}'),
        actions: [
          if (!_isLoading && _userLocation != null)
            IconButton(
              icon: const Icon(Icons.directions),
              onPressed: _openInGoogleMaps,
              tooltip: 'Abrir en Google Maps',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _userLocation == null
                  ? const Center(child: Text('No se pudo obtener tu ubicación'))
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            bounds: _bounds,
                            boundsOptions: const FitBoundsOptions(
                              padding: EdgeInsets.all(50.0),
                            ),
                            interactiveFlags: InteractiveFlag.all,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            if (_routePoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints,
                                    color: Colors.blue,
                                    strokeWidth: 4.0,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _userLocation!,
                                  builder: (ctx) => const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                ),
                                Marker(
                                  point: LatLng(
                                      widget.destinationLat, widget.destinationLng),
                                  builder: (ctx) => const Icon(
                                    Icons.store_mall_directory,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_distance.isNotEmpty && _duration.isNotEmpty)
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(Icons.directions_car),
                                        Text(_distance),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(Icons.access_time),
                                        Text(_duration),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
      floatingActionButton: !_isLoading && _userLocation != null
          ? FloatingActionButton.extended(
              onPressed: _openInGoogleMaps,
              label: const Text('Abrir en Google Maps'),
              icon: const Icon(Icons.map),
            )
          : null,
    );
  }
}