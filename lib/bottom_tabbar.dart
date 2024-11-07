import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'helper/constant.dart';
import 'models/user.dart';
import 'screens/Cart/my_cart.dart';
import 'screens/Order/order_list.dart';
import 'screens/Setting/setting_screen.dart';
import 'screens/Category/categories.dart';

class BottomTabBar extends StatefulWidget {
  const BottomTabBar({super.key});
  @override
  State<StatefulWidget> createState() {
    return _BottomTabBarState();
  }
}

class _BottomTabBarState extends State<BottomTabBar> {
  int _selectedIndex = 0;

  // INIT STATE
  @override
  void initState() {
    getUserCartCount();
    User? user = fAuth.currentUser;
    final uid = user?.uid;
    if ((uid ?? "").trim().isEmpty) {
      // NOT LOGGED IN
    } else {
      // LOGGED IN
      var uid = fAuth.currentUser?.uid ?? "";
      _userDetail(uid);
    }
    super.initState();
  }

  /// Fetches user details from the Firestore database using the provided user ID (uid).
  ///
  /// This function retrieves the user document from the 'users' collection in Firestore,
  /// converts the document data to a `CurrentUser` object, and updates the state with the
  /// retrieved user data.
  ///
  /// The function is asynchronous and uses the `await` keyword to wait for the Firestore
  /// operations to complete.
  ///
  /// Parameters:
  /// - `uid`: A `String` representing the user ID of the user whose details are to be fetched.
  void _userDetail(String uid) async {
    var value = await db.collection('users').doc(uid).get();
    var data = value.data();
    if (data != null) {
      var userData = CurrentUser.fromMap(data);
      setState(() {
        currentUser = userData;
      });
    }
  }

  // GET USER CART COUNT
  Future<void> getUserCartCount() async {
    cartbadgeCount.value = await getCartCount(context);
  }

  static const List<Widget> _widgetOptionsAdmin = <Widget>[
    OrderList(),
    CategoriesScreen(),
    SettingScreen(),
  ];

  static const List<Widget> _widgetOptionsUser = <Widget>[
    CategoriesScreen(),
    MyCartScreen(),
    SettingScreen(),
  ];

  // BOTTOM NAVIGATION BAR ITEMS FOR ADMIN
  static const List<BottomNavigationBarItem> _bottomOptionsAdmin =
      <BottomNavigationBarItem>[
    BottomNavigationBarItem(
        icon: Icon(
          Icons.list,
        ),
        label: 'Orders'),
    BottomNavigationBarItem(
        icon: Icon(
          Icons.category,
        ),
        label: 'Categories'),
    BottomNavigationBarItem(
        icon: Icon(
          Icons.settings,
        ),
        label: 'Setting'),
  ];

  // BOTTOM NAVIGATION BAR ITEMS FOR USER
  final List<BottomNavigationBarItem> _bottomOptionsUser =
      <BottomNavigationBarItem>[
    const BottomNavigationBarItem(
        icon: Icon(
          Icons.category,
        ),
        label: 'Categories'),
    BottomNavigationBarItem(
        icon: ValueListenableBuilder(
          valueListenable: cartbadgeCount,
          builder: (context, value, widget) {
            return Badge(
              label: Text(value.toString()),
              isLabelVisible: value > 0,
              child: const Icon(
                Icons.shopping_cart,
              ),
            );
          },
        ),
        label: 'Cart'),
    const BottomNavigationBarItem(
        icon: Icon(
          Icons.settings,
        ),
        label: 'Setting'),
  ];

  // CHANGE SELECTED INDEX ON BOTTOM NAVIGATION BAR ITEM CHANGE
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: (currentUser != null && currentUser?.isAdmin == true)
            ? _widgetOptionsAdmin.elementAt(_selectedIndex)
            : _widgetOptionsUser.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: (currentUser != null && currentUser?.isAdmin == true)
            ? _bottomOptionsAdmin
            : _bottomOptionsUser,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
