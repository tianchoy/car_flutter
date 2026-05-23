import '../../model/home/device_model.dart';
import '../../shared/services/api_service.dart';

class DetailRepository {
  final ApiService _apiService = ApiService();
  final trackData = [];

  Future<void> fetchTrackData(DeviceModel? data) async {
    if (data == null) {
      return;
    }
    final response = await _apiService.getTrackPos(data.toJson());
    print(response.data);
    // trackData.addAll(response.data['data']);
  }
}
