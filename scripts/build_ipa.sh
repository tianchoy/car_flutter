#!/usr/bin/env bash
#
# 一键出 iOS 包（Runner.ipa），版本号自动与 pubspec.yaml 的 version 保持一致。
#
# 原理：flutter build ipa 在打包前会重新生成 ios/Flutter/Generated.xcconfig，
# 因此 FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER 始终同步 pubspec.yaml，
# 不会出现「iOS 端版本号停留在旧值」的问题。
#
# 用法：
#   ./scripts/build_ipa.sh                 # 默认 Release 出包
#   ./scripts/build_ipa.sh --export-method ad-hoc   # 透传参数给 flutter build ipa
#
# 产物：build/ios/ipa/Runner.ipa（可用 Apple Transporter 上传 App Store / 分发）
#
set -euo pipefail

# 切换到仓库根目录（脚本位于 <repo>/scripts/ 下）
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

echo "==> flutter pub get (刷新 Generated.xcconfig 与依赖)"
flutter pub get

echo "==> flutter build ipa"
flutter build ipa "$@"

echo "==> 完成，产物见 build/ios/ipa/Runner.ipa"
