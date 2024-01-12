class Cart {
  const Cart({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.quantity,
  });

  final String id;
  final String title;
  final int price;
  final String image;
  final int quantity;

  factory Cart.fromMap(Map<String, dynamic> data) {
    return Cart(
      id: data['id'],
      title: data['title'],
      price: data['price'],
      image: data['image'],
      quantity: data['quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'quantity': quantity,
      'image': image,
    };
  }
}

class Orders {
  Orders({
    required this.id,
    required this.status,
    required this.cartItems,
    required this.userId,
    required this.orderDate,
    required this.amount,
  });

  final String id;
  final String status;
  final List<Cart> cartItems;
  final String userId;
  final int orderDate;
  final double amount;

  factory Orders.fromMap(Map<String, dynamic> data) {
    List<dynamic> itemsJson = data['cartItems'];
    List<Cart> items = itemsJson.map((item) => Cart.fromMap(item)).toList();

    return Orders(
        id: data['id'],
        status: data['status'],
        cartItems: items,
        userId: data['userId'],
        orderDate: data['orderDate'],
        amount: data['amount']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'cartItems': cartItems.map((item) => item.toMap()).toList(),
      'userId': userId,
      'orderDate': orderDate,
      'amount': amount
    };
  }
}
