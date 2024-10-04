import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String userType = 'Buyer'; // Default user type
  bool _isDarkMode = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: Duration(seconds: 1));
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final url = Uri.parse('http://192.168.1.32:8000/api/register');
    final data = {
      'name': nameController.text,
      'email': emailController.text,
      'password': passwordController.text,
      'password_confirmation': confirmPasswordController.text,
      'user_type': userType, // Send user_type (Buyer/Seller)
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final registrationResponse = json.decode(response.body);
        print('Registration successful: $registrationResponse');
        _showSuccessDialog('Registration successful!');
      } else {
        print('Error: ${response.statusCode} - ${response.reasonPhrase}');
        _showErrorDialog('Registration failed. Please try again.');
      }
    } catch (e) {
      print('Exception: $e');
      _showErrorDialog('An error occurred. Please check your connection and try again.');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Okay'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Okay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900], // Lighter grey for dark mode
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // White background for input fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue), // Blue border in dark mode
          ),
        ),
      )
          : ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.black, // Black for light mode
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // White background for input fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue), // Blue border in light mode
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
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
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 50),
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 80,
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        'Welcome to Mint Watch',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Register now to experience the best!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 30),
                      _buildTextField('Name', nameController, _isDarkMode),
                      SizedBox(height: 20),
                      _buildTextField('Email', emailController, _isDarkMode,
                          inputType: TextInputType.emailAddress),
                      SizedBox(height: 20),
                      _buildTextField('Password', passwordController, _isDarkMode,
                          isPassword: true),
                      SizedBox(height: 20),
                      _buildTextField('Confirm Password', confirmPasswordController,
                          _isDarkMode, isPassword: true),
                      SizedBox(height: 20),
                      _buildDropdown(_isDarkMode),
                      SizedBox(height: 20),
                      // Register button is now positioned below the UserType dropdown and is longer
                      ElevatedButton(
                        onPressed: _register,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50), // Make the button longer
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Add text below Register button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontSize: 16,
                              color: _isDarkMode ? Colors.white : Colors.blue,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              'Click here',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDarkMode,
      {bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(bool isDarkMode) {
    return DropdownButtonFormField<String>(
      value: userType,
      items: ['Buyer', 'Seller']
          .map((value) => DropdownMenuItem<String>(
        value: value,
        child: Text(
          value,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          userType = value!;
        });
      },
      dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
      decoration: InputDecoration(
        labelText: 'User Type',
        labelStyle: TextStyle(color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}
