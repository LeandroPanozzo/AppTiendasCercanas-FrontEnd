import 'package:http/http.dart' as http;
import 'package:flutter/material.dart' show TimeOfDay;
import 'dart:convert';
import 'dart:io';
import './auth_service.dart';
import 'dart:typed_data';

class ApiService {
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  static const String baseUrl = AuthService.baseUrl;

  static Future<void> enviarDatos(
    String nombre,
    String categoria,
    String diasAtencion,
    String descripcion,
    String ciudad,
    String provincia,
    String direccionCalle,
    String direccionNumero,
    double latitud,
    double longitud,
    TimeOfDay horarioApertura,
    TimeOfDay horarioCierre,
    List<String> metodosPago,
    String whatsapp,
    {File? logoImage,}
  ) async {
    final url = Uri.parse('$baseUrl/tiendas/');

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer ${AuthService.accessToken}',
      });

      // Add text fields
      request.fields.addAll({
        'nombre': nombre,
        'categoria': categoria,
        'dias_atencion': diasAtencion,
        'descripcion': descripcion,
        'ciudad': ciudad,
        'provincia': provincia,
        'direccion_calle': direccionCalle,
        'direccion_numero': direccionNumero,
        'coordenada_latitud': latitud.toString(),
        'coordenada_longitud': longitud.toString(),
        'horario_apertura': formatTimeOfDay(horarioApertura),
        'horario_cierre': formatTimeOfDay(horarioCierre),
        'efectivo': metodosPago.contains('efectivo').toString(),
        'debito': metodosPago.contains('debito').toString(),
        'credito': metodosPago.contains('credito').toString(),
        'transferencia_bancaria': metodosPago.contains('transferencia_bancaria').toString(),
        'pago_movil': metodosPago.contains('pago_movil').toString(),
        'qr': metodosPago.contains('qr').toString(),
        'monedero_electronico': metodosPago.contains('monedero_electronico').toString(),
        'criptomoneda': metodosPago.contains('criptomoneda').toString(),
        'pasarela_en_linea': metodosPago.contains('pasarela_en_linea').toString(),
        'cheque': metodosPago.contains('cheque').toString(),
        'pagos_a_plazos': metodosPago.contains('pagos_a_plazos').toString(),
        'vales': metodosPago.contains('vales').toString(),
        'contra_entrega': metodosPago.contains('contra_entrega').toString(),
        'debito_directo': metodosPago.contains('debito_directo').toString(),
        'creditos_internos': metodosPago.contains('creditos_internos').toString(),
        'whatsapp': whatsapp,
      });

      // Add the image if it exists
      if (logoImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            logoImage.path,
          ),
        );
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception('Error al crear la tienda: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> actualizarTienda(
    int id,
    String nombre,
    String categoria,
    String diasAtencion,
    String descripcion,
    String ciudad,
    String provincia,
    String direccionCalle,
    String direccionNumero,
    double latitud,
    double longitud,
    TimeOfDay horarioApertura,
    TimeOfDay horarioCierre,
    List<String> metodosPago,
    String whatsapp,
    {dynamic logoImage,}  // Cambiar File? a dynamic para aceptar tanto File como Uint8List
) async {
    final url = Uri.parse('$baseUrl/tiendas/$id/');

    try {
      var request = http.MultipartRequest('PUT', url);
      
      request.headers.addAll({
        'Authorization': 'Bearer ${AuthService.accessToken}',
      });

      request.fields.addAll({
        'nombre': nombre,
        'categoria': categoria,
        'dias_atencion': diasAtencion,
        'descripcion': descripcion,
        'ciudad': ciudad,
        'provincia': provincia,
        'direccion_calle': direccionCalle,
        'direccion_numero': direccionNumero,
        'coordenada_latitud': latitud.toString(),
        'coordenada_longitud': longitud.toString(),
        'horario_apertura': formatTimeOfDay(horarioApertura),
        'horario_cierre': formatTimeOfDay(horarioCierre),
        'efectivo': metodosPago.contains('efectivo').toString(),
        'debito': metodosPago.contains('debito').toString(),
        'credito': metodosPago.contains('credito').toString(),
        'transferencia_bancaria': metodosPago.contains('transferencia_bancaria').toString(),
        'pago_movil': metodosPago.contains('pago_movil').toString(),
        'qr': metodosPago.contains('qr').toString(),
        'monedero_electronico': metodosPago.contains('monedero_electronico').toString(),
        'criptomoneda': metodosPago.contains('criptomoneda').toString(),
        'pasarela_en_linea': metodosPago.contains('pasarela_en_linea').toString(),
        'cheque': metodosPago.contains('cheque').toString(),
        'pagos_a_plazos': metodosPago.contains('pagos_a_plazos').toString(),
        'vales': metodosPago.contains('vales').toString(),
        'contra_entrega': metodosPago.contains('contra_entrega').toString(),
        'debito_directo': metodosPago.contains('debito_directo').toString(),
        'creditos_internos': metodosPago.contains('creditos_internos').toString(),
        'whatsapp': whatsapp,
      });

      // Manejar la imagen según su tipo
      if (logoImage != null) {
        if (logoImage is File) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'logo',
              logoImage.path,
            ),
          );
        } else if (logoImage is Uint8List) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'logo',
              logoImage,
              filename: 'logo.png', // o el formato que corresponda
            ),
          );
        }
      }

      final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('Respuesta de actualización de tienda:');
    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la tienda: ${response.body}');
    }
  } catch (e) {
    print('Error detallado: $e');
    throw Exception('Error de conexión: $e');
  }
}
  static Future<List<Map<String, dynamic>>> obtenerProductosPorCiudad(String ciudad) async {
    final url = Uri.parse('$baseUrl/productos/?ciudad=$ciudad');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Error al obtener productos: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> reservarProducto(int productoId, int cantidad) async {
    final url = Uri.parse('$baseUrl/reservas/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
        body: json.encode({
          'producto': productoId,
          'cantidad': cantidad,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al reservar el producto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
static Future<Map<String, dynamic>> obtenerTienda(int id) async {
  final url = Uri.parse('$baseUrl/tiendas/$id/');
  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.accessToken}',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');  // Añadir este print

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Error al obtener la tienda: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}
  static Future<List<dynamic>> fetchStoresByCategory(
  String category, 
  String city, {
  int page = 1,
  int limit = 10,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/tiendas/?categoria=$category'),
      headers: {
        'Authorization': 'Bearer ${AuthService.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      // Filter stores by city manually after fetching
      final List<dynamic> allStores = json.decode(response.body);
      final filteredStores = allStores.where((store) => 
        store['ciudad'].toString().toLowerCase() == city.toLowerCase()
      ).toList();

      // Calculate the start and end indices for the requested page
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      // Return the paginated subset of filtered stores
      if (startIndex >= filteredStores.length) {
        return []; // Return empty list if page is out of bounds
      }
      
      return filteredStores.sublist(
        startIndex,
        endIndex > filteredStores.length ? filteredStores.length : endIndex
      );
    } else {
      throw Exception('Failed to load stores');
    }
  } catch (e) {
    print('Error fetching stores: $e');
    rethrow;
  }
}
 static Future<List<dynamic>> fetchStoresByPaymentMethod(
  String paymentMethod, 
  String city, {
  int page = 1,
  int limit = 10,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/tiendas/?$paymentMethod=true'),
      headers: {
        'Authorization': 'Bearer ${AuthService.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      // Filter stores by city manually
      final List<dynamic> allStores = jsonDecode(response.body);
      final filteredStores = allStores.where((store) => 
        store['ciudad'].toString().toLowerCase() == city.toLowerCase()
      ).toList();

      // Calculate pagination indices
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      // Return empty list if page is out of bounds
      if (startIndex >= filteredStores.length) {
        return [];
      }
      
      // Return the paginated subset
      return filteredStores.sublist(
        startIndex,
        endIndex > filteredStores.length ? filteredStores.length : endIndex
      );
    } else {
      throw Exception('Error al cargar tiendas');
    }
  } catch (e) {
    print('Error fetching stores: $e');
    rethrow;
  }
}
}
