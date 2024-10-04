import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Add shared_preferences for token storage

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final url = Uri.parse('http://192.168.1.32:8000/api/login'); // Replace with your API URL
    final data = {
      'email': emailController.text,
      'password': passwordController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final loginResponse = json.decode(response.body);

        String loginToken = loginResponse['login_token'];
        String customToken = loginResponse['custom_token'];

        print('Login Token: $loginToken');
        print('Custom Token: $customToken');

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', loginToken);
        await prefs.setString('custom_token', customToken);

        _showSuccessDialog('Login successful. Tokens saved.');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorDialog('Login failed. Please try again.');
      }
    } catch (e) {
      print('Exception: $e');
      _showErrorDialog('An error occurred. Please check your connection and try again.');
    }
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
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.black, // Black background for both modes
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // White background for input fields in both modes
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue), // Blue outline for input fields
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.grey[800]), // Dark grey text
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Center(
            child: Image.asset('assets/logo.png', height: 40), // Logo
          ),
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
                        child: Image.asset('assets/logo.png', height: 80),
                      ),
                      SizedBox(height: 30),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue, // Blue color for "Welcome Back"
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Log in to your account.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue, // Blue color for "Log in to your account."
                        ),
                      ),
                      SizedBox(height: 30),
                      _buildTextField('Email', emailController),
                      SizedBox(height: 20),
                      _buildTextField('Password', passwordController, isPassword: true),
                      SizedBox(height: 20),
                      // Login button
                      ElevatedButton(
                        onPressed: _login,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // White text for login button
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50), // Make button longer
                          backgroundColor: Colors.blue, // Blue button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Add text below Login button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800], // Dark grey text for both modes
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/register');
                            },
                            child: Text(
                              'Click here',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue, // Blue text link for both modes
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

  // Helper to build a text field
  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: TextInputType.text,
      style: TextStyle(color: Colors.black), // Black text for both modes
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue), // Blue label text for both modes
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue), // Blue border for both modes
        ),
      ),
    );
  }
}
