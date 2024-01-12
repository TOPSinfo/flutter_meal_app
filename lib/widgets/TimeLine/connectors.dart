import 'package:flutter/material.dart';
import 'connector_theme.dart';
import 'line_painter.dart';

abstract class Connector extends StatelessWidget with ThemedConnectorComponent {
  const Connector({
    super.key,
    this.direction,
    this.space,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  })  : assert(thickness == null || thickness >= 0.0),
        assert(space == null || space >= 0.0),
        assert(indent == null || indent >= 0.0),
        assert(endIndent == null || endIndent >= 0.0);

  factory Connector.solidLine({
    Key? key,
    Axis? direction,
    double? thickness,
    double? space,
    double? indent,
    double? endIndent,
    Color? color,
  }) {
    return SolidLineConnector(
      key: key,
      direction: direction,
      thickness: thickness,
      space: space,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }

  factory Connector.dashedLine({
    Key? key,
    Axis? direction,
    double? thickness,
    double? dash,
    double? gap,
    double? space,
    double? indent,
    double? endIndent,
    Color? color,
    Color? gapColor,
  }) {
    return DashedLineConnector(
      key: key,
      direction: direction,
      thickness: thickness,
      dash: dash,
      gap: gap,
      space: space,
      indent: indent,
      endIndent: endIndent,
      color: color,
      gapColor: gapColor,
    );
  }

  factory Connector.transparent({
    Key? key,
    Axis? direction,
    double? indent,
    double? endIndent,
    double? space,
  }) {
    return TransparentConnector(
      key: key,
      direction: direction,
      indent: indent,
      endIndent: endIndent,
      space: space,
    );
  }

  @override
  final Axis? direction;
  @override
  final double? space;
  @override
  final double? thickness;
  @override
  final double? indent;
  @override
  final double? endIndent;
  @override
  final Color? color;
}

class SolidLineConnector extends Connector {
  const SolidLineConnector({
    super.key,
    Axis? direction,
    super.thickness,
    super.space,
    super.indent,
    super.endIndent,
    super.color,
  });

  @override
  Widget build(BuildContext context) {
    final direction = getEffectiveDirection(context);
    final thickness = getEffectiveThickness(context);
    final color = getEffectiveColor(context);
    final space = getEffectiveSpace(context);
    final indent = getEffectiveIndent(context);
    final endIndent = getEffectiveEndIndent(context);

    switch (direction) {
      case Axis.vertical:
        return _ConnectorIndent(
          direction: direction,
          indent: indent,
          endIndent: endIndent,
          space: space,
          child: Container(
            width: thickness,
            color: color,
          ),
        );
      case Axis.horizontal:
        return _ConnectorIndent(
          direction: direction,
          indent: indent,
          endIndent: endIndent,
          space: space,
          child: Container(
            height: thickness,
            color: color,
          ),
        );
    }
  }
}

class DecoratedLineConnector extends Connector {
  const DecoratedLineConnector({
    super.key,
    Axis? direction,
    super.thickness,
    super.space,
    super.indent,
    super.endIndent,
    this.decoration,
  });

  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    final direction = getEffectiveDirection(context);
    final thickness = getEffectiveThickness(context);
    final space = getEffectiveSpace(context);
    final indent = getEffectiveIndent(context);
    final endIndent = getEffectiveEndIndent(context);
    final color = decoration == null ? getEffectiveColor(context) : null;

    switch (direction) {
      case Axis.vertical:
        return _ConnectorIndent(
          direction: direction,
          indent: indent,
          endIndent: endIndent,
          space: space,
          child: Container(
            width: thickness,
            color: color,
            decoration: decoration,
          ),
        );
      case Axis.horizontal:
        return _ConnectorIndent(
          direction: direction,
          indent: indent,
          endIndent: endIndent,
          space: space,
          child: Container(
            height: thickness,
            color: color,
            decoration: decoration,
          ),
        );
    }
  }
}

class DashedLineConnector extends Connector {
  const DashedLineConnector({
    super.key,
    super.direction,
    super.thickness,
    this.dash,
    this.gap,
    super.space,
    super.indent,
    super.endIndent,
    super.color,
    this.gapColor,
  });

  final double? dash;
  final double? gap;
  final Color? gapColor;

  @override
  Widget build(BuildContext context) {
    final direction = getEffectiveDirection(context);
    return _ConnectorIndent(
      direction: direction,
      indent: getEffectiveIndent(context),
      endIndent: getEffectiveEndIndent(context),
      space: getEffectiveSpace(context),
      child: CustomPaint(
        painter: DashedLinePainter(
          direction: direction,
          color: getEffectiveColor(context),
          strokeWidth: getEffectiveThickness(context),
          dashSize: dash ?? 1.0,
          gapSize: gap ?? 1.0,
          gapColor: gapColor ?? Colors.transparent,
        ),
        child: Container(),
      ),
    );
  }
}

class TransparentConnector extends Connector {
  const TransparentConnector({
    super.key,
    super.direction,
    super.indent,
    super.endIndent,
    super.space,
  });

  @override
  Widget build(BuildContext context) {
    return _ConnectorIndent(
      direction: getEffectiveDirection(context),
      indent: getEffectiveIndent(context),
      endIndent: getEffectiveEndIndent(context),
      space: getEffectiveSpace(context),
      child: Container(),
    );
  }
}

class _ConnectorIndent extends StatelessWidget {
  const _ConnectorIndent({
    required this.direction,
    required this.space,
    this.indent,
    this.endIndent,
    required this.child,
  })   : assert(space == null || space >= 0),
        assert(indent == null || indent >= 0),
        assert(endIndent == null || endIndent >= 0);

  final Axis direction;
  final double? space;
  final double? indent;
  final double? endIndent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: direction == Axis.vertical ? space : null,
      height: direction == Axis.vertical ? null : space,
      child: Center(
        child: Padding(
          padding: direction == Axis.vertical
              ? EdgeInsetsDirectional.only(
                  top: indent ?? 0,
                  bottom: endIndent ?? 0,
                )
              : EdgeInsetsDirectional.only(
                  start: indent ?? 0,
                  end: endIndent ?? 0,
                ),
          child: child,
        ),
      ),
    );
  }
}
