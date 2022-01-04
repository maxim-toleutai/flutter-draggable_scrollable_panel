part of 'draggable_scrollable_panel.dart';

typedef ScrollableDraggableWidgetBuilder = Widget Function(
  BuildContext,
  ScrollController,
  AnimationController,
);

typedef ScrollableDraggableOnInitCallback = Function(
  ScrollController,
  AnimationController,
);

typedef _ExtentResolverCallback = _DraggableSheetExtent Function();
