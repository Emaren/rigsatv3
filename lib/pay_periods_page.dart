import 'package:flutter/material.dart';

class PayPeriodsPage extends StatefulWidget {
  const PayPeriodsPage({super.key});

  @override
  _PayPeriodsPageState createState() => _PayPeriodsPageState();
}

class _PayPeriodsPageState extends State<PayPeriodsPage> {
  @override
  Widget build(BuildContext context) {
    DateTime startDate = DateTime(2023, 1, 9);
    List<DateTime> payPeriodDates = [];

    while (startDate.isBefore(DateTime.now())) {
      DateTime endDate = startDate.add(const Duration(days: 14));
      payPeriodDates.add(startDate);
      payPeriodDates.add(endDate);
      startDate = endDate.add(const Duration(days: 1));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Pay Periods'),
      ),
      body: ListView.builder(
        itemCount: payPeriodDates.length ~/ 2,
        itemBuilder: (context, index) {
          DateTime startDate = payPeriodDates[index * 2];
          DateTime endDate = payPeriodDates[index * 2 + 1];
          return ListTile(
            title: Text(
              'Pay Period ${index + 1}: ${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day}',
            ),
          );
        },
      ),
    );
  }
}
