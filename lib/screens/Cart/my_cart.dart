import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../../helper/constant.dart';
import '../../models/cart.dart';

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

  // INIT STATE
  @override
  void initState() {
    getCartList(context, true);
    super.initState();
  }

  // HIDE LOADER
  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  /// Fetches the cart list from the Firestore database and updates the UI.
  ///
  /// This function retrieves the current user's cart items from the Firestore
  /// database, calculates the subtotal, tax, and total payable amount, and
  /// updates the UI with the fetched cart items and calculated values.
  ///
  /// The function performs the following steps:
  /// 1. Shows a progress indicator if `showLoader` is true.
  /// 2. Retrieves the current user's UID.
  /// 3. Fetches the cart items from the Firestore database.
  /// 4. Calculates the subtotal, tax, and total payable amount.
  /// 5. Updates the UI with the fetched cart items and calculated values.
  ///
  /// Parameters:
  /// - `context`: The build context.
  /// - `showLoader`: A boolean indicating whether to show a progress indicator.
  ///
  /// Note:
  /// - The tax is calculated as 5% of the subtotal.
  /// - The delivery fee is 90.0 if the subtotal is less than or equal to 700,
  ///   otherwise, it is 0.0.
  void getCartList(BuildContext context, bool showLoader) async {
    if (showLoader) {
      _showProgress();
    }

    User? user = fAuth.currentUser;
    final uid = user?.uid;
    final List<Cart> localCart = [];
    var querySnapshot =
        await db.collection('cart').doc(uid).collection("mycart").get();

    // CALCULATING CART ITEMS TOTAL AMOUNT, TAX AND DELIVERY FEES
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

    // DATA SET IN UI
    setState(() {
      _hideProgress();
      tax = subtotal * 0.05;
      deliveryFees = subtotal > 700 ? 0.0 : 90.0;
      totalPayableAmount = subtotal + tax + deliveryFees;
      cartList = localCart;
    });
  }

  /// Increases the quantity of an item in the cart by 1 and updates the database.
  ///
  /// This method retrieves the current quantity of the item at the specified
  /// index in the `cartList`, increments it by 1, and updates the corresponding
  /// document in the Firestore database. After updating the quantity, it calls
  /// `getCartList` to refresh the cart list.
  ///
  /// Parameters:
  /// - `index`: The index of the item in the `cartList` whose quantity is to be increased.
  void _addQuantity(int index) {
    int qt = cartList[index].quantity;
    String id = cartList[index].id;
    User? user = fAuth.currentUser;
    final uid = user?.uid;
    db.collection('cart').doc(uid).collection("mycart").doc(id).update(
        {'quantity': qt + 1}).then((value) => {getCartList(context, false)});
  }

  /// Decreases the quantity of an item in the cart by 1 if the quantity is greater than 1.
  ///
  /// This function updates the quantity of the item in the Firestore database and then
  /// refreshes the cart list.
  ///
  /// Parameters:
  /// - `index`: The index of the item in the cart list.
  void _deleteQuantity(int index) {
    int qt = cartList[index].quantity;
    String id = cartList[index].id;
    if (qt > 1) {
      User? user = fAuth.currentUser;
      final uid = user?.uid;
      db.collection('cart').doc(uid).collection("mycart").doc(id).update(
          {'quantity': qt - 1}).then((value) => {getCartList(context, false)});
    }
  }

  /// Deletes an item from the cart at the specified index.
  ///
  /// This method retrieves the item ID from the `cartList` at the given index,
  /// gets the current user's UID, and then deletes the corresponding document
  /// from the Firestore database. After deletion, it refreshes the cart list.
  ///
  /// Parameters:
  /// - `index`: The index of the item to be deleted in the `cartList`.
  ///
  /// Note:
  /// - Ensure that `cartList` is properly initialized and contains valid items.
  /// - The user must be authenticated to have a valid UID.
  void _deleteItem(int index) {
    String id = cartList[index].id;
    User? user = fAuth.currentUser;
    final uid = user?.uid;

    db
        .collection('cart')
        .doc(uid)
        .collection("mycart")
        .doc(id)
        .delete()
        .then((value) => {getCartList(context, false)});
  }

  /// Places an order by creating a new document in the 'orders' collection in the database.
  ///
  /// This function performs the following steps:
  /// 1. Shows a progress indicator.
  /// 2. Generates a random document ID.
  /// 3. Retrieves the current user's UID.
  /// 4. Creates an `Orders` object with the necessary details.
  /// 5. Adds the order to the 'orders' collection in the database.
  /// 6. Hides the progress indicator.
  /// 7. Shows a success message using a `SnackBar`.
  /// 8. Clears the cart and resets the cart badge count.
  ///
  /// If there is an error while adding the order to the database, it hides the progress indicator
  /// and prints the error message in debug mode.
  void _placeOrder() {
    _showProgress();
    String documentID = getRandomString(20);

    var uid = fAuth.currentUser?.uid ?? "";

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

  /// Deletes all items from the user's cart in the Firestore database.
  ///
  /// This method retrieves the current user's UID and accesses the 'cart' collection
  /// in Firestore. It then deletes all documents in the 'mycart' subcollection for
  /// the user. After successfully deleting the documents, it clears the local cart
  /// list and navigates back to the first route in the navigation stack.
  ///
  /// Returns a [Future] that completes when the deletion and navigation are done.
  Future<void> deleteAll() async {
    var uid = fAuth.currentUser?.uid ?? "";

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

  // UI
  @override
  Widget build(BuildContext context) {
    TextStyle amountStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.normal);

    TextStyle totalTitleStyle = Theme.of(context)
        .textTheme
        .titleMedium!
        .copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold);

    TextStyle priceStyle = Theme.of(context).textTheme.titleSmall!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.normal);

    TextStyle totalValueStyle = Theme.of(context)
        .textTheme
        .titleSmall!
        .copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                          Text('\$ ${subtotal.toStringAsFixed(2)}',
                              style: priceStyle),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Taxes & Fees : ',
                            style: amountStyle,
                          ),
                          const Spacer(),
                          Text('\$ ${tax.toStringAsFixed(2)}',
                              style: priceStyle),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Delivery Fees : ',
                            style: amountStyle,
                          ),
                          const Spacer(),
                          Text('\$ ${deliveryFees.toStringAsFixed(2)}',
                              style: priceStyle),
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
                            color: Theme.of(context).colorScheme.onSurface,
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

// QUANTITY ADD/REMOVE BUTTONS
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          onPressed: addQuantity,
          icon: Icon(
            Icons.add_circle_outlined,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// CART ITEM WIDGET
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
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(cartItem.image),
                  fit: BoxFit.cover,
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
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      '\$ ${cartItem.price}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
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
                            color: Theme.of(context).colorScheme.onSurface,
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
