import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:showcaseview/custom_paint.dart';
import 'get_position.dart';
import 'layout_overlays.dart';
import 'tooltip_widget.dart';
import 'dart:ui'as ui;

typedef OverlayCallback = Future<bool> Function();

class Showcase extends StatefulWidget {
  final Widget child;
  final String title;
  final String widgetPosition;
  final String description;
  final ShapeBorder shapeBorder;
  final TextStyle titleTextStyle;
  final TextStyle descTextStyle;
  final GlobalKey key;
  final Color overlayColor;
  final double overlayOpacity;
  final Widget container;
  final Color showcaseBackgroundColor;
  final Color textColor;
  final bool showArrow;
  final double height;
  final double width;
  final Duration animationDuration;
  final VoidCallback onToolTipClick;
  final VoidCallback onTargetClick;
  final OverlayCallback overlayCallback;
  final bool overLayCallbackBool;
  final bool disposeOnTap;

  const Showcase({@required this.key,
    @required this.child,
    this.title,
    this.widgetPosition,
    @required this.description,
    this.shapeBorder,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.75,
    this.titleTextStyle,
    this.descTextStyle,
    this.showcaseBackgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.showArrow = true,
    this.onTargetClick,
    this.disposeOnTap,
    this.overlayCallback,
    this.overLayCallbackBool = false,
    this.animationDuration = const Duration(milliseconds: 2000)})
      : height = null,
        width = null,
        container = null,
        this.onToolTipClick = null,
        assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0,
        "overlay opacity should be >= 0.0 and <= 1.0."),
        assert(
        onTargetClick == null
            ? true
            : (disposeOnTap == null ? false : true),
        "disposeOnTap is required if you're using onTargetClick"),
        assert(
        disposeOnTap == null
            ? true
            : (onTargetClick == null ? false : true),
        "onTargetClick is required if you're using disposeOnTap"),
        assert(key != null ||
            child != null ||
            title != null ||
            showArrow != null ||
            description != null ||
            shapeBorder != null ||
            overlayColor != null ||
            titleTextStyle != null ||
            descTextStyle != null ||
            showcaseBackgroundColor != null ||
            textColor != null ||
            shapeBorder != null ||
            animationDuration != null);

  const Showcase.withWidget({this.key,
    @required this.child,
    @required this.container,
    @required this.height,
    @required this.width,
    this.title,
    this.description,
    this.widgetPosition,
    this.shapeBorder,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.75,
    this.titleTextStyle,
    this.descTextStyle,
    this.showcaseBackgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.onTargetClick,
    this.disposeOnTap,
    this.overlayCallback,
    this.overLayCallbackBool = false,
    this.animationDuration = const Duration(milliseconds: 2000)})
      : this.showArrow = false,
        this.onToolTipClick = null,
        assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0,
        "overlay opacity should be >= 0.0 and <= 1.0."),
        assert(key != null ||
            child != null ||
            title != null ||
            description != null ||
            shapeBorder != null ||
            overlayColor != null ||
            titleTextStyle != null ||
            descTextStyle != null ||
            showcaseBackgroundColor != null ||
            textColor != null ||
            shapeBorder != null ||
            animationDuration != null);

  @override
  _ShowcaseState createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> with TickerProviderStateMixin {
  bool _showShowCase = false;
  Animation<double> _slideAnimation;
  AnimationController _slideAnimationController;

  GetPosition position;


  @override
  void initState() {
    super.initState();

    _slideAnimationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _slideAnimationController.reverse();
        }
        if (_slideAnimationController.isDismissed) {
          _slideAnimationController.forward();
        }
      });

    _slideAnimation = CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    );

    position = GetPosition(key: widget.key);
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showOverlay();
  }

  ///
  /// show overlay if there is any target widget
  ///
  void showOverlay() {
    GlobalKey activeStep = ShowCaseWidget.activeTargetWidget(context);
    setState(() {
      _showShowCase = activeStep == widget.key;
    });

    if (activeStep == widget.key) {
      _slideAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery
        .of(context)
        .size;
    return AnchoredOverlay(
      overlayBuilder: (BuildContext context, Rect rectBound, Offset offset) =>
          buildOverlayOnTarget(offset, rectBound.size, rectBound, size),
      showOverlay: true,
      child: widget.child,
    );
  }

  _nextIfAny() async {
    if (widget.overLayCallbackBool) {
      await widget.overlayCallback();
    }
    ShowCaseWidget.of(context).completed(widget.key);
    _slideAnimationController.forward();
  }

  _getOnTargetTap() {
    if (widget.disposeOnTap == true) {
      return widget.onTargetClick == null
          ? () {
        ShowCaseWidget.of(context).dismiss();
      }
          : () {
        ShowCaseWidget.of(context).dismiss();
        widget.onTargetClick();
      };
    } else {
      return widget.onTargetClick ?? _nextIfAny;
    }
  }

  _getOnTooltipTap() {
    if (widget.disposeOnTap == true) {
      return widget.onToolTipClick == null
          ? () {
        ShowCaseWidget.of(context).dismiss();
      }
          : () {
        ShowCaseWidget.of(context).dismiss();
        widget.onToolTipClick();
      };
    } else {
      return widget.onToolTipClick ?? () {};
    }
  }

  buildOverlayOnTarget(Offset offset,
      Size size,
      Rect rectBound,
      Size screenSize,) =>
      Visibility(
        visible: _showShowCase,
        maintainAnimation: true,
        maintainState: true,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _nextIfAny,
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                height: MediaQuery
                    .of(context)
                    .size
                    .height,
                child:Stack(
                  children: <Widget>[
                    ClipPath(
                      clipper: _CoachMarkClipper(position.getRect()),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                        child: Container(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: ShapePainter(
                          opacity: widget.overlayOpacity,
                          rect: position.getRect(),
                          shapeBorder: widget.shapeBorder,
                          color: widget.overlayColor),
                    ),
                  ],
                ),
              ),
            ),
            _TargetWidget(
              offset: offset,
              size: size,
              onTap: _getOnTargetTap(),
              shapeBorder: widget.shapeBorder,
            ),
            ToolTipWidget(
              widgetPosition: widget.widgetPosition,
              position: position,
              offset: offset,
              screenSize: screenSize,
              title: widget.title,
              description: widget.description,
              animationOffset: _slideAnimation,
              titleTextStyle: widget.titleTextStyle,
              descTextStyle: widget.descTextStyle,
              container: widget.container,
              tooltipColor: widget.showcaseBackgroundColor,
              textColor: widget.textColor,
              showArrow: widget.showArrow,
              contentHeight: widget.height,
              contentWidth: widget.width,
              onTooltipTap: _getOnTooltipTap(),
            ),
            new SkipButtonClass(_showShowCase, context)
          ],
        ),
      );
}

class _TargetWidget extends StatelessWidget {
  final Offset offset;
  final Size size;
  final Animation<double> widthAnimation;
  final VoidCallback onTap;
  final ShapeBorder shapeBorder;

  _TargetWidget({
    Key key,
    @required this.offset,
    this.size,
    this.widthAnimation,
    this.onTap,
    this.shapeBorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: size.height + 16,
            width: size.width + 16,
            decoration: ShapeDecoration(
              shape: shapeBorder ??
                  RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class SkipButtonClass extends StatelessWidget {
  bool _showShowCase;
  BuildContext contextForDismiss;

  SkipButtonClass(this._showShowCase, this.contextForDismiss);

  @override
  Widget build(BuildContext context) {
    return _showShowCase ? Positioned(
      top: (MediaQuery
          .of(context)
          .size
          .height - 70),
      left: 100.0,
      right: 100.0,
      child: new Material(
          color: Colors.transparent,
          child: new GestureDetector(onTap: () {
            ShowCaseWidget.of(contextForDismiss).dismiss();
          }, child: new Container(
            height: 50.0,
            color: Colors.transparent,
            alignment: Alignment.center,
            width: MediaQuery
                .of(context)
                .size
                .width,
            child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
            new Text("Skip",
              style: new TextStyle(color: Colors.white, fontSize: 20.0),),
                new SizedBox(width: 5.0,),
                new Icon(Icons.arrow_forward,color: Colors.white,size: 18.0,)
                ]
          ),
            ))

      ),) : new Container();
  }
}

class _CoachMarkClipper extends CustomClipper<Path> {
  final Rect rect;

  _CoachMarkClipper(this.rect);

  @override
  Path getClip(Size size) {
    return Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRect(rect));
  }

  @override
  bool shouldReclip(_CoachMarkClipper old) => rect != old.rect;
}
