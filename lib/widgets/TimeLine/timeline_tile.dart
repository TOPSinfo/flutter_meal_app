import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'timeline_node.dart';
import 'timeline_theme.dart';
import 'util.dart';

enum TimelineNodeAlign {
  start,
  end,
  basic,
}

class TimelineTile extends StatelessWidget {
  const TimelineTile({
    super.key,
    this.direction,
    required this.node,
    this.nodeAlign = TimelineNodeAlign.basic,
    this.nodePosition,
    this.contents,
    this.oppositeContents,
    this.mainAxisExtent,
    this.crossAxisExtent,
  })  : assert(
          nodeAlign == TimelineNodeAlign.basic ||
              (nodeAlign != TimelineNodeAlign.basic && nodePosition == null),
          'Cannot provide both a nodeAlign and a nodePosition',
        ),
        assert(nodePosition == null || nodePosition >= 0);

  final Axis? direction;
  final Widget node;
  final TimelineNodeAlign nodeAlign;
  final double? nodePosition;
  final Widget? contents;
  final Widget? oppositeContents;
  final double? mainAxisExtent;
  final double? crossAxisExtent;

  double _getEffectiveNodePosition(BuildContext context) {
    if (nodeAlign == TimelineNodeAlign.start) return 0.0;
    if (nodeAlign == TimelineNodeAlign.end) return 1.0;
    var nodePosition = this.nodePosition;
    nodePosition ??= (node is TimelineTileNode)
        ? (node as TimelineTileNode).getEffectivePosition(context)
        : TimelineTheme.of(context).nodePosition;
    return nodePosition;
  }

  @override
  Widget build(BuildContext context) {
    final direction = this.direction ?? TimelineTheme.of(context).direction;
    final nodeFlex = _getEffectiveNodePosition(context) * kFlexMultiplier;

    var minNodeExtent = TimelineTheme.of(context).indicatorTheme.size ?? 0.0;
    var items = [
      if (nodeFlex > 0)
        Expanded(
          flex: nodeFlex.toInt(),
          child: Align(
            alignment: direction == Axis.vertical
                ? AlignmentDirectional.centerEnd
                : Alignment.bottomCenter,
            child: oppositeContents ?? const SizedBox.shrink(),
          ),
        ),
      ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: direction == Axis.vertical ? minNodeExtent : 0.0,
          minHeight: direction == Axis.vertical ? 0.0 : minNodeExtent,
        ),
        child: node,
      ),
      if (nodeFlex < kFlexMultiplier)
        Expanded(
          flex: (kFlexMultiplier - nodeFlex).toInt(),
          child: Align(
            alignment: direction == Axis.vertical
                ? AlignmentDirectional.centerStart
                : Alignment.topCenter,
            child: contents ?? const SizedBox.shrink(),
          ),
        ),
    ];

    Widget result;
    switch (direction) {
      case Axis.vertical:
        result = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items,
        );

        if (mainAxisExtent != null) {
          result = SizedBox(
            width: crossAxisExtent,
            height: mainAxisExtent,
            child: result,
          );
        } else {
          result = IntrinsicHeight(
            child: result,
          );

          if (crossAxisExtent != null) {
            result = SizedBox(
              width: crossAxisExtent,
              child: result,
            );
          }
        }
        break;
      case Axis.horizontal:
        result = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items,
        );
        if (mainAxisExtent != null) {
          result = SizedBox(
            width: mainAxisExtent,
            height: crossAxisExtent,
            child: result,
          );
        } else {
          result = IntrinsicWidth(
            child: result,
          );

          if (crossAxisExtent != null) {
            result = SizedBox(
              height: crossAxisExtent,
              child: result,
            );
          }
        }
        break;
      default:
        throw ArgumentError.value(direction, '$direction is invalid.');
    }

    result = Align(
      child: result,
    );

    if (TimelineTheme.of(context).direction != direction) {
      result = TimelineTheme(
        data: TimelineTheme.of(context).copyWith(
          direction: direction,
        ),
        child: result,
      );
    }

    return result;
  }
}
