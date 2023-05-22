import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';

import 'auth_service.dart';
import 'firestore_mini_timesheet_widget.dart';
import 'hours_entry_page.dart';
import 'logout.dart';
import 'timesheets.dart';
import 'utils.dart';

class HiddenDrawer extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>>? userDocRef;
  // final Widget child;
  final Function onLogout;
  // final String displayName;
  final String role;
  // final AuthService authService;
  // final Widget body;
  // final Widget header;
  // final List<PayDate> payDates;
  final List<Map<String, dynamic>> usersData;
  final FloatingActionButton? floatingActionButton;

  const HiddenDrawer({
    Key? key,
    required this.userDocRef,
    // required this.child,
    required this.onLogout,
    // required this.displayName,
    required this.role,
    // required this.authService,
    // required this.body,
    // required this.header,
    required List<IconButton> actions,
    // required this.payDates,
    required this.usersData,
    required this.floatingActionButton,
    required Center body,
  }) : super(key: key);

  @override
  State<HiddenDrawer> createState() => _HiddenDrawerState();
}

class _HiddenDrawerState extends State<HiddenDrawer> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ScreenHiddenDrawer> _pages = [];
  late final AuthService authService;
  List<PayDate> payDates = [];

  @override
  void initState() {
    super.initState();
    // authService = widget.authService;
  }

  @override
  Widget build(BuildContext context) {
    try {
      // String? userId = widget.userDocRef?.id;
      // if (userId == null) {
      //   return const Center(child: Text('User ID is not available.'));
      // }

      return StreamBuilder<List<Map<String, String>>>(
          stream: fetchUsersData(),
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, String>>> usersSnapshot) {
            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (usersSnapshot.hasError) {
              return Center(child: Text('Error: ${usersSnapshot.error}'));
            } else {
              // List<Map<String, String>> usersData = usersSnapshot.data ?? [];

              // Map<String, String> userData = { for (var user in usersData) user['id'] as String : user['displayName'] as String };

              return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: fetchAllHourEntriesData(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>>
                          hourEntriesSnapshot) {
                    if (hourEntriesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (hourEntriesSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${hourEntriesSnapshot.error}'));
                    } else {
                      // List<Map<String, dynamic>> hourEntriesData =
                      //     hourEntriesSnapshot.data ?? [];

                      _pages = [
                        // ScreenHiddenDrawer(
                        //   ItemHiddenMenu(
                        //     // name: '${widget.displayName}, ${widget.role}',
                        //     baseStyle: const TextStyle(
                        //         fontWeight: FontWeight.bold, fontSize: 19),
                        //     selectedStyle: const TextStyle(),
                        //   ),
                        //   Scaffold(
                        //     appBar: AppBar(
                        //       backgroundColor: Colors.blueGrey,
                        //       actions: [
                        //         IconButton(
                        //           icon: const Icon(Icons.logout),
                        //           onPressed: () {
                        //             widget.onLogout();
                        //           },
                        //         ),
                        //       ],
                        //     ),
                        //     body: widget.body,
                        //   ),
                        // ),
                        ScreenHiddenDrawer(
                          ItemHiddenMenu(
                              name: 'Timesheets',
                              baseStyle: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 19),
                              selectedStyle:
                                  const TextStyle(color: Colors.white)),
                          Timesheets(
                            userDocRef: widget.userDocRef,
                            title: '',
                            payDates: payDates,
                          ),
                        ),
                        if (['Admin', 'Owner', 'Manager']
                            .contains(widget.role)) ...[
                          ScreenHiddenDrawer(
                            ItemHiddenMenu(
                                name: 'Review Hours',
                                baseStyle: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 19),
                                selectedStyle:
                                    const TextStyle(color: Colors.white)),
                            Scaffold(
                              body: Center(
                                child: FirestoreMiniTimesheetWidget(),
                              ),
                            ),
                          ),
                        ],

                        ScreenHiddenDrawer(
                          ItemHiddenMenu(
                            name: "Logout",
                            baseStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 19),
                            selectedStyle: const TextStyle(color: Colors.white),
                          ),
                          Logout(
                            onLogout: widget.onLogout,
                            userDocRef: null,
                            title: '',
                            openDrawer: () {},
                          ),
                        ),
                      ];
                    }
                    return WillPopScope(
                        onWillPop: () async {
                          return Future.value(false);
                        },
                        child: HiddenDrawerMenu(
                          screens: _pages,
                          backgroundColorMenu: Colors.blueGrey,
                          contentCornerRadius: 32,
                          slidePercent: 70,
                          typeOpen: TypeOpen.FROM_LEFT,
                          enableScaleAnimation: true,
                          enableCornerAnimation: true,
                          backgroundColorAppBar: Colors.blueGrey,
                        ));
                  });
            }
          });
    } catch (error, stacktrace) {
      print('Error in build() method: $error');
      print(stacktrace);
      return Container();
    }
  }
}
