import 'package:car/views/geofence/geofence_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_URL=https://example.com');
  });

  test('generates the first available type-specific default fence name', () {
    final controller = GeofenceController();
    addTearDown(controller.onClose);

    controller.fences.addAll([
      GeofenceRecord(id: '1', name: '多边形围栏1', type: 'polygon', area: ''),
      GeofenceRecord(id: '2', name: '多边形围栏2', type: 'polygon', area: ''),
    ]);

    expect(controller.defaultFenceName(), '多边形围栏3');

    controller.setDrawingMode('circle');
    expect(controller.defaultFenceName(), '圆形围栏1');
  });
}
