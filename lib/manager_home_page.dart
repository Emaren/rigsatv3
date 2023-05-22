import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';

import 'auth_service.dart';
import 'hidden_drawer.dart';
import 'hours_entry_page.dart';
import 'review_tickets_page.dart';
import 'review_timesheet_page.dart';
// import 'role_service.dart';
import 'sign_up_page.dart';
import 'user_list_page.dart';
import 'utils.dart';

class ManagerHomePage extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>>? userDocRef;
  // final AuthService authService;
  // final String displayName;
  final String role;
  // final Map<String, String> userData;
  // final List<PayDate> payDates;
  final Future<void> Function() onLogout;
  // final FloatingActionButton? floatingActionButton;
  // final List<TimesheetData>? timesheetData;
  // final String uid;
  // final SimpleHiddenDrawerController? controller;

  const ManagerHomePage({
    Key? key,
    required this.userDocRef,
    // required this.authService,
    // required this.displayName,
    required this.role,
    // required this.userData,
    // required this.payDates,
    required this.onLogout,
    // this.floatingActionButton,
    // required this.timesheetData,
    // required this.uid,
    // required List actions,
    // required String title,
    // this.controller
  }) : super(key: key);

  @override
  State<ManagerHomePage> createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends State<ManagerHomePage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _passwordController = TextEditingController();
  // final RoleService _roleService = RoleService();
  late final displayName;
  String? role;
  String title = 'Manager Home';
  final List<String> userRoles = [
    'Admin',
    'Owner',
    'Manager',
    'Supervisor',
    'Employee',
    'Client',
    'Customer',
    'Vendor'
  ];
  List<PayDate> payDates = [];
  List<DateTime> payPeriodDates = generatePayPeriodDates(14,
      end: DateTime(2023, 5, 23), start: DateTime(2023, 5, 9));

  List<Map<String, dynamic>> hourEntriesData = [];

  String userId = '';
  String userDisplayName = 'Unknown';

  @override
  void initState() {
    super.initState();
    // displayName = widget.displayName;
    role = widget.role;
    payDates = payPeriodDates
        .map((date) =>
            PayDate(date: date, endDate: null, startDate: null, uid: userId))
        .toList();

    // userId = widget.userData['userId'] ?? '';

    if (userId.isNotEmpty) {
      fetchUserDisplayName(userId).then((name) {
        setState(() {
          userDisplayName = name;
        });
      });
    } else if (hourEntriesData.isNotEmpty) {
      final hourEntry = hourEntriesData.first;
      userId = hourEntry['userId'] ?? '';
      fetchUserDisplayName(userId).then((name) {
        setState(() {
          userDisplayName = name;
        });
      });
    } else {
      userId = '';
      userDisplayName = 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    // DateTime date;
    // TimeOfDay startTime;
    // TimeOfDay endTime;
    // bool lunchTaken;
    // String userId;
    // String userDisplayName;

    return Scaffold(
      body: HiddenDrawer(
        userDocRef: widget.userDocRef,
        // displayName: widget.displayName,
        // authService: widget.authService,
        role: widget.role,
        actions: const [],
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('FloatingActionButton pressed');
            final controller = SimpleHiddenDrawerController.of(context);
            print('Controller: $controller');
            if (controller == null) {
              print('Controller is null');
            } else {
              print('Toggling controller');
              controller.toggle();
            }
          },
          child: const Icon(Icons.menu),
        ),
        // onLogout: () async {
        //   await _authService.signOut();
        //   Navigator.pushAndRemoveUntil(
        //     context,
        //     MaterialPageRoute(builder: (context) => const LoginPage()),
        //     (Route<dynamic> route) => false,
        //   );
        // },
        // header: const Text('Header'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(children: [
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserListPage(
                            authService: _authService,
                            emailController: _emailController,
                            nameController: _nameController,
                            currentRole: widget.role,
                            userRoles: const [
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
                            ],
                            createUser: (BuildContext) {},
                          ),
                        ),
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 33, 55, 73),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(26),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Users',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 122, 122, 122)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 95, 101, 106),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_alt_1,
                                size: 48,
                                color: Color.fromARGB(255, 132, 14, 14)),
                            SizedBox(height: 16),
                            Text(
                              'Create User',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StreamBuilder<
                                  List<Map<String, dynamic>>>(
                              stream: fetchAllHourEntriesData(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<List<Map<String, dynamic>>>
                                      hourEntriesSnapshot) {
                                return StreamBuilder<List<Map<String, String>>>(
                                    stream: fetchUsersData(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<List<Map<String, String>>>
                                            usersSnapshot) {
                                      if (hourEntriesSnapshot.hasData &&
                                          usersSnapshot.hasData) {
                                        return ReviewTimesheetPage(
                                          // timesheetData:
                                          //     widget.timesheetData ?? [],
                                          // uid: widget.uid,
                                          authService: _authService,
                                        );
                                      } else {
                                        return const CircularProgressIndicator();
                                      }
                                    });
                              }),
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Review Timesheets',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReviewTicketsPage(),
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Review Tickets &\n Safety Documents',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
        // payDates: const [],
        usersData: const [],
        onLogout: widget.onLogout,
        // child: const SizedBox.shrink(),
      ),
    );
  }
}
