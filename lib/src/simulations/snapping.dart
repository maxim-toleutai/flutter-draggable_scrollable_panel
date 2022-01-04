part of '../draggable_scrollable_panel.dart';

class _SnappingSimulation extends Simulation {
  _SnappingSimulation({
    required this.position,
    required double initialVelocity,
    required List<DraggableSnap> pixelSnaps,
    this.curve,
    Tolerance tolerance = Tolerance.defaultTolerance,
  }) : super(tolerance: tolerance) {
    _pixelSnap = _getSnapSize(initialVelocity, pixelSnaps);
    if (_pixelSnap.pixelPosition! < position) {
      velocity = math.min(-_pixelSnap.minSpeed, initialVelocity);
    } else {
      velocity = math.max(_pixelSnap.minSpeed, initialVelocity);
    }
  }

  final double position;
  final Curve? curve;
  late final double velocity;

  late final DraggableSnap _pixelSnap;

  @override
  double dx(double time) {
    if (isDone(time)) {
      return 0;
    }
    return velocity;
  }

  @override
  bool isDone(double time) {
    return x(time) == _pixelSnap.pixelPosition;
  }

  @override
  double x(double time) {
    final double newPosition =
        position + velocity * (curve != null ? curve!.transform(time) : time);
    if ((velocity >= 0 && newPosition > _pixelSnap.pixelPosition!) ||
        (velocity < 0 && newPosition < _pixelSnap.pixelPosition!)) {
      return _pixelSnap.pixelPosition!;
    }
    return newPosition;
  }

  DraggableSnap _getSnapSize(
      double initialVelocity, List<DraggableSnap> pixelSnaps) {
    final int indexOfNextSnap = pixelSnaps
        .indexWhere((DraggableSnap snap) => snap.pixelPosition! >= position);

    if (indexOfNextSnap == -1) {
      return pixelSnaps.last;
    }
    if (indexOfNextSnap == 0) {
      return pixelSnaps.first;
    }
    final DraggableSnap nextSnap = pixelSnaps[indexOfNextSnap];
    final DraggableSnap previousSnap = pixelSnaps[indexOfNextSnap - 1];

    if (initialVelocity.abs() <= tolerance.velocity) {
      if (position - previousSnap.pixelPosition! <
          nextSnap.pixelPosition! - position) {
        return previousSnap;
      } else {
        return nextSnap;
      }
    }

    if (initialVelocity < 0.0) return pixelSnaps[indexOfNextSnap - 1];
    return pixelSnaps[indexOfNextSnap];
  }
}
