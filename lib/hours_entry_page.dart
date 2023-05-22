// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils.dart';
import 'pay_periods_page.dart';
import 'review_time_page.dart';

class PayDate {
  DateTime date;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool lunchTaken;
  bool submitted;
  final String uid;

  PayDate(
      {required this.uid,
      required this.date,
      this.startTime,
      this.endTime,
      this.lunchTaken = false,
      this.submitted = false,
      required endDate,
      required startDate});

  static fromMap(Map<String, dynamic> data) {}
}

class HoursEntryPage extends StatefulWidget {
  const HoursEntryPage({super.key});

  @override
  _HoursEntryPageState createState() => _HoursEntryPageState();
}

class _HoursEntryPageState extends State<HoursEntryPage> {
  List<ValueNotifier<bool>> _submitNotifiers = [];

  List<DateTime> payPeriodDates = generatePayPeriodDates(15,
      start: DateTime(2023, 5, 9), end: DateTime(2023, 5, 23));

  List<PayDate> payDates = [];

  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String? displayName;
  bool _isSnackBarActive = false;

  @override
  void initState() {
    super.initState();
    payDates = payPeriodDates
        .map((date) =>
            PayDate(date: date, endDate: null, startDate: null, uid: userId))
        .toList();

    _submitNotifiers = List<ValueNotifier<bool>>.generate(
        payDates.length, (index) => ValueNotifier<bool>(false));

    loadTimes(userId, payDates, () {
      for (int i = 0; i < payDates.length; i++) {
        _submitNotifiers[i].value = payDates[i].submitted;
      }
      setState(() {});
    });

    displayName = FirebaseAuth.instance.currentUser?.displayName;
  }

  @override
  Widget build(BuildContext context) {
    DateTime endDate = payPeriodDates.last;
    DateTime startDate = payPeriodDates.first;
    String payPeriodHeader;
    payPeriodHeader =
        'Pay Period: ${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day}';

    return Scaffold(
      appBar: AppBar(title: const Text("Hours Entry")),
      body: Column(children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
                ),
                child: Text(
                  payPeriodHeader,
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: payDates.length,
            itemBuilder: (context, index) {
              PayDate payDate = payDates[index];
              TimeOfDay startTime =
                  payDate.startTime ?? const TimeOfDay(hour: 0, minute: 0);
              TimeOfDay endTime =
                  payDate.endTime ?? const TimeOfDay(hour: 0, minute: 0);
              bool lunchTaken = payDate.lunchTaken;
              double totalHours =
                  calculateHoursWorked(startTime, endTime, lunchTaken);

              return GestureDetector(
                onTap: () async {
                  TimeOfDay currentStartTime = TimeOfDay(
                      hour: payDate.startTime?.hour ?? 0,
                      minute: payDate.startTime?.minute ?? 0);
                  TimeOfDay currentEndTime = TimeOfDay(
                      hour: payDate.endTime?.hour ?? 0,
                      minute: payDate.endTime?.minute ?? 0);

                  TimeOfDay? newStartTime =
                      await showCustomTimePicker(context, currentStartTime);
                  TimeOfDay? newEndTime =
                      await showCustomTimePicker(context, currentEndTime);

                  if (newStartTime != null && newEndTime != null) {
                    setState(() {
                      payDate.startTime = newStartTime;
                      payDate.endTime = newEndTime;
                    });

                    await saveTime(
                        payDate, index, FirebaseAuth.instance.currentUser!.uid);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat.yMMMMd().format(payDate.date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
                                    color: DateTime.now().year ==
                                                payDate.date.year &&
                                            DateTime.now().month ==
                                                payDate.date.month &&
                                            DateTime.now().day ==
                                                payDate.date.day
                                        ? const Color.fromARGB(255, 11, 11, 191)
                                        : Colors.black,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Builder(
                                      builder: (BuildContext context) {
                                        return ValueListenableBuilder<bool>(
                                          valueListenable:
                                              _submitNotifiers[index],
                                          builder: (BuildContext context,
                                              bool isSubmitted, Widget? child) {
                                            return IconButton(
                                              onPressed: isSubmitted
                                                  ? null
                                                  : () async {
                                                      if (!_isSnackBarActive) {
                                                        _isSnackBarActive =
                                                            true;
                                                        bool? submitConfirmed =
                                                            await showSubmitConfirmationDialog(
                                                                context);
                                                        if (submitConfirmed ??
                                                            false) {
                                                          setState(() {
                                                            _submitNotifiers[
                                                                    index]
                                                                .value = true;
                                                          });

                                                          setState(() {
                                                            payDates[index]
                                                                    .submitted =
                                                                true;
                                                          });
                                                          await saveTime(
                                                              payDate,
                                                              index,
                                                              userId);

                                                          showSuccessSnackBar(
                                                              context, index);
                                                        }
                                                        _isSnackBarActive =
                                                            false;
                                                      }
                                                    },
                                              icon: Icon(
                                                  isSubmitted
                                                      ? Icons.check_circle
                                                      : Icons.send,
                                                  color: isSubmitted
                                                      ? Colors.green
                                                      : const Color.fromARGB(
                                                          255, 11, 11, 191)),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1.0),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start: ${formatTimeOfDay(startTime)}',
                                      ),
                                      Text(
                                        'End: ${formatTimeOfDay(endTime)}',
                                      ),
                                      const SizedBox(height: 8.0),
                                      const Text(
                                        'Lunch Taken:',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        lunchTaken ? 'Yes' : 'No',
                                      ),
                                      Switch(
                                        value: lunchTaken,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            payDate.lunchTaken = value ?? false;
                                          });
                                          saveTime(payDate, index, userId);
                                        },
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hours Worked:',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        totalHours.toStringAsFixed(2),
                                      ),
                                    ],
                                  )
                                ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8.0),
        const SizedBox(height: 8.0),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PayPeriodsPage(),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Pay Periods',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // String hoursWorked = '';
          List<String> hoursWorkedList = [];
          for (int i = 0; i < payDates.length; i++) {
            PayDate payDate = payDates[i];
            if (payDate.startTime != null && payDate.endTime != null) {
              hoursWorkedList.add(calculateHoursWorked(
                      payDate.startTime!, payDate.endTime!, payDate.lunchTaken)
                  .toStringAsFixed(2));
            } else {
              hoursWorkedList.add("Not calculated");
            }
          }
          // hoursWorked = hoursWorkedList.join(', ');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReviewTimePage(),
            ),
          );
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
