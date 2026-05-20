import '../../model/home/device_model.dart';
import '../../shared/services/api_service.dart';

class DetailRepository {
  final ApiService _apiService = ApiService();

  Future<void> fetchDetailData(DeviceModel? date) async {
    print('fetchDetailData called: ${date?.deviceId}');
    return;
  }
}
