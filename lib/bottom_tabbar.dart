import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meal_app/models/user.dart';
import 'screens/Cart/my_cart.dart';
import 'screens/MyOrder/order_list.dart';
import 'screens/Setting/setting_screen.dart';
import 'screens/categories.dart';
import 'main.dart';

class BottomTabBar extends StatefulWidget {
  const BottomTabBar({super.key});
  @override
  State<StatefulWidget> createState() {
    return _BottomTabBarState();
  }
}

class _BottomTabBarState extends State<BottomTabBar> {
  int _selectedIndex = 0;

  @override
  void initState() {
    getUserCartCount();
    User? user = auth.currentUser;
    final uid = user?.uid;
    if ((uid ?? "").trim().isEmpty) {
      // NOT LOGGED IN
    } else {
      // LOGGED IN
      var uid = auth.currentUser?.uid ?? "";
      _userDetail(uid);
    }
    super.initState();
  }

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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