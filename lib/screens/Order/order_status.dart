import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../helper/constant.dart';
import '../../models/cart.dart';
import '../../widgets/timeline_delivery.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key, required this.order});
  final Orders order;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          surfaceTintColor: Theme.of(context).colorScheme.surface,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text("Order Status")),
      // STREAM BUILDER WILL GETTING CALLED WHENEVER THERE IS A CHANGE IN STREAM
      // ONCE ADMIN WILL UPDATE THE ORDER STATUS THEN STREAM BUILDER WILL GET CALLED AND UI WILL BE CHANGED AS PER UPDATED ORDER STATUS
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('orders').doc(widget.order.id).snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          // DATA FETCHING ERROR
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }
          // DATA FETCHING IN PROGRESS
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          }
          // DATA FOUND & CONVERTING DATA TO OUR MODEL
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          Orders order = Orders.fromMap(data);
          return TimeLineDelivery(order: order);
        },
      ),
    );
  }
}
