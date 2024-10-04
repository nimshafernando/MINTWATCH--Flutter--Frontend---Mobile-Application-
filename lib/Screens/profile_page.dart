import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:petsitter/Screens/FavoritesPage.dart';
import 'package:petsitter/Screens/add_product_screen.dart';
import 'package:petsitter/Screens/home_screen.dart';
import 'package:petsitter/Screens/listing.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final bioController = TextEditingController();
  final locationController = TextEditingController();

  bool isLoading = true;
  bool isEditing = false;
  bool _isDarkMode = false;
  String? profileImagePath;
  String coverImagePath = 'assets/cover.jpg'; // Set from assets

  int _currentIndex = 4; // Initialize to 4, as it's the profile screen's index

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Fetch user profile data
  Future<void> _fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('http://192.168.1.32:8000/api/profile'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            nameController.text = data['name'] ?? 'N/A';
            emailController.text = data['email'] ?? 'N/A';
            phoneNumberController.text = data['phone_number'] ?? '';
            bioController.text = data['bio'] ?? '';
            locationController.text = data['location'] ?? '';
            isLoading = false;
          });
        }
      } catch (error) {
        print('Error fetching profile data: $error');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Upload profile picture
  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImagePath = pickedFile.path;
      });
    }
  }

  // Update user profile
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token != null) {
        try {
          final response = await http.put(
            Uri.parse('http://192.168.1.32:8000/api/profile/update'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'name': nameController.text,
              'email': emailController.text,
              'phone_number': phoneNumberController.text,
              'bio': bioController.text,
              'location': locationController.text,
            }),
          );

          if (response.statusCode == 200) {
            _showSaveConfirmation(); // Show confirmation dialog
          }
        } catch (error) {
          print('Error updating profile: $error');
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  // Confirm save changes
  Future<void> _showSaveConfirmation() async {
    bool confirmSave = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Save Changes'),
          content: Text('Are you sure you want to save these changes?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel save
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm save
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
    if (confirmSave) {
      ElegantNotification.success(
        title: Text('Profile Saved'),
        description: Text('Your profile information has been updated.'),
        animation: AnimationType.fromTop,
      ).show(context);
    }
  }

  // Delete user account
  Future<void> _deleteAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      try {
        final response = await http.delete(
          Uri.parse('http://192.168.1.32:8000/api/profile/delete'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          _redirectToWelcome();
        }
      } catch (error) {
        print('Error deleting account: $error');
      }
    }
  }

  // Directly redirect to welcome screen after account deletion
  void _redirectToWelcome() {
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  // Confirm delete account
  Future<void> _confirmDeleteAccount() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel delete
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm delete
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
    if (confirmDelete) {
      _deleteAccount();
    }
  }

  // Show logout confirmation
  Future<void> _showLogoutConfirmation() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sign Out'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel logout
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
    if (confirmLogout) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Toggle dark mode
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Custom Bottom Navigation Bar with Routing
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

  // Handle Bottom NavBar Tap with Navigation
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
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Center(
            child: Image.asset('assets/logo.png', height: 40),
          ),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleDarkMode,
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
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  // Cover Image
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(coverImagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.black,
                          backgroundImage: profileImagePath != null
                              ? FileImage(File(profileImagePath!))
                              : null,
                          child: profileImagePath == null
                              ? Text(
                            nameController.text.isNotEmpty
                                ? nameController.text[0]
                                : 'A',
                            style: TextStyle(
                              fontSize: 50,
                              color: Colors.white,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Edit Profile Button at the bottom right of the cover image
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isEditing = true; // Enable edit mode
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue, // Background color
                          shape: BoxShape.circle, // Circular shape
                        ),
                        padding: EdgeInsets.all(10), // Size of the button
                        child: Icon(
                          Icons.edit,
                          size: 24, // Size of the edit icon
                          color: Colors.white, // Color of the icon
                        ),
                      ),
                    ),
                  ),

                  // Red Cross to exit edit mode when editing
                  if (isEditing)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isEditing = false; // Exit edit mode
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red, // Red background for the cross
                            shape: BoxShape.circle, // Circular shape
                          ),
                          padding: EdgeInsets.all(10), // Padding for the icon
                          child: Icon(
                            Icons.close,
                            size: 24, // Size of the cross icon
                            color: Colors.white, // Color of the icon
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        'Name',
                        nameController,
                        enabled: isEditing,
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        'Email',
                        emailController,
                        enabled: isEditing,
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        'Phone Number',
                        phoneNumberController,
                        enabled: isEditing,
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        'Bio',
                        bioController,
                        enabled: isEditing,
                        maxLines: 3,
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        'Location',
                        locationController,
                        enabled: isEditing,
                      ),
                      SizedBox(height: 40),

                      // Place "Delete My Account" and "Sign Out" buttons below location field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _confirmDeleteAccount,
                            icon: Icon(Icons.delete, color: Colors.white), // Icon color set to white
                            label: Text(
                              'Delete My Account',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white, // Text color set to white
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              fixedSize: Size(150, 50),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showLogoutConfirmation,
                            icon: Icon(Icons.logout, color: Colors.white), // Icon color set to white
                            label: Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white, // Text color set to white
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              fixedSize: Size(150, 50),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (isEditing)
                        ElevatedButton(
                          onPressed: _updateProfile,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            child: Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white, // Text color set to white
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNavBar(),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        hintText: label == 'Phone Number' ? 'e.g. +94123456789' : null,
        hintStyle: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    );
  }
}
