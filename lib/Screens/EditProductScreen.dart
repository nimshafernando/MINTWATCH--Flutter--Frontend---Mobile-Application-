import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io'; // To handle file
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product; // Product to edit

  EditProductScreen({required this.product});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture form input
  late TextEditingController nameController;
  late TextEditingController brandController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController categoryController;
  late TextEditingController descriptionController;

  List<XFile>? _selectedImages = []; // Store multiple selected images
  bool isLoading = false;
  bool _isDarkMode = false; // Toggle dark mode

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the current product data
    nameController = TextEditingController(text: widget.product['name']);
    brandController = TextEditingController(text: widget.product['brand']);
    priceController = TextEditingController(text: widget.product['price'].toString());
    stockController = TextEditingController(text: widget.product['stock'].toString());
    categoryController = TextEditingController(text: widget.product['category']);
    descriptionController = TextEditingController(text: widget.product['description']);
  }

  // Function to pick multiple images from the gallery
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

  // Function to update the product via the API
  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      final url = Uri.parse('http://192.168.1.32:8000/api/products/${widget.product['id']}');

      var request = http.MultipartRequest('POST', url);
      request.fields['_method'] = 'PUT'; // Laravel expects this for updates

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

        if (response.statusCode == 200) {
          ElegantNotification.success(
            title: Text('Product Updated'),
            description: Text('Your product has been successfully updated.'),
            animation: AnimationType.fromTop,
          ).show(context);

          Navigator.pop(context); // Go back after successful update
        } else {
          print('Failed to update product');
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
      theme: _isDarkMode ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Dark mode background for content
        cardColor: Colors.grey[850], // Dark color for cards
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // White text in dark mode
        ),
      ) : ThemeData.light(),
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
                // Header
                Center(
                  child: Text(
                    'Edit Your Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                _buildTextField('Product Name', nameController),
                _buildTextField('Brand', brandController),
                _buildTextField('Price', priceController, keyboardType: TextInputType.number),
                _buildTextField('Stock', stockController, keyboardType: TextInputType.number),
                _buildTextField('Category', categoryController),
                _buildTextField('Description', descriptionController, maxLines: 3),

                SizedBox(height: 20),

                // Pick Product Images
                Text(
                  'Edit Product Images',
                  style: TextStyle(fontSize: 18, color: _isDarkMode ? Colors.white : Colors.black),
                ),
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

                // Update Product Button
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _updateProduct,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Text(
                      'Update Product',
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
          labelStyle: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
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
