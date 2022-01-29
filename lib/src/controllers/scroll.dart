part of '../draggable_scrollable_panel.dart';

class _DraggableScrollableSheetScrollController extends ScrollController {
  _DraggableScrollableSheetScrollController({
    double initialScrollOffset = 0.0,
    String? debugLabel,
  }) : super(
          debugLabel: debugLabel,
          initialScrollOffset: initialScrollOffset,
        );

  late _DraggableSheetExtent Function()? _getExtent;

  @override
  _DraggableScrollableSheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _DraggableScrollableSheetScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      getExtent: _getExtent!,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('extent: ${_getExtent!()}');
  }

  @override
  _DraggableScrollableSheetScrollPosition get position =>
      super.position as _DraggableScrollableSheetScrollPosition;
}

class _DraggableScrollableSheetScrollPosition
    extends ScrollPositionWithSingleContext {
  _DraggableScrollableSheetScrollPosition({
    required ScrollPhysics physics,
    required ScrollContext context,
    double initialPixels = 0.0,
    bool keepScrollOffset = true,
    ScrollPosition? oldPosition,
    String? debugLabel,
    required this.getExtent,
  }) : super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  final _DraggableSheetExtent Function() getExtent;
  VoidCallback? _dragCancelCallback;
  VoidCallback? _ballisticCancelCallback;

  bool get listShouldScroll => pixels > 0.0;

  _DraggableSheetExtent get extent => getExtent();

  void _cancelDrag() {
    _dragCancelCallback?.call();
    _dragCancelCallback = null;
  }

  @override
  void beginActivity(ScrollActivity? newActivity) {
    _ballisticCancelCallback?.call();
    super.beginActivity(newActivity);
  }

  @override
  bool applyContentDimensions(double minScrollSize, double maxScrollSize) =>
      super.applyContentDimensions(
        minScrollSize - extent.additionalMinSize,
        maxScrollSize + extent.additionalMaxSize,
      );

  @override
  void applyUserOffset(double delta) {
    if (!extent.animating &&
        extent.draggable &&
        !listShouldScroll &&
        (!(extent.isAtMin || extent.isAtMax) ||
            (extent.isAtMin && delta < 0) ||
            (extent.isAtMax && delta > 0))) {
      extent.addPixelDelta(-delta, context.notificationContext!);
    } else {
      super.applyUserOffset(delta);
    }
  }

  bool get _isAtSnap {
    return extent.snaps.any(
      (DraggableSnap snap) {
        return (extent.currentSize - snap.position).abs() <=
            extent.pixelsToSize(physics.tolerance.distance);
      },
    );
  }

  bool get _shouldSnap =>
      extent.draggable && extent.snap && extent.hasChanged && !_isAtSnap;

  @override
  void dispose() {
    // Stop the animation before dispose.
    _ballisticCancelCallback?.call();
    super.dispose();
  }

  @override
  void goBallistic(double velocity) {
    if (extent.animating || _ballisticCancelCallback != null) {
      return;
    }
    if (!extent.draggable ||
        (velocity == 0.0 && !_shouldSnap) ||
        (velocity < 0.0 && listShouldScroll) ||
        (velocity > 0.0 && extent.isAtMax)) {
      super.goBallistic(velocity);
      return;
    }

    _cancelDrag();

    late final Simulation simulation;
    if (extent.snap) {
      simulation = _SnappingSimulation(
        position: extent.currentPixels,
        initialVelocity: velocity,
        pixelSnaps: extent.pixelSnaps,
        tolerance: physics.tolerance,
        curve: Curves.ease,
      );
    } else {
      simulation = ClampingScrollSimulation(
        position: extent.currentPixels,
        velocity: velocity,
        tolerance: physics.tolerance,
      );
    }

    final AnimationController ballisticController =
        AnimationController.unbounded(
      debugLabel: objectRuntimeType(this, '_DraggableScrollableSheetPosition'),
      vsync: context.vsync,
    );

    _ballisticCancelCallback = ballisticController.stop;
    double lastPosition = extent.currentPixels;
    void _tick() {
      final double delta = ballisticController.value - lastPosition;
      lastPosition = ballisticController.value;
      extent.addPixelDelta(delta, context.notificationContext!);
      if ((velocity > 0 && extent.isAtMax) ||
          (velocity < 0 && extent.isAtMin)) {
        velocity = ballisticController.velocity +
            (physics.tolerance.velocity * ballisticController.velocity.sign);
        super.goBallistic(velocity);
        ballisticController.stop();
      } else if (ballisticController.isCompleted) {
        super.goBallistic(0);
      }
    }

    ballisticController
      ..addListener(_tick)
      ..animateWith(simulation).whenCompleteOrCancel(
        () {
          _ballisticCancelCallback = null;
          ballisticController.dispose();
        },
      );
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _dragCancelCallback = dragCancelCallback;
    if (extent.animating && extent.animationController.isAnimating) {
      extent.animationController.stop(canceled: true);
    }
    return super.drag(details, _cancelDrag) as ScrollDragController;
  }
}
