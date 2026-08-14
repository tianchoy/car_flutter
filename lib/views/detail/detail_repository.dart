import '../../shared/services/api_service.dart';

class DetailRepository {
  final ApiService _apiService = ApiService();
  final trackData = [];

  Future<void> fetchTrackData(Map<String, dynamic> data) async {
    final response = await _apiService.getTrackPos(data);
    print(response.data);
    // trackData.addAll(response.data['data']);
  }
}
