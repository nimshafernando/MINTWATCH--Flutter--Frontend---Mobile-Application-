import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petsitter/Screens/review_form.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailsScreen({required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  List<dynamic> reviews = [];
  bool isLoadingReviews = true;
  bool isFavorite = false;
  int currentImageIndex = 0;
  late Timer _timer;
  bool _isImageExpanded = false;
  Offset _fabPosition = Offset(50, 600);
  double averageRating = 0.0;
  bool _isDarkMode = false; // Toggle dark mode

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _checkIfFavorite();
    _startImageSlider();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Start image slider timer
  void _startImageSlider() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      setState(() {
        currentImageIndex = (currentImageIndex + 1) % _getImages().length;
      });
    });
  }

  // Fetch reviews for the product and calculate average rating
  Future<void> _fetchReviews() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.32:8000/api/products/${widget.product['id']}/reviews'),
      );

      if (response.statusCode == 200) {
        setState(() {
          reviews = json.decode(response.body);
          isLoadingReviews = false;

          // Calculate average rating
          if (reviews.isNotEmpty) {
            double totalRating = 0;
            for (var review in reviews) {
              totalRating += double.tryParse(review['rating'].toString()) ?? 0;
            }
            averageRating = totalRating / reviews.length;
          }
        });
      } else {
        setState(() {
          isLoadingReviews = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoadingReviews = false;
      });
    }
  }

  // Check if the product is already marked as favorite
  Future<void> _checkIfFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('http://192.168.1.32:8000/api/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> favoriteProducts = json.decode(response.body);
        setState(() {
          isFavorite = favoriteProducts
              .any((favorite) => favorite['product']['id'] == widget.product['id']);
        });
      }
    }
  }

  // Toggle favorite status and show notification
  Future<void> _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      final response = await http.post(
        Uri.parse('http://192.168.1.32:8000/api/products/${widget.product['id']}/toggle-favorite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isFavorite = !isFavorite;
        });
        _showSuccessNotification(isFavorite
            ? 'Product added to favorites'
            : 'Product removed from favorites');
      } else {
        _showErrorNotification('Failed to update favorites.');
      }
    }
  }

  // Handle images field safely
  List<dynamic> _getImages() {
    if (widget.product['images'] is String) {
      return json.decode(widget.product['images']);
    } else if (widget.product['images'] is List) {
      return widget.product['images'];
    } else {
      return [];
    }
  }

  // Format the review time ago
  String _timeAgo(String dateTime) {
    DateTime postedDate = DateTime.parse(dateTime).toLocal();
    final now = DateTime.now();
    final difference = now.difference(postedDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Launch call or SMS actions
  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Share the product
  // Share the product with a custom link
  void _shareProduct() {
    // Assuming the product ID is included in widget.product['id']
    final productId = widget.product['id'];

    // Replace this with your actual domain
    final productUrl = 'https://www.the1916company.com/rolex/lady-datejust/';

    // Share the custom message with the product link
    Share.share('Check out this watch on MintWatch: $productUrl');
  }


  // Show success notification
  void _showSuccessNotification(String message) {
    ElegantNotification.success(
      title: Text('Success'),
      description: Text(message),
      animation: AnimationType.fromTop,
    ).show(context);
  }

  // Show error notification
  void _showErrorNotification(String message) {
    ElegantNotification.error(
      title: Text('Error'),
      description: Text(message),
      animation: AnimationType.fromBottom,
    ).show(context);
  }

  // Toggle dark mode
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    bool isLandscape = screenSize.width > screenSize.height;
    List<dynamic> images = _getImages();

    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black, // Black top bar
          title: Center(
            child: Image.asset('assets/logo.png', height: 40), // Logo in center
          ),
          actions: [
            // Dark Mode Toggle Button
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleDarkMode, // Toggle light/dark mode
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
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Image Section with Floating Action Buttons
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isImageExpanded = !_isImageExpanded;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _isImageExpanded ? (isLandscape ? 400 : 500) : 300,
                      child: Stack(
                        children: [
                          PageView.builder(
                            onPageChanged: (index) {
                              setState(() {
                                currentImageIndex = index;
                              });
                            },
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                'http://192.168.1.32:8000/storage/' + images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            },
                          ),
                          // Dots Indicator
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (index) {
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  width: currentImageIndex == index ? 12 : 8,
                                  height: currentImageIndex == index ? 12 : 8,
                                  decoration: BoxDecoration(
                                    color: currentImageIndex == index
                                        ? Colors.black
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ),
                          // Favorite and Share Floating Action Buttons
                          Positioned(
                            right: 10,
                            bottom: 40,
                            child: Column(
                              children: [
                                FloatingActionButton(
                                  mini: true,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: _toggleFavorite,
                                ),
                                SizedBox(height: 10),
                                FloatingActionButton(
                                  mini: true,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.share, color: Colors.blue),
                                  onPressed: _shareProduct, // Share product
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Product Information Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product['name'],
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto'),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'LKR ${widget.product['price']}',
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.green,
                              fontFamily: 'Roboto'),
                        ),
                        SizedBox(height: 8),
                        // Brand and Category Section
                        Text(
                          'Brand: ${widget.product['brand']}',
                          style: TextStyle(fontSize: 18, fontFamily: 'Roboto'),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Category: ${widget.product['category']}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto'),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Description Section
                        Text(
                          'Description:',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto'),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.product['description'] ??
                              'No description available.',
                          style: TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                        ),
                        SizedBox(height: 20),

                        // Reviews Section inside Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.orangeAccent),
                                    SizedBox(width: 5),
                                    Text(
                                      'Reviews (${averageRating.toStringAsFixed(1)})',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Roboto'),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                isLoadingReviews
                                    ? Center(child: CircularProgressIndicator())
                                    : reviews.isEmpty
                                    ? Text('No reviews yet')
                                    : Column(
                                  children: reviews.map((review) {
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      color: _isDarkMode ? Colors.grey[800] : Colors.orange[50], // Ensure visibility in dark mode
                                      margin: EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                          Colors.blueAccent,
                                          child: Text(
                                            review['user']['name']
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                        title: Text(
                                            review['user']['name'] ??
                                                'Anonymous',
                                            style: TextStyle(
                                                color: _isDarkMode
                                                    ? Colors.white
                                                    : Colors.black)), // Adjust text color for dark mode
                                        subtitle: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review['review'],
                                              style: TextStyle(
                                                color: _isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ), // Adjust text color
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              _timeAgo(review[
                                              'created_at']),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                SizedBox(height: 20),

                                // Dark Blue "Write a Review" Button
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewForm(
                                              productId: widget.product['id']),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Write a Review',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white), // White text
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: StadiumBorder(), backgroundColor: Colors.blue[900], // Dark Blue Color
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 15,
                                      ),
                                      textStyle: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // "Are you interested?" Section with Call and SMS
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Are you interested?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _launchURL('tel:076804769');
                                    },
                                    icon: Icon(Icons.call),
                                    label: Text('Call'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white, backgroundColor: Colors.blueAccent,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _launchURL('sms:076804769');
                                    },
                                    icon: Icon(Icons.sms),
                                    label: Text('SMS'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white, backgroundColor: Colors.orangeAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
