# car

A new Flutter project for car connect internet.

### Component

- showDialog
    ```dart
    AppDialog.show(
      context,
      title: '提示',
      content: '确定退出登录吗?',
      onConfirm: () {
        print('点击确认');
      },
      onCancel: () {
        print('点击取消');
      },
    );
    ```
- showPopup
    - String options
      ```dart
      AppPopup.show(
        context: context,
        options: ['编辑', '删除', '分享'],
        displayText: (option) => option,
        isShowTitle: false,
        isShowMessage: false,
        cancelText: '关闭',
        onSelected: (selected) {
          print(selected);
        },
      );
      ```
    - Object options
      ```dart
      AppPopup.show<Map<String, dynamic>>(
        context: context,
        title: '请选择',
        message: '请从以下选项中选择一项',
        options: [
          {'name': '选项1', 'value': 1},
          {'name': '选项2', 'value': 2},
          {'name': '选项3', 'value': 3},
        ],
        displayText: (item) => item['name'] as String,
        isShowTitle: true,
        isShowMessage: true,
        isShowCancel: true,
        onSelected: (selected) {
          if (selected != null) {
            print('选中了: ${selected['name']}');
          } else {
            print('用户取消了');
          }
        },
        onCancel: () {
          print('点击了取消按钮');
        },
      );
      ```

- snackbar
    ```dart
    
    Get.snackbar
    (
    title,
    content,
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 1),
    );
    
    ```
