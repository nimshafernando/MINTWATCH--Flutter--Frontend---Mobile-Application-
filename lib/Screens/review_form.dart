import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewForm extends StatefulWidget {
  final int productId;

  ReviewForm({required this.productId});

  @override
  _ReviewFormState createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final reviewController = TextEditingController();
  int _rating = 1; // Default rating value
  bool isLoading = false;
  bool _isDarkMode = false; // Dark mode toggle

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  // Submit the review
  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token != null) {
        final url = Uri.parse('http://192.168.1.32:8000/api/products/${widget.productId}/reviews');
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'rating': _rating,
            'review': reviewController.text,
          }),
        );

        if (response.statusCode == 201) {
          Navigator.pop(context); // Go back after successful submission
        } else {
          print('Failed to submit review');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to submit review. Please try again.'),
          ));
        }

        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Top Bar with Dark Mode Toggle and Logo
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[850],
      )
          : ThemeData.light(),
      home: Scaffold(
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Title
                Text(
                  'Write a Review',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),

                // Rating Dropdown
                Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                DropdownButtonFormField<int>(
                  value: _rating,
                  items: List.generate(5, (index) => index + 1)
                      .map((value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _rating = value!;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  dropdownColor: _isDarkMode ? Colors.grey[850] : Colors.white,
                ),
                SizedBox(height: 20),

                // Review Text Field
                TextFormField(
                  controller: reviewController,
                  decoration: InputDecoration(
                    labelText: 'Review',
                    labelStyle:
                    TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 5,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your review';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Submit Button
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitReview,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Text(
                      'Submit Review',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
