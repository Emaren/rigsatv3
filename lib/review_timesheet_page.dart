import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'mini_timesheet_widget.dart';

class ReviewTimesheetPage extends StatelessWidget {
  // final String uid;
  final String? displayName;
  final AuthService authService;

  const ReviewTimesheetPage(
      {super.key,
      // required this.uid,
      // required List<TimesheetData> timesheetData,
      this.displayName,
      required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Timesheeet Page'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('timesheets')
            // .where('uid', isEqualTo: uid)
            // .orderBy('timestamp', descending: true) // adjust as needed
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong: ${snapshot.error.toString()}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          print(
              'Documents: ${snapshot.data!.docs}'); // Print the documents to the console

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              // You may need to map the 'timesheetData' into a List of TimesheetData objects
              List<TimesheetData> timesheetData =
                  (data['timesheetData'] as List)
                      .map((item) => TimesheetData.fromMap(item))
                      .toList();

              return MiniTimesheetWidget(
                displayName: data['displayName'] ?? 'Unknown User',
                timesheetData: timesheetData,
                uid: data['uid'] ?? '',
                authService: authService,
                displayControls: true,
                displaySendIcon: false, // Add this line
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
