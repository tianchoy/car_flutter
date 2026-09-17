import 'package:flutter_test/flutter_test.dart';

import 'package:car/views/account/scan_code/scan_code_controller.dart';

void main() {
  group('ScanCodeController.deviceIdFromScanValue（仅提取，不计算）', () {
    test('extracts a plain device identifier without calculating', () {
      expect(
        ScanCodeController.deviceIdFromScanValue('  000094082357294  '),
        '000094082357294',
      );
    });

    test('extracts identifiers from JSON payloads', () {
      expect(
        ScanCodeController.deviceIdFromScanValue('{"deviceId":"device-001"}'),
        'device-001',
      );
      expect(
        ScanCodeController.deviceIdFromScanValue('{"imei": "860123"}'),
        '860123',
      );
    });

    test('extracts identifiers from URL query payloads', () {
      expect(
        ScanCodeController.deviceIdFromScanValue(
          'https://example.com/device?deviceId=device-002',
        ),
        'device-002',
      );
    });

    test('extracts labelled identifiers', () {
      expect(
        ScanCodeController.deviceIdFromScanValue('IMEI：000094082357294'),
        '000094082357294',
      );
    });

    test('strips AIM symbology identifier prefixes from barcodes', () {
      // 部分 Code 128 / GS1 条码会带 AIM 符号标识前缀（如 ]C1）。
      expect(
        ScanCodeController.deviceIdFromScanValue(']C194082357294'),
        '94082357294',
      );
    });

    test('rejects empty values', () {
      expect(ScanCodeController.deviceIdFromScanValue(null), isNull);
      expect(ScanCodeController.deviceIdFromScanValue('  '), isNull);
    });
  });

  group('ScanCodeController.standardizeScanResult（扫码后计算，与 Web 一致）', () {
    test('converts a 15-digit scan result using the web slice rule', () {
      // Web 端规则：'0' + result.slice(4, 15)
      expect(
        ScanCodeController.standardizeScanResult('000094082357294'),
        '094082357294',
      );
      expect(
        ScanCodeController.standardizeScanResult('860123456789012'),
        '023456789012',
      );
    });

    test('converts an 11-digit scan result by prefixing a single zero', () {
      expect(
        ScanCodeController.standardizeScanResult('94082357294'),
        '094082357294',
      );
    });

    test('rejects scan results of other digit lengths', () {
      // 与 Web 端一致：其他长度 toast 提示且不回填（这里以 null 表示）。
      expect(ScanCodeController.standardizeScanResult('094082357294'), isNull);
      expect(ScanCodeController.standardizeScanResult('1234567890'), isNull);
    });

    test('passes non-digit identifiers through unchanged', () {
      expect(
        ScanCodeController.standardizeScanResult('device-001'),
        'device-001',
      );
    });

    test('calculates a full scan flow: strip prefix then convert', () {
      final raw = ScanCodeController.deviceIdFromScanValue(']C194082357294');
      expect(ScanCodeController.standardizeScanResult(raw!), '094082357294');
    });
  });

  group('ScanCodeController.standardizeDeviceId（手输/提交，宽松）', () {
    test('keeps a 12-digit standard id unchanged for manual input', () {
      expect(
        ScanCodeController.standardizeDeviceId('094082357294'),
        '094082357294',
      );
    });

    test('converts 15/11-digit manual input with the same rule', () {
      expect(
        ScanCodeController.standardizeDeviceId('000094082357294'),
        '094082357294',
      );
      expect(
        ScanCodeController.standardizeDeviceId('94082357294'),
        '094082357294',
      );
    });
  });
}
