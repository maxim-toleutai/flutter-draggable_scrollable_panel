library draggable_scrollable_panel;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

part 'types.dart';
part 'noop.dart';
part 'extent.dart';
part 'notification.dart';
part 'simulations/snapping.dart';
part 'controllers/scroll.dart';
part 'controllers/pane.dart';
part 'snap.dart';

class DraggableScrollablePanel extends StatefulWidget {
  const DraggableScrollablePanel({
    Key? key,
    this.initialExtent = 0.5,
    this.minExtent = 0.25,
    this.maxExtent = 1.0,
    this.expand = true,
    this.snap = false,
    this.snapToMax = true,
    this.snapToMin = true,
    this.drag = true,
    this.rebuild = false,
    this.snaps,
    this.controller,
    this.animationController,
    this.onInit,
    required this.builder,
  })  : assert(minExtent >= 0.0),
        assert(maxExtent <= 1.0),
        assert(minExtent <= initialExtent),
        assert(initialExtent <= maxExtent),
        assert(controller != null ? animationController == null : true,
            'Either controller or animationController should persist the same time'),
        super(key: key);

  final double initialExtent;

  final double minExtent;

  final double maxExtent;

  final bool expand;

  final bool snap;

  final bool snapToMax;

  final bool snapToMin;

  final bool drag;

  final bool rebuild;

  final List<DraggableSnap>? snaps;

  final DraggableScrollablePanelController? controller;

  final AnimationController? animationController;

  final ScrollableDraggableOnInitCallback? onInit;

  final ScrollableDraggableWidgetBuilder builder;

  @override
  State<DraggableScrollablePanel> createState() =>
      _DraggableScrollablePanelState();
}

class _DraggableScrollablePanelState extends State<DraggableScrollablePanel>
    with SingleTickerProviderStateMixin {
  late _DraggableScrollableSheetScrollController _scrollController;
  late AnimationController _animationController;
  late _DraggableSheetExtent _extent;

  @override
  void initState() {
    super.initState();
    _animationController = widget.controller?._animationController ??
        widget.animationController ??
        AnimationController(vsync: this);
    _animationController.value = widget.initialExtent;
    _extent = _DraggableSheetExtent(
      minSize: widget.minExtent,
      maxSize: widget.maxExtent,
      snap: widget.snap,
      snaps: _impliedSnaps(),
      initialSize: widget.initialExtent,
      animationController: _animationController,
      draggable: widget.drag,
    );
    _scrollController = (widget.controller?._scrollController ??
        _DraggableScrollableSheetScrollController())
      .._getExtent = _getExtent;
    if (widget.controller != null) {
      widget.controller!._context = context;
      widget.controller!._getExtent = _getExtent;
      if (widget.controller!._isNoop) {
        widget.controller!._animationController.resync(this);
      }
    }
    if (widget.onInit != null) {
      widget.onInit!(_scrollController, _animationController);
    }
  }

  @override
  void didUpdateWidget(covariant DraggableScrollablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onInit == null && widget.onInit != null) {
      widget.onInit!(_scrollController, _animationController);
    }
    widget.controller!._context = context;
    _scrollController._getExtent ??= _getExtent;
    _replaceExtent();
  }

  @override
  void didChangeDependencies() => super.didChangeDependencies();

  @override
  void dispose() {
    if (widget.controller == null) {
      widget.controller!._context = null;
      _scrollController.dispose();
      if (widget.animationController == null) {
        _animationController.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _extent.availablePixels = widget.maxExtent * constraints.biggest.height;

        final Widget sheet = AnimatedBuilder(
          animation: _animationController,
          child: !widget.rebuild ? _buildContent(context) : null,
          builder: (context, child) => FractionallySizedBox(
            heightFactor: _extent.currentSize,
            alignment: Alignment.bottomCenter,
            child: child ?? _buildContent(context),
          ),
        );
        return widget.expand ? SizedBox.expand(child: sheet) : sheet;
      },
    );
  }

  Widget _buildContent(BuildContext context) =>
      widget.builder(context, _scrollController, _animationController);

  _DraggableSheetExtent _getExtent() => _extent;

  List<DraggableSnap> _impliedSnaps() {
    if (!widget.drag || !widget.snap) {
      return [];
    }
    for (int index = 0; index < (widget.snaps?.length ?? 0); index += 1) {
      final DraggableSnap snap = widget.snaps![index];

      assert(
          snap.position >= widget.minExtent &&
              snap.position <= widget.maxExtent,
          '${_snapSizeErrorMessage(index)}\nSnap sizes must be between `minChildSize` and `maxChildSize`. ');
      assert(index == 0 || snap.position > widget.snaps![index - 1].position,
          '${_snapSizeErrorMessage(index)}\nSnap sizes must be in ascending order. ');
    }

    if (widget.snaps == null || widget.snaps!.isEmpty) {
      return <DraggableSnap>[
        if (widget.snapToMin)
          DraggableSnap.defaultSpeed(position: widget.minExtent),
        if (widget.snapToMax)
          DraggableSnap.defaultSpeed(position: widget.maxExtent),
      ];
    }
    return <DraggableSnap>[
      if (widget.snaps!.first.position != widget.minExtent && widget.snapToMin)
        DraggableSnap.defaultSpeed(position: widget.minExtent),
      ...widget.snaps!,
      if (widget.snaps!.last.position != widget.maxExtent && widget.snapToMax)
        DraggableSnap.defaultSpeed(position: widget.maxExtent),
    ];
  }

  void _replaceExtent() {
    _extent = _extent.copyWith(
      minSize: widget.minExtent,
      maxSize: widget.maxExtent,
      snap: widget.snap,
      snaps: _impliedSnaps(),
      initialSize: widget.initialExtent,
      animationController: _animationController,
      draggable: widget.drag,
    );
    if (widget.drag && widget.snap) {
      void resetScroll() {
        WidgetsBinding.instance!.addPostFrameCallback((Duration timeStamp) {
          _scrollController.position.goBallistic(0);
        });
      }

      if (_scrollController.position._dragCancelCallback == null) {
        resetScroll();
      }
    }
  }

  String _snapSizeErrorMessage(int invalidIndex) {
    final List<String> snapSizesWithIndicator = widget.snaps!.asMap().keys.map(
      (int index) {
        final String snapSizeString = widget.snaps![index].toString();
        if (index == invalidIndex) {
          return '>>> $snapSizeString <<<';
        }
        return snapSizeString;
      },
    ).toList();
    return "Invalid snapSize '${widget.snaps![invalidIndex]}' at index $invalidIndex of:\n"
        '  $snapSizesWithIndicator';
  }
}
