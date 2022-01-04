part of '../draggable_scrollable_panel.dart';

class DraggableScrollablePanelController {
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.ease;
  static const Curve animationScrollCurve = Curves.easeInOutCubic;

  DraggableScrollablePanelController({
    AnimationController? animationController,
  })  : _animationController = animationController ??
            AnimationController(vsync: NoopTickerProvider()),
        _scrollController = _DraggableScrollableSheetScrollController(),
        _isNoop = animationController == null;

  final AnimationController _animationController;
  final _DraggableScrollableSheetScrollController _scrollController;
  final bool _isNoop;

  BuildContext? _context;
  _ExtentResolverCallback? _getExtent;

  AnimationController get animationController => _animationController;

  ScrollController get scrollController => _scrollController;

  Animation get animation => _animationController;

  Listenable get scroll => _scrollController;

  _DraggableSheetExtent? get _extent =>
      _getExtent != null ? _getExtent!() : null;

  bool canSnapTo(int index) => _extent != null && _context != null
      ? _extent!.snaps.length - 1 > index
      : false;

  bool isAtSnapOf(int index) => _extent != null
      ? _extent!.snaps[index].position == animation.value
      : false;

  Future<bool> resetScroll({
    Duration? duration,
    Curve? curve,
    bool force = false,
  }) async {
    if (force || _scrollController.offset != 0.0) {
      await _scrollController.animateTo(
        0.0,
        duration: duration ?? animationDuration,
        curve: curve ?? animationScrollCurve,
      );
      return true;
    }
    return false;
  }

  FutureOr<bool> snapTo(
    int index, {
    Duration? duration,
    Curve? curve,
  }) async {
    if (_extent == null || !canSnapTo(index) || isAtSnapOf(index)) {
      return false;
    }

    return animateTo(
      _extent!.snaps[index].position,
      duration: duration,
      curve: curve,
      autoSnap: true,
    );
  }

  FutureOr<bool> animateTo(
    double point, {
    Duration? duration,
    Curve? curve,
    Curve? scrollCurve,
    bool cancelDrag = true,
    bool autoSnap = false,
  }) async {
    if (_extent!.animating || _animationController.isAnimating) {
      return false;
    }

    if (!_processDrag(cancelDrag)) {
      return false;
    }

    _extent!.animating = true;
    _scrollController.position._ballisticCancelCallback?.call();
    void animationListener() => _extent!.notifyChangedSize(_context!);
    _animationController.addListener(animationListener);

    final List<Future> waitList = [];
    final TickerFuture Function(double, {Curve curve, Duration? duration})
        animate = _animationController.value > point
            ? _animationController.animateBack
            : _animationController.animateTo;

    try {
      await Future.wait([
        resetScroll(duration: duration, curve: scrollCurve),
        (animate(
          point,
          duration: duration ?? animationDuration,
          curve: curve ?? animationCurve,
        )..whenCompleteOrCancel(() {
                waitList.add(Future.delayed(
                    Duration.zero, () => _extent!.animating = false));
                _animationController.removeListener(animationListener);
              }))
            .orCancel,
      ]);
    } catch (e) {
      return false;
    }

    if (autoSnap && _extent!.draggable && _extent!.snap) {
      final Completer postFrameCompleter = Completer();
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _scrollController.position.goBallistic(0);
        postFrameCompleter.complete();
      });
      waitList.add(postFrameCompleter.future);
    }

    if (waitList.isNotEmpty) {
      await Future.wait(waitList);
    }
    return true;
  }

  FutureOr<bool> reset({
    Duration? duration,
    Curve? curve,
    Curve? scrollCurve,
    bool cancelDrag = true,
  }) =>
      _extent != null
          ? animateTo(
              _extent!.initialSize,
              duration: duration,
              curve: curve,
              scrollCurve: scrollCurve,
              autoSnap: false,
              cancelDrag: cancelDrag,
            )
          : false;

  FutureOr<bool> dismiss({
    Duration? duration,
    Curve? curve,
    Curve? scrollCurve,
    bool cancelDrag = true,
  }) =>
      _extent != null
          ? animateTo(
              _extent!.minSize,
              duration: duration,
              curve: curve,
              scrollCurve: scrollCurve,
              autoSnap: false,
              cancelDrag: cancelDrag,
            )
          : false;

  FutureOr<bool> goToMin({
    Duration? duration,
    Curve? curve,
    Curve? scrollCurve,
    bool cancelDrag = true,
  }) =>
      _extent != null
          ? animateTo(
              _extent!.minSize,
              duration: duration,
              curve: curve,
              scrollCurve: scrollCurve,
              autoSnap: false,
              cancelDrag: cancelDrag,
            )
          : false;

  FutureOr<bool> goToMax({
    Duration? duration,
    Curve? curve,
    Curve? scrollCurve,
    bool cancelDrag = true,
  }) =>
      _extent != null
          ? animateTo(
              _extent!.maxSize,
              duration: duration,
              curve: curve,
              scrollCurve: scrollCurve,
              autoSnap: false,
              cancelDrag: cancelDrag,
            )
          : false;

  bool _processDrag([bool cancel = false]) {
    if (_scrollController.position._dragCancelCallback != null) {
      if (cancel) {
        _scrollController.position._cancelDrag();
      } else {
        return false;
      }
    }
    return true;
  }

  dispose() {
    _context = null;
    if (_isNoop) {
      _animationController.dispose();
    }
  }
}
