import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static String? accessToken;
  static String? refreshToken;
  static const String ACCESS_TOKEN_KEY = 'access_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';

  // Inicializar tokens desde SharedPreferences
  static Future<void> initializeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(ACCESS_TOKEN_KEY);
    refreshToken = prefs.getString(REFRESH_TOKEN_KEY);
  }

  // Guardar tokens
  static Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ACCESS_TOKEN_KEY, access);
    await prefs.setString(REFRESH_TOKEN_KEY, refresh);
    accessToken = access;
    refreshToken = refresh;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/token/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(data['access'], data['refresh']);
        return data;
      } else {
        throw Exception('Error al iniciar sesión: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Método para refrescar el token
  Future<bool> refreshAccessToken() async {
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(data['access'], data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Método para hacer peticiones HTTP con renovación automática del token
  Future<http.Response> authenticatedRequest(
    String url,
    String method,
    {Map<String, dynamic>? body}
  ) async {
    http.Response response;
    
    try {
      response = await _makeRequest(url, method, body: body);
      
      // Si el token expiró, intentamos renovarlo y repetir la petición
      if (response.statusCode == 401) {
        final bool refreshed = await refreshAccessToken();
        if (refreshed) {
          response = await _makeRequest(url, method, body: body);
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('Error en la petición: $e');
    }
  }

  Future<http.Response> _makeRequest(
    String url,
    String method,
    {Map<String, dynamic>? body}
  ) async {
    final headers = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(Uri.parse(url), headers: headers);
      case 'POST':
        return await http.post(Uri.parse(url), headers: headers, body: json.encode(body));
      case 'PUT':
        return await http.put(Uri.parse(url), headers: headers, body: json.encode(body));
      case 'DELETE':
        return await http.delete(Uri.parse(url), headers: headers);
      default:
        throw Exception('Método HTTP no soportado');
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ACCESS_TOKEN_KEY);
      await prefs.remove(REFRESH_TOKEN_KEY);
      
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      
      accessToken = null;
      refreshToken = null;
    } catch (e) {
      print('Error during logout: $e');
      accessToken = null;
      refreshToken = null;
    }
  }

  static bool isAuthenticated() {
    return accessToken != null;
  }


  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/users/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'password2': password,
        }),
      );

      if (response.statusCode == 201) {
        try {
          final loginResponse = await login(username, password);
          return loginResponse;
        } catch (loginError) {
          return json.decode(response.body);
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData.toString());
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

}