import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'hours_entry_page.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

DateTime calculateStartDate() {
  DateTime now = DateTime.now();
  DateTime firstPayPeriodStart = DateTime(now.year, now.month, 9);
  DateTime secondPayPeriodStart = DateTime(now.year, now.month, 24);

  // If the current date is before the first pay period, return the start date of the previous month's second pay period
  if (now.isBefore(firstPayPeriodStart)) {
    if (now.month == 1) {
      return DateTime(now.year - 1, 12, 24);
    } else {
      return DateTime(now.year, now.month - 1, 24);
    }
  }
  // If the current date is before the second pay period, return the first start date
  else if (now.isBefore(secondPayPeriodStart)) {
    return firstPayPeriodStart;
  }
  // If the current date is after both pay periods, return the second start date
  else {
    return secondPayPeriodStart;
  }
}

List<DateTime> calculatePayPeriodDates(DateTime startDate) {
  List<DateTime> payPeriodDates = [];

  int daysUntilEndOfMonth =
      DateTime(startDate.year, startDate.month + 1, 0).day - startDate.day;

  if (startDate.day == 9) {
    for (int i = 0; i <= min(14, daysUntilEndOfMonth); i++) {
      payPeriodDates.add(startDate.add(Duration(days: i)));
    }
  } else if (startDate.day == 24) {
    for (int i = 0; i <= min(15, daysUntilEndOfMonth); i++) {
      payPeriodDates.add(startDate.add(Duration(days: i)));
    }
    if (daysUntilEndOfMonth < 15) {
      for (int i = 1; i <= 15 - daysUntilEndOfMonth; i++) {
        payPeriodDates.add(DateTime(startDate.year, startDate.month + 1, i));
      }
    }
  }

  return payPeriodDates;
}

Future<TimeOfDay?> showCustomTimePicker(
    BuildContext context, TimeOfDay initialTime) async {
  int selectedHour = initialTime.hour;
  int selectedMinute = initialTime.minute;

  final FixedExtentScrollController hourController =
      FixedExtentScrollController(initialItem: selectedHour - 1);
  final FixedExtentScrollController minuteController =
      FixedExtentScrollController(initialItem: selectedMinute ~/ 15);

  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 450,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: CupertinoPicker(
                      scrollController: hourController,
                      itemExtent: 32,
                      onSelectedItemChanged: (int index) {
                        selectedHour = index + 1;
                      },
                      children: List<Widget>.generate(24, (int index) {
                        return Text('${index + 1}');
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: CupertinoPicker(
                      scrollController: minuteController,
                      itemExtent: 32,
                      onSelectedItemChanged: (int index) {
                        selectedMinute = index * 15;
                      },
                      children: List<Widget>.generate(4, (int index) {
                        return Text('${index * 15}'.padLeft(2, '0'));
                      }),
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context)
                    .pop(TimeOfDay(hour: selectedHour, minute: selectedMinute));
              },
            ),
          ],
        ),
      );
    },
  );
}

List<DateTime> generatePayPeriodDates(int payPeriodDuration,
    {required DateTime end, required DateTime start}) {
  List<DateTime> dates = [];

  // DateTime today = DateTime.now();
  DateTime startDate = calculateStartDate();
  DateTime endDate = startDate.add(Duration(days: payPeriodDuration - 1));

  DateTime date = startDate;
  while (date.isBefore(endDate) || date.isAtSameMomentAs(endDate)) {
    dates.add(date);
    date = date.add(const Duration(days: 1));
  }
  return dates;
}

Future<String> fetchUserDisplayName(String uid) async {
  String displayName = 'Unknown';
  if (uid.isNotEmpty) {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    displayName = userSnapshot.data()?['displayName'] ?? 'Unknown';
  }
  return displayName;
}

Future<bool?> showSubmitConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Submit hours for review?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('No'),
          ),
        ],
      );
    },
  );
}

double calculateHoursWorked(
    TimeOfDay startTime, TimeOfDay endTime, bool lunchTaken) {
  double startHours = startTime.hour + startTime.minute / 60.0;
  double endHours = endTime.hour + endTime.minute / 60.0;
  double hoursWorked = endHours - startHours;

  if (lunchTaken) {
    hoursWorked -= 0.5;
  }

  return hoursWorked;
}

DateTime dateTimeWithTimeOfDay(DateTime date, TimeOfDay timeOfDay) {
  return DateTime(
    date.year,
    date.month,
    date.day,
    timeOfDay.hour,
    timeOfDay.minute,
  );
}

String formatTimeOfDay(TimeOfDay timeOfDay) {
  final now = DateTime.now();
  final dateTime = dateTimeWithTimeOfDay(now, timeOfDay);
  final format = DateFormat.jm();
  return format.format(dateTime);
}

Stream<List<Map<String, dynamic>>> fetchAllHourEntriesData() {
  return _firestore.collection('hour_entries').snapshots().map(
    (querySnapshot) {
      List<Map<String, dynamic>> hourEntriesData = [];

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc
          in querySnapshot.docs) {
        Map<String, dynamic> hourEntry = doc.data();
        hourEntry['id'] = doc.id;
        hourEntriesData.add(hourEntry);
      }

      print('Fetched hour entries data: $hourEntriesData');
      return hourEntriesData;
    },
  );
}

Stream<List<Map<String, String>>> fetchUsersData() {
  return _firestore.collection('users').snapshots().map(
    (querySnapshot) {
      List<Map<String, String>> usersData = [];

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc
          in querySnapshot.docs) {
        Map<String, String> user = {
          'id': doc.id,
          'displayName': doc.data()['displayName'],
        };
        usersData.add(user);
      }

      print('Fetched users data: $usersData');
      return usersData;
    },
  );
}

bool _isSnackBarActive = false;

void showSuccessSnackBar(BuildContext context, int index) {
  if (!_isSnackBarActive) {
    _isSnackBarActive = true;
    const snackBar = SnackBar(
      content: Text('Hours submitted successfully 👍'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      _isSnackBarActive = false;
    });
  }
}

Future<void> saveTime(PayDate payDate, int index, String userId) async {
  String docId = '${userId}_$index';

  try {
    await _firestore.collection('hour_entries').doc(docId).set({
      'userId': userId,
      'index': index,
      'date': payDate.date.toIso8601String(),
      'unixTimestamp': payDate.date.millisecondsSinceEpoch,
      'dateYMD':
          '${payDate.date.year}-${payDate.date.month.toString().padLeft(2, '0')}-${payDate.date.day.toString().padLeft(2, '0')}',
      'startHour': payDate.startTime?.hour,
      'startMinute': payDate.startTime?.minute,
      'endHour': payDate.endTime?.hour,
      'endMinute': payDate.endTime?.minute,
      'lunchTaken': payDate.lunchTaken,
      'submitted': payDate.submitted,
    });
  } catch (e) {
    print('Error saving to Firestore: $e');
  }
}

Future<void> loadTimes(String userId, List<PayDate> payDates,
    VoidCallback onPayDatesUpdated) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
      .collection('hour_entries')
      .where('userId', isEqualTo: userId)
      .get();

  for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot.docs) {
    Map<String, dynamic> data = doc.data();
    int index = data['index'] ?? 0;

    if (index >= 0 && index < payDates.length) {
      String? dateString = data['date'];
      int? unixTimestamp = data['unixTimestamp'];
      String? dateYMD = data['dateYMD'];
      int? startHour = int.tryParse(data['startHour']?.toString() ?? '0') ?? 0;
      int? startMinute =
          int.tryParse(data['startMinute']?.toString() ?? '0') ?? 0;
      int? endHour = int.tryParse(data['endHour']?.toString() ?? '0') ?? 0;
      int? endMinute = int.tryParse(data['endMinute']?.toString() ?? '0') ?? 0;

      bool lunchTaken = data['lunchTaken'] ?? false;
      bool submitted = data['submitted'] ?? false;

      if (dateString != null) {
        payDates[index].date = DateTime.parse(dateString);
      } else if (unixTimestamp != null) {
        payDates[index].date =
            DateTime.fromMillisecondsSinceEpoch(unixTimestamp);
      } else if (dateYMD != null) {
        payDates[index].date = DateTime.parse(dateYMD);
      }
      payDates[index].startTime =
          TimeOfDay(hour: startHour, minute: startMinute);
      payDates[index].endTime = TimeOfDay(hour: endHour, minute: endMinute);
      payDates[index].lunchTaken = lunchTaken;
      payDates[index].submitted = submitted;

      onPayDatesUpdated();
    }
  }
}
