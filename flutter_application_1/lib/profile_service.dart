// profile_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProfileService {
  static const String baseUrl = AuthService.baseUrl;

  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/profiles/me/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener el perfil: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
  final url = Uri.parse('$baseUrl/profiles/me/');
  try {
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.accessToken}',
      },
      body: json.encode(userData),  // Send the data as is, since it's already structured correctly
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al actualizar el usuario: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}


   Future<String> getCity() async {
    final url = Uri.parse('$baseUrl/profiles/me/');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ciudad'] as String;
      } else {
        throw Exception('Error al obtener la ciudad del perfil: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}