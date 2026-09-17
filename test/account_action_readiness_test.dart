import 'package:car/shared/services/api_service.dart';
import 'package:car/shared/services/api_http.dart';
import 'package:car/views/account/forgot_password/forgot_password_controller.dart';
import 'package:car/views/account/forgot_password/forgot_password_repository.dart';
import 'package:car/views/account/register/register_controller.dart';
import 'package:car/views/account/register/register_repository.dart';
import 'package:flutter_test/flutter_test.dart';

RegisterRepository registerRepository() => RegisterRepository(
  apiService: ApiService(
    httpService: HttpService(baseUrl: 'https://example.com'),
  ),
);

ForgotPasswordRepository forgotPasswordRepository() => ForgotPasswordRepository(
  apiService: ApiService(
    httpService: HttpService(baseUrl: 'https://example.com'),
  ),
);

void main() {
  test('register submit requires complete valid data and agreement', () {
    final controller = RegisterController(repository: registerRepository());
    controller.onInit();
    addTearDown(controller.onClose);

    expect(controller.isSubmitReady, isFalse);

    controller.phoneController.text = '13800138000';
    controller.codeController.text = '123456';
    controller.passwordController.text = 'Password1!';
    expect(controller.isSubmitReady, isFalse);

    controller.agreed.value = true;
    expect(controller.isSubmitReady, isTrue);

    controller.codeController.text = '12345';
    expect(controller.isSubmitReady, isFalse);
  });

  test('forgot password actions require complete valid step data', () {
    final controller = ForgotPasswordController(
      repository: forgotPasswordRepository(),
    );
    controller.onInit();
    addTearDown(controller.onClose);

    expect(controller.isIdentityReady, isFalse);
    controller.phoneController.text = '13800138000';
    controller.codeController.text = '123456';
    expect(controller.isIdentityReady, isTrue);

    expect(controller.isResetReady, isFalse);
    controller.passwordController.text = 'Password1!';
    controller.confirmController.text = 'Different1!';
    expect(controller.isResetReady, isFalse);

    controller.confirmController.text = 'Password1!';
    expect(controller.isResetReady, isTrue);

    controller.passwordController.text = 'password';
    expect(controller.isResetReady, isFalse);
  });
}
