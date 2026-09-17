import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:car/shared/widgets/app_toast.dart';
import 'scan_code_repository.dart';

class ScanCodeController extends GetxController with WidgetsBindingObserver {
  ScanCodeController({ScanCodeRepository? repository})
    : repository = repository ?? const ScanCodeRepository();

  final ScanCodeRepository repository;
  final scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 500,
    // 保持自动启动：由 MobileScanner 在平台视图就绪后自行 start，
    // 不依赖我们手动调用，避免平台视图未就绪导致两端相机都不启动。
    autoStart: true,
    // 同时支持二维码与常见条形码
    formats: const <BarcodeFormat>[
      BarcodeFormat.qrCode,
      BarcodeFormat.aztec,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf14,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  final isCompleting = false.obs;
  final errorMessage = ''.obs;
  /// 相机权限就绪后才挂载 MobileScanner，避免权限未定时自动启动失败。
  final cameraReady = false.obs;
  /// 画面中同时识别到多个码时，供用户手动选择。
  final candidates = <String>[].obs;

  /// 安卓端同一画面里的多个码通常是「分帧」回调的，若每帧直接取一个，
  /// 就会默认选中先识别到的那个（结果经常不正确）。
  /// 这里在窗口期内累积识别结果（值 -> 命中次数），窗口结束后再决定：
  /// 只有一个值才自动返回；出现多个值则交给用户手动选择。
  static const Duration _settleDuration = Duration(milliseconds: 800);
  final Map<String, int> _pending = <String, int>{};
  Timer? _settleTimer;

  bool _wasRunningBeforePause = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // 等首页构建完成后再初始化相机，确保 MobileScanner 已挂载，start() 不会因
    // 平台视图尚未就绪而失败。
    WidgetsBinding.instance.addPostFrameCallback((_) => initCamera());
  }

  /// 进入页面先确保相机权限；权限就绪后才挂载相机（cameraReady）。
  /// 启动交给 MobileScanner 的 autoStart，不再手动 start，
  /// 避免平台视图未就绪 / 重复 start 导致两端「相机启动失败」。
  Future<void> initCamera() async {
    errorMessage.value = '';
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final requested = await Permission.camera.request();
      if (!requested.isGranted) {
        cameraReady.value = false;
        errorMessage.value = requested.isPermanentlyDenied
            ? '相机权限已被拒绝，请在系统设置中开启后重试'
            : '需要相机权限才能扫码，请允许后重试';
        return;
      }
    }
    cameraReady.value = true;
  }

  /// 权限被永久拒绝后，引导用户到系统设置页开启。
  Future<void> goToAppSettings() async {
    await openAppSettings();
    // 返回后重新探测权限状态。
    await initCamera();
  }

  /// Handles a barcode from the camera.
  ///
  /// 流程与 Web 端一致：
  /// 1. 识别 → 剔除 `]C1` 等 AIM 符号标识前缀、控制字符，提取设备标识（**不计算**）；
  /// 2. 多码 → 弹候选由用户选择，**选完再计算**；
  /// 3. 计算规则见 [standardizeScanResult]：15 位去前 4 位补 0、11 位补 0，
  ///    其他长度 toast「扫码结果长度不是标准设备ID，请确认后提交」且不回填。
  void onDetect(BarcodeCapture capture) {
    if (isCompleting.value) return;

    final frameValues = <String>[];
    for (final barcode in capture.barcodes) {
      final value = deviceIdFromScanValue(
        barcode.rawValue ?? barcode.displayValue,
      );
      if (value == null || value.isEmpty) continue;
      frameValues.add(value);
    }
    if (frameValues.isEmpty) return;

    final unique = frameValues.toSet().toList();

    // 同一帧内识别到多个码：立即给出候选，由用户选择，选完再计算。
    if (unique.length >= 2) {
      _settleTimer?.cancel();
      candidates.assignAll(unique);
      return;
    }

    // 正在展示候选时不再自动回填，避免覆盖用户的选择。
    if (candidates.isNotEmpty) return;

    final value = unique.single;
    // 长度不是标准 15/11 位的纯数字结果：提示但不回填，继续扫码（不静默吞掉）。
    if (_isInvalidScanLength(value)) {
      _notifyInvalidLength();
      return;
    }

    // 单帧只有 1 个码：累积进窗口，稳定后自动返回；
    // 若窗口内又出现其他不同值，则转为候选让用户选择。
    _pending[value] = (_pending[value] ?? 0) + 1;
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleDuration, _resolvePending);
  }

  /// 是否为长度不合规的纯数字扫码结果（标准长度仅 15 位 / 11 位）。
  static bool _isInvalidScanLength(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) return false;
    return value.length != 15 && value.length != 11;
  }

  DateTime? _lastInvalidToastAt;

  /// 提示「长度不是标准设备ID」。扫码持续命中同一码时会连续回调，
  /// 用 2 秒节流避免 toast 刷屏；[force] 用于用户主动选择后必须给出反馈。
  void _notifyInvalidLength({bool force = false}) {
    final now = DateTime.now();
    if (!force &&
        _lastInvalidToastAt != null &&
        now.difference(_lastInvalidToastAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastInvalidToastAt = now;
    AppToast.show('提示', '扫码结果长度不是标准设备ID，请确认后提交');
  }

  void _resolvePending() {
    if (isCompleting.value || _pending.isEmpty) return;
    // 已展示候选时不再自动判定，避免覆盖用户正在做的选择。
    if (candidates.isNotEmpty) return;
    final entries = _pending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _pending.clear();
    if (entries.isEmpty) return;
    if (entries.length == 1) {
      // 窗口期内只识别到唯一结果，直接返回。
      _complete(entries.first.key);
      return;
    }
    // 出现多个结果：不再默认选第一个，改为让用户手动选择。
    candidates.assignAll(entries.map((entry) => entry.key));
  }

  /// 用户在多个识别结果中选择某一个。
  void selectCandidate(String value) {
    if (isCompleting.value) return;
    _complete(value);
  }

  /// 放弃当前候选、重新扫描。
  /// 展示候选时会暂停自动回填，若无退出入口，页面会一直停在候选上、再也扫不了新的码。
  void rescan() {
    if (isCompleting.value) return;
    _settleTimer?.cancel();
    _pending.clear();
    candidates.clear();
    errorMessage.value = '';
  }

  void onDetectError(Object error, StackTrace stackTrace) {
    errorMessage.value = '相机启动失败，请检查相机权限或改用手动输入';
  }

  Future<void> toggleTorch() async {
    try {
      await scannerController.toggleTorch();
    } on MobileScannerException {
      errorMessage.value = '当前设备不支持手电筒';
    }
  }

  Future<void> switchCamera() async {
    try {
      await scannerController.switchCamera();
    } on MobileScannerException {
      errorMessage.value = '无法切换摄像头';
    }
  }

  /// Extracts an identifier from plain text, JSON, or a URL query payload.
  ///
  /// Device QR codes commonly contain the raw IMEI, but accepting the common
  /// structured forms makes the scanner work with QR codes generated by web
  /// portals as well.
  /// 从扫码原文提取设备标识：仅剔除 `]C1` 等 AIM 前缀 / 控制字符并解析
  /// JSON / URL / 标签格式，**不做 15/11 位规整计算**（计算发生在选择之后）。
  static String? deviceIdFromScanValue(String? rawValue) {
    final value = _extractIdentifier(rawValue);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// 扫码结果计算规则（与 Web 端 handleScanResult 完全一致）：
  /// - 15 位纯数字：`'0' + slice(4, 15)`，即去掉前 4 位、左侧补一个 0；
  /// - 11 位纯数字：`'0' + result`，即左侧补一个 0；
  /// - 其他长度的纯数字：返回 null（Web 端 toast「扫码结果长度不是标准设备ID，
  ///   请确认后提交」且不回填）；
  /// - 非纯数字（JSON/URL/带字母 ID）原样返回。
  static String? standardizeScanResult(String raw) {
    final value = raw.trim();
    if (!RegExp(r'^\d+$').hasMatch(value)) return value;
    if (value.length == 15) return '0${value.substring(4)}';
    if (value.length == 11) return '0$value';
    return null;
  }

  /// 手输/提交场景的宽松规整：15/11 位转换，其余（含 12 位标准 ID）原样返回。
  static String standardizeDeviceId(String raw) {
    return standardizeScanResult(raw) ?? raw.trim();
  }

  static String? _extractIdentifier(String? rawValue) {
    // 安卓端部分二维码（尤其是纯数字码）会带入不可见控制字符 / BOM；
    // 部分 Code 128 / GS1 条码还会带上 AIM 符号标识前缀（如「]C1」），
    // 导致结果形如「]C194082357294」。先统一剔除再解析。
    final value = _sanitize(rawValue ?? '').replaceFirst(
      RegExp(r'^\][A-Za-z]\d'),
      '',
    );
    if (value.isEmpty) return null;

    final jsonValue = _identifierFromJson(value);
    if (jsonValue != null) return _sanitize(jsonValue);

    final uriValue = _identifierFromUri(value);
    if (uriValue != null) return _sanitize(uriValue);

    final labelledValue = RegExp(
      r'(?:device[_ -]?id|imei)\s*[:=：]\s*([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(value)?.group(1);
    if (labelledValue != null && labelledValue.isNotEmpty) {
      return _sanitize(labelledValue);
    }

    return value;
  }

  /// 剔除不可见控制字符（含 BOM / ESC 等），仅保留可打印内容并去首尾空白。
  static String _sanitize(String value) {
    return value
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F\uFEFF]'), '')
        .trim();
  }

  static String? _identifierFromJson(String value) {
    if (!(value.startsWith('{') && value.endsWith('}'))) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      for (final key in const ['deviceId', 'device_id', 'imei', 'id']) {
        final candidate = decoded[key]?.toString().trim();
        if (candidate != null && candidate.isNotEmpty) return candidate;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static String? _identifierFromUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasQuery) return null;
    for (final key in const ['deviceId', 'device_id', 'imei', 'id']) {
      final candidate = uri.queryParameters[key]?.trim();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  /// 选定（或窗口内唯一）结果后，先按 Web 端规则计算再回填。
  /// 计算不通过（长度不是 15/11 位）时提示且不回填，清空候选继续扫码。
  Future<void> _complete(String value) async {
    final ruled = standardizeScanResult(value);
    if (ruled == null) {
      _settleTimer?.cancel();
      _pending.clear();
      candidates.clear();
      _notifyInvalidLength(force: true);
      return;
    }
    if (isCompleting.value) return;
    isCompleting.value = true;
    errorMessage.value = '';
    candidates.clear();
    _pending.clear();
    try {
      await scannerController.stop();
    } on MobileScannerException {
      // Returning the decoded value is still safe if stopping the preview fails.
    }
    if (!isClosed) Get.back(result: ruled);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isClosed || isCompleting.value) return;
    if (state == AppLifecycleState.paused) {
      _wasRunningBeforePause = scannerController.value.isRunning;
      if (_wasRunningBeforePause) {
        scannerController.stop();
      }
    } else if (state == AppLifecycleState.resumed && _wasRunningBeforePause) {
      _wasRunningBeforePause = false;
      scannerController.start();
    }
  }

  @override
  void onClose() {
    _settleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    scannerController.dispose();
    super.onClose();
  }
}
