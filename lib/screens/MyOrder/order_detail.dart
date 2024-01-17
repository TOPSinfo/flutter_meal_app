import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meal_app/main.dart';
import '../../models/cart.dart';
import '../../widgets/timeline_new_delivery.dart';
import '../Cart/my_cart.dart';
import 'order_status.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Orders order;

  @override
  State<OrderDetailScreen> createState() {
    return OrderDetailScreenState();
  }
}

class OrderStatus {
  String status = '';
  String statusTitle = '';

  OrderStatus(this.status, this.statusTitle);
}

class OrderDetailScreenState extends State<OrderDetailScreen> {
  double subtotal = 0.0;
  double tax = 0.0;
  double deliveryFees = 50.0;
  double totalPayableAmount = 0.0;

  // ORDER STATUS OPTIONS
  List<OrderStatus> orderStatusList = <OrderStatus>[
    OrderStatus('0', 'Order Placed'),
    OrderStatus('1', 'Order Accepted'),
    OrderStatus('2', 'Cooking/Preparing'),
    OrderStatus('3', 'Ready for Pickup'),
    OrderStatus('4', 'Out for Delivery'),
    OrderStatus('5', 'Delivered'),
  ];

  OrderStatus? dropdownValue;

  // INIT STATE
  @override
  void initState() {
    super.initState();
    subtotal = 0.0;
    tax = 0.0;
    totalPayableAmount = 0.0;

    // CALCULATE SUBTOTAL, TAX AND TOTAL AMOUNT
    for (var i = 0; i < widget.order.cartItems.length; i++) {
      Cart item = widget.order.cartItems[i];
      subtotal = subtotal + (item.price * item.quantity);
    }

    tax = subtotal * 0.5;
    totalPayableAmount = subtotal + tax + deliveryFees;

    tax = subtotal * 0.05;
    deliveryFees = subtotal > 700 ? 0.0 : 90.0;
    totalPayableAmount = subtotal + tax + deliveryFees;

    checkOrderStatusAndUpdate();
  }

  // CHECK CURRENT ORDER STATUS AND UPDATE DROPDOWN VALUE
  void checkOrderStatusAndUpdate() {
    OrderStatus od = orderStatusList
        .where((element) => element.status == widget.order.status)
        .first;
    dropdownValue = od;
    if (kDebugMode) {
      print('Order Status is ==> ${dropdownValue?.status}');
    }
  }

  // DISPLAY ORDER STATUS UPDATE MESSAGE
  void _showToastMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ONCE ADMIN WILL CHANGE THE ORDER STATUS, UPDATE THE ORDER STATUS IN FIRESTORE
  void updateOrderStatus() {
    var collection = db.collection('orders');
    collection.doc(widget.order.id).update({
      'status': dropdownValue?.status,
    }).then(
      (value) {
        _showToastMessage('Order status updated successfully.');
      },
      onError: (e) {
        if (kDebugMode) {
          _showToastMessage(e.toString());
          print("Error updating document $e");
        }
      },
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    TextStyle amountStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
        color: Theme.of(context).colorScheme.onBackground,
        fontWeight: FontWeight.normal);

    TextStyle totalTitleStyle = Theme.of(context)
        .textTheme
        .titleMedium!
        .copyWith(
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.bold);

    TextStyle priceStyle = Theme.of(context).textTheme.titleSmall!.copyWith(
        color: Theme.of(context).colorScheme.onBackground,
        fontWeight: FontWeight.normal);

    TextStyle totalValueStyle = Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Detail'),
        actions: [
          if (currentUser != null && currentUser?.isAdmin == false)
          IconButton(
              color: Theme.of(context).colorScheme.onBackground,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => OrderStatusScreen(order: widget.order),
                  ),
                );
              },
              icon: const Icon(Icons.track_changes_rounded),
            )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (currentUser != null && currentUser?.isAdmin == false)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream:
                    db.collection('orders').doc(widget.order.id).snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }
              
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading");
                  }
              
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  Orders order = Orders.fromMap(data);
                  return SizedBox(
                      height: 180,
                      child: TimelineDeliveryNew(
                        order: order,
                      ));
                },
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < widget.order.cartItems.length; i++)
                      CartItem(
                        cartItem: widget.order.cartItems[i],
                        addQuantity: () {},
                        deleteQuantity: () {},
                        deleteItem: () {},
                        isCart: false,
                      ),
                  ],
                ),
              ),
            ),
            if (currentUser != null && currentUser?.isAdmin == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Order Status : ',
                      style: totalTitleStyle,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onBackground,
                          // width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: dropdownValue?.statusTitle,
                          icon: const Icon(Icons.arrow_drop_down),
                          elevation: 16,
                          onChanged: (String? value) {
                            OrderStatus od = orderStatusList
                                .where((element) => element.statusTitle == value)
                                .first;
                        
                            setState(() {
                              dropdownValue = od;
                              updateOrderStatus();
                            });
                        
                            if (kDebugMode) {
                              print('Order Status is ==> ${dropdownValue?.status}');
                            }
                          },
                          items: orderStatusList
                              .map<DropdownMenuItem<String>>((OrderStatus value) {
                            return DropdownMenuItem<String>(
                              value: value.statusTitle,
                              child: Text(
                                value.statusTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                runSpacing: 10,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sub total : ',
                        style: amountStyle,
                      ),
                      const Spacer(),
                      Text('\$ ${subtotal.toStringAsFixed(2)}', style: priceStyle),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Taxes & Fees : ',
                        style: amountStyle,
                      ),
                      const Spacer(),
                      Text('\$ ${tax.toStringAsFixed(2)}', style: priceStyle),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Delivery Fees : ',
                        style: amountStyle,
                      ),
                      const Spacer(),
                      Text('\$ ${deliveryFees.toStringAsFixed(2)}', style: priceStyle),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Total : ',
                        style: totalTitleStyle,
                      ),
                      const Spacer(),
                      Text('\$ ${widget.order.amount.toStringAsFixed(2)}', style: totalValueStyle),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}