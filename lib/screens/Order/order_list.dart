import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:intl/intl.dart';
import '../../helper/constant.dart';
import '../../helper/extension.dart';
import '../../models/cart.dart';
import '../../widgets/no_data.dart';
import 'order_detail.dart';

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

  // ADMIN STREAM TO LISTEN TO ORDERS
  Stream<QuerySnapshot<Map<String, dynamic>>>? adminStream = db
      .collection('orders')
      .orderBy("orderDate", descending: true)
      .snapshots();
  // USER STREAM TO LISTEN TO ORDERS
  Stream<QuerySnapshot<Map<String, dynamic>>>? userStream = db
      .collection('orders')
      .where('userId', isEqualTo: fAuth.currentUser?.uid ?? "")
      .orderBy("orderDate", descending: true)
      .snapshots();

  // HIDE LOADER
  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  /// Parses the order data from a list of DocumentSnapshot objects and updates the orders list.
  ///
  /// This function takes a list of DocumentSnapshot objects, extracts the data from each document,
  /// converts it into an Orders object, and adds it to a local list of orders. Finally, it updates
  /// the orders list with the local list of orders.
  ///
  /// If [isWantToSetState] is true, the function will also trigger a state update.
  ///
  /// - Parameters:
  ///   - mealsData: A list of DocumentSnapshot objects containing the order data.
  ///   - isWantToSetState: A boolean indicating whether to trigger a state update.
  void parseOrderData(List<DocumentSnapshot> mealsData, bool isWantToSetState) {
    final List<Orders> localOrders = [];
    for (var doc in mealsData) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      var order = Orders.fromMap(data);
      localOrders.add(order);
    }
    orders = localOrders;
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text((currentUser != null && currentUser?.isAdmin == true)
            ? 'Orders'
            : 'My Order'),
      ),
      // STREAM BUILDER WILL GETTING CALLED WHENEVER THERE IS A CHANGE IN STREAM
      // IF CURRENT USER IS ADMIN THEN ADMIN STREAM OTHERWISE USER STREAM
      body: SafeArea(
        child: StreamBuilder(
          stream: (currentUser != null && currentUser?.isAdmin == true)
              ? adminStream
              : userStream,
          builder: (context, snapshot) {
            // DATA FETCHING ERROR
            if (snapshot.hasError) {
              _hideProgress();
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            // DATA FETCHING IN PROGRESS
            if (snapshot.connectionState == ConnectionState.waiting) {
              _showProgress();
              return Container();
            }
            // NO DATA FOUND
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              _hideProgress();
              return noDataWidget(context);
            }

            _hideProgress();

            // DATA FOUND & PARSE DOCUMENT SNAPSHOT TO OUR MODEL
            List<DocumentSnapshot> data = snapshot.data!.docs;
            parseOrderData(data, false);

            // UI
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
                          // TAPPING ON THE ITEM WILL NAVIGATE TO ORDER DETAIL SCREEN
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
      ),
    );
  }
}

// CUSTOM WIDGET FOR ORDERS LAYOUT
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700),
                          children: <TextSpan>[
                            TextSpan(
                              text: item.id.toString().lastChars(4),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
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
                                          .onSurface,
                                      fontWeight: FontWeight.normal),
                            );
                          },
                        ),
                      ),
                      Text(
                        date.toString(),
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.onSurface,
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
