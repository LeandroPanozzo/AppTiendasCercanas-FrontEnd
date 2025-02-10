//localizacion del usuario que se vera en la parte superior de la pagina
// location_display.dart
// location_display.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../profile_service.dart';

class LocationDisplay extends StatefulWidget {
  const LocationDisplay({Key? key}) : super(key: key);

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay> {
  final ProfileService _profileService = ProfileService();
  String _ciudad = '';
  String _direccionCalle = '';
  String _direccionNumero = '';
  bool _isLoading = true;
  String _error = '';

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
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      final profileData = await _profileService.getProfile();
      setState(() {
        _ciudad = normalizeText(profileData['ciudad'] ?? 'No disponible');
        _direccionCalle = normalizeText(profileData['direccion_calle'] ?? '');
        _direccionNumero = normalizeText(profileData['direccion_numero'] ?? '');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la ubicación';
        _isLoading = false;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    );
  }

  if (_error.isNotEmpty) {
    return Text(_error, 
      style: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      )
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          const Icon(
            Icons.location_on,
            size: 20,
            color: Colors.black54,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _ciudad,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      if (_direccionCalle.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            '$_direccionCalle ${_direccionNumero.isNotEmpty ? _direccionNumero : ''}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ],
  );
}
}