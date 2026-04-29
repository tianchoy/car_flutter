import 'package:get/get.dart';
import 'home_repository.dart';

class HomeController extends GetxController {
  final HomeRepository repository = Get.put(HomeRepository());

  double get latitude => repository.latitude.value;
  double get longitude => repository.longitude.value;
  bool get isLoading => repository.isLoading.value;
  String get errorMessage => repository.errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    repository.getCurrentLocation();
  }
}
