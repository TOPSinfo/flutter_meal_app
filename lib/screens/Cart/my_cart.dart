import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:meal_app/models/cart.dart';
import 'package:meal_app/main.dart';

class MyCartScreen extends StatefulWidget {
  const MyCartScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyCartScreenState();
  }
}

class _MyCartScreenState extends State<MyCartScreen> {
  List<Cart> cartList = [];
  double subtotal = 0.0;
  double tax = 0.0;
  double deliveryFees = 50.0;
  double totalPayableAmount = 0.0;

  @override
  void initState() {
    getCartList(context, true);
    super.initState();
  }

  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  void _showProgress() {
    context.loaderOverlay.show();
  }

  void getCartList(BuildContext context, bool showLoader) async {
    if (showLoader) {
      _showProgress();
    }

    User? user = auth.currentUser;
    final uid = user?.uid;
    final List<Cart> localCart = [];
    var querySnapshot =
        await db.collection('cart').doc(uid).collection("mycart").get();

    subtotal = 0.0;
    tax = 0.0;
    totalPayableAmount = 0.0;

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data();
      var cart = Cart.fromMap(data);
      subtotal = subtotal + (cart.price * cart.quantity);
      localCart.add(cart);
    }

    tax = subtotal * 0.5;
    totalPayableAmount = subtotal + tax + deliveryFees;

    setState(() {
      _hideProgress();
      tax = subtotal * 0.05;
      deliveryFees = subtotal > 700 ? 0.0 : 90.0;
      totalPayableAmount = subtotal + tax + deliveryFees;
      cartList = localCart;
    });
  }

  void _addQuantity(int index) {
    int qt = cartList[index].quantity;
    String id = cartList[index].id;
    User? user = auth.currentUser;
    final uid = user?.uid;
    db.collection('cart').doc(uid).collection("mycart").doc(id).update(
        {'quantity': qt + 1}).then((value) => {getCartList(context, false)});
  }

  void _deleteQuantity(int index) {
    int qt = cartList[index].quantity;
    String id = cartList[index].id;
    if (qt > 1) {
      User? user = auth.currentUser;
      final uid = user?.uid;
      db.collection('cart').doc(uid).collection("mycart").doc(id).update(
          {'quantity': qt - 1}).then((value) => {getCartList(context, false)});
    }
  }

  void _deleteItem(int index) {
    String id = cartList[index].id;
    User? user = auth.currentUser;
    final uid = user?.uid;

    db
        .collection('cart')
        .doc(uid)
        .collection("mycart")
        .doc(id)
        .delete()
        .then((value) => {getCartList(context, false)});
  }

  void _placeOrder() {
    _showProgress();
    String documentID = getRandomString(20);

    var uid = auth.currentUser?.uid ?? "";

    var order = Orders(
      id: documentID,
      status: '0',
      cartItems: cartList,
      userId: uid,
      orderDate: DateTime.now().millisecondsSinceEpoch,
      amount: totalPayableAmount,
    );

    db.collection('orders').doc(documentID).set(order.toMap()).then(
      (value) {
        _hideProgress();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order Placed Successfully"),
          ),
        );
        deleteAll();
        cartbadgeCount.value = 0;
        // Navigator.of(context).popUntil((_) => count-- <= 0);
        // Navigator.of(context).popUntil((route) => route.isFirst);
      },
      onError: (e) {
        _hideProgress();
        if (kDebugMode) {
          print("Error updating document $e");
        }
      },
    );
  }

  Future<void> deleteAll() async {
    var uid = auth.currentUser?.uid ?? "";

    final collection =
        await db.collection("cart").doc(uid).collection('mycart').get();
    final batch = db.batch();

    for (final doc in collection.docs) {
      batch.delete(doc.reference);
    }
    batch.commit().then((value) {
      setState(() {
        cartList = [];
      });
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

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
        title: const Text('My Cart'),
        centerTitle: true,
      ),
      body: cartList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.shopping_cart,
                    size: 50.0,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    'Empty Cart',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (var i = 0; i < cartList.length; i++)
                        CartItem(
                          cartItem: cartList[i],
                          addQuantity: () {
                            _addQuantity(i);
                          },
                          deleteQuantity: () {
                            _deleteQuantity(i);
                          },
                          deleteItem: () {
                            _deleteItem(i);
                          },
                          isCart: true,
                        ),
                    ],
                  ),
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
                        Text('\$ ${totalPayableAmount.toStringAsFixed(2)}',
                            style: totalValueStyle),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    _placeOrder();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(
                    'Checkout',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class PlusMinusButtons extends StatelessWidget {
  final VoidCallback deleteQuantity;
  final VoidCallback addQuantity;
  final String text;
  const PlusMinusButtons(
      {super.key,
      required this.addQuantity,
      required this.deleteQuantity,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: deleteQuantity,
          icon: Icon(
            Icons.remove_circle_outlined,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          onPressed: addQuantity,
          icon: Icon(
            Icons.add_circle_outlined,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ],
    );
  }
}

class CartItem extends StatelessWidget {
  const CartItem({
    super.key,
    required this.cartItem,
    required this.addQuantity,
    required this.deleteQuantity,
    required this.deleteItem,
    required this.isCart,
  });

  final Cart cartItem;
  final VoidCallback deleteQuantity;
  final VoidCallback addQuantity;
  final VoidCallback deleteItem;
  final bool isCart;

  @override
  Widget build(BuildContext context) {
    return Card(
      // color: const Color.fromARGB(255, 255, 255, 255),
      // elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                // shape: BoxShape.circle,
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(cartItem.image), fit: BoxFit.cover,
                  // ProgressiveImage(
                  //   placeholder: null,
                  //   thumbnail: NetworkImage(cartItem.image),
                  //   image: NetworkImage(cartItem.image),
                  //   fit: BoxFit.cover,
                  //   height: 90,
                  //   width: 90,
                  // ),
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    cartItem.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      '\$ ${cartItem.price}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.w100),
                    ),
                  ),
                  if (isCart)
                    Row(
                      children: [
                        PlusMinusButtons(
                          addQuantity: () {
                            addQuantity();
                          },
                          deleteQuantity: () {
                            deleteQuantity();
                          },
                          text: cartItem.quantity.toString(),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            deleteItem();
                          },
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
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
