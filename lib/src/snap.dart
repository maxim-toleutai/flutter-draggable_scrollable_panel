part of 'draggable_scrollable_panel.dart';

class DraggableSnap {
  static const double _defaultMinSpeed = 1200;
  static double defaultMinSpeed = _defaultMinSpeed;

  DraggableSnap({
    required this.position,
    this.pixelPosition,
    this.minSpeed = _defaultMinSpeed,
  });

  const DraggableSnap.byPosition({
    required this.position,
    this.minSpeed = _defaultMinSpeed,
  }) : pixelPosition = null;

  // const DraggableSnap.byPixels({
  //   required this.pixelPosition,
  //   this.minSpeed = _defaultMinSpeed,
  // })  : assert(pixelPosition != null),
  //       position = null;

  factory DraggableSnap.defaultSpeed({
    required double position,
    double? pixelPosition,
  }) {
    return DraggableSnap(
      position: position,
      pixelPosition: pixelPosition,
      minSpeed: defaultMinSpeed,
    );
  }

  final double position;
  final double minSpeed;
  final double? pixelPosition;

  DraggableSnap _copyWithPixels(double pixelPosition) => DraggableSnap(
        position: position,
        minSpeed: minSpeed,
        pixelPosition: pixelPosition,
      );
}
