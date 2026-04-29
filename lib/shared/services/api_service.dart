import 'package:dio/dio.dart';
import 'api_http.dart';

class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  final HttpService _httpService = HttpService(baseUrl: _baseUrl);

  // 用户相关API
  Future<Response> login(String email, String password) async {
    final data = {'email': email, 'password': password};
    return await _httpService.post('/auth/login', data: data);
  }

  Future<Response> register(String email, String password) async {
    final data = {'email': email, 'password': password};
    return await _httpService.post('/auth/register', data: data);
  }

  // 数据相关API
  Future<Response> fetchHomeData() async {
    return await _httpService.get('/posts');
  }

  Future<Response> updateUserProfile(Map<String, dynamic> data) async {
    return await _httpService.put('/users/me', data: data);
  }

  Future<Response> uploadFile(
    String filePath, {
    required ProgressCallback onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    return await _httpService.post(
      '/upload',
      data: formData,
      options: Options(contentType: Headers.multipartFormDataContentType),
      onSendProgress: onSendProgress,
    );
  }
}
