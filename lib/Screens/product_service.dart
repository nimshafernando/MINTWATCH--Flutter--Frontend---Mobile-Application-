import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  final String baseUrl = 'http://192.168.1.32:8000/api'; // Update with your correct API

  // Fetch all products
  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Fetch a single product by ID
  Future<dynamic> fetchProductById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load product');
    }
  }

  // Add a product (POST request)
  Future<void> addProduct(Map<String, dynamic> productData) async {
    final url = Uri.parse('$baseUrl/products');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(productData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add product');
    }
  }
}
