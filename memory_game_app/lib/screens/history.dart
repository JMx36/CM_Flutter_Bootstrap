import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      spacing: 40,
      children: [
        Text(
          "History",
          textAlign: .center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        Expanded(child: HistoryList()),
      ],
    );
  }
}

class HistoryList extends StatefulWidget {
  const HistoryList({super.key});

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> with WidgetsBindingObserver {
  final User? user = FirebaseAuth.instance.currentUser;
  String userID = "";
  DatabaseReference? dbRef;

  List<Widget> listItems = [];

  String toTimeFormat(int seconds) {
    int minutes = seconds ~/ 60;
    int leftOverSeconds = seconds % 60;

    return "${minutes.toString().padLeft(2, '0')}:${leftOverSeconds.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    userID = user?.uid ?? "";
    dbRef = FirebaseDatabase.instance.ref("$userID/history");
    fetchData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // screen came back into view
      fetchData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void fetchData() async {
    print("Fetching");
    try {
      if (dbRef == null) {
        print("No database ref");
        return;
      }

      final snapshot = await dbRef!.get();

      if (snapshot.exists) {
        final raw = snapshot.value;

        if (raw is! Map) {
          print("HistoryList::fetchData:Error: Not a map");
          return;
        }
        // Extract values and convert each to Map<String, dynamic>
        final values = raw.values.toList();
        List<Widget> tempList = [];
        print("Values $values");
        values.sort((a, b) {
          final da = DateTime.parse(a['played_at'] as String);
          final db = DateTime.parse(b['played_at'] as String);
          return db.compareTo(da);
        });

        for (var value in values) {
          tempList.add(
            getListItem(
              context,
              DateTime.parse(value['played_at'] as String),
              value["flips"] as int,
              value["duration"] as int,
              value["completed"] as bool,
            ),
          );
        }

        setState(() {
          listItems = tempList;
        });
      }
    } catch (e) {
      print("Error fetching history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: listItems);
  }
}

const m_colors = [Colors.deepPurple, Colors.deepPurpleAccent];

int currColorIdx = -1;

String toTimeFormat(int seconds) {
  int minutes = seconds ~/ 60;
  int leftOverSeconds = seconds % 60;

  return "${minutes.toString().padLeft(2, '0')}:${leftOverSeconds.toString().padLeft(2, '0')}";
}

Card getListItem(
  BuildContext context,
  datetime,
  int moves,
  int duration,
  bool completed,
) {
  currColorIdx = (currColorIdx + 1) % m_colors.length;

  String formatDateTime(DateTime dt) {
    // Round minutes
    int roundedMinute = dt.minute;
    if (dt.second >= 30) {
      roundedMinute += 1;
    }
    if (roundedMinute == 60) {
      roundedMinute = 0;
      dt = dt.add(Duration(hours: 1));
    }

    // Format components with leading zeros
    String year = dt.year.toString();
    String month = dt.month.toString().padLeft(2, '0');
    String day = dt.day.toString().padLeft(2, '0');
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = roundedMinute.toString().padLeft(2, '0');

    return "$year-$month-$day | $hour:$minute";
  }

  return Card(
    color: m_colors[currColorIdx],
    child: Padding(
      padding: .all(10),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(
            formatDateTime(datetime),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            spacing: 10,
            children: [
              Row(
                spacing: 5,
                children: [
                  Icon(completed ? Icons.check : Icons.close_rounded),
                  Text(
                    completed ? "Won" : "Lost",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              Row(
                spacing: 5,
                children: [
                  Icon(Icons.timer_outlined),
                  Text(
                    toTimeFormat(duration),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              Row(
                spacing: 5,
                children: [
                  SvgPicture.asset(
                    'assets/card_play.svg',
                    semanticsLabel: 'Card Play Logo',
                    width: 20,
                    height: 20,
                  ),
                  Text(
                    moves.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
