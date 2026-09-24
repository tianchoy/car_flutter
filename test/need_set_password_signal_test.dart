import 'package:flutter_test/flutter_test.dart';
import 'package:car/models/api_response.dart';

void main() {
  test('NEED_SET_PASSWORD 兼容 msg / data / 顶层字段三种形态', () {
    // 1) msg 文本（Web 端实际形态：NEED_SET_PASSWORD:xxx）
    expect(
      isNeedSetPasswordSignal(
        message: 'NEED_SET_PASSWORD:18888888888',
        payload: const {'code': 500, 'msg': 'NEED_SET_PASSWORD:18888888888'},
      ),
      isTrue,
    );
    // 2) data 中的布尔字段
    expect(
      isNeedSetPasswordSignal(
        message: '手机号已注册',
        payload: const {
          'code': 500,
          'data': {'needSetPassword': true},
        },
      ),
      isTrue,
    );
    // 3) 顶层标志字段
    expect(
      isNeedSetPasswordSignal(
        message: '手机号已注册',
        payload: const {'code': 500, 'flag': 'NEED_SET_PASSWORD'},
      ),
      isTrue,
    );
    // 其他业务失败不应误判
    expect(
      isNeedSetPasswordSignal(
        message: '验证码错误',
        payload: const {'code': 500, 'msg': '验证码错误'},
      ),
      isFalse,
    );
    expect(isNeedSetPasswordSignal(message: '', payload: null), isFalse);
  });

  test('NEED_REGISTER 与 NEED_SET_PASSWORD 走同一套设置密码流程', () {
    expect(
      isNeedRegisterSignal(
        message: 'NEED_REGISTER:18888888888',
        payload: const {'code': 500, 'msg': 'NEED_REGISTER:18888888888'},
      ),
      isTrue,
    );
    // 未注册手机号也要跳设置密码页。
    expect(
      requiresPasswordSetup(
        message: 'NEED_REGISTER:18888888888',
        payload: const {'code': 500, 'msg': 'NEED_REGISTER:18888888888'},
      ),
      isTrue,
    );
    expect(
      requiresPasswordSetup(
        message: 'NEED_SET_PASSWORD:18888888888',
        payload: const {'code': 500, 'msg': 'NEED_SET_PASSWORD:18888888888'},
      ),
      isTrue,
    );
    // 两个标志不能互相误判。
    expect(
      isNeedSetPasswordSignal(
        message: 'NEED_REGISTER:18888888888',
        payload: const {'code': 500, 'msg': 'NEED_REGISTER:18888888888'},
      ),
      isFalse,
    );
    expect(
      requiresPasswordSetup(
        message: '验证码错误',
        payload: const {'code': 500, 'msg': '验证码错误'},
      ),
      isFalse,
    );
  });
}
