part of 'sliding_scroll_panel.dart';

class _PanelBackdrop extends StatefulWidget {
  static const double _opacity = 0.2;
  static const Interval _interval = Interval(0.4, 1.0);

  const _PanelBackdrop({
    required this.animationController,
    required this.action,
    required this.ignorePointer,
    this.backgroundColor,
    double? opacity,
    Interval? interval,
    Key? key,
  })  : opacity = opacity ?? _opacity,
        interval = interval ?? _interval,
        super(key: key);

  final AnimationController animationController;
  final VoidCallback action;
  final bool ignorePointer;
  final Color? backgroundColor;

  final double opacity;
  final Interval interval;

  @override
  _PanelBackdropState createState() => _PanelBackdropState();
}

class _PanelBackdropState extends State<_PanelBackdrop> {
  late Animation<double> _opacityBackdropAnimation;

  bool _isSetAnimations = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isSetAnimations) {
      return;
    }

    _opacityBackdropAnimation = Tween<double>(
      begin: 0,
      end: widget.opacity,
    ).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: widget.interval,
      ),
    );

    _isSetAnimations = true;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.ignorePointer,
      child: FadeTransition(
        opacity: _opacityBackdropAnimation,
        child: GestureDetector(
          onTap: widget.action,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: widget.backgroundColor!,
          ),
        ),
      ),
    );
  }
}
