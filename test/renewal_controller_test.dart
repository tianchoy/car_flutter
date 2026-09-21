import 'package:car/services/api_http.dart';
import 'package:car/services/api_service.dart';
import 'package:car/services/url.dart';
import 'package:car/views/account/renewal/renewal_controller.dart';
import 'package:car/views/account/renewal/renewal_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _RenewalApiService extends ApiService {
  _RenewalApiService({required this.devicesData, required this.platformAppData})
    : super(httpService: HttpService(baseUrl: 'https://example.com'));

  final Object? devicesData;
  final Object? platformAppData;

  @override
  Future<Response<dynamic>> getUserDeviceList(Map<String, dynamic> data) async {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: ApiEndpoints.userDeviceList),
      data: devicesData,
    );
  }

  @override
  Future<Response<dynamic>> getHomePlatformApp() async {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: ApiEndpoints.homePlatformApp),
      data: platformAppData,
    );
  }
}

RenewalController _controller({
  required Object? devicesData,
  required Object? platformAppData,
}) {
  return RenewalController(
    repository: RenewalRepository(
      apiService: _RenewalApiService(
        devicesData: devicesData,
        platformAppData: platformAppData,
      ),
    ),
  );
}

const _devicesResponse = <String, dynamic>{
  'code': 200,
  'msg': '操作成功',
  'data': <String, dynamic>{
    'list': <Map<String, dynamic>>[
      <String, dynamic>{
        'deviceId': 'device-1',
        'deviceNo': '866001234567890',
        'deviceName': '测试车辆',
      },
    ],
  },
};

void main() {
  test('loads the platform mini-program AppID with renewal devices', () async {
    final controller = _controller(
      devicesData: _devicesResponse,
      platformAppData: const <String, dynamic>{
        'code': 200,
        'msg': '操作成功',
        'data': ' wx1d647f2cfdc089e6 ',
      },
    );
    addTearDown(controller.onClose);

    await controller.load();

    expect(controller.devices, hasLength(1));
    expect(controller.platformAppId.value, 'wx1d647f2cfdc089e6');
    expect(controller.platformAppErrorMessage.value, isEmpty);
  });

  test('keeps renewal devices when platform AppID is unavailable', () async {
    final controller = _controller(
      devicesData: _devicesResponse,
      platformAppData: const <String, dynamic>{
        'code': 200,
        'msg': '操作成功',
        'data': null,
      },
    );
    addTearDown(controller.onClose);

    await controller.load();

    expect(controller.devices, hasLength(1));
    expect(controller.errorMessage.value, isEmpty);
    expect(controller.platformAppId.value, isNull);
    expect(controller.platformAppErrorMessage.value, isEmpty);
  });

  test(
    'reports platform AppID business failures without blocking devices',
    () async {
      final controller = _controller(
        devicesData: _devicesResponse,
        platformAppData: const <String, dynamic>{
          'code': 500,
          'msg': '系统异常，请稍后重试',
          'data': null,
        },
      );
      addTearDown(controller.onClose);

      await controller.load();

      expect(controller.devices, hasLength(1));
      expect(controller.platformAppId.value, isNull);
      expect(controller.platformAppErrorMessage.value, '系统异常，请稍后重试');
    },
  );
}
