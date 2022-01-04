part of 'draggable_scrollable_panel.dart';

class _DraggableSheetExtent {
  _DraggableSheetExtent({
    required this.minSize,
    required this.maxSize,
    required this.snap,
    required this.snaps,
    required this.initialSize,
    required this.animationController,
    required this.draggable,
    this.animating = false,
    bool? hasChanged,
  })  : assert(minSize >= 0),
        assert(maxSize <= 1),
        assert(minSize <= initialSize),
        assert(initialSize <= maxSize),
        _currentSize = ValueNotifier<double>(animationController.value),
        availablePixels = double.infinity,
        hasChanged = hasChanged ?? false;

  final double minSize;
  final double maxSize;
  final bool snap;
  final List<DraggableSnap> snaps;
  final double initialSize;
  final ValueNotifier<double> _currentSize;
  final AnimationController animationController;
  final bool draggable;
  double availablePixels;

  bool hasChanged;
  bool animating;

  bool get isAtMin => minSize >= animationController.value;

  bool get isAtMax => maxSize <= animationController.value;

  double get currentSize => animationController.value;

  double get currentPixels => sizeToPixels(animationController.value);

  double get additionalMinSize => isAtMin ? 0.0 : 1.0;

  double get additionalMaxSize => isAtMax ? 0.0 : 1.0;

  set currentSize(double value) {
    hasChanged = true;
    animationController.value = value.clamp(minSize, maxSize);
  }

  List<DraggableSnap> get pixelSnaps => snaps
      .map((snap) => snap._copyWithPixels(sizeToPixels(snap.position)))
      .toList();

  void addPixelDelta(double delta, BuildContext context) {
    if (availablePixels == 0) return;
    updateSize(currentSize + pixelsToSize(delta), context);
  }

  void updateSize(double newSize, BuildContext context) {
    currentSize = newSize;
    notifyChangedSize(context);
  }

  notifyChangedSize(BuildContext context) {
    _currentSize.value = animationController.value;
    DraggableScrollableNotification(
      minExtent: minSize,
      maxExtent: maxSize,
      extent: currentSize,
      initialExtent: initialSize,
      context: context,
    ).dispatch(context);
  }

  double pixelsToSize(double pixels) {
    return pixels / availablePixels * maxSize;
  }

  double sizeToPixels(double extent) {
    return extent / maxSize * availablePixels;
  }

  _DraggableSheetExtent copyWith({
    required double minSize,
    required double maxSize,
    required bool snap,
    required List<DraggableSnap> snaps,
    required double initialSize,
    required AnimationController animationController,
    required bool draggable,
  }) {
    return _DraggableSheetExtent(
      minSize: minSize,
      maxSize: maxSize,
      snap: snap,
      snaps: snaps,
      initialSize: initialSize,
      hasChanged: hasChanged,
      animating: animating,
      animationController: animationController,
      draggable: draggable,
    );
  }
}
