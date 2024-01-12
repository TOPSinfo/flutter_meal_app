# Meal_app

This Flutter app for meal ordering simplifies the process with its intuitive design. Key features include phone login with OTP verification, user information management, browsing and managing meal categories, adding and editing individual meals with detailed descriptions, order placement and tracking, a shopping cart, and account settings.


![video](/Media/Flutter-Meal-App.gif)

# Technical details

- Project Name ==> Meal App
- Language   ==> Dart
- Database   ==> Firebase Phone Authentication, Firebase Firestore, Firebase Storage

# User App Description  

In the Phone Login/Registration screen, You need to enter the Phone Number and then you will get the OTP to the number that you entered and it will redirect you to the OTP screen. Once the OTP verification is done you will be redirected to the categories screen.

If the Entered Phone number is not registered then it will redirect to the Personal Detail screen where the user can add their Profile photo, First name, Last name, and Email.

In the Categories tab, the User can see the list of meal categories. Once the user taps on any category it will redirect to the Meals screen.

In the Meals screen, the User can see the list of meals available in selected categories. Once the user taps on any meal it will redirect to the Meal Detail screen.

In the Meal Detail Screen, the User can see the selected meal details like Meal Image, Ingredients and list of steps to prepare the meal. Users can also add the meal to the cart by pressing the Add to Cart button.

In the Cart tab, the User can see the list of meals which was added to the cart by the user. It will also show the Meal amount, Tax, and Delivery Fees. Users can place the order by pressing the Checkout button.

In the Settings tab, There are a few options like Profile, My Orders, Rate App and Logout.

In the Profile screen, the User can see the details like Profile photo, First name, Last name, and Email from where the user can modify all the details excluding Phone Number.

In the My Order screen, the User can see the list of orders placed by him. Tapping on any order it will redirect to the Order Detail screen.

In the Order Detail screen, the User can see the Order Status (Placed, Accepted, Preparing, Ready for Pickup, Out for Delivery, Delivered), and the list of meals the order contains.

Tapping on Rate App will ask the user to give a rating to the app.

Tapping on the Logout, the User will be logged out and redirected to the Phone login screen.

# Admin App Description 

In the Phone Login screen, You need to enter the Phone Number and then you will get the OTP to the number which you entered and it will redirect you to the OTP screen. Once the OTP verification is done you will be redirected to the orders screen which shows all orders.

Tapping on the order will redirect to the Order Detail screen where the admin can see the list of meals in the order and the option to change the Order status.

In the Categories tab, Admin can see the list of meal categories. Admin can add a new category by pressing the + button.

In the Add Category screen, the Admin can add a new category with category ID, name, and colour details.

Tapping on any category will redirect to the meals screen. Admin can delete a category from there by pressing the Delete button. Admin can add new meals by pressing the + button.

Tapping on any meal will redirect to the meal detail screen. Admin can edit/delete the meal by pressing the edit/delete button.

The Add Meal screen allows the admin to add new meals to the database. Users can provide the meal's name, image, ingredients, and steps.


# Admin Credential

- Phone Number  ==>  9999999999 
- OTP           ==>  123456

# User Credential

- Phone Number  ==>  8888888888
- OTP           ==>  123456


# Table of Contents

- Categories UI - List of available categories.
- Meal UI - List of meals in a category.
- Meal Detail UI - Detailed information about a meal, including ingredients, steps, and the ability to edit or delete the meal.

- Phone Login UI - It will validate with the phone number.
- OTP Verification UI - It will validate OTP. Once validation is done admin/user will be redirected to the Categories/Orders UI.
- Personal Detail UI - User can add their personal details.
- Categories UI - Admin/User can see the list of Categories.
- Add/Delete Category UI - Admin can add/delete the Category.
- Meals UI - Admin/User can see the list of Meals.
- Add/Edit Meal UI - Admin can add/delete the Meal.
- Meal Detail UI - Admin/User can see the meal detail screen.
- Orders UI - Admin/User can see user orders.
- Order Detail UI - Admin/User can see Order details.
- Cart UI - User can see their cart items.
- Setting UI - Admin/User can see the list of options.
- Profile UI - Admin/User can modify their details.
- Rate App UI - Admin/User can rate the app.
