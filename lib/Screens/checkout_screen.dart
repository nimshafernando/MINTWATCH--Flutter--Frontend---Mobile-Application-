import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ThankYouPage.dart'; // Import Thank You page

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  CheckoutScreen({required this.product});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for card details
  final cardNumberController = TextEditingController();
  final cardExpiryController = TextEditingController();
  final cardCvvController = TextEditingController();

  bool isLoading = false;

  // Function to handle payment process and store in the backend
  Future<void> processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true; // Show loading while processing payment
      });

      try {
        // Retrieve token from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('access_token');

        if (token == null) {
          // Handle missing token error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication token not found.')),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }

        final url = Uri.parse('http://192.168.8.136:8000/api/payments'); // Your API endpoint

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'product_id': widget.product['id'], // Pass product ID
            'state': 'paid', // Payment state
          }),
        );

        if (response.statusCode == 201) {
          // Payment success, navigate to Thank You page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ThankYouPage(product: widget.product),
            ),
          );
        } else {
          // Print server error details
          print('Server response: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: ${response.reasonPhrase}. Please try again.')),
          );
        }
      } catch (e) {
        print('Error processing payment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again.')),
        );
      } finally {
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Product: ${widget.product['name']}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildTextField('Card Number', cardNumberController),
              SizedBox(height: 16),
              _buildTextField('Expiry Date', cardExpiryController),
              SizedBox(height: 16),
              _buildTextField('CVV', cardCvvController, isPassword: true),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: processPayment, // Call payment function
                child: Text('Proceed to Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build input fields
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }
}
