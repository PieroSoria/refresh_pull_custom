import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:refresh_pull_custom/refresh_custom/circule_progress.dart';

const double _kDragContainerExtentPercentage = 0.25;

const double _kDragSizeFactorLimit = 1.5;

const Duration _kIndicatorScaleDuration = Duration(milliseconds: 200);
typedef RefreshCallback = Future<void> Function();

enum _RefreshMode { drag, armed, snap, refresh, done, canceled }

class RefreshPullCustom extends StatefulWidget {
  const RefreshPullCustom({
    super.key,
    required this.child,
    this.height,
    this.springAnimationDurationInMilliseconds = 500,
    this.animSpeedFactor = 1.0,
    this.borderWidth = 2.0,
    this.showChildOpacityTransition = true,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  final Widget child;
  final double? height;
  final int springAnimationDurationInMilliseconds;
  final double animSpeedFactor;
  final double borderWidth;
  final bool showChildOpacityTransition;
  final RefreshCallback onRefresh;
  final Color? color;
  final Color? backgroundColor;

  @override
  State<RefreshPullCustom> createState() => _RefreshPullCustomState();
}

class _RefreshPullCustomState extends State<RefreshPullCustom>
    with TickerProviderStateMixin {
  late AnimationController _springController;

  late AnimationController _progressingController;
  late Animation<double> _progressingRotateAnimation;
  late Animation<double> _progressingPercentAnimation;
  late Animation<double> _progressingStartAngleAnimation;

  late AnimationController _ringDisappearController;
  late Animation<double> _ringRadiusAnimation;
  late Animation<double> _ringOpacityAnimation;

  late AnimationController _showPeakController;

  late AnimationController _indicatorMoveWithPeakController;
  late Animation<double> _indicatorTranslateWithPeakAnimation;
  late Animation<double> _indicatorRadiusWithPeakAnimation;

  late AnimationController _indicatorTranslateInOutController;
  late Animation<double> _indicatorTranslateAnimation;

  late AnimationController _radiusController;
  late Animation<double> _radiusAnimation;

  late Animation<double> _childOpacityAnimation;

  late AnimationController _positionController;
  late Animation<double> _value;
  late Animation<Color?> _valueColor;
  _RefreshMode? _mode;
  Future<void>? _pendingRefreshFuture;
  bool? _isIndicatorAtTop;
  double? _dragOffset;

  static final Animatable<double> _threeQuarterTween = Tween(
    begin: 0.0,
    end: 0.75,
  );
  static final Animatable<double> _oneToZeroTween = Tween(begin: 1.0, end: 0.0);

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(vsync: this);

    _progressingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressingRotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressingController,
        curve: const Interval(0.0, 1.0),
      ),
    );
    _progressingPercentAnimation = Tween<double>(begin: 0.25, end: 5 / 6)
        .animate(
          CurvedAnimation(
            parent: _progressingController,
            curve: Interval(0.0, 1.0, curve: ProgressRingCurve()),
          ),
        );
    _progressingStartAngleAnimation = Tween<double>(begin: -2 / 3, end: 1 / 2)
        .animate(
          CurvedAnimation(
            parent: _progressingController,
            curve: const Interval(0.5, 1.0),
          ),
        );

    _ringDisappearController = AnimationController(vsync: this);
    _ringRadiusAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _ringDisappearController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );
    _ringOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ringDisappearController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    _showPeakController = AnimationController(vsync: this);

    _indicatorMoveWithPeakController = AnimationController(vsync: this);
    _indicatorTranslateWithPeakAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _indicatorMoveWithPeakController,
            curve: const Interval(0.1, 0.2, curve: Curves.easeOut),
          ),
        );
    _indicatorRadiusWithPeakAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _indicatorMoveWithPeakController,
            curve: const Interval(0.1, 0.2, curve: Curves.easeOut),
          ),
        );

    _indicatorTranslateInOutController = AnimationController(vsync: this);
    _indicatorTranslateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorTranslateInOutController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _radiusController = AnimationController(vsync: this);
    _radiusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _radiusController, curve: Curves.easeIn));

    _positionController = AnimationController(vsync: this);
    _value = _positionController.drive(_threeQuarterTween);

    _childOpacityAnimation = _positionController.drive(_oneToZeroTween);
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _valueColor = _positionController.drive(
      ColorTween(
        begin: (widget.color ?? theme.colorScheme.secondary).withOpacity(0.0),
        end: (widget.color ?? theme.colorScheme.secondary).withOpacity(1.0),
      ).chain(
        CurveTween(curve: const Interval(0.0, 1.0 / _kDragSizeFactorLimit)),
      ),
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _springController.dispose();
    _progressingController.dispose();
    _positionController.dispose();
    _ringDisappearController.dispose();
    _showPeakController.dispose();
    _indicatorMoveWithPeakController.dispose();
    _indicatorTranslateInOutController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.metrics.extentBefore == 0.0 &&
        _mode == null &&
        _start(notification.metrics.axisDirection)) {
      setState(() {
        _mode = _RefreshMode.drag;
      });
      return false;
    }
    bool? indicatorAtTopNow;
    switch (notification.metrics.axisDirection) {
      case AxisDirection.down:
        indicatorAtTopNow = true;
        break;
      case AxisDirection.up:
        indicatorAtTopNow = false;
        break;
      case AxisDirection.left:
      case AxisDirection.right:
        indicatorAtTopNow = null;
        break;
    }
    if (indicatorAtTopNow != _isIndicatorAtTop) {
      if (_mode == _RefreshMode.drag || _mode == _RefreshMode.armed) {
        _dismiss(_RefreshMode.canceled);
      }
    } else if (notification is ScrollUpdateNotification) {
      if (_mode == _RefreshMode.drag || _mode == _RefreshMode.armed) {
        if (notification.metrics.extentBefore > 0.0) {
          _dismiss(_RefreshMode.canceled);
        } else {
          if (_dragOffset != null) {
            _dragOffset = _dragOffset! - notification.scrollDelta!;
          }
          _checkDragOffset(notification.metrics.viewportDimension);
        }
      }
      if (_mode == _RefreshMode.armed && notification.dragDetails == null) {
        _show();
      }
    } else if (notification is OverscrollNotification) {
      if (_mode == _RefreshMode.drag || _mode == _RefreshMode.armed) {
        if (_dragOffset != null) {
          _dragOffset = _dragOffset! - notification.overscroll / 2.0;
        }
        _checkDragOffset(notification.metrics.viewportDimension);
      }
    } else if (notification is ScrollEndNotification) {
      switch (_mode) {
        case _RefreshMode.armed:
          _show();
          break;
        case _RefreshMode.drag:
          _dismiss(_RefreshMode.canceled);
          break;
        default:
          break;
      }
    }
    return false;
  }

  bool _handleGlowNotification(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading) return false;
    if (_mode == _RefreshMode.drag) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  Future<void> _dismiss(_RefreshMode newMode) async {
    await Future<void>.value();
    assert(newMode == _RefreshMode.canceled || newMode == _RefreshMode.done);
    setState(() {
      _mode = newMode;
    });
    switch (_mode) {
      case _RefreshMode.done:
        _progressingController.stop();
        _ringDisappearController.animateTo(
          1.0,
          duration: Duration(
            milliseconds:
                (widget.springAnimationDurationInMilliseconds /
                        widget.animSpeedFactor)
                    .round(),
          ),
          curve: Curves.linear,
        );

        _indicatorMoveWithPeakController.animateTo(
          0.0,
          duration: Duration(
            milliseconds:
                (widget.springAnimationDurationInMilliseconds /
                        widget.animSpeedFactor)
                    .round(),
          ),
          curve: Curves.linear,
        );
        _indicatorTranslateInOutController.animateTo(
          0.0,
          duration: Duration(
            milliseconds:
                (widget.springAnimationDurationInMilliseconds /
                        widget.animSpeedFactor)
                    .round(),
          ),
          curve: Curves.linear,
        );

        await _showPeakController.animateTo(
          0.3,
          duration: Duration(
            milliseconds:
                (widget.springAnimationDurationInMilliseconds /
                        widget.animSpeedFactor)
                    .round(),
          ),
          curve: Curves.linear,
        );

        _radiusController.animateTo(
          0.0,
          duration: Duration(
            milliseconds:
                (widget.springAnimationDurationInMilliseconds /
                        (widget.animSpeedFactor * 5))
                    .round(),
          ),
          curve: Curves.linear,
        );

        _showPeakController.value = 0.175;
        await _showPeakController.animateTo(
          0.1,
          duration: Duration(
            milliseconds:
                (widget.springAnimationDurationInMilliseconds /
                        (widget.animSpeedFactor * 5))
                    .round(),
          ),
          curve: Curves.easeOut,
        );
        _showPeakController.value = 0.0;

        await _positionController.animateTo(
          0.0,
          duration: Duration(
            milliseconds:
                (widget.springAnimationDurationInMilliseconds /
                        widget.animSpeedFactor)
                    .round(),
          ),
        );
        break;

      case _RefreshMode.canceled:
        await _positionController.animateTo(
          0.0,
          duration: _kIndicatorScaleDuration,
        );
        break;
      default:
        assert(false);
    }
    if (mounted && _mode == newMode) {
      _dragOffset = null;
      _isIndicatorAtTop = null;
      setState(() {
        _mode = null;
      });
    }
  }

  bool _start(AxisDirection direction) {
    assert(_mode == null);
    assert(_isIndicatorAtTop == null);
    assert(_dragOffset == null);
    switch (direction) {
      case AxisDirection.down:
        _isIndicatorAtTop = true;
        break;
      case AxisDirection.up:
        _isIndicatorAtTop = false;
        break;
      case AxisDirection.left:
      case AxisDirection.right:
        _isIndicatorAtTop = null;
        return false;
    }
    _dragOffset = 0.0;
    _positionController.value = 0.0;
    _springController.value = 0.0;
    _progressingController.value = 0.0;
    _ringDisappearController.value = 1.0;
    _showPeakController.value = 0.0;
    _indicatorMoveWithPeakController.value = 0.0;
    _indicatorTranslateInOutController.value = 0.0;
    _radiusController.value = 1.0;
    return true;
  }

  void _checkDragOffset(double containerExtent) {
    assert(_mode == _RefreshMode.drag || _mode == _RefreshMode.armed);
    double newValue =
        _dragOffset! / (containerExtent * _kDragContainerExtentPercentage);
    if (_mode == _RefreshMode.armed) {
      newValue = math.max(newValue, 1.0 / _kDragSizeFactorLimit);
    }
    _positionController.value = newValue.clamp(0.0, 1.0);
    if (_mode == _RefreshMode.drag && _valueColor.value!.alpha == 0xFF) {
      _mode = _RefreshMode.armed;
    }
  }

  void _show() {
    assert(_mode != _RefreshMode.refresh);
    assert(_mode != _RefreshMode.snap);
    final Completer<void> completer = Completer<void>();
    _pendingRefreshFuture = completer.future;
    _mode = _RefreshMode.snap;

    _positionController.animateTo(
      1.0 / _kDragSizeFactorLimit,
      duration: Duration(
        milliseconds: widget.springAnimationDurationInMilliseconds,
      ),
      curve: Curves.linear,
    );

    _showPeakController.animateTo(
      1.0,
      duration: Duration(
        milliseconds: widget.springAnimationDurationInMilliseconds,
      ),
      curve: Curves.linear,
    );

    _indicatorMoveWithPeakController.animateTo(
      1.0,
      duration: Duration(
        milliseconds: widget.springAnimationDurationInMilliseconds,
      ),
      curve: Curves.linear,
    );

    _indicatorTranslateInOutController.animateTo(
      1.0,
      duration: Duration(
        milliseconds: widget.springAnimationDurationInMilliseconds,
      ),
      curve: Curves.linear,
    );

    _ringDisappearController.animateTo(
      0.0,
      duration: Duration(
        milliseconds: widget.springAnimationDurationInMilliseconds,
      ),
    );

    _springController
        .animateTo(
          0.5,
          duration: Duration(
            milliseconds: widget.springAnimationDurationInMilliseconds,
          ),
          curve: Curves.elasticOut,
        )
        .then<void>((void value) {
          if (mounted && _mode == _RefreshMode.snap) {
            setState(() {
              _mode = _RefreshMode.refresh;
            });

            _progressingController.repeat();

            final Future<void> refreshResult = widget.onRefresh();

            refreshResult.whenComplete(() {
              if (mounted && _mode == _RefreshMode.refresh) {
                completer.complete();

                _dismiss(_RefreshMode.done);
              }
            });
          }
        });
  }

  Future<void>? show({bool atTop = true}) {
    if (_mode != _RefreshMode.refresh && _mode != _RefreshMode.snap) {
      if (_mode == null) _start(atTop ? AxisDirection.down : AxisDirection.up);
      _show();
    }
    return _pendingRefreshFuture;
  }

  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Color defaultColor = Theme.of(context).colorScheme.secondary;
    Color defaultBackgroundColor = Theme.of(context).canvasColor;

    double defaultHeight = 100.0;

    Color color = (widget.color != null) ? widget.color! : defaultColor;
    Color backgroundColor = (widget.backgroundColor != null)
        ? widget.backgroundColor!
        : defaultBackgroundColor;
    double height = (widget.height != null) ? widget.height! : defaultHeight;

    final Widget child = NotificationListener<ScrollNotification>(
      key: _key,
      onNotification: _handleScrollNotification,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: _handleGlowNotification,
        child: widget.child,
      ),
    );

    if (_mode == null) {
      assert(_dragOffset == null);
      assert(_isIndicatorAtTop == null);
      return child;
    }
    assert(_dragOffset != null);
    assert(_isIndicatorAtTop != null);

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _positionController,
          child: child,
          builder: (BuildContext buildContext, Widget? child) {
            if (widget.showChildOpacityTransition) {
              return Opacity(
                opacity: (widget.showChildOpacityTransition)
                    ? (_childOpacityAnimation.value - (1 / 3) - 0.01).clamp(
                        0.0,
                        1.0,
                      )
                    : 1.0,
                child: child,
              );
            }
            return Transform.translate(
              offset: Offset(0.0, _positionController.value * height * 1.5),
              child: child,
            );
          },
        ),
        AnimatedBuilder(
          animation: Listenable.merge([
            _positionController,
            _springController,
            _showPeakController,
          ]),
          builder: (context, child) {
            return Container(height: _value.value * height * 2, color: color);
          },
        ),
        // AnimatedBuilder(
        //   animation: Listenable.merge([
        //     _positionController,
        //     _springController,
        //     _showPeakController,
        //   ]),
        //   builder: (BuildContext buildContext, Widget? child) {
        //     return ClipPath(
        //       clipper: CurveHillClipper(
        //         centreHeight: height,
        //         curveHeight: height / 2 * _springAnimation.value,
        //         peakHeight: height *
        //             3 /
        //             10 *
        //             ((_peakHeightUpAnimation.value != 1.0)
        //                 ? _peakHeightUpAnimation.value
        //                 : _peakHeightDownAnimation.value),
        //         peakWidth: (_peakHeightUpAnimation.value != 0.0 &&
        //                 _peakHeightDownAnimation.value != 0.0)
        //             ? height * 35 / 100
        //             : 0.0,
        //       ),
        //       child: Container(
        //         height: _value.value * height * 2,
        //         color: color,
        //       ),
        //     );
        //   },
        // ),
        SizedBox(
          height: height,
          child: Align(
            alignment: Alignment(
              0.0,
              (1.0 -
                  (0.36 * _indicatorTranslateWithPeakAnimation.value) -
                  (0.64 * _indicatorTranslateAnimation.value)),
            ),
            child: CircularProgress(
              backgroundColor: backgroundColor,
              progressCircleOpacity: _ringOpacityAnimation.value,
              innerCircleRadius:
                  height *
                  15 /
                  100 *
                  ((_mode != _RefreshMode.done)
                      ? _indicatorRadiusWithPeakAnimation.value
                      : _radiusAnimation.value),
              progressCircleBorderWidth: widget.borderWidth,
              progressCircleRadius: (_ringOpacityAnimation.value != 0.0)
                  ? (height * 2 / 10) * _ringRadiusAnimation.value
                  : 0.0,
              startAngle: _progressingStartAngleAnimation.value * math.pi,
              progressPercent: _progressingPercentAnimation.value,
            ),
          ),
        ),
        // SizedBox(
        //   height: height,
        //   child: AnimatedBuilder(
        //     animation: Listenable.merge([
        //       _progressingController,
        //       _ringDisappearController,
        //       _indicatorMoveWithPeakController,
        //       _indicatorTranslateInOutController,
        //       _radiusController,
        //     ]),
        //     builder: (buildContext, child) {
        //       return Align(
        //         alignment: Alignment(
        //           0.0,
        //           (1.0 -
        //               (0.36 * _indicatorTranslateWithPeakAnimation.value) -
        //               (0.64 * _indicatorTranslateAnimation.value)),
        //         ),
        //         child: Transform(
        //           transform: Matrix4.identity()
        //             ..rotateZ(
        //                 _progressingRotateAnimation.value * 5 * math.pi / 6),
        //           alignment: FractionalOffset.center,
        //           // child: LoadingIndicator(),
        //           child: CircularProgress(
        //             backgroundColor: backgroundColor,
        //             progressCircleOpacity: _ringOpacityAnimation.value,
        //             innerCircleRadius: height *
        //                 15 /
        //                 100 *
        //                 ((_mode != _RefreshMode.done)
        //                     ? _indicatorRadiusWithPeakAnimation.value
        //                     : _radiusAnimation.value),
        //             progressCircleBorderWidth: widget.borderWidth,
        //             progressCircleRadius: (_ringOpacityAnimation.value != 0.0)
        //                 ? (height * 2 / 10) * _ringRadiusAnimation.value
        //                 : 0.0,
        //             startAngle: _progressingStartAngleAnimation.value * math.pi,
        //             progressPercent: _progressingPercentAnimation.value,
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }
}

class ProgressRingCurve extends Curve {
  @override
  double transform(double t) {
    if (t <= 0.5) {
      return 2 * t;
    } else {
      return 2 * (1 - t);
    }
  }
}
