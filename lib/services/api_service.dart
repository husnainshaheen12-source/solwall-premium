import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/wallpaper.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String username,
    required String password,
  }) async {
    return _post('/auth/signup', {
      'full_name': fullName,
      'username': username,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return _post('/auth/login', {
      'username': username,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> getUser(String username) async {
    return _get('/users/$username');
  }

  static Future<Map<String, dynamic>> updateUser({
    required String username,
    required String fullName,
    String? password,
  }) async {
    return _put('/users/$username', {
      'full_name': fullName,
      'password': password,
    });
  }

  static Future<List<WallpaperCategory>> getCategories() async {
    final response = await _getList('/categories');
    return response.map((item) => WallpaperCategory.fromJson(item)).toList();
  }

  static Future<List<Wallpaper>> getWallpapers(String category) async {
    final encodedCategory = Uri.encodeComponent(category);
    final response = await _getList('/categories/$encodedCategory/wallpapers');
    return response.map((item) => Wallpaper.fromJson(item)).toList();
  }

  static Future<Map<String, dynamic>> getWallet() async {
    return _get('/wallet');
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String username,
    required String customerWallet,
    required String transactionSignature,
  }) async {
    return _post('/payments/verify', {
      'username': username,
      'customer_wallet': customerWallet,
      'transaction_signature': transactionSignature,
    });
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    return _decodeObject(response);
  }

  static Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    final decoded = _decode(response);
    if (decoded is! List) {
      throw ApiException('Invalid backend response');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decodeObject(response);
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decodeObject(response);
  }

  static Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid backend response');
    }
    return decoded;
  }

  static dynamic _decode(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    if (decoded is Map && decoded['error'] != null) {
      throw ApiException(decoded['error'].toString());
    }
    throw ApiException('Backend request failed with status ${response.statusCode}');
  }
}
