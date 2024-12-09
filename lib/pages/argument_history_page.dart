import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:aitutor/services/auth_service.dart';

class ArgumentHistoryPage extends StatefulWidget {
  const ArgumentHistoryPage({Key? key}) : super(key: key);

  @override
  _ArgumentHistoryPageState createState() => _ArgumentHistoryPageState();
}

class _ArgumentHistoryPageState extends State<ArgumentHistoryPage> {
  late Future<List<Map<String, String>>> _allNotes;

  @override
  void initState() {
    super.initState();
    _allNotes = _loadAllNotes();
  }

  Future<List<Map<String, String>>> _loadAllNotes() async {
    final uid = AuthService().getUid(); // 유저의 uid 가져오기
    final DatabaseReference _dbRef =
        FirebaseDatabase.instance.ref('Chat/AI 글쓰기 튜터/History/$uid/AI LAW');
    final snapshot = await _dbRef.get();

    if (!snapshot.exists) {
      return []; // 데이터가 없을 경우 빈 리스트 반환
    }

    // 모든 노트를 리스트로 변환하고, 타입을 명시적으로 캐스팅
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.entries.map((entry) {
      final note = Map<String, dynamic>.from(entry.value);
      return {
        'time': entry.key,
        'contents': note['contents']?.toString() ?? 'No contents available',
        'response': note['response']?.toString() ?? 'No response available',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Argument History"),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _allNotes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final notes = snapshot.data!;
            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Time: ${note['time']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Note Contents:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            note['contents']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Evaluation Response:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            note['response']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text("No data available."));
          }
        },
      ),
    );
  }
}