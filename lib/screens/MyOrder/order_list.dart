import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:meal_app/main.dart';
import 'package:intl/intl.dart';
import '../../models/cart.dart';
import '../MyOrder/order_detail.dart';

Widget noDataWidget(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Uh oh ... nothing here!',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Try selecting a different category!',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
              ),
        ),
      ],
    ),
  );
}

class OrderList extends StatefulWidget {
  const OrderList({super.key});

  @override
  State<StatefulWidget> createState() {
    return OrderListState();
  }
}

class OrderListState extends State<OrderList> {
  List<Orders> orders = [];
  final collection = db.collection('orders');

  Stream<QuerySnapshot<Map<String, dynamic>>>? adminStream = db
      .collection('orders')
      .orderBy("orderDate", descending: true)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>>? userStream = db
      .collection('orders')
      .where('userId', isEqualTo: auth.currentUser?.uid ?? "")
      .orderBy("orderDate", descending: true)
      .snapshots();

  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  void _showProgress() {
    context.loaderOverlay.show();
  }

  void parseOrderData(List<DocumentSnapshot> mealsData, bool isWantToSetState) {
    final List<Orders> localOrders = [];
    for (var doc in mealsData) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      var order = Orders.fromMap(data);
      localOrders.add(order);
    }
    orders = localOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((currentUser != null && currentUser?.isAdmin == true)
            ? 'Orders'
            : 'My Order'),
      ),
      body: StreamBuilder(
        stream: (currentUser != null && currentUser?.isAdmin == true)
            ? adminStream
            : userStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _hideProgress();
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            _showProgress();
            return Container();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            _hideProgress();
            return noDataWidget(context);
          }

          _hideProgress();

          List<DocumentSnapshot> data = snapshot.data!.docs;
          parseOrderData(data, false);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var item = orders[index];
                    return CustomMyOrderList(
                      item: item,
                      onTap: () {
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (ctx) => OrderDetailScreen(
                              order: item,
                            ),
                          ),
                        )
                            .then((value) {
                          if (value == true) {
                            setState(() {});
                          }
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CustomMyOrderList extends StatelessWidget {
  final Orders item;
  final VoidCallback onTap;

  const CustomMyOrderList({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var names = item.cartItems.map((e) => e.title).toList();
    var dateTimeFromMilliseconds =
        DateTime.fromMillisecondsSinceEpoch(item.orderDate);
    var date = DateFormat('dd/MM/yyyy').format(dateTimeFromMilliseconds);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.food_bank_outlined),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Order ID: ',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  fontWeight: FontWeight.w700),
                          children: <TextSpan>[
                            TextSpan(
                              text: item.id.toString().lastChars(4),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: names.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return Text(
                              "🥗 ${names[index]}",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground,
                                      fontWeight: FontWeight.normal),
                            );
                          },
                        ),
                      ),
                      Text(
                        date.toString(),
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Text(
                  '\$${item.amount}',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension E on String {
  String lastChars(int n) => substring(length - n);
}
