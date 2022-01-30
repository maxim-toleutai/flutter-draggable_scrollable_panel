library draggable_scrollable_panel;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'draggable_scrollable_panel.dart';

part 'controllers/panel.dart';

part 'panel_pan.dart';

part 'backdrop.dart';

class SlidingScrollPanel extends StatefulWidget {
  static const double panHeight = PanelPan.height;
  static const double borderRadiusValue = 20;

  static const Interval _panInterval = Interval(
    0.85,
    0.95,
  );
  static const Interval _borderRadiusInterval = Interval(
    0.9,
    1.0,
  );

  static const BorderRadius _borderRadius =
      BorderRadius.vertical(top: Radius.circular(borderRadiusValue));

  const SlidingScrollPanel({
    required this.builder,
    this.snaps,
    this.initialExtent = 0.4,
    this.minExtent = 0.0,
    this.maxExtent = 1.0,
    this.topOffset,
    this.controller,
    this.withPan = false,
    this.backdropDismissible = false,
    this.withBackdrop = false,
    this.backdropIgnorePointer = true,
    this.backdropAction,
    this.backdropOpacity,
    this.backdropInterval,
    this.panInterval = _panInterval,
    this.borderRadiusInterval = _borderRadiusInterval,
    this.backgroundColor,
    this.backdropColor,
    this.panColor,
    this.panAlwaysVisible = false,
    this.animateToInitial = false,
    this.boxShadow,
    this.onDismiss,
    this.aboveChildren,
    this.belowChildren,
    Key? key,
  })  : assert(withBackdrop ? backdropColor != null : true),
        assert(withPan ? panColor != null : true),
        super(key: key);

  final ScrollableDraggableWidgetBuilder builder;
  final List<DraggableSnap>? snaps;
  final double initialExtent;
  final double minExtent;
  final double maxExtent;
  final double? topOffset;
  final SlidingScrollPanelController? controller;
  final bool withPan;
  final bool withBackdrop;
  final bool backdropDismissible;
  final bool backdropIgnorePointer;
  final VoidCallback? backdropAction;
  final double? backdropOpacity;
  final Interval? backdropInterval;
  final Interval panInterval;
  final Interval borderRadiusInterval;
  final Color? backgroundColor;
  final Color? backdropColor;
  final Color? panColor;
  final bool panAlwaysVisible;
  final bool animateToInitial;
  final List<BoxShadow>? boxShadow;
  final FutureOr<bool> Function()? onDismiss;
  final List<Widget>? aboveChildren;
  final List<Widget>? belowChildren;

  @override
  _SlidingScrollPanelState createState() => _SlidingScrollPanelState();
}

class _SlidingScrollPanelState extends State<SlidingScrollPanel>
    with SingleTickerProviderStateMixin {
  late SlidingScrollPanelController _panelController;

  late AnimationController _animationController;

  late Animation<double> _panOpacityAnimation;
  late Animation<BorderRadius?> _borderRadiusAnimation;

  bool _initialized = false;
  bool _isSetAnimations = false;
  bool _isHandlingDismiss = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _panelController = widget.controller!;
      _animationController = _panelController.animationController;
      if (_panelController._isNoop) {
        _animationController.resync(this);
      }
    } else {
      _animationController = AnimationController(vsync: this);
      _panelController = SlidingScrollPanelController(
          animationController: _animationController);
    }

    _panelController._updatePanel = _externalUpdate;
    _setupDismissHandler();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      _initialized = true;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant SlidingScrollPanel oldWidget) {
    if (oldWidget.onDismiss != null && widget.onDismiss == null) {
      _disposeDismissHandler(true);
    } else if (oldWidget.onDismiss == null && widget.onDismiss != null) {
      _setupDismissHandler();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _panelController._updatePanel = null;
    _disposeDismissHandler();
    if (widget.controller == null) {
      _panelController.dispose();
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isSetAnimations) {
      return;
    }

    _panOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.panInterval,
      ),
    );

    _borderRadiusAnimation = BorderRadiusTween(
      begin: SlidingScrollPanel._borderRadius,
      end: BorderRadius.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.borderRadiusInterval,
      ),
    );

    _isSetAnimations = true;
  }

  void _externalUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setupDismissHandler([bool force = false]) {
    if (force || widget.onDismiss != null) {
      _animationController.addListener(_handleDismissListener);
    }
  }

  void _disposeDismissHandler([bool force = false]) {
    if (force || widget.onDismiss != null) {
      _animationController.removeListener(_handleDismissListener);
    }
  }

  void _handleDismissListener() {
    if (!_animationController.isAnimating &&
        !_isHandlingDismiss &&
        _animationController.value - 0.000000000002 <= widget.minExtent) {
      _handleDismiss();
    }
  }

  FutureOr<bool> _handleDismiss() async {
    _isHandlingDismiss = true;
    bool handled = false;
    if (!(await widget.onDismiss!())) {
      handled = await _panelController.reset();
    }
    _isHandlingDismiss = false;
    return handled;
  }

  void _handleBackdropAction() {
    if (widget.backdropDismissible) {
      _panelController.dismiss();
    }
    if (widget.backdropAction != null) {
      widget.backdropAction!();
    }
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      child: widget.builder(context, scrollController, _animationController),
      builder: (context, child) => Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: _borderRadiusAnimation.value,
          boxShadow: widget.boxShadow,
        ),
        child: child,
      ),
    );
  }

  Widget _buildSheet(BuildContext context) => DraggableScrollablePanel(
        snaps: widget.snaps,
        initialExtent: widget.animateToInitial && !_initialized
            ? widget.minExtent
            : widget.initialExtent,
        maxExtent: widget.maxExtent,
        minExtent: widget.minExtent,
        controller: _panelController,
        snap: _panelController.snap,
        drag: _panelController.drag,
        builder: (context, scrollController, animationController) =>
            widget.withPan
                ? Stack(
                    children: [
                      _buildContent(context, scrollController),
                      Align(
                        alignment: Alignment.topCenter,
                        child: widget.panAlwaysVisible
                            ? PanelPan(
                                color: widget.panColor!,
                                onTap: _panelController.goToMax,
                              )
                            : FadeTransition(
                                opacity: _panOpacityAnimation,
                                child: PanelPan(
                                  color: widget.panColor!,
                                  onTap: _animationController.value >
                                          (widget.maxExtent * 0.9)
                                      ? null
                                      : _panelController.goToMax,
                                ),
                              ),
                      ),
                    ],
                  )
                : _buildContent(context, scrollController),
      );

  Widget _buildBody(BuildContext context) => widget.topOffset != null
      ? Padding(
          padding: EdgeInsets.only(top: widget.topOffset!),
          child: _buildSheet(context),
        )
      : _buildSheet(context);

  Widget _buildBackdrop(BuildContext context) => _PanelBackdrop(
        animationController: _animationController,
        action: _handleBackdropAction,
        ignorePointer: widget.backdropIgnorePointer,
        backgroundColor: widget.backdropColor,
        opacity: widget.backdropOpacity,
        interval: widget.backdropInterval,
      );

  @override
  Widget build(BuildContext context) => widget.withBackdrop ||
          widget.aboveChildren != null ||
          widget.belowChildren != null
      ? Stack(
          children: [
            if (widget.belowChildren != null) ...widget.belowChildren!,
            if (widget.withBackdrop) _buildBackdrop(context),
            _buildBody(context),
            if (widget.aboveChildren != null) ...widget.aboveChildren!,
          ],
        )
      : _buildBody(context);
}
