import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:intl/intl.dart';

class ArgumentHistoryPage extends StatefulWidget {
  const ArgumentHistoryPage({Key? key}) : super(key: key);

  @override
  _ArgumentHistoryPageState createState() => _ArgumentHistoryPageState();
}

class _ArgumentHistoryPageState extends State<ArgumentHistoryPage> {
  late Future<List<Map<String, dynamic>>> _evaluationHistory;

  @override
  void initState() {
    super.initState();
    _evaluationHistory = _loadEvaluationHistory();
  }

  Future<List<Map<String, dynamic>>> _loadEvaluationHistory() async {
    final uid = AuthService().getUid(); // 유저의 uid 가져오기
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('Chat/AI 글쓰기 튜터/History/$uid/AI LAW');
    final snapshot = await dbRef.get();

    if (!snapshot.exists) {
      return []; // 데이터가 없을 경우 빈 리스트 반환
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final List<Map<String, dynamic>> evaluations = data.entries.map((entry) {
      final evaluation = Map<String, dynamic>.from(entry.value);
      return {
        'time': entry.key,
        'contents': evaluation['contents'] ?? '',
        'response': evaluation['response'] ?? '',
        'rating': _extractRating(evaluation['response'] ?? ''),
      };
    }).toList();

    evaluations.sort((a, b) {
      DateTime? aTime = _tryParseDateTime(a['time']);
      DateTime? bTime = _tryParseDateTime(b['time']);
      if (aTime != null && bTime != null) {
        return bTime.compareTo(aTime);
      }
      return 0;
    });

    return evaluations;
  }

  DateTime? _tryParseDateTime(String time) {
    // 실제 데이터 포맷에 맞게 수정 필요
    try {
      return DateFormat("yyyy-MM-dd HH:mm:ss").parse(time);
    } catch (_) {
      return null;
    }
  }

  String _extractRating(String response) {
    if (response.contains("평가: 상")) {
      return "상";
    } else if (response.contains("평가: 중")) {
      return "중";
    } else if (response.contains("평가: 하")) {
      return "하";
    }
    return "알 수 없음";
  }

  String _getAverageResult(List<Map<String, dynamic>> evaluations) {
    int countHigh = 0;
    int countMedium = 0;
    int countLow = 0;

    for (var eval in evaluations) {
      String rating = eval['rating'];
      if (rating == '상') {
        countHigh++;
      } else if (rating == '중') {
        countMedium++;
      } else if (rating == '하') {
        countLow++;
      }
    }

    // 단순한 예시 로직
    if (countHigh == evaluations.length) {
      return '탁월함';
    } else if (countHigh > 1 && countMedium > 1 && countLow < 1) {
      return '우수함';
    } else if (countMedium == evaluations.length) {
      return '적절함';
    } else if (countMedium < 1 && countLow > 1 && countHigh > 1) {
      return '보통';
    } else if (countLow == evaluations.length) {
      return '미흡함';
    } else {
      return '해당 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _evaluationHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(fontFamily: 'Cafe24Oneprettynight'),
            ));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final evaluations = snapshot.data!;
            final averageResult = _getAverageResult(evaluations);

            Color averageColor = Colors.black;
            if (averageResult == '탁월함') {
              averageColor = Colors.green;
            } else if (averageResult == '우수함') {
              averageColor = Colors.green[300]!;
            } else if (averageResult == '적절함') {
              averageColor = Colors.orange;
            } else if (averageResult == '보통') {
              averageColor = Colors.orange[300]!;
            } else if (averageResult == '미흡함') {
              averageColor = Colors.red;
            }

            // 가장 최근 기록 날짜
            DateTime? recentDate;
            if (evaluations.isNotEmpty) {
              recentDate = _tryParseDateTime(evaluations.first['time']);
            }

            double screenWidth = MediaQuery.of(context).size.width;
            double screenHeight = MediaQuery.of(context).size.height;

            return ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                // 상단 헤더
                Container(
                  width: screenWidth,
                  color: const Color(0xFF0F1E5E),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Center(
                    child: Text(
                      "글쓰기 평가 기록",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cafe24Oneprettynight',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (recentDate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 60, right: 60),
                    child: Text(
                      "${recentDate.month}월 ${recentDate.day}일의 평가 결과, 당신의 비판적 사고능력은 ...",
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDebateIconWithArrow(screenWidth, screenHeight),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 50),
                      child: RichText(
                          text: TextSpan(children: [
                        TextSpan(
                          text: averageResult,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: averageColor,
                            fontFamily: 'Cafe24Oneprettynight',
                          ),
                        ),
                        const TextSpan(
                          text: ' 정도의 비판적 사고능력을 보여주고 있어요!',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cafe24Oneprettynight',
                            color: Colors.black,
                          ),
                        ),
                      ])),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 평가 리스트 출력: GridView로 변경
                _buildEvaluationGrid(evaluations, screenWidth),
                const SizedBox(height: 20),
              ],
            );
          } else {
            return const Center(
              child: Text(
                "데이터가 없습니다.",
                style: TextStyle(fontFamily: 'Cafe24Oneprettynight'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDebateIconWithArrow(double screenWidth, double screenHeight) {
    double debateImageWidth = screenWidth * 0.5 > 402 ? 402 : screenWidth * 0.5;
    double arrowPadding = (debateImageWidth - 99) / 2;

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: SizedBox(
                width: debateImageWidth,
                height: debateImageWidth * (208 / 402),
                child: Image.asset("assets/icons/debateIcon.png"),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: arrowPadding),
          child: SizedBox(
            width: 99,
            height: 100,
            child: Image.asset("assets/icons/arrowRed.png"),
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationGrid(List<Map<String, dynamic>> evaluations, double screenWidth) {
    // GridView로 변환하여 자식들을 일정 크기로 배치
    // shrinkWrap와 NeverScrollableScrollPhysics로 내부 스크롤 방지 (상위 ListView에만 스크롤 위임)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: evaluations.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: (screenWidth > 800) ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7, // 카드 비율 조정
        ),
        itemBuilder: (context, index) {
          final evaluation = evaluations[index];
          return _buildEvaluationCard(evaluation);
        },
      ),
    );
  }

  Widget _buildEvaluationCard(Map<String, dynamic> evaluation) {
    String rating = evaluation['rating'] ?? '알 수 없음';
    Color evaluationColor = Colors.grey;
    String imagePath = 'assets/icons/debateLow.png';

    if (rating == '상') {
      evaluationColor = Colors.green;
      imagePath = 'assets/icons/debateHigh.png';
    } else if (rating == '중') {
      evaluationColor = Colors.orange;
      imagePath = 'assets/icons/debateMedium.png';
    } else if (rating == '하') {
      evaluationColor = Colors.red;
      imagePath = 'assets/icons/debateLow.png';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFe0e6f8),
        border: Border.all(
          color: const Color(0xFF0F1E5E),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 헤더
          Container(
            color: const Color(0xFF0F1E5E),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Center(
              child: Text(
                "평가 등급",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cafe24Oneprettynight',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Image.asset(imagePath),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              color: evaluationColor.withOpacity(0.2),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  "$rating 등급",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cafe24Oneprettynight',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "[작성 내용]",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      evaluation['contents'] ?? '작성 내용 없음',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "[평가 결과]",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      evaluation['response'] ?? '평가 결과 없음',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "시간: ${evaluation['time']}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
