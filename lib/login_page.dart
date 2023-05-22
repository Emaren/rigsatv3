import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  final String? email;
  const LoginPage({super.key, this.email});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _isLoading = false;

  void onLogin(BuildContext context) async {
    final email = _emailController.text;
    final password = _passwordController.text;

    User? user = await _authService.signIn(email, password);

    if (user != null) {
      print('User is not null: $user');
      final userDocRef =
          _authService.firestore.collection('users').doc(user.uid);
      final String? role = await _authService.getUserRole(user.uid);
      final String? displayName =
          await _authService.getUserDisplayName(user.uid);

      // Update the display name in FirebaseAuth
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // Assign the display name to _displayName
      _authService.displayName = displayName;

      _authService.navigateToHomePage(
        role ?? '',
        context,
        userDocRef: userDocRef,
        displayName: displayName,
        onLogout: () async {
          // Add the logout function here
          await _authService.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
          );
        },
      );
    } else {
      print('User is null');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20, 16.0, 0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('assets/RigSat.jpg', width: 380, height: 99),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 33),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            onLogin(context);
                          }
                        },
                        child: const Text('Login'),
                      ),
                    ),
                  const SizedBox(height: 2),
                  // SizedBox(height: 27),
                  SizedBox(
                    height: 26,
                    child: TextButton(
                      onPressed: () {
                        // TODO: implement forgot password
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // SizedBox(height: 1),
                  SizedBox(
                    height: 34,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/signup');
                      },
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(
                              vertical: 1, horizontal: 16),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'New Employee?',
                            style: TextStyle(
                              color: Color.fromARGB(255, 1, 1, 1),
                              fontSize: 11.0,
                            ),
                          ),
                          SizedBox(height: 0),
                          Text(
                            'Register Now',
                            style: TextStyle(
                              color: Color.fromARGB(255, 1, 8, 203),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
