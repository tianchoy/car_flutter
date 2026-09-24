import 'dart:convert';

import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'package:car/models/device/command_models.dart';
import 'commands_repository.dart';

class CommandsController extends GetxController {
  CommandsController({CommandsRepository? repository})
    : _repository = repository ?? CommandsRepository();

  final CommandsRepository _repository;
  final DeviceModel? device = DeviceRouteArgs.deviceFrom(Get.arguments);
  final availableCommands = <CommandTemplate>[].obs;
  final history = <CommandRecord>[].obs;
  final selectedCommand = Rxn<CommandTemplate>();
  final parameterValues = <String, String>{}.obs;
  final parameterErrors = <String, String>{}.obs;
  final isLoading = false.obs;
  final isHistoryLoading = false.obs;
  final isSending = false.obs;
  final isDetailLoading = false.obs;
  final errorMessage = ''.obs;
  final activeTab = 0.obs;
  final historyPage = 1.obs;
  final historyTotal = 0.obs;
  final hasMoreHistory = true.obs;
  final detailRecord = Rxn<CommandRecord>();

  String get deviceId => device?.deviceId ?? '';

  /// 切换「下发指令 / 指令记录」：首次切到记录页时懒加载历史记录。
  void setActiveTab(int index) {
    if (index != 0 && index != 1) return;
    if (activeTab.value == index) return;
    activeTab.value = index;
    if (index == 1 && history.isEmpty) loadHistory(reset: true);
  }

  String get deviceIdentity => device?.deviceNo?.isNotEmpty == true
      ? device!.deviceNo!
      : device?.deviceName ?? deviceId;

  @override
  void onInit() {
    super.onInit();
    if (deviceId.isNotEmpty) loadAvailableCommands();
  }

  Future<void> loadAvailableCommands() async {
    if (deviceId.isEmpty || isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repository.fetchAvailableCommands(deviceId);
      final result = ApiResponse<List<Object?>>.fromJson(
        response.data,
        dataParser: jsonListFrom,
      );
      if (!result.isSuccess) {
        availableCommands.clear();
        selectedCommand.value = null;
        errorMessage.value = result.message.isEmpty
            ? '加载可用指令失败'
            : result.message;
        return;
      }
      availableCommands.assignAll(
        (result.data ?? const <Object?>[])
            .map((item) => CommandTemplate.fromJson(jsonMapFrom(item)))
            .where((item) => item.id.isNotEmpty),
      );
      final currentId = selectedCommand.value?.id;
      if (currentId != null) {
        final replacement = availableCommands.firstWhereOrNull(
          (item) => item.id == currentId,
        );
        if (replacement == null) selectCommand(null);
      }
    } catch (_) {
      errorMessage.value = '加载可用指令失败，请稍后重试';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void selectCommand(CommandTemplate? command) {
    if (command == null || !command.allowed) {
      selectedCommand.value = null;
      parameterValues.clear();
      parameterErrors.clear();
      return;
    }
    selectedCommand.value = command;
    parameterValues.assignAll({
      for (final parameter in command.paramSchema)
        parameter.key: parameter.defaultValue,
    });
    parameterErrors.clear();
  }

  void updateParameter(CommandParameter parameter, String value) {
    parameterValues[parameter.key] = value;
    parameterErrors.remove(parameter.key);
  }

  String parameterValue(CommandParameter parameter) =>
      parameterValues[parameter.key] ?? '';

  bool validateForm() {
    final command = selectedCommand.value;
    if (command == null || !command.allowed) return false;
    parameterErrors.clear();
    for (final parameter in command.paramSchema) {
      final value = parameterValue(parameter).trim();
      var error = '';
      if (parameter.required && value.isEmpty) {
        error = '请填写${parameter.label}';
      } else if (value.isNotEmpty && parameter.type == 'number') {
        final number = double.tryParse(value);
        if (number == null) {
          error = '${parameter.label}必须为数字';
        } else if (parameter.min != null && number < parameter.min!) {
          error = '${parameter.label}不能小于${parameter.min}';
        } else if (parameter.max != null && number > parameter.max!) {
          error = '${parameter.label}不能大于${parameter.max}';
        }
      }
      if (error.isNotEmpty) parameterErrors[parameter.key] = error;
    }
    return parameterErrors.isEmpty;
  }

  Future<void> sendSelectedCommand() async {
    final command = selectedCommand.value;
    if (command == null || isSending.value || !validateForm()) return;
    isSending.value = true;
    try {
      final response = await _repository.sendCommand(<String, dynamic>{
        'deviceId': deviceId,
        'cmdId': command.id,
        if (command.code.isNotEmpty) 'cmdCode': command.code,
        'params': Map<String, dynamic>.from(parameterValues),
      });
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) {
        AppToast.show('成功', '指令已提交，请在指令记录中查看结果');
        await loadHistory(reset: true);
      } else {
        AppToast.show('提示', result.message.isEmpty ? '指令下发失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '指令下发失败，请稍后重试');
    } finally {
      if (!isClosed) isSending.value = false;
    }
  }

  Future<void> loadHistory({bool reset = false}) async {
    if (deviceId.isEmpty || isHistoryLoading.value) return;
    if (!reset && !hasMoreHistory.value) return;
    final page = reset ? 1 : historyPage.value;
    isHistoryLoading.value = true;
    try {
      final response = await _repository.fetchHistory(<String, dynamic>{
        'deviceId': deviceId,
        'pageNum': page,
        'pageSize': 10,
      });
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) {
        AppToast.show(
          '提示',
          result.message.isEmpty ? '加载指令记录失败' : result.message,
        );
        return;
      }
      final data = result.data ?? const <String, dynamic>{};
      final rows = data['rows'] is List
          ? data['rows'] as List
          : const <dynamic>[];
      final records = rows
          .whereType<Map>()
          .map((item) => CommandRecord(data: jsonMapFrom(item)))
          .toList();
      if (reset) {
        history.assignAll(records);
      } else {
        history.addAll(records);
      }
      historyTotal.value = intValue(data['total']);
      historyPage.value = page + 1;
      hasMoreHistory.value =
          history.length < historyTotal.value && records.isNotEmpty;
    } catch (_) {
      AppToast.show('提示', '加载指令记录失败，请稍后重试');
    } finally {
      if (!isClosed) isHistoryLoading.value = false;
    }
  }

  Future<void> openDetail(CommandRecord record) async {
    detailRecord.value = record;
    if (record.id.isEmpty) return;
    isDetailLoading.value = true;
    try {
      final response = await _repository.fetchDetail(record.id);
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (result.isSuccess && result.data != null) {
        detailRecord.value = CommandRecord(data: result.data!);
      }
    } catch (_) {
      AppToast.show('提示', '加载指令详情失败');
    } finally {
      if (!isClosed) isDetailLoading.value = false;
    }
  }

  Future<void> retryRecord(CommandRecord record) async {
    if (record.id.isEmpty) return;
    try {
      final response = await _repository.retry(record.id);
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) {
        AppToast.show('成功', '已重新提交指令');
        await loadHistory(reset: true);
      } else {
        AppToast.show('提示', result.message.isEmpty ? '重试失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '重试失败，请稍后重试');
    }
  }

  List<CommandParameter> parseSchemaFallback(
    CommandTemplate command,
    Map<String, dynamic> raw,
  ) {
    final value = raw['paramSchema'];
    if (value is! String || value.trim().isEmpty) return command.paramSchema;
    try {
      final parsed = jsonDecode(value);
      if (parsed is List) {
        return parsed
            .whereType<Map>()
            .map((item) => CommandParameter.fromJson(jsonMapFrom(item)))
            .toList();
      }
    } catch (_) {}
    return command.paramSchema;
  }
}
