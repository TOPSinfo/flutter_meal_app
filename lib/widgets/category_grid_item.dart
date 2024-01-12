import 'package:flutter/material.dart';
import 'package:meal_app/main.dart';
import '../models/category.dart';

class CategoryGridItem extends StatelessWidget {
  const CategoryGridItem({
    super.key,
    required this.category,
    required this.onSelectCategory,
  });

  final Categoryy category;
  final void Function() onSelectCategory;

  @override
  Widget build(BuildContext context) {
    Widget titleWidget(BuildContext context) {
      return Text(
        category.title,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
            ),
      );
    }

    return InkWell(
      onTap: onSelectCategory,
      splashColor: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                HexColor.fromHex(category.color).withOpacity(0.55),
                HexColor.fromHex(category.color).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )),
        child: titleWidget(context),
      ),
    );
  }
}
