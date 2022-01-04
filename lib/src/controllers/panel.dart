part of '../sliding_scroll_panel.dart';

class SlidingScrollPanelController extends DraggableScrollablePanelController {
  SlidingScrollPanelController({
    AnimationController? animationController,
    bool drag = true,
    bool snap = true,
  })  : _isNoop = animationController == null,
        _drag = drag,
        _snap = snap,
        super(animationController: animationController);

  final bool _isNoop;

  bool _drag;
  bool _snap;

  bool get drag => _drag;

  bool get snap => _snap;

  VoidCallback? _updatePanel;

  set drag(bool drag) => setDrag(drag);

  set snap(bool snap) => setSnap(snap);

  void setDrag(bool drag) {
    if (_drag == drag) {
      return;
    }
    _drag = drag;
    _update();
  }

  void setSnap(bool snap) {
    if (_snap == snap) {
      return;
    }
    _snap = snap;
    _update();
  }

  void freeze() {
    if (!_drag && !_snap) {
      return;
    }
    _drag = false;
    _snap = false;
    _update();
  }

  void unfreeze() {
    if (_drag && _snap) {
      return;
    }
    _drag = true;
    _snap = true;
    _update();
  }

  Future<bool> expand({
    Duration? duration,
    Curve? curve,
    Curve? scrollCurve,
    bool freeze = false,
  }) async {
    final bool didGo = await goToMax(
      duration: duration,
      curve: curve,
      scrollCurve: scrollCurve,
    );
    if (!didGo) {
      return false;
    }

    if (freeze) {
      this.freeze();
    }

    return true;
  }

  void _update() {
    if (_updatePanel != null) {
      _updatePanel!();
    }
  }
}
