import '../../shared/services/api_service.dart';

class LoginRepository {
  final ApiService _apiService = ApiService();

  Future<dynamic> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      if (response.statusCode == 200) {
        return response.data.json();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Repository Error: $e');
      rethrow;
    }
  }
}
