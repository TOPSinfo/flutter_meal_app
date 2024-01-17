import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'timeline_theme.dart';

@immutable
class ConnectorThemeData with Diagnosticable {
  const ConnectorThemeData({
    this.color,
    this.space,
    this.thickness,
    this.indent,
  });

  final Color? color;
  final double? space;
  final double? thickness;
  final double? indent;

  ConnectorThemeData copyWith({
    Color? color,
    double? space,
    double? thickness,
    double? indent,
  }) {
    return ConnectorThemeData(
      color: color ?? this.color,
      space: space ?? this.space,
      thickness: thickness ?? this.thickness,
      indent: indent ?? this.indent,
    );
  }
  static ConnectorThemeData lerp(
      ConnectorThemeData? a, ConnectorThemeData? b, double t) {
    return ConnectorThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      space: lerpDouble(a?.space, b?.space, t),
      thickness: lerpDouble(a?.thickness, b?.thickness, t),
      indent: lerpDouble(a?.indent, b?.indent, t),
    );
  }

  @override
  int get hashCode {
    return Object.hash(
      color,
      space,
      thickness,
      indent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is ConnectorThemeData &&
        other.color == color &&
        other.space == space &&
        other.thickness == thickness &&
        other.indent == indent;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(DoubleProperty('space', space, defaultValue: null))
      ..add(DoubleProperty('thickness', thickness, defaultValue: null))
      ..add(DoubleProperty('indent', indent, defaultValue: null));
  }
}

class ConnectorTheme extends InheritedTheme {
  const ConnectorTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final ConnectorThemeData data;
  static ConnectorThemeData of(BuildContext context) {
    final connectorTheme =
        context.dependOnInheritedWidgetOfExactType<ConnectorTheme>();
    return connectorTheme?.data ?? TimelineTheme.of(context).connectorTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final ancestorTheme =
        context.findAncestorWidgetOfExactType<ConnectorTheme>();
    return identical(this, ancestorTheme)
        ? child
        : ConnectorTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(ConnectorTheme oldWidget) => data != oldWidget.data;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    data.debugFillProperties(properties);
  }
}

mixin ThemedConnectorComponent on Widget {
  Axis? get direction;
  Axis getEffectiveDirection(BuildContext context) {
    return direction ?? TimelineTheme.of(context).direction;
  }

  double? get thickness;
  double getEffectiveThickness(BuildContext context) {
    return thickness ?? ConnectorTheme.of(context).thickness ?? 2.0;
  }

  double? get space;
  double? getEffectiveSpace(BuildContext context) {
    return space ?? ConnectorTheme.of(context).space;
  }

  double? get indent;
  double getEffectiveIndent(BuildContext context) {
    return indent ?? ConnectorTheme.of(context).indent ?? 0.0;
  }

  double? get endIndent;
  double getEffectiveEndIndent(BuildContext context) {
    return endIndent ?? ConnectorTheme.of(context).indent ?? 0.0;
  }

  Color? get color;
  Color getEffectiveColor(BuildContext context) {
    return color ??
        ConnectorTheme.of(context).color ??
        TimelineTheme.of(context).color;
  }
}
