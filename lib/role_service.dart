import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class RoleService {
  Future<UserCredential?> createUser(
      String email, String password, String name, String role) async {
    try {
      AuthService authService = AuthService();
      UserCredential? userCredential =
          await authService.signUp(email, password, name, role);
      if (userCredential != null) {
        // await authService.sendEmailVerification(userCredential.user!);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'name': name,
          'role': role,
        });
      }
      return userCredential;
    } catch (e) {
      print("Error creating user with role '$role': $e");
      rethrow;
    }
  }
}

// Add the missing getRole and updateRole methods
Future<String?> getRole(String email, String password) async {
  try {
    // Retrieve the user with the given email and password
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // Fetch the user's role from Firestore
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    return userSnapshot.get('role');
  } catch (e) {
    print("Error getting role: $e");
    return null;
  }
}

Future<bool> updateRole(String email, String password, String newRole) async {
  try {
    // Retrieve the user with the given email and password
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // Update the user's role in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .update({'role': newRole});

    return true;
  } catch (e) {
    print("Error updating role: $e");
    return false;
  }
}
