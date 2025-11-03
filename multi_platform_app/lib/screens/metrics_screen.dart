import 'package:flutter/material.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder content for demonstration; replace with your actual metrics UI
    return Scaffold(
      appBar: AppBar(title: const Text('Metrics')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Metrics Data Visualization Coming Soon',
                style: TextStyle(fontSize: 20, color: Colors.teal),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
