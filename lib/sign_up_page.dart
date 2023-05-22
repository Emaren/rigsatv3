import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'client_home_page.dart';
import 'customer_home_page.dart';
import 'employee_home_page.dart';
import 'login_page.dart';
import 'manager_home_page.dart';
import 'role_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService _authService = AuthService();
  final RoleService _roleService = RoleService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedRole;

  Future<void> onLogout() async {
    await _authService.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select Role'),
              value: _selectedRole,
              items: [
                'Admin',
                'Owner',
                'Manager',
                'Administration',
                'Secretary',
                'Sales',
                'Supervisor',
                'Field Tech',
                'Shop Tech',
                'Tech',
                'Technician',
                'Employee',
                'Client',
                'Customer',
                'Vendor'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue;
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (_selectedRole != null) {
                  UserCredential? userCredential =
                      await _roleService.createUser(
                    _emailController.text,
                    _nameController.text,
                    _passwordController.text,
                    _selectedRole!,
                  );

                  if (userCredential != null) {
                    // Create a SnackBar to display a success message
                    DocumentReference<Map<String, dynamic>> userDocRef =
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userCredential.user!.uid);
                    const snackBar = SnackBar(
                      content: Text('User Created Successfully'),
                    );
                    // Display the snackbar
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);

                    Widget? nextPage;

                    switch (_selectedRole) {
                      case 'Manager':
                        nextPage = ManagerHomePage(
                          role: 'Admin',
                          userDocRef: userDocRef,
                          onLogout: onLogout,
                        );
                        break;
                      case 'Employee':
                        nextPage = const EmployeeHomePage();
                        break;
                      case 'Client':
                        nextPage = const ClientHomePage();
                        break;
                      case 'Customer':
                        nextPage = const CustomerHomePage();
                        break;
                      default:
                        break;
                    }
                    if (nextPage == null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LoginPage(email: _emailController.text),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: const Text(
                                'An error occurred. Please try again.'),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
