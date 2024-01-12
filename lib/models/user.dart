class CurrentUser {
  const CurrentUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.isAdmin,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String imageUrl;
  final bool isAdmin;

  CurrentUser.fromMap(Map<String, dynamic> data)
      : userId = data['userId'],
        firstName = data['firstName'],
        lastName = data['lastName'],
        email = data['email'],
        phone = data['phone'],
        imageUrl = data['imageUrl'],
        isAdmin = data['isAdmin'];

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'isAdmin': isAdmin,
    };
  }
}
