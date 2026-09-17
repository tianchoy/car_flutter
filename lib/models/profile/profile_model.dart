/// 用户注册来源渠道（接口字段 userSourceType，字典编码 user_source_type）。
///
/// 注意：这是「注册来源渠道」，与登录体系类型（LoginHelper.getUserType，
/// pc/app 设备维度）语义完全不同，二者不可混用。
enum UserSourceType {
  app('0', 'APP'),
  miniProgram('1', '小程序'),
  h5('2', 'H5'),
  backend('3', '后台录入');

  const UserSourceType(this.code, this.label);

  final String code;
  final String label;

  static UserSourceType? fromCode(String? code) {
    for (final value in UserSourceType.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// 「获取当前登录用户个人信息」接口（GET /system/appUser/profile）的 data 结构。
class UserProfileModel {
  const UserProfileModel({
    required this.userName,
    required this.phoneNumber,
    required this.userSourceType,
    required this.createTime,
  });

  /// 用户账号。
  final String userName;

  /// 手机号（是否明文由服务端策略决定）。
  final String phoneNumber;

  /// 用户注册来源渠道编码，见 [UserSourceType]。
  final String userSourceType;

  /// 创建时间，格式 yyyy-MM-dd HH:mm:ss。
  final String createTime;

  /// 同时兼容新接口字段（userName / phoneNumber）与回退的旧接口字段
  /// （username / phone、phonenumber、mobile）。
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    String text(List<Object?> keys) {
      for (final key in keys) {
        final value = json[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    return UserProfileModel(
      userName: text(const ['userName', 'username']),
      phoneNumber: text(const ['phoneNumber', 'phone', 'phonenumber', 'mobile']),
      userSourceType: text(const ['userSourceType']),
      createTime: text(const ['createTime', 'create_time']),
    );
  }

  /// 用户来源渠道的中文名（按文档 §3.3 字典映射，未知编码返回 '--'）。
  String get userSourceTypeName =>
      UserSourceType.fromCode(userSourceType)?.label ?? '--';
}

