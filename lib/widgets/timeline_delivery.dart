import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../models/cart.dart';

var greenColor = const Color(0xFF27AA69);
var disableColor = const Color(0xFFDADADA);
var padding = const EdgeInsets.symmetric(horizontal: 6);

class TimeLineDelivery extends StatefulWidget {
  const TimeLineDelivery({super.key, required this.order});
  final Orders order;

  @override
  State<TimeLineDelivery> createState() => _TimeLineDeliveryState();
}

class _TimeLineDeliveryState extends State<TimeLineDelivery> {
  int status = 0;

  @override
  void initState() {
    super.initState();

    status = int.parse(widget.order.status);
    if (kDebugMode) {
      print("INIT STATE STATUS IS ==> $status");
    }
  }

  @override
  void didUpdateWidget(covariant TimeLineDelivery oldWidget) {
    setState(() {
      status = int.parse(widget.order.status);
      if (kDebugMode) {
        print("UPDATE WIDGET STATUS IS ==> $status");
      }
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isFirst: true,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: (status >= 0) ? greenColor : disableColor,
            padding: padding,
          ),
          endChild: RightChild(
            disabled: (status >= 0) ? false : true,
            asset: 'assets/delivery/0.jpg',
            title: 'Order Placed',
            message: 'We have received your order.',
          ),
          beforeLineStyle: LineStyle(
            color: (status >= 0) ? greenColor : disableColor,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: (status >= 0 && status < 1)
                ? Theme.of(context).colorScheme.primary
                : greenColor,
            padding: padding,
          ),
          endChild: RightChild(
            disabled: (status >= 1) ? false : true,
            asset: 'assets/delivery/1.jpg',
            title: 'Order Accepted',
            message: 'Your order has been Accepted.',
          ),
          beforeLineStyle: LineStyle(
            color: (status >= 0) ? greenColor : disableColor,
          ),
          afterLineStyle: LineStyle(
            color: (status >= 1) ? greenColor : disableColor,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: (status >= 1 && status < 2)
                ? Theme.of(context).colorScheme.primary
                : (status >= 1)
                    ? greenColor
                    : disableColor,
            padding: padding,
          ),
          endChild: RightChild(
            disabled: (status >= 2) ? false : true,
            asset: 'assets/delivery/2.jpg',
            title: 'Order Processing',
            message: 'We are preparing your order.',
          ),
          beforeLineStyle: LineStyle(
            color: (status >= 1) ? greenColor : disableColor,
          ),
          afterLineStyle: LineStyle(
            color: (status >= 2) ? greenColor : disableColor,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: (status >= 2 && status < 3)
                ? Theme.of(context).colorScheme.primary
                : (status >= 2)
                    ? greenColor
                    : disableColor,
            padding: padding,
          ),
          endChild: RightChild(
            disabled: (status >= 3) ? false : true,
            asset: 'assets/delivery/3.jpg',
            title: 'Ready to Pickup',
            message: 'Your order is ready for pickup.',
          ),
          beforeLineStyle: LineStyle(
            color: (status >= 2) ? greenColor : disableColor,
          ),
          afterLineStyle: LineStyle(
            color: (status >= 3) ? greenColor : disableColor,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: (status >= 3 && status < 4)
                ? Theme.of(context).colorScheme.primary
                : (status >= 3)
                    ? greenColor
                    : disableColor,
            padding: padding,
          ),
          endChild: RightChild(
            disabled: (status >= 4) ? false : true,
            asset: 'assets/delivery/4.jpg',
            title: 'Out for Delivery',
            message: 'Your order is out for Delivery.',
          ),
          beforeLineStyle: LineStyle(
            color: (status >= 3) ? greenColor : disableColor,
          ),
          afterLineStyle: LineStyle(
            color: (status >= 4) ? greenColor : disableColor,
          ),
        ),
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isLast: true,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: (status >= 4 && status < 5)
                ? Theme.of(context).colorScheme.primary
                : (status >= 4)
                    ? greenColor
                    : disableColor,
            padding: padding,
          ),
          endChild: RightChild(
            disabled: (status >= 5) ? false : true,
            asset: 'assets/delivery/5.jpg',
            title: 'Delivered',
            message: 'Your order has been Delivered.',
          ),
          beforeLineStyle: LineStyle(
            color: (status >= 4) ? greenColor : disableColor,
          ),
          afterLineStyle: LineStyle(
            color: (status >= 5) ? greenColor : disableColor,
          ),
        ),
      ],
    );
  }
}

class RightChild extends StatelessWidget {
  const RightChild({
    super.key,
    required this.asset,
    required this.title,
    required this.message,
    this.disabled = false,
  });

  final String asset;
  final String title;
  final String message;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          Opacity(
            opacity: disabled ? 0.5 : 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.fromSize(
                child: Image.asset(asset, height: 60),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: disabled
                        ? Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.5)
                        : Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: disabled
                        ? Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.5)
                        : Theme.of(context).colorScheme.onBackground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
