import 'package:draggable_scrollable_panel/index.dart';
import 'package:flutter/material.dart';

void main() => runApp(const Example());

class AppScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
    BuildContext context,
    Widget child,
    AxisDirection axisDirection,
  ) {
    return child;
  }
}

class Example extends StatelessWidget {
  const Example({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: "Draggable Scrollable Panel Example",
        color: Colors.blueAccent,
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: AppScrollBehavior(),
            child: Container(
              color: Colors.grey,
              child: child,
            ),
          );
        },
        navigatorObservers: [
          HeroController(),
        ],
        home: const ExampleScreen(),
      );
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({Key? key}) : super(key: key);

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen>
    with SingleTickerProviderStateMixin {
  final SlidingScrollPanelController _controller =
      SlidingScrollPanelController();

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () async {
      // await _controller.snapTo(0, duration: const Duration(seconds: 1));
      // await Future.delayed(const Duration(seconds: 2));
      // await _controller.reset();
      // await Future.delayed(const Duration(seconds: 2));
      // await _controller.dismiss();
      // await Future.delayed(const Duration(seconds: 2));
      // await _controller.expand(freeze: true);
      // await Future.delayed(const Duration(seconds: 3));
      // _controller.unfreeze();
    });
    super.initState();
  }

  int i = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlidingScrollPanel(
        snaps: [
          DraggableSnap.defaultSpeed(position: 0.2),
          DraggableSnap.defaultSpeed(position: 0.5),
          // DraggableSnap.defaultSpeed(position: 0.9),
        ],
        controller: _controller,
        minExtent: 0.2,
        backgroundColor: Colors.blueGrey,
        // snapToMax: false,
        backdropColor: Colors.black,
        backdropInterval: const Interval(
          0.5,
          1.0,
        ),
        backdropOpacity: 0.7,
        backdropDismissible: true,
        backdropIgnorePointer: true,
        withBackdrop: true,
        withPan: true,
        panColor: Colors.white,
        onDismiss: () => false,
        builder: (context, scrollController, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Builder(
                  builder: (_) {
                    print('build ${i++}');
                    return SizedBox(height: 20);
                  },
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  childCount: 50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
