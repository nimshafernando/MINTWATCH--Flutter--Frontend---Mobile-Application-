import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:petsitter/Screens/EditProductScreen.dart';
import 'package:petsitter/Screens/home_screen.dart';
import 'package:petsitter/Screens/FavoritesPage.dart';
import 'package:petsitter/Screens/add_product_screen.dart';
import 'package:petsitter/Screens/profile_page.dart';

class ListingsPage extends StatefulWidget {
  @override
  _ListingsPageState createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  int _currentIndex = 3; // Set the current index to reflect Listings as the active page
  bool _isDarkMode = false;

  // Define category colors for consistency
  Map<String, Color> categoryColors = {
    'Electronics': Colors.orange,
    'Clothing': Colors.purple,
    'Toys': Colors.blue,
    // Add more categories as needed
  };

  @override
  void initState() {
    super.initState();
    _fetchUserProducts(); // Fetch products posted by the logged-in user
  }

  Future<void> _fetchUserProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token'); // Retrieve the token

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('http://192.168.1.32:8000/api/user/products'), // API endpoint to fetch user products
          headers: {
            'Authorization': 'Bearer $token', // Send the token in the header
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            products = data; // Store products in the state
            isLoading = false; // Stop loading
          });
        } else {
          print('Failed to load products');
          setState(() {
            isLoading = false;
          });
        }
      } catch (error) {
        print('Error fetching products: $error');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsPaid(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token'); // Retrieve the token

    if (token != null) {
      try {
        final response = await http.put(
          Uri.parse('http://192.168.1.32:8000/api/products/$productId/mark-paid'), // API endpoint to mark product as paid
          headers: {
            'Authorization': 'Bearer $token', // Send the token in the header
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          print('Product marked as paid');
          setState(() {
            products = products.map((product) {
              if (product['id'] == productId) {
                product['payment_status'] = 'paid';
                product['updated_at'] = DateTime.now().toIso8601String();
              }
              return product;
            }).toList();
          });
        } else {
          print('Failed to mark as paid');
        }
      } catch (error) {
        print('Error marking as paid: $error');
      }
    }
  }

  void _navigateToEditScreen(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product), // Pass the product to the Edit screen
      ),
    );
  }

  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return DateFormat('yyyy-MM-dd HH:mm').format(date); // Format to YYYY-MM-DD HH:MM
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

  @override
  Widget build(BuildContext context) {
    List<dynamic> pendingProducts = products.where((p) => p['status'] == 'pending').toList();
    List<dynamic> approvedProducts = products.where((p) => p['status'] == 'approved').toList();
    List<dynamic> declinedProducts = products.where((p) => p['status'] == 'declined').toList();

    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Dark mode background for content
      ) : ThemeData.light(),
      home: Scaffold(
        appBar: _buildAppBar(),
        body: isLoading
            ? Center(child: CircularProgressIndicator()) // Show loading indicator
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Pending Listings'),
              _buildProductList(pendingProducts, 'assets/pending.png', Colors.yellow),
              _buildSectionHeader('Approved Listings'),
              _buildProductList(approvedProducts, 'assets/mark.png', Colors.green),
              _buildSectionHeader('Declined Listings'),
              _buildProductList(declinedProducts, 'assets/cancel.png', Colors.red),
            ],
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNavBar(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductList(List<dynamic> products, String statusIcon, Color statusColor) {
    return products.isEmpty
        ? Center(child: Text('No products found in this section'))
        : ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        String name = product['name'] ?? 'No Name';
        String price = product['price'].toString();
        String description = product['description'] ?? 'No Description';
        String category = product['category'] ?? 'Unknown Category';
        String paymentStatus = product['payment_status'] ?? 'unpaid';
        String updatedAt = _formatDate(product['updated_at']); // Format updated time

        return Card(
          color: statusColor.withOpacity(0.2), // Set card color based on status
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 80, // Increased image size
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: AssetImage(statusIcon), // Status icon
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Price: LKR $price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(description, style: TextStyle(fontSize: 14)),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColors[category] ?? Colors.grey,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (product['status'] == 'approved')
                                ElevatedButton.icon(
                                  onPressed: paymentStatus == 'paid'
                                      ? null
                                      : () => _markAsPaid(product['id']),
                                  icon: Icon(Icons.attach_money),
                                  label: Text(paymentStatus == 'paid' ? 'Paid' : 'Paid?'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(100, 35),
                                    backgroundColor: Colors.green[700],
                                  ),
                                ),
                              ElevatedButton(
                                onPressed: () => _navigateToEditScreen(product),
                                child: Text('Edit Listing'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(100, 35),
                                  backgroundColor: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              'Updated: $updatedAt',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
