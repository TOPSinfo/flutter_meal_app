import 'package:flutter/material.dart';

import 'connectors.dart';
import 'indicators.dart';
import 'timeline_node.dart';
import 'timeline_theme.dart';
import 'timeline_tile.dart';

enum ContentsAlign {
  basic,
  reverse,
  alternating,
}

enum ConnectionDirection { before, after }
enum ConnectorType { start, end }
enum IndicatorStyle {
  dot,
  outlined,
  container,
  transparent,
}

enum ConnectorStyle {
  solidLine,
  dashedLine,
  transparent,
}

typedef ConnectedConnectorBuilder = Widget? Function(
    BuildContext context, int index, ConnectorType type);
typedef IndexedValueBuilder<T> = T Function(BuildContext context, int index);

class TimelineTileBuilder {
  factory TimelineTileBuilder.connected({
    required int itemCount,
    ContentsAlign contentsAlign = ContentsAlign.basic,
    ConnectionDirection connectionDirection = ConnectionDirection.after,
    NullableIndexedWidgetBuilder? contentsBuilder,
    NullableIndexedWidgetBuilder? oppositeContentsBuilder,
    NullableIndexedWidgetBuilder? indicatorBuilder,
    ConnectedConnectorBuilder? connectorBuilder,
    WidgetBuilder? firstConnectorBuilder,
    WidgetBuilder? lastConnectorBuilder,
    double? itemExtent,
    IndexedValueBuilder<double>? itemExtentBuilder,
    IndexedValueBuilder<double>? nodePositionBuilder,
    IndexedValueBuilder<double>? indicatorPositionBuilder,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) {
    return TimelineTileBuilder(
      itemCount: itemCount,
      contentsAlign: contentsAlign,
      contentsBuilder: contentsBuilder,
      oppositeContentsBuilder: oppositeContentsBuilder,
      indicatorBuilder: indicatorBuilder,
      startConnectorBuilder: _createConnectedStartConnectorBuilder(
        connectionDirection: connectionDirection,
        firstConnectorBuilder: firstConnectorBuilder,
        connectorBuilder: connectorBuilder,
      ),
      endConnectorBuilder: _createConnectedEndConnectorBuilder(
        connectionDirection: connectionDirection,
        lastConnectorBuilder: lastConnectorBuilder,
        connectorBuilder: connectorBuilder,
        itemCount: itemCount,
      ),
      itemExtent: itemExtent,
      itemExtentBuilder: itemExtentBuilder,
      nodePositionBuilder: nodePositionBuilder,
      indicatorPositionBuilder: indicatorPositionBuilder,
    );
  }

  factory TimelineTileBuilder.connectedFromStyle({
    @required required int itemCount,
    ConnectionDirection connectionDirection = ConnectionDirection.after,
    NullableIndexedWidgetBuilder? contentsBuilder,
    NullableIndexedWidgetBuilder? oppositeContentsBuilder,
    ContentsAlign contentsAlign = ContentsAlign.basic,
    IndexedValueBuilder<IndicatorStyle>? indicatorStyleBuilder,
    IndexedValueBuilder<ConnectorStyle>? connectorStyleBuilder,
    ConnectorStyle firstConnectorStyle = ConnectorStyle.solidLine,
    ConnectorStyle lastConnectorStyle = ConnectorStyle.solidLine,
    double? itemExtent,
    IndexedValueBuilder<double>? itemExtentBuilder,
    IndexedValueBuilder<double>? nodePositionBuilder,
    IndexedValueBuilder<double>? indicatorPositionBuilder,
  }) {
    return TimelineTileBuilder(
      itemCount: itemCount,
      contentsAlign: contentsAlign,
      contentsBuilder: contentsBuilder,
      oppositeContentsBuilder: oppositeContentsBuilder,
      indicatorBuilder: (context, index) => _createStyledIndicatorBuilder(
          indicatorStyleBuilder?.call(context, index))(context),
      startConnectorBuilder: _createConnectedStartConnectorBuilder(
        connectionDirection: connectionDirection,
        firstConnectorBuilder: (context) =>
            _createStyledConnectorBuilder(firstConnectorStyle)(context),
        connectorBuilder: (context, index, __) => _createStyledConnectorBuilder(
            connectorStyleBuilder?.call(context, index))(context),
      ),
      endConnectorBuilder: _createConnectedEndConnectorBuilder(
        connectionDirection: connectionDirection,
        lastConnectorBuilder: (context) =>
            _createStyledConnectorBuilder(lastConnectorStyle)(context),
        connectorBuilder: (context, index, __) => _createStyledConnectorBuilder(
            connectorStyleBuilder?.call(context, index))(context),
        itemCount: itemCount,
      ),
      itemExtent: itemExtent,
      itemExtentBuilder: itemExtentBuilder,
      nodePositionBuilder: nodePositionBuilder,
      indicatorPositionBuilder: indicatorPositionBuilder,
    );
  }

  factory TimelineTileBuilder.fromStyle({
    required int itemCount,
    NullableIndexedWidgetBuilder? contentsBuilder,
    NullableIndexedWidgetBuilder? oppositeContentsBuilder,
    ContentsAlign contentsAlign = ContentsAlign.basic,
    IndicatorStyle indicatorStyle = IndicatorStyle.dot,
    ConnectorStyle connectorStyle = ConnectorStyle.solidLine,
    ConnectorStyle endConnectorStyle = ConnectorStyle.solidLine,
    double? itemExtent,
    IndexedValueBuilder<double>? itemExtentBuilder,
    IndexedValueBuilder<double>? nodePositionBuilder,
    IndexedValueBuilder<double>? indicatorPositionBuilder,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) {
    return TimelineTileBuilder(
      itemCount: itemCount,
      contentsAlign: contentsAlign,
      contentsBuilder: contentsBuilder,
      oppositeContentsBuilder: oppositeContentsBuilder,
      indicatorBuilder: (context, index) =>
          _createStyledIndicatorBuilder(indicatorStyle)(context),
      startConnectorBuilder: (context, _) =>
          _createStyledConnectorBuilder(connectorStyle)(context),
      endConnectorBuilder: (context, _) =>
          _createStyledConnectorBuilder(connectorStyle)(context),
      itemExtent: itemExtent,
      itemExtentBuilder: itemExtentBuilder,
      nodePositionBuilder: nodePositionBuilder,
      indicatorPositionBuilder: indicatorPositionBuilder,
    );
  }

  factory TimelineTileBuilder({
    required int itemCount,
    ContentsAlign contentsAlign = ContentsAlign.basic,
    NullableIndexedWidgetBuilder? contentsBuilder,
    NullableIndexedWidgetBuilder? oppositeContentsBuilder,
    NullableIndexedWidgetBuilder? indicatorBuilder,
    NullableIndexedWidgetBuilder? startConnectorBuilder,
    NullableIndexedWidgetBuilder? endConnectorBuilder,
    double? itemExtent,
    IndexedValueBuilder<double>? itemExtentBuilder,
    IndexedValueBuilder<double>? nodePositionBuilder,
    IndexedValueBuilder<bool?>? nodeItemOverlapBuilder,
    IndexedValueBuilder<double>? indicatorPositionBuilder,
    IndexedValueBuilder<TimelineThemeData>? themeBuilder,
  }) {
    assert(
      itemExtent == null || itemExtentBuilder == null,
      'Cannot provide both a itemExtent and a itemExtentBuilder.',
    );

    final effectiveContentsBuilder = _createAlignedContentsBuilder(
      align: contentsAlign,
      contentsBuilder: contentsBuilder,
      oppositeContentsBuilder: oppositeContentsBuilder,
    );
    final effectiveOppositeContentsBuilder = _createAlignedContentsBuilder(
      align: contentsAlign,
      contentsBuilder: oppositeContentsBuilder,
      oppositeContentsBuilder: contentsBuilder,
    );

    return TimelineTileBuilder._(
      (context, index) {
        final tile = TimelineTile(
          mainAxisExtent: itemExtent ?? itemExtentBuilder?.call(context, index),
          node: TimelineNode(
            indicator: indicatorBuilder?.call(context, index) ??
                Indicator.transparent(),
            startConnector: startConnectorBuilder?.call(context, index),
            endConnector: endConnectorBuilder?.call(context, index),
            overlap: nodeItemOverlapBuilder?.call(context, index),
            position: nodePositionBuilder?.call(context, index),
            indicatorPosition: indicatorPositionBuilder?.call(context, index),
          ),
          contents: effectiveContentsBuilder(context, index),
          oppositeContents: effectiveOppositeContentsBuilder(context, index),
        );

        final theme = themeBuilder?.call(context, index);
        if (theme != null) {
          return TimelineTheme(
            data: theme,
            child: tile,
          );
        } else {
          return tile;
        }
      },
      itemCount: itemCount,
    );
  }

  const TimelineTileBuilder._(
    this._builder, {
    required this.itemCount,
  }) : assert(itemCount >= 0);

  final IndexedWidgetBuilder _builder;
  final int itemCount;

  Widget build(BuildContext context, int index) {
    return _builder(context, index);
  }

  static NullableIndexedWidgetBuilder _createConnectedStartConnectorBuilder({
    ConnectionDirection? connectionDirection,
    WidgetBuilder? firstConnectorBuilder,
    ConnectedConnectorBuilder? connectorBuilder,
  }) =>
      (context, index) {
        if (index == 0) {
          if (firstConnectorBuilder != null) {
            return firstConnectorBuilder.call(context);
          } else {
            return null;
          }
        }

        if (connectionDirection == ConnectionDirection.before) {
          return connectorBuilder?.call(context, index, ConnectorType.start);
        } else {
          return connectorBuilder?.call(
              context, index - 1, ConnectorType.start);
        }
      };

  static NullableIndexedWidgetBuilder _createConnectedEndConnectorBuilder({
    ConnectionDirection? connectionDirection,
    WidgetBuilder? lastConnectorBuilder,
    ConnectedConnectorBuilder? connectorBuilder,
    required int itemCount,
  }) =>
      (context, index) {
        if (index == itemCount - 1) {
          if (lastConnectorBuilder != null) {
            return lastConnectorBuilder.call(context);
          } else {
            return null;
          }
        }

        if (connectionDirection == ConnectionDirection.before) {
          return connectorBuilder?.call(context, index + 1, ConnectorType.end);
        } else {
          return connectorBuilder?.call(context, index, ConnectorType.end);
        }
      };

  static NullableIndexedWidgetBuilder _createAlignedContentsBuilder({
    required ContentsAlign align,
    NullableIndexedWidgetBuilder? contentsBuilder,
    NullableIndexedWidgetBuilder? oppositeContentsBuilder,
  }) {
    return (context, index) {
      switch (align) {
        case ContentsAlign.alternating:
          if (index.isOdd) {
            return oppositeContentsBuilder?.call(context, index);
          }

          return contentsBuilder?.call(context, index);
        case ContentsAlign.reverse:
          return oppositeContentsBuilder?.call(context, index);
        case ContentsAlign.basic:
        default:
          return contentsBuilder?.call(context, index);
      }
    };
  }

  static WidgetBuilder _createStyledIndicatorBuilder(IndicatorStyle? style) {
    return (_) {
      switch (style) {
        case IndicatorStyle.dot:
          return Indicator.dot();
        case IndicatorStyle.outlined:
          return Indicator.outlined();
        case IndicatorStyle.container:
          return Indicator.widget();
        case IndicatorStyle.transparent:
        default:
          return Indicator.transparent();
      }
    };
  }

  static WidgetBuilder _createStyledConnectorBuilder(ConnectorStyle? style) {
    return (_) {
      switch (style) {
        case ConnectorStyle.solidLine:
          return Connector.solidLine();
        case ConnectorStyle.dashedLine:
          return Connector.dashedLine();
        case ConnectorStyle.transparent:
        default:
          return Connector.transparent();
      }
    };
  }
}

int _kDefaultSemanticIndexCallback(Widget _, int localIndex) => localIndex;

class TimelineTileBuilderDelegate extends SliverChildBuilderDelegate {
  TimelineTileBuilderDelegate(
    super.builder, {
    super.findChildIndexCallback,
    super.childCount,
    super.addAutomaticKeepAlives,
    super.addRepaintBoundaries,
    super.addSemanticIndexes,
    super.semanticIndexCallback =
        _kDefaultSemanticIndexCallback,
    super.semanticIndexOffset,
  });
}
