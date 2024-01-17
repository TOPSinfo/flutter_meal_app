import 'package:flutter/material.dart';

import 'indicator_theme.dart';
import 'timeline_theme.dart';

/// [TimelineNode]'s indicator.
mixin PositionedIndicator on Widget {
  double? get position;
  double getEffectivePosition(BuildContext context) {
    return position ??
        IndicatorTheme.of(context).position ??
        TimelineTheme.of(context).indicatorPosition;
  }
}

abstract class Indicator extends StatelessWidget
    with PositionedIndicator, ThemedIndicatorComponent {
  const Indicator({
    super.key,
    this.size,
    this.color,
    this.border,
    this.position,
    this.child,
  })  : assert(size == null || size >= 0),
        assert(position == null || 0 <= position && position <= 1);

  factory Indicator.dot({
    Key? key,
    double? size,
    Color? color,
    double? position,
    Border? border,
    Widget? child,
  }) =>
      DotIndicator(
        size: size,
        color: color,
        position: position,
        boxBorder: border,
        childWidget: child,
      );

  factory Indicator.outlined({
    Key? key,
    double? size,
    Color? color,
    Color? backgroundColor,
    double? position,
    double borderWidth = 2.0,
    Widget? child,
  }) =>
      OutlinedDotIndicator(
        size: size,
        color: color,
        position: position,
        backgroundColor: backgroundColor,
        borderWidth: borderWidth,
        childWidget: child,
      );

  factory Indicator.transparent({
    Key? key,
    double? size,
    double? position,
  }) =>
      ContainerIndicator(
        size: size,
        position: position,
      );

  factory Indicator.widget({
    Key? key,
    double? size,
    double? position,
    Widget? child,
  }) =>
      ContainerIndicator(
        size: size,
        position: position,
        childWidget: child,
      );

  @override
  final double? size;
  @override
  final Color? color;
  @override
  final double? position;
  final BoxBorder? border;
  final Widget? child;
}

class ContainerIndicator extends Indicator {
  const ContainerIndicator({
    super.key,
    super.size,
    super.position,
    this.childWidget,
  }) : super(
          color: Colors.transparent,
        );

  final Widget? childWidget;

  @override
  Widget build(BuildContext context) {
    final size = getEffectiveSize(context);
    return SizedBox(
      width: size,
      height: size,
      child: childWidget,
    );
  }
}

class DotIndicator extends Indicator {
  const DotIndicator({
    super.key,
    super.size,
    super.color,
    super.position,
    this.boxBorder,
    this.childWidget,
  });

  final BoxBorder? boxBorder;
  final Widget? childWidget;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = getEffectiveSize(context);
    final effectiveColor = getEffectiveColor(context);
    return Center(
      child: Container(
        width: effectiveSize ?? ((childWidget == null) ? 15.0 : null),
        height: effectiveSize ?? ((childWidget == null) ? 15.0 : null),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: effectiveColor,
          border: boxBorder,
        ),
        child: childWidget,
      ),
    );
  }
}

class OutlinedDotIndicator extends Indicator {
  const OutlinedDotIndicator({
    super.key,
    super.size,
    super.color,
    super.position,
    this.backgroundColor,
    this.borderWidth = 2.0,
    this.childWidget,
  })  : assert(size == null || size >= 0),
        assert(position == null || 0 <= position && position <= 1);

  final Color? backgroundColor;
  final double borderWidth;
  final Widget? childWidget;

  @override
  Widget build(BuildContext context) {
    return DotIndicator(
      size: size,
      color: backgroundColor ?? Colors.transparent,
      position: position,
      boxBorder: Border.all(
        color: color ?? getEffectiveColor(context),
        width: borderWidth,
      ),
      childWidget: childWidget,
    );
  }
}
