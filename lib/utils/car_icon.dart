/// 车标资源管理，对应原项目 utils/cars.uts 的 getDeviceIcon。
///
/// 资源目录 assets/static/cars/{online,offline}/ 下包含 default 与以下各车型图标，
/// 离线为灰色、在线为彩色。添加设备时由用户选择车标（即 carType），其它页面根据
/// 接口返回的 carType + 在线状态决定展示哪个车标。
library;

class CarIconOption {
  const CarIconOption(this.name, this.label);

  final String name;
  final String label;
}

/// 车标选择器中展示的可选项，顺序与标签与原项目保持一致。
const List<CarIconOption> carIconOptions = <CarIconOption>[
  CarIconOption('car', '轿车'),
  CarIconOption('suv', '越野车'),
  CarIconOption('bus', '公交车'),
  CarIconOption('huoche', '货车'),
  CarIconOption('train', '火车'),
  CarIconOption('diandong', '电动车'),
  CarIconOption('moto', '摩托车'),
  CarIconOption('bike', '自行车'),
  CarIconOption('sanlun', '三轮车'),
  CarIconOption('tuola', '拖拉机'),
  CarIconOption('wajue', '挖掘机'),
  CarIconOption('tuiche', '手推车'),
  CarIconOption('baby', '婴儿车'),
  CarIconOption('muma', '木马'),
  CarIconOption('tank', '坦克'),
  CarIconOption('zhuangjia', '装甲车'),
  CarIconOption('plan', '飞机'),
  CarIconOption('hangmu', '航母'),
  CarIconOption('junjian', '军舰'),
  CarIconOption('walk', '步行'),
];

const List<String> _validCarTypes = <String>[
  'car',
  'bus',
  'bike',
  'moto',
  'diandong',
  'huoche',
  'sanlun',
  'tuola',
  'suv',
  'baby',
  'tank',
  'zhuangjia',
  'wajue',
  'plan',
  'walk',
  'muma',
  'hangmu',
  'junjian',
  'tuiche',
  'train',
];

/// 根据在线状态与 carType 返回车标资源路径。
/// 当 carType 非法或缺失时回退到 default.png。
String deviceIconPath({required bool online, String? carType}) {
  final type =
      carType != null && _validCarTypes.contains(carType) ? carType : 'default';
  return 'assets/static/cars/${online ? 'online' : 'offline'}/$type.png';
}

/// 选择器里展示用的预览图（统一用在线态彩色图标）。
String carIconPreviewPath(String name) =>
    'assets/static/cars/online/$name.png';

/// 根据车标名称取中文标签，未命中时返回原名。
String carIconLabel(String name) {
  for (final option in carIconOptions) {
    if (option.name == name) return option.label;
  }
  return name;
}
