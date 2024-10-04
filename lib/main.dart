import 'package:flutter/material.dart';
import 'package:petsitter/Screens/EditProductScreen.dart';
import 'package:petsitter/Screens/add_product_screen.dart';
import 'package:petsitter/Screens/cart_screen.dart';
import 'package:petsitter/Screens/listing.dart'; // Import Listings Page
import 'package:petsitter/Screens/login_screen.dart';
import 'package:petsitter/Screens/register_screen.dart';
import 'package:petsitter/Screens/home_screen.dart';
import 'package:petsitter/Screens/welcome_screen.dart';
import 'package:petsitter/Screens/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electronics Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => WelcomeScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (context) => RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (context) => HomeScreen());
          case '/listings': // New route for Listings Page
            return MaterialPageRoute(builder: (context) => ListingsPage());
          case '/profile':
            return MaterialPageRoute(builder: (context) => ProfilePage());
          case '/add_product':
            return MaterialPageRoute(builder: (context) => AddProductScreen());
          case '/edit_product': // New route for Edit Product Screen
            return MaterialPageRoute(builder: (context) => EditProductScreen(product: settings.arguments as Map<String, dynamic>)); // Pass product data
          default:
            return MaterialPageRoute(builder: (context) => WelcomeScreen());
        }
      },
    );
  }
}
