import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewTimePage extends StatefulWidget {
  const ReviewTimePage({super.key});

  @override
  _ReviewTimePageState createState() => _ReviewTimePageState();
}

class _ReviewTimePageState extends State<ReviewTimePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<Map<String, dynamic>> payDatesData = [];

  @override
  void initState() {
    super.initState();
    _loadPayDatesData(userId);
  }

  Future<void> _loadPayDatesData(String userId) async {
  QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
      .collection('hour_entries')
      .where('userId', isEqualTo: userId)
      .get();

  DateTime start = DateTime(2023, 4, 9);
  DateTime end = DateTime(2023, 4, 23);
  int daysDifference = end.difference(start).inDays + 1;
  List<Map<String, dynamic>> loadedData = List.generate(daysDifference, (index) {
    DateTime currentDate = start.add(Duration(days: index));
    Map<String, dynamic> defaultData = {
      'date': currentDate.toIso8601String(),
      'startHour': 0,
      'startMinute': 0,
      'endHour': 0,
      'endMinute': 0,
      'lunchTaken': false,
    };
    return defaultData;
  });

  for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot.docs) {
    Map<String, dynamic> data = doc.data();
DateTime date = DateTime.parse(data['date'] ?? '1970-01-01');
    int index = date.difference(start).inDays;
    if (index >= 0 && index < loadedData.length) {
      loadedData[index] = data;
    }
  }

  setState(() {
    payDatesData = loadedData;
  });
}

 @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity!.isNegative) {
          // Swiped from left to right
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Review Time",
            style: GoogleFonts.robotoSlab(
              textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF87CEEB),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF87CEEB), Color(0xFF6495ED)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView.builder(
            itemCount: payDatesData.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = payDatesData[index];

              DateTime date = DateTime.parse(data['date']);
                TimeOfDay startTime = TimeOfDay(
    hour: data['startHour'] ?? 0,
    minute: data['startMinute'] ?? 0,
  );
  TimeOfDay endTime = TimeOfDay(
    hour: data['endHour'] ?? 0,
    minute: data['endMinute'] ?? 0,
  );

              bool lunchTaken = data['lunchTaken'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      "Pay date: ${date.year}-${date.month}-${date.day}",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Start time: ${startTime.format(context)}",
                      style: GoogleFonts.robotoSlab(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "End time: ${endTime.format(context)}",
                      style: GoogleFonts.robotoSlab(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Lunch Taken: ${lunchTaken ? 'Yes' : 'No'}",
                      style: GoogleFonts.robotoSlab(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    )
    );
  }
}