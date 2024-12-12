import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/models/user_model.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/dialogs.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

String parseSubmittedText(String rawData) {
  // JSON 포맷에서 텍스트 추출
  String cleanedText = rawData
      .replaceAll('[{"insert":"', '') // 초반 불필요 텍스트 제거
      .replaceAll('"}]', '') // 마지막 불필요 텍스트 제거
      .replaceAll('\\n', '\n'); // \n을 실제 줄바꿈으로 변환

  return cleanedText;
}

List<TextSpan> parseRichText(String text) {
  // **문자**와 \"문자\", 그리고 숫자를 모두 볼드 처리하는 정규식
  final regex = RegExp(r'(\*\*(.+?)\*\*|\\\"(.+?)\\\"|\d+)');
  final matches = regex.allMatches(text);

  List<TextSpan> spans = [];
  int lastIndex = 0;

  for (var match in matches) {
    // 일반 텍스트 추가
    if (lastIndex < match.start) {
      spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
    }
    // 볼드체 텍스트 추가
    String? boldText = match.group(2) ?? match.group(3) ?? match.group(0); // **문자**, \"문자\", 또는 숫자 추출
    if (boldText != null) {
      spans.add(TextSpan(
        text: boldText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
    }
    lastIndex = match.end;
  }
  // 남은 일반 텍스트 추가
  if (lastIndex < text.length) {
    spans.add(TextSpan(text: text.substring(lastIndex)));
  }

  return spans;
}

String removeLastEvaluation(String text) {
  // 마지막 줄에 평가 결과가 포함되어 있으면 제거
  final lastLinePattern = RegExp(r'\*\*평가:\s.+?\*\*$', multiLine: true);
  text = text.replaceAll(lastLinePattern, '').trim();

  // '-' 기호 제거
  text = text.replaceAll(RegExp(r'\s*-\s*'), '\n');

  return text.trim(); // 양쪽 공백 제거
}


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

  Future<void> userInit() async {
    setState(() {
      _loading = true;
    });

    List resList = await UserServices().getUserModel(uid: AuthService().getUid());

    if (resList.first) {
      setState(() {
        _userModel = resList.last;
      });
    } else {
      Dialogs().onlyContentOneActionDialog(
        context: context,
        content: '사용자 정보를 불러오는 중 오류가 발생했습니다.\n${resList.last}',
        firstText: '확인',
      );
    }

    _evaluationHistory = _loadEvaluationHistory();

    setState(() {
      _loading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _loadEvaluationHistory() async {
    final uid = AuthService().getUid();
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('Chat/AI 글쓰기 튜터/History/$uid/AI LAW');
    final snapshot = await dbRef.get();

    if (!snapshot.exists) {
      return [];
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

    // 가장 최근 항목이 first가 되도록 정렬
    evaluations.sort((a, b) {
      String timeA = a['time'];
      String timeB = b['time'];
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

  String _formatDateFromString(String rawTime) {
    if (rawTime.length >= 8) {
      String monthStr = rawTime.substring(4, 6);
      String dayStr = rawTime.substring(6, 8);

      int month = int.tryParse(monthStr) ?? 0;
      int day = int.tryParse(dayStr) ?? 0;
      return "${month}월 ${day}일";
    }
    return "";
  }

  Color _getRatingColor(String rating) {
    switch (rating) {
      case "상":
        return Colors.green;
      case "중":
        return Colors.orange;
      case "하":
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                    ),
                  );
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final evaluations = snapshot.data!;
                  final recent = evaluations.first; // 가장 최근 평가
                  final recentRating = recent['rating'] ?? '알 수 없음';
                  final recentTimeStr = recent['time'] ?? '';
                  final recentDate = _formatDateFromString(recentTimeStr);

                  double screenWidth = MediaQuery.of(context).size.width;
                  double screenHeight = MediaQuery.of(context).size.height;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단 헤더
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
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
                        if (recentTimeStr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15),
                            child: Text(
                              "$recentDate ${_userModel.nm ?? ""}의 글쓰기 역량은 ...",
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
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: recentRating,
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: _getRatingColor(recentRating),
                                        fontFamily: 'Cafe24Oneprettynight',
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' 등급으로 평가되어요!',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cafe24Oneprettynight',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 최근 평가 1개 카드만 보여주기
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: _buildEvaluationCard(recent),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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
                child: Image.asset("assets/icons/argumentIcon.png"),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: arrowPadding, bottom: 10),
          child: SizedBox(
            width: 160,
            height: 100,
            child: Image.asset("assets/icons/arrowRed.png"),
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationCard(Map<String, dynamic> evaluation) {
    String rating = evaluation['rating'] ?? '알 수 없음';
    Color evaluationColor = _getRatingColor(rating);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기 결정
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF0F1E5E),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                "평가 결과: $rating 등급",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cafe24Oneprettynight',
                ),
              ),
            ),
          ),
          // 내용부는 스크롤 가능하도록 SingleChildScrollView 적용
          Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFe0e6f8), // 하늘색 배경
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "제출한 글쓰기 내용",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 200, // 박스 높이 지정
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF0F1E5E), width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: SingleChildScrollView(
                      child: RichText(
                        text: TextSpan(
                          children: parseRichText(parseSubmittedText(evaluation['contents'] ?? '작성 내용 없음')),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Cafe24Oneprettynight',
                            color: Colors.black, // 기본 텍스트 색상
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFe0e6f8), // 하늘색 배경
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "평가 근거",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      children: parseRichText(
                        removeLastEvaluation(
                          evaluation['response'] ?? '평가 근거 없음',
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Cafe24Oneprettynight',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
