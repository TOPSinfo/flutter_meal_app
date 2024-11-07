// NO DATA FOUND WIDGET
import 'package:flutter/material.dart';

Widget noDataWidget(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Uh oh ... nothing here!',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Try selecting a different category!',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    ),
  );
}
