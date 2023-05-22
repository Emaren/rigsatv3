import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'client_home_page.dart';
import 'customer_home_page.dart';
import 'employee_home_page.dart';
import 'manager_home_page.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');
  String? get currentUserId => _auth.currentUser?.uid;
  String? _role;
  String? _displayName;
  late final Function onLogout;
  String? get role => _role;

  late final String uid;

  set role(String? role) {
    _role = role;
  }

  set displayName(String? displayName) {
    _displayName = displayName;
  }

  String? get displayName => _displayName;

  Future<String?> getCurrentUserDisplayName() async {
    User? user = _auth.currentUser;

    if (user != null) {
      return user.displayName;
    } else {
      return null;
    }
  }

  Future<UserCredential?> signUp(
      String email, String displayName, String password, String role) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Save additional user information to Firestore
      if (user != null) {
        await _userCollection.doc(user.uid).set({
          'displayName': displayName,
          'email': email,
          'role': role,
          'creationTime': FieldValue.serverTimestamp(),
        });
        print(
            'User info: ID=${user.uid}, displayName=$displayName, email=$email, , role=$role');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error signing up: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Exception in signUp: $e');
      return null;
    }
  }

  Future<void> navigateToHomePage(String userRole, BuildContext context,
      {DocumentReference<Map<String, dynamic>>? userDocRef,
      required Future<void> Function() onLogout,
      String? displayName}) async {
    print('navigateToHomePage called with userRole: $userRole');

    Widget destination;

    switch (userRole) {
      case 'Admin':
        destination = ManagerHomePage(
          role: 'Admin',
          userDocRef: userDocRef,
          onLogout: onLogout,
          // displayName: displayName.trim(),
          // authService: this,
          // actions: const [],
          // title: 'm',
          // payDates: const [],
          // userData: const {},
          // floatingActionButton: FloatingActionButton(
          // onPressed: () {
          // SimpleHiddenDrawerController.of(context).toggle();
          // },
          // child: const Icon(Icons.menu),
          // ),
          // timesheetData: timesheetData,
          // uid: '',
        );
        break;
      case 'Manager':
        destination = ManagerHomePage(
          role: 'Admin',
          userDocRef: userDocRef,
          onLogout: onLogout,
        );
        break;
      case 'Client':
        destination = const ClientHomePage();
        break;
      case 'Customer':
        destination = const CustomerHomePage();
        break;
      default:
        destination = const EmployeeHomePage();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => destination,
      ),
    );
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Exception in signIn: $e');
      return null;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      print(e);
      rethrow;
    }
  }

// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

// Get user role by uid
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDocSnapshot =
          await firestore.collection('users').doc(uid).get();
      return (userDocSnapshot.data() as Map<String, dynamic>)['role'];
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<String?> getUserDisplayName(String uid) async {
    try {
      DocumentSnapshot userDocSnapshot =
          await firestore.collection('users').doc(uid).get();
      return (userDocSnapshot.data() as Map<String, dynamic>)['displayName'];
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      final userDocRef = await firestore.collection('users').doc(uid).get();
      if (userDocRef.exists) {
        await firestore.collection('users').doc(uid).delete();
        User? currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          await currentUser.delete();
          await _auth.signOut();
        }
      }
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }

  Future<void> _fetchUserData() async {
    String? fetchedName = await fetchDisplayName();
    if (currentUserId != null) {
      String? fetchedRole = await getUserRole(currentUserId!);
      displayName = fetchedName;
      role = fetchedRole;
    }
  }

  Future<String?> fetchDisplayName() async {
    String? uid = currentUserId;
    if (uid != null) {
      String? fetchedName = await getUserDisplayName(uid);
      return fetchedName;
    }
    return null;
  }
}
