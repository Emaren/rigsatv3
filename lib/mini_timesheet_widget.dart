import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils.dart';
import 'auth_service.dart';

class TimesheetData {
  final String dateYMD;
  final int startHour;
  final int endHour;
  final int startMinute;
  final int endMinute;
  final bool lunchTaken;

  TimesheetData({
    required this.lunchTaken,
    required this.dateYMD,
    required this.startHour,
    required this.endHour,
    required this.startMinute,
    required this.endMinute,
  });

  factory TimesheetData.fromMap(Map<String, dynamic> data) {
    return TimesheetData(
      lunchTaken: data['lunchTaken'] ?? false,
      dateYMD: data['dateYMD'] ?? 'nu',
      startHour: data['startHour'] ?? 0,
      startMinute: data['startMinute'] ?? 0,
      endHour: data['endHour'] ?? 0,
      endMinute: data['endMinute'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateYMD': dateYMD,
      'startHour': startHour,
      'endHour': endHour,
      'startMinute': startMinute,
      'endMinute': endMinute,
    };
  }
}

class TimesheetWidget extends StatelessWidget {
  final String? displayName;
  final String uid;
  final AuthService authService;

  const TimesheetWidget({
    super.key,
    this.displayName,
    required this.uid,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    print('Querying hour_entries with uid: $uid');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hour_entries')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong: ${snapshot.error.toString()}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        List<TimesheetData> timesheetData = snapshot.data!.docs.map((doc) {
          print('Document data: ${doc.data()}');
          if (doc.data() is Map<String, dynamic>) {
            return TimesheetData.fromMap(doc.data() as Map<String, dynamic>);
          } else {
            return TimesheetData(
              dateYMD: 'nu',
              startHour: 0,
              endHour: 0,
              startMinute: 0,
              endMinute: 0,
              lunchTaken: false,
            );
          }
        }).toList();

        return MiniTimesheetWidget(
          displayName: displayName ?? 'Unknown User',
          timesheetData: timesheetData,
          uid: uid,
          authService: authService,
          displayControls: false,
          displaySendIcon: true,
        );
      },
    );
  }
}

class MiniTimesheetWidget extends StatefulWidget {
  final List<TimesheetData> timesheetData;
  final AuthService authService;
  final bool displayControls;
  final String? displayName;
  final String uid;
  final bool displaySendIcon;

  const MiniTimesheetWidget({
    super.key,
    required this.timesheetData,
    this.displayName,
    required this.uid,
    required this.authService,
    this.displayControls = false,
    required this.displaySendIcon,
  });

  @override
  _MiniTimesheetWidgetState createState() => _MiniTimesheetWidgetState();
}

class _MiniTimesheetWidgetState extends State<MiniTimesheetWidget> {
  final _firestore = FirebaseFirestore.instance;
  bool isSaved = false;
  String? docId;

  void _updateIsSaved(bool value) {
    setState(() {
      isSaved = value;
    });
  }

  void _updateDocId(String? value) {
    setState(() {
      docId = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeTimesheet();
  }

  void _initializeTimesheet() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('timesheets')
        .where('uid', isEqualTo: widget.uid)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot timesheetDoc = querySnapshot.docs.first;

      if (mounted) {
        setState(() {
          isSaved = true;
          docId = timesheetDoc.id;
        });
      }
    }
  }

  List<TableRow> _createTableRows() {
    List<TableRow> tableRows = [];
    List<String> headers = [
      'Pay\nPeriod',
      'Date\n(2023)',
      'Start\nTime',
      'End\nTime',
      'Total\nHrs',
    ];

    DateTime today = DateTime.now();

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

    int payPeriodStart = 9;
    TimesheetData? lastData;
    double totalHours = 0;

    for (TimesheetData data in widget.timesheetData) {
      DateTime date = DateTime.parse(data.dateYMD);
      var payPeriodDates = calculatePayPeriodDates(date);
      lastData = data;
      double hoursWorked = (data.endHour + data.endMinute / 60.0) -
          (data.startHour + data.startMinute / 60.0) -
          (data.lunchTaken ? 0.5 : 0);

      totalHours += hoursWorked;

      // calculate isToday here, inside the loop, so it's based on the current date being added to the table
      bool isToday = date.day == today.day &&
          date.month == today.month &&
          date.year == today.year;

      tableRows.add(TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: isToday ? const Color.fromARGB(255, 16, 2, 176) : null,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                data.dateYMD.isNotEmpty
                    ? '${data.dateYMD.substring(5, 7)} - ${data.dateYMD.substring(8)}'
                    : '-',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
                child: Text(
              data.startMinute != null
                  ? '${data.startHour}:${data.startMinute.toString().padLeft(2, '0')}'
                  : '-',
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
                child: Text(
              data.endMinute != null
                  ? '${data.endHour}:${data.endMinute.toString().padLeft(2, '0')}'
                  : '-',
            )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
                child: Text(hoursWorked != null
                    ? hoursWorked.toStringAsFixed(2)
                    : '-')),
          ),
        ],
      ));

      payPeriodStart += 1;

      if (payPeriodStart > 23) {
        break;
      }
    }

    while (payPeriodStart <= 23) {
      tableRows.add(TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                payPeriodStart.toString(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text('-')),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text('-')),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text('-')),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text('-')),
          ),
        ],
      ));

      payPeriodStart += 1;
    }

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
              totalHours.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ));
    return tableRows;
  }

  @override
  Widget build(BuildContext context) {
    String? supervisorName;

    DateTime currentPayPeriodStart = calculateStartDate();
    DateTime currentPayPeriodEnd =
        currentPayPeriodStart.add(const Duration(days: 14));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        ..color = const Color.fromARGB(255, 207, 29, 35),
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
            Row(
              children: [
                const Text(
                  'Employee Name: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.displayName ?? '________',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2.0,
                  ),
                ),
              ],
            ),
            Text(
              'Pay Period: ${currentPayPeriodStart.month}/${currentPayPeriodStart.day} - ${currentPayPeriodEnd.month}/${currentPayPeriodEnd.day}',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
          children: _createTableRows(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FutureBuilder<String?>(
              future: widget.authService.getCurrentUserDisplayName(),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                if (snapshot.hasData) {
                  supervisorName = snapshot.data;
                  return Row(
                    children: [
                      const Text('Supervisor Approval: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )),
                      Text(
                        supervisorName ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationThickness: 2.0,
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            ),
            if (widget.displaySendIcon)
              GestureDetector(
                onTap: () async {
                  if (isSaved) {
                    if (docId != null) {
                      try {
                        await _firestore
                            .collection('timesheets')
                            .doc(docId)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Timesheet deleted!')),
                        );
                        setState(() {
                          isSaved = false;
                        });
                      } catch (e) {
                        print(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to delete timesheet.')),
                        );
                      }
                    }
                  } else {
                    try {
                      var docRef =
                          await _firestore.collection('timesheets').add({
                        'uid': widget.uid,
                        'displayName': widget.displayName,
                        'timesheetData': widget.timesheetData
                            .map((data) => data.toJson())
                            .toList(),
                        'timestamp': FieldValue.serverTimestamp(),
                        'supervisor': supervisorName,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Timesheet submitted!')),
                      );
                      setState(() {
                        isSaved = true;
                        docId = docRef.id;
                      });
                    } catch (e) {
                      print(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to submit timesheet.')),
                      );
                    }
                  }
                },
                child: Icon(
                  isSaved ? Icons.check : Icons.send,
                  color: isSaved
                      ? const Color.fromARGB(255, 0, 128, 0)
                      : const Color.fromARGB(255, 33, 8, 192),
                ),
              ),
            if (widget.displayControls)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Color.fromARGB(255, 145, 14, 4)),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Authorize \n   & File'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ]);
  }
}
