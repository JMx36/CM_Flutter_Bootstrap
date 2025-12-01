import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 40,
      children: [
        Text("Stats", style: Theme.of(context).textTheme.displayLarge),
        HistoryList(),
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

  double avgTime = 0;
  int bestTime = 0;
  int totalGames = 0;
  int avgFlips = 0;

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
    print("Fetching history ");
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

        double totalTime = 0;
        int totalFlips = 0;
        int tempBestTime = 99999999;

        for (var value in values) {
          int duration = value["duration"] as int;
          totalFlips += value["flips"] as int;
          totalTime += duration;
          bool wasCompleted = value["completed"] as bool;
          if (wasCompleted && duration < tempBestTime) {
            tempBestTime = duration;
          }
        }
        setState(() {
          avgTime = (totalTime / values.length);
          avgFlips = (totalFlips / values.length).round();
          totalGames = values.length;
          bestTime = tempBestTime == 99999999 ? 0 : tempBestTime;
        });
      }
    } catch (e) {
      print("Error fetching history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        crossAxisCount: 2,
      ),
      children: [
        getCard(
          "Best Time",
          Icon(Icons.bolt),
          toTimeFormat(bestTime.round()),
          context,
        ),
        getCard(
          "Avg. Time",
          Icon(Icons.timer_outlined),
          toTimeFormat(avgTime.round()),
          context,
        ),
        getCard(
          "Total Games",
          Icon(Icons.sports_esports),
          totalGames.toString(),
          context,
        ),
        getCard(
          "Avg. moves",
          SvgPicture.asset(
            'assets/card_play.svg',
            semanticsLabel: 'Card Play Logo',
            width: 25,
            height: 25,
          ),
          avgFlips.toString(),
          context,
        ),
      ],
    );
  }
}

const m_colors = [Colors.deepPurple];

int currColorIdx = -1;
Card getCard(String title, Widget icon, String value, BuildContext context) {
  currColorIdx = (currColorIdx + 1) % m_colors.length;
  return Card(
    color: m_colors[currColorIdx],
    child: Padding(
      padding: .all(10),
      child: Column(
        spacing: 20,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              icon,
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
