import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // To handle file
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture form input
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();

  List<XFile>? _selectedImages = []; // Store multiple selected images
  bool isLoading = false;
  bool _isDarkMode = false; // Toggle dark mode

  // Function to pick multiple images from gallery
  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage(); // Multiple image selection

    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles;
      });
    }
  }

  // Function to capture image from camera
  Future<void> _captureImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImages!.add(XFile(pickedFile.path));
      });
    }
  }

  // Function to add the product to the API
  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      final url = Uri.parse('http://192.168.1.32:8000/api/products');

      var request = http.MultipartRequest('POST', url);

      // Add text fields to the request
      request.fields['name'] = nameController.text;
      request.fields['brand'] = brandController.text;
      request.fields['price'] = priceController.text;
      request.fields['stock'] = stockController.text;
      request.fields['category'] = categoryController.text;
      request.fields['description'] = descriptionController.text;

      // Add the images to the request
      if (_selectedImages != null && _selectedImages!.isNotEmpty) {
        for (var image in _selectedImages!) {
          var imageStream = http.ByteStream(File(image.path).openRead());
          var imageLength = await File(image.path).length();

          var multipartFile = http.MultipartFile(
            'images[]', // The field name expected in Laravel
            imageStream,
            imageLength,
            filename: image.path.split('/').last,
          );

          request.files.add(multipartFile);
        }
      }

      try {
        var response = await request.send();

        if (response.statusCode == 201) {
          ElegantNotification.success(
            title: Text('Product Added'),
            description: Text('Your product is under admin moderation.'),
            animation: AnimationType.fromTop,
          ).show(context);

          Navigator.pop(context); // Go back after successful addition
        } else {
          print('Failed to add product');
        }
      } catch (e) {
        print('Error: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Toggle dark mode
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black, // Black top bar
          title: Center(
            child: Image.asset('assets/logo.png', height: 40), // Logo in center
          ),
          actions: [
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Step Dots with horizontal lines
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStepDot('Step 1', 'Fill Details', true),
                    Expanded(child: Divider(color: Colors.blue, thickness: 2)),
                    _buildStepDot('Step 2', 'Approval', false),
                    Expanded(child: Divider(color: Colors.blue, thickness: 2)),
                    _buildStepDot('Step 3', 'On Homepage', false),
                  ],
                ),
                SizedBox(height: 20),

                _buildTextField('Watch Name', nameController),
                _buildTextField('Brand', brandController),
                _buildTextField('Price', priceController, keyboardType: TextInputType.number),
                _buildTextField('Stock', stockController, keyboardType: TextInputType.number),
                _buildTextField('Model', categoryController),
                _buildTextField('Description', descriptionController, maxLines: 3),

                SizedBox(height: 20),

// Pick Product Images
                Text('Add Watch Images', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),

// Image Picker with Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImagePickerCard('Gallery', Icons.photo_library, Colors.blue, _pickImages),
                    _buildImagePickerCard('Camera', Icons.camera_alt, Colors.red, _captureImage),
                  ],
                ),

                SizedBox(height: 20),

// Display selected images
                if (_selectedImages != null && _selectedImages!.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    children: _selectedImages!.map((image) {
                      return Image.file(
                        File(image.path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      );
                    }).toList(),
                  ),
                SizedBox(height: 20),

// Add Product Button
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _addProduct,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Text(
                      'Add Product',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white, // Set text color to white
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build step dots
  Widget _buildStepDot(String step, String description, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Text(step.split(' ')[1], style: TextStyle(color: Colors.white)),
        ),
        SizedBox(height: 5),
        Text(description, style: TextStyle(fontSize: 12, color: isActive ? Colors.black : Colors.grey)),
      ],
    );
  }

  // Helper method to build image picker cards
  Widget _buildImagePickerCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            SizedBox(height: 10),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
