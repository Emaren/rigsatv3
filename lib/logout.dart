import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hidden_drawer_menu/controllers/simple_hidden_drawer_controller.dart';

class Logout extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>>? userDocRef;
  final String title;
  final VoidCallback openDrawer;
  final Function onLogout;

  const Logout(
      {Key? key,
      required this.userDocRef,
      required this.title,
      required this.openDrawer,
      required this.onLogout})
      : super(key: key);

  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/RigSat.jpg', width: 380, height: 100),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await widget.onLogout();
              },
              child: const Text('Logout'),
            ),
          ],
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
