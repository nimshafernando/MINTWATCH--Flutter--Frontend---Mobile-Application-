import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> pastOrders;

  HistoryPage({required this.pastOrders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase History'),
      ),
      body: ListView.builder(
        itemCount: pastOrders.length,
        itemBuilder: (context, index) {
          final order = pastOrders[index];
          return ListTile(
            title: Text(order['name']),
            subtitle: Text('Paid: \$${order['price']}'),
            trailing: Text(order['date']),
          );
        },
      ),
    );
  }
}
