import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
import 'hours_entry_page.dart';
import 'legacy_hours_entry_page.dart';
import 'login_page.dart';

class Timesheets extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>>? userDocRef;
  final String title;

  final SimpleHiddenDrawerController? controller;
  final List<PayDate> payDates;

  const Timesheets(
      {Key? key,
      required this.userDocRef,
      this.controller,
      required this.payDates,
      required this.title})
      : super(key: key);

  @override
  State<Timesheets> createState() => _TimesheetsState();
}

class _TimesheetsState extends State<Timesheets> {
  List<PayDate> payDates = [];
  Future<void> _navigateToHoursEntryPage(BuildContext context) async {
    if (widget.userDocRef != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HoursEntryPage(),
          ));
    } else {
      print("UserDocRef is null");
    }
  }

  LoginPage? navigateToLegacyHoursEntryPage(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LegacyHoursEntryPage(
              // provide a value to payDates
              // payDates: payDates,
              ),
        ),
      );
      // return LoginPage or throw an exception if the user is not null
      return null; // or throw Exception('User is not null');
    } else {
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: SizedBox(
          height: 200, // Set a fixed height for the container
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/RigSat.jpg', width: 380, height: 100),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _navigateToHoursEntryPage(context),
                child: const Text('Hours'),
              ),
              SizedBox(
                height: 35,
                width: 130,
                child: ElevatedButton(
                  onPressed: () => navigateToLegacyHoursEntryPage(context),
                  child: const Text('Legacy Hours'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          SimpleHiddenDrawerController.of(context).toggle();
        },
        child: const Icon(Icons.menu),
      ),
    );
  }
}
