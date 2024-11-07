import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

String greenColor = "21A558";
String pinkColor = "E91E63";

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color.fromARGB(255, 131, 57, 0),
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: Colors.white,
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);
