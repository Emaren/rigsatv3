import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils.dart';
import 'hours_entry_page.dart';

class LegacyHoursEntryPage extends StatefulWidget {
  const LegacyHoursEntryPage({Key? key}) : super(key: key);

  @override
  State<LegacyHoursEntryPage> createState() => _LegacyHoursEntryPageState();
}

class _LegacyHoursEntryPageState extends State<LegacyHoursEntryPage> {
  List<DateTime?> selectedDates = List<DateTime?>.generate(16, (index) => null);
  List<int?> startTimes = List<int?>.generate(16, (index) => null);
  List<int?> endTimes = List<int?>.generate(16, (index) => null);
  List<bool> isAM = List<bool>.generate(16, (index) => false);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  String? displayName;
  List<PayDate> payDates = [];

  @override
  void initState() {
    super.initState();
    // Load the times from Firestore when the page is initialized
    _loadTimesFromFirestore();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    User? user = _auth.currentUser;
    setState(() {
      currentUser = user;
    });
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          displayName = userData['displayName'];
        });
      } else {
        print('User document does not exist.');
      }
    } else {
      print('User is not signed in.');
    }
  }

  Future<void> saveHoursToFirestore(PayDate payDate, int index) async {
    try {
      // String userId = currentUser?.uid ?? '';
      await saveTime(payDate, index, FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
      print(e);
    }
  }

  bool supervisorApproval = false;
  List<TextEditingController> startTimeControllers =
      List<TextEditingController>.generate(
          16, (index) => TextEditingController());
  List<TextEditingController> endTimeControllers =
      List<TextEditingController>.generate(
          16, (index) => TextEditingController());

  Future<void> _loadTimesFromFirestore() async {
    try {
      for (int i = 0; i < 16; i++) {
        DocumentSnapshot doc =
            await _firestore.collection('hour_entries').doc(i.toString()).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            startTimes[i] = data['startHour'];
            endTimes[i] = data['endHour'];
            selectedDates[i] = data['date']?.toDate();

            startTimeControllers[i].text = startTimes[i].toString();
            endTimeControllers[i].text = endTimes[i].toString();
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void _onStartTimeChanged(int index, TimeOfDay time) {
    setState(() {
      payDates[index].startTime = time;
    });

    saveHoursToFirestore(payDates[index], index);
  }

  void _onEndTimeChanged(int index, TimeOfDay time) {
    setState(() {
      payDates[index].endTime = time;
    });

    saveHoursToFirestore(payDates[index], index);
  }

  void _updateAndSaveTimes(int index, String startTime, String endTime) {
    int? parsedStart = int.tryParse(startTime);
    int? parsedEnd = int.tryParse(endTime);

    setState(() {
      startTimes[index] = parsedStart;
      endTimes[index] = parsedEnd;
    });

    if (parsedStart != null && parsedEnd != null) {
      saveHoursToFirestore(payDates[index], index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Time Card'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/RigSat.jpg', fit: BoxFit.cover),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Text(
                          'TIME CARD',
                          style: TextStyle(
                            fontSize: 24,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = const Color.fromARGB(255, 207, 41, 29),
                          ),
                        ),
                        const Text(
                          'TIME CARD',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Employee Name: ${displayName ?? '________'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Pay Period:              ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Table(
                border: TableBorder.all(color: Colors.black),
                defaultColumnWidth: const FlexColumnWidth(1),
                children: _createTableRows(17),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Supervisor Approval: ____________',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(
                      supervisorApproval ? Icons.check : Icons.send,
                      color: supervisorApproval ? Colors.green : Colors.blue,
                    ),
                    onPressed: () {
                      setState(() {
                        supervisorApproval = !supervisorApproval;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TableRow> _createTableRows(int numRows) {
    List<TableRow> tableRows = [];
    List<String> headers = [
      'Pay\nPeriod',
      'Date\n(2023)',
      'Start\nTime',
      'End\nTime',
      'Total\nHrs',
    ];

    List<int> dates = List<int>.generate(16, (index) => index + 9);

    tableRows.add(TableRow(
      children: headers
          .map((header) => Padding(
                padding: const EdgeInsets.all(5.0),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      header,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ))
          .toList(),
    ));

    DateTime currentDate = DateTime.now();

    for (int i = 0; i < numRows - 1; i++) {
      DateTime specificDate =
          DateTime(currentDate.year, currentDate.month, dates[i]);

      String totalHours = '';
      if (startTimes[i] != null && endTimes[i] != null) {
        int total =
            ((endTimes[i] ?? 0) + (isAM[i] ? 0 : 12)) - (startTimes[i] ?? 0);
        if (total < 0) total += 24;
        totalHours = total.toString();
      }

      tableRows.add(TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Center(
              child: Text(
                dates[i].toString(),
                style: currentDate.day == dates[i]
                    ? const TextStyle(color: Color.fromARGB(255, 51, 4, 240))
                    : null,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                if (selectedDates[i] != null) {
                  selectedDates[i] = null;
                } else {
                  selectedDates[i] = specificDate;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: selectedDates[i] == null
                    ? const Text('')
                    : Text(
                        '${selectedDates[i]!.month.toString().padLeft(2, '0')}-${selectedDates[i]!.day.toString().padLeft(2, '0')}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentDate.day == dates[i] &&
                                  selectedDates[i] != null
                              ? const Color.fromARGB(255, 51, 4, 240)
                              : Colors.black,
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: TextFormField(
                controller: startTimeControllers[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final time =
                      TimeOfDay.fromDateTime(DateFormat.jm().parse(value));
                  _onStartTimeChanged(i, time);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Center(
                  child: TextFormField(
                    controller: endTimeControllers[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final time =
                          TimeOfDay.fromDateTime(DateFormat.jm().parse(value));
                      _onEndTimeChanged(i, time);
                    },
                  ),
                ),
                Positioned(
                  top: -9,
                  right: 0,
                  left: 43,
                  bottom: 40,
                  child: IconButton(
                    icon: Icon(
                      isAM[i] ? Icons.brightness_2 : Icons.wb_sunny,
                      size: 16.0,
                    ),
                    onPressed: () {
                      setState(() {
                        isAM[i] = !isAM[i];
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(23),
            child: Center(child: Text(totalHours)),
          ),
        ],
      ));
    }

    int totalHoursSum = endTimes
        .asMap()
        .entries
        .where((entry) => selectedDates[entry.key] != null)
        .map((entry) =>
            ((entry.value ?? 0) + (isAM[entry.key] ? 0 : 12)) -
            (startTimes[entry.key] ?? 0))
        .map((hours) => hours < 0 ? hours + 24 : hours)
        .fold(0, (previousValue, currentValue) => previousValue + currentValue);

    tableRows.add(TableRow(
      children: [
        const SizedBox(height: 24),
        const SizedBox(height: 24),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              'Total:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              totalHoursSum == 0 ? '' : totalHoursSum.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ));

    return tableRows;
  }
}
