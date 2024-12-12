import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/models/user_model.dart'; // UserModel import
import 'package:aitutor/services/user_services.dart'; // UserServices import
import 'package:aitutor/services/chat_services.dart'; // ChatServices import
import 'package:aitutor/widgets/dialogs.dart'; // Dialogs import
import 'package:intl/intl.dart';

class ArgumentHistoryPage extends StatefulWidget {
  const ArgumentHistoryPage({Key? key}) : super(key: key);

  @override
  _ArgumentHistoryPageState createState() => _ArgumentHistoryPageState();
}

class _ArgumentHistoryPageState extends State<ArgumentHistoryPage> {
  late Future<List<Map<String, dynamic>>> _evaluationHistory;
  UserModel _userModel = UserModel();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    userInit();
  }

  // 사용자 정보를 불러오는 메서드
  Future<void> userInit() async {
    setState(() {
      _loading = true;
    });

    // 사용자 정보 로드
    List resList = await UserServices().getUserModel(uid: AuthService().getUid());

    if (resList.first) {
      setState(() {
        _userModel = resList.last;
      });
    } else {
      // 사용자 정보 로드 실패 시 Dialog를 띄우거나 에러 처리
      Dialogs().onlyContentOneActionDialog(
        context: context,
        content: '사용자 정보를 불러오는 중 오류가 발생했습니다.\n${resList.last}',
        firstText: '확인',
      );
    }

    // 사용자 정보를 로드한 뒤 평가 히스토리 로드를 진행
    _evaluationHistory = _loadEvaluationHistory();

    setState(() {
      _loading = false;
    });
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

    // 시간 기준으로 내림차순 정렬
    evaluations.sort((a, b) {
      // 기존 tryParseDateTime 제거 후 그대로 사용
      // 여기서는 정렬이 필요하다면 time 문자열을 파싱해서 비교 가능
      // time 형식: YYYYMMDD_HHmmss
      String timeA = a['time'];
      String timeB = b['time'];
      // 최신 순 정렬: timeB.compareTo(timeA)
      return timeB.compareTo(timeA);
    });

    return evaluations;
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

  /// "20241210_165457" 형식의 문자열을 "12월 10일" 형태로 포맷하는 메서드
  String _formatDateFromString(String rawTime) {
    // rawTime: "YYYYMMDD_HHmmss" 형식 가정
    // 예: "20241210_165457" -> year=2024, month=12, day=10
    // month월 day일
    if (rawTime.length >= 8) {
      String monthStr = rawTime.substring(4, 6);
      String dayStr = rawTime.substring(6, 8);

      int month = int.tryParse(monthStr) ?? 0;
      int day = int.tryParse(dayStr) ?? 0;
      return "${month}월 ${day}일";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
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

                  // 가장 최근 기록 시간 문자열
                  String? recentTimeStr;
                  if (evaluations.isNotEmpty) {
                    recentTimeStr = evaluations.first['time'];
                  }

                  double screenWidth = MediaQuery.of(context).size.width;
                  double screenHeight = MediaQuery.of(context).size.height;

                  return ListView(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      // 상단 헤더
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15), // 좌우 10 공백 추가
                        child: Container(
                          width: screenWidth,
                          color: const Color(0xFF0F1E5E),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              "${_userModel.nm ?? ""}님의 글쓰기 역량",
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cafe24Oneprettynight',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (recentTimeStr != null && recentTimeStr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 60),
                          child: Text(
                            "   ${_formatDateFromString(recentTimeStr)} ${_userModel.nm ?? ""}의 글쓰기 역량은 ...",
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cafe24Oneprettynight',
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDebateIconWithArrow(screenWidth, screenHeight),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 15, bottom: 50),
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
    double debateImageWidth =
        screenWidth * 0.5 > 402 ? 402 : screenWidth * 0.5;
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
                child: Image.asset("asset/icons/argumentIcon.png"),
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
