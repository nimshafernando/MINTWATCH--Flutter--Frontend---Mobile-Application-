import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:petsitter/Screens/FavoritesPage.dart';
import 'package:petsitter/Screens/add_product_screen.dart';
import 'package:petsitter/Screens/listing.dart';
import 'package:petsitter/Screens/product_details_screen.dart';
import 'package:petsitter/Screens/profile_page.dart';
import 'package:petsitter/Screens/product_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> products = [];
  Set<String> categories = {}; // Use Set to avoid duplicate categories
  Set<String> selectedCategories = {}; // Track selected categories
  bool isLoading = true;
  Timer? _timer;
  int _currentIndex = 0;
  bool _isDarkMode = false;
  late TextEditingController searchController;
  late AnimationController _animationController;
  late PageController _pageController; // Controller for slideshow
  late PageController _reviewScrollController; // Controller for auto-scrolling reviews
  double _minPrice = 0.0;
  double _maxPrice = 10000.0;
  RangeValues _priceRange = RangeValues(0, 10000);

  List<String> availableNames = [];
  List<String> availableBrands = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _startPolling();
    searchController = TextEditingController();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _pageController = PageController(initialPage: 0); // Initialize PageController for slideshow
    _reviewScrollController = PageController(); // Initialize page controller for reviews

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page!.round() + 1) % 3; // Assuming 3 images
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }

      if (_reviewScrollController.hasClients) {
        int nextReview = (_reviewScrollController.page!.round() + 1) % 3; // Assuming 3 review cards
        _reviewScrollController.animateToPage(
          nextReview,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startPolling() {
    const duration = Duration(seconds: 2);
    _timer = Timer.periodic(duration, (Timer timer) {
      _fetchProducts();
    });
  }

  // Fetch products from the API
  Future<void> _fetchProducts() async {
    try {
      final productService = ProductService();
      final fetchedProducts = await productService.fetchProducts();
      setState(() {
        products = fetchedProducts.where((p) => p['status'] == 'approved').toList();
        categories = fetchedProducts
            .map<String>((product) => product['category'] ?? 'Unknown')
            .toSet(); // Dynamically generate unique categories

        // Extract names and brands for filtering
        availableNames = fetchedProducts
            .map<String>((product) => product['name'] ?? 'No Name')
            .toSet()
            .toList();
        availableBrands = fetchedProducts
            .map<String>((product) => product['brand'] ?? 'Unknown Brand')
            .toSet()
            .toList();

        // Set price range based on the products
        if (fetchedProducts.isNotEmpty) {
          _minPrice = fetchedProducts
              .map<double>((product) => double.parse(product['price'].toString()))
              .reduce((a, b) => a < b ? a : b);
          _maxPrice = fetchedProducts
              .map<double>((product) => double.parse(product['price'].toString()))
              .reduce((a, b) => a > b ? a : b);
          _priceRange = RangeValues(_minPrice, _maxPrice);
        }

        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching products: $error');
    }
  }

  // Filter products by category, search term, and price range
  List<dynamic> _filterProducts() {
    String searchQuery = searchController.text.toLowerCase();
    return products.where((product) {
      final matchesCategory = selectedCategories.isEmpty ||
          selectedCategories.contains(product['category']);
      final matchesSearch = searchQuery.isEmpty ||
          product['name'].toString().toLowerCase().contains(searchQuery) ||
          product['brand'].toString().toLowerCase().contains(searchQuery) ||
          product['category'].toString().toLowerCase().contains(searchQuery);
      final matchesPrice = double.parse(product['price'].toString()) >= _priceRange.start &&
          double.parse(product['price'].toString()) <= _priceRange.end;
      return matchesCategory && matchesSearch && matchesPrice;
    }).toList();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    _pageController.dispose(); // Dispose the page controller
    _reviewScrollController.dispose(); // Dispose review controller
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Updated bottom navigation routing
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

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Drawer with filters that fills the entire screen
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 50),
                SizedBox(height: 5),
                Text('Filter Products', style: TextStyle(color: Colors.white, fontSize: 24)),
              ],
            ),
          ),
          _buildFilterOption('Name', availableNames),
          _buildFilterOption('Brand', availableBrands),
          _buildPriceRangeSlider(), // Advanced Price Filter
          Spacer(), // This pushes the profile and logout buttons to the bottom
          _buildDrawerButton('Manage My Profile', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
          }),
          SizedBox(height: 10),
          _buildDrawerButton('Logout', () {
            // Logout logic
            Navigator.pushReplacementNamed(context, '/login');
          }),
          SizedBox(height: 20), // Adding space between buttons and bottom edge
        ],
      ),
    );
  }

  Widget _buildDrawerButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Price Range Slider with filtering logic
  Widget _buildPriceRangeSlider() {
    return Column(
      children: [
        Text("Price Range"),
        RangeSlider(
          values: _priceRange,
          min: _minPrice,
          max: _maxPrice,
          divisions: 20,
          labels: RangeLabels('${_priceRange.start.round()}', '${_priceRange.end.round()}'),
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterOption(String filterName, List<String> options) {
    return ExpansionTile(
      title: Text(filterName),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            setState(() {
              searchController.text = option;
            });
            Navigator.pop(context); // Close the drawer after selection
          },
        );
      }).toList(),
    );
  }

  // Search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
          hintText: 'Search products by name, brand, or category...',
          prefixIcon: Icon(Icons.search, color: Colors.black),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  // Horizontal scrollable list of categories with black background and white text
  Widget _buildCategoryList() {
    return Container(
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: Colors.white, // Text color is always white
                      ),
                    ),
                    selectedColor: Colors.grey,
                    backgroundColor: Colors.black,
                    selected: selectedCategories.contains(category),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          _buildClearButton(), // Clear button at the end of the category list
        ],
      ),
    );
  }


  // Clear button for categories
  Widget _buildClearButton() {
    return selectedCategories.isNotEmpty
        ? TextButton(
      onPressed: () {
        setState(() {
          selectedCategories.clear();
        });
      },
      child: Text('Clear', style: TextStyle(color: Colors.black)),
    )
        : SizedBox.shrink();
  }

  // Slideshow of images with automatic transitions
  Widget _buildSlideshow() {
    return Container(
      height: 300,
      child: PageView.builder(
        controller: _pageController, // Use the page controller
        itemCount: 3, // Number of images in the slideshow
        itemBuilder: (context, index) {
          return Image.asset(
            'assets/pic${index + 1}.jpg', // Assuming images are named pic1.jpg, pic2.jpg, etc.
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  // Light grey review cards with bigger profile image and text
  Widget _buildTestimonialCard(
      String avatar, String name, String designation, String testimony, {required Color color}) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black; // Adjust text color based on theme
    return Container(
      width: 300,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(12),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[300], // Light grey color for the card
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(avatar),
            radius: 60, // Increased size of profile image
          ),
          SizedBox(height: 15),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)), // Adjust text color
          Text(designation, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 10),
          Text(testimony, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textColor)), // Adjust text color
        ],
      ),
    );
  }

  // Testimonial section with auto-scrolling reviews
  Widget _buildTestimonialSection() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What People Are Saying',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 300, // Increased height for taller cards
            child: PageView.builder(
              controller: _reviewScrollController, // Auto-scroll reviews
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildTestimonialCard(
                  'assets/review${index + 1}.jpg', // Different images
                  'John Doe',
                  'Watch Specialist',
                  'I love Mint Watches. They have an amazing collection.',
                  color: Colors.primaries[index % Colors.primaries.length], // Different card colors
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // "Top Watch News" section
  Widget _buildTopWatchNewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Top Watch News',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, // Center the header
          ),
          SizedBox(height: 8),
          _buildNewsCard(
            'The Latest in Watch Trends',
            'Discover the top trends in luxury watches...',
            'assets/cover.jpg',
            'https://yourwatchnews.com/trends',
          ),
          SizedBox(height: 16),
          _buildNewsCard(
            'Vintage Watches on the Rise',
            'Find out why vintage watches are making a comeback...',
            'assets/cover.jpg',
            'https://yourwatchnews.com/vintage',
          ),
        ],
      ),
    );
  }

  // Build each news card
  Widget _buildNewsCard(String title, String description, String imagePath, String url) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 5),
                Text(description, style: TextStyle(fontSize: 14)),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => launch(url),
                  child: Text('Read more'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.black, shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the product grid listing
  Widget _buildProductGrid() {
    final filteredProducts = _filterProducts();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.7,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];

          List<dynamic> images;
          if (product['images'] is String) {
            images = json.decode(product['images']);
          } else if (product['images'] is List) {
            images = product['images'];
          } else {
            images = [];
          }

          String name = product['name'] ?? 'No Name';
          String brand = product['brand'] ?? 'Unknown Brand';
          String price = product['price'].toString();

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        'http://192.168.1.32:8000/storage/' + images[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          'LKR ${price}', // Changed to LKR
                          style: TextStyle(
                            color: Colors.green[700], // Green and bold
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // New custom bottom navigation bar design with square edges
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
          IconButton(
            icon: Icon(Icons.add, color: _currentIndex == 2 ? Colors.yellow : Colors.white),
            onPressed: () => _onNavBarTapped(2),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Center(child: Image.asset('assets/logo.png', height: 40)),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: _toggleDarkMode,
            ),
          ],
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.white,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: _buildDrawer(),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildSlideshow(),
              _buildSearchBar(), // Search bar added here
              _buildCategoryList(), // Horizontal scrollable categories
              _buildProductGrid(),
              _buildTestimonialSection(), // Auto-scrolling testimonials
              _buildTopWatchNewsSection(), // Top Watch News section
            ],
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNavBar(),
      ),
    );
  }
}
