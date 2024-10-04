import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:petsitter/Screens/listing.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petsitter/Screens/home_screen.dart';
import 'package:petsitter/Screens/FavoritesPage.dart';
import 'package:petsitter/Screens/add_product_screen.dart';
import 'package:petsitter/Screens/profile_page.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> favoriteProducts = [];
  bool isLoading = true;
  int _currentIndex = 1; // Set current index for Favorites in the bottom navbar
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteProducts(); // Fetch the user's favorite products
  }

  Future<void> _fetchFavoriteProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('http://192.168.1.32:8000/api/favorites'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            favoriteProducts = json.decode(response.body);
            isLoading = false;
          });
        } else {
          print('Failed to load favorites');
          setState(() {
            isLoading = false;
          });
        }
      } catch (error) {
        print('Error fetching favorites: $error');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _unfavoriteProduct(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      try {
        final response = await http.delete(
          Uri.parse('http://192.168.1.32:8000/api/favorites/$productId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            favoriteProducts.removeWhere((product) => product['product']['id'] == productId);
          });
          print('Product unfavorited successfully');
        } else {
          print('Failed to unfavorite product');
        }
      } catch (error) {
        print('Error unfavoriting product: $error');
      }
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: Center(
        child: Image.asset('assets/logo.png', height: 40), // Logo in center
      ),
      actions: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
        ),
        SizedBox(width: 10),
      ],
      leading: Container(
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white, // White background for the back button
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black), // Black arrow
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.zero), // Square edges
      ),
      height: 65,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.home, color: _currentIndex == 0 ? Colors.yellow : Colors.white),
            onPressed: () => _onNavBarTapped(0),
          ),
          IconButton(
            icon: Icon(Icons.favorite, color: _currentIndex == 1 ? Colors.yellow : Colors.white),
            onPressed: () => _onNavBarTapped(1),
          ),
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 4), // Yellow circle for + button
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.black),
              onPressed: () => _onNavBarTapped(2),
            ),
          ),
          IconButton(
            icon: Icon(Icons.list, color: _currentIndex == 3 ? Colors.yellow : Colors.white),
            onPressed: () => _onNavBarTapped(3),
          ),
          IconButton(
            icon: Icon(Icons.person, color: _currentIndex == 4 ? Colors.yellow : Colors.white),
            onPressed: () => _onNavBarTapped(4),
          ),
        ],
      ),
    );
  }

  void _onNavBarTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FavoritesPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddProductScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ListingsPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product, Color neonColor) {
    String name = product['name'] ?? 'No Name';
    String price = product['price'].toString();
    String category = product['category'] ?? 'Unknown Category';
    String description = product['description'] ?? 'No Description';
    int productId = product['id'];

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      color: neonColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: IconButton(
                icon: Icon(Icons.favorite, color: Colors.red, size: 40), // Red heart icon
                onPressed: () => _unfavoriteProduct(productId), // Unfavorite on press
              ),
            ),
            SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black, // Change text color based on dark mode
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Price: LKR $price',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black, // Change text color based on dark mode
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Category: $category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white70 : Colors.black, // Change text color based on dark mode
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Description: $description',
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white70 : Colors.grey[700], // Change description color based on dark mode
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Color> neonColors = [Colors.greenAccent, Colors.pinkAccent, Colors.cyanAccent, Colors.amberAccent, Colors.purpleAccent];

    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Dark mode background for content
        cardColor: Colors.grey[850], // Dark mode for cards
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // White text in dark mode
        ),
      ) : ThemeData.light(),
      home: Scaffold(
        appBar: _buildAppBar(),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : favoriteProducts.isEmpty
            ? Center(child: Text('No favorite products found', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)))
            : ListView.builder(
          itemCount: favoriteProducts.length,
          itemBuilder: (context, index) {
            final product = favoriteProducts[index]['product'];
            Color neonColor = neonColors[index % neonColors.length]; // Cycle through neon colors
            return _buildProductCard(product, neonColor);
          },
        ),
        bottomNavigationBar: _buildCustomBottomNavBar(),
      ),
    );
  }
}
