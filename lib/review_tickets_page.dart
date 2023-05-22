import 'package:flutter/material.dart';

class ReviewTicketsPage extends StatefulWidget {
  const ReviewTicketsPage({super.key});

  @override
  State<ReviewTicketsPage> createState() => _ReviewTicketsPageState();
}

class _ReviewTicketsPageState extends State<ReviewTicketsPage> {
  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(title: const Text('Review Tickets'),),
      body: const Center(child: Text('Review Tickets content goes here')),
    );
  }
  }
