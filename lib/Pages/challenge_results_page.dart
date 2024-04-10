import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChallengeResultsPage extends StatefulWidget {
  const ChallengeResultsPage({super.key});

  @override
  State<ChallengeResultsPage> createState() => _ChallengeResultsPageState();
}

class _ChallengeResultsPageState extends State<ChallengeResultsPage> {
  late Future<List<QueryDocumentSnapshot>> challengeResults;

  @override
  void initState() {
    super.initState();
    challengeResults = getChallengeResults();
  }

  Future<List<QueryDocumentSnapshot>> getChallengeResults() async {
    // get the challenge results
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Challenges').get();
    // return challenge documents
    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFD3C3),
      appBar: AppBar(
        title: Text('Challenge Results'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: challengeResults,
        builder: (context, snapshot) {
          // check for errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: $snapshot.error'));
          }

          // show a loading spinner while waiting for challenge data
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // display the challenge data
          var challenges = snapshot.data!;

          return ListView.builder(
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              // convert snapshot to a Map
              var challenge = challenges[index].data() as Map<String, dynamic>;

              String challengeName = challenge['name'];
              bool isActive = challenge['active'] ?? false;
              bool isSuccess = challenge['success'] ?? false;
              String challengeImage = challenge['currentMap'];

              // Determine background color based on challenge status
              Color backgroundColor;
              if (isSuccess) {
                backgroundColor = Color(0xBB283D3B); // Success color
              } else if (isActive) {
                backgroundColor = Colors.white;
                // Active (pending) color
              } else {
                backgroundColor = Color(0xBBF45B69); // Failed or inactive color
              }

              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(challengeImage,
                            height: 50, width: 50, fit: BoxFit.cover)),
                    title: Text(challengeName),
                    subtitle: Text('Results for Challenge $index'),
                    trailing: isSuccess
                        ? Icon(Icons.check)
                        : isActive
                            ? Icon(Icons.pending)
                            : Icon(Icons.error),
                    onTap: () {},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
