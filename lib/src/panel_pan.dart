part of 'sliding_scroll_panel.dart';

class PanelPan extends StatelessWidget {
  static const double height = 20;
  static const double panHeight = 4;

  const PanelPan({
    this.onTap,
    required this.color,
    Key? key,
  }) : super(key: key);

  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: SizedBox(
            height: height,
            width: 60,
            child: Center(
              child: Container(
                height: 4,
                width: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(height / 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
