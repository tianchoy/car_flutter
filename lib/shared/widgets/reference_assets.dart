import 'package:flutter/cupertino.dart';

/// Image assets shared with the reference mobile client.
class ReferenceIcon extends StatelessWidget {
  const ReferenceIcon(
    this.name, {
    super.key,
    this.size = 26,
    this.semanticLabel,
    this.fit = BoxFit.contain,
  });

  final String name;
  final double size;
  final String? semanticLabel;
  final BoxFit fit;

  String get _assetPath {
    final normalized = name.startsWith('assets/')
        ? name
        : 'assets/static/$name';
    return normalized.toLowerCase().endsWith('.png')
        ? normalized
        : '$normalized.png';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (_, error, stackTrace) => Icon(
        CupertinoIcons.photo,
        size: size,
        color: CupertinoColors.systemGrey,
      ),
    );
  }
}

class ReferenceFeatureIcon extends StatelessWidget {
  const ReferenceFeatureIcon({
    super.key,
    required this.assetName,
    required this.color,
    this.size = 42,
    this.semanticLabel,
  });

  final String assetName;
  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * .17),
      child: ReferenceIcon(
        assetName,
        size: size * .66,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

const _vehicleTypes = <String>{
  'car',
  'suv',
  'bus',
  'huoche',
  'train',
  'diandong',
  'moto',
  'bike',
  'sanlun',
  'tuola',
  'wajue',
  'tuiche',
  'baby',
  'muma',
  'tank',
  'zhuangjia',
  'plan',
  'hangmu',
  'junjian',
  'walk',
};

String vehicleAssetName({String? carType, required bool online}) {
  final type = carType?.trim().toLowerCase();
  final safeType = type != null && _vehicleTypes.contains(type)
      ? type
      : 'default';
  return 'cars/${online ? 'online' : 'offline'}/$safeType.png';
}

class VehicleAssetIcon extends StatelessWidget {
  const VehicleAssetIcon({
    super.key,
    this.carType,
    required this.online,
    this.size = 42,
    this.semanticLabel,
  });

  final String? carType;
  final bool online;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => ReferenceIcon(
    vehicleAssetName(carType: carType, online: online),
    size: size,
    semanticLabel: semanticLabel,
  );
}
