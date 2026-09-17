import 'package:flutter/widgets.dart';

/// 全局路由观察者：用于感知页面进出栈，实现「离开页面即暂停刷新」等需求。
final RouteObserver<PageRoute<void>> routeObserver =
    RouteObserver<PageRoute<void>>();
