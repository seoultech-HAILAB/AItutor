import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/models/user_model.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/dialogs.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:aitutor/models/colors_model.dart'; // 추가된 부분
import 'package:dropdown_button2/dropdown_button2.dart'; // 추가된 부분
import 'dart:ui' as ui; // 추가된 부분

String parseSubmittedText(String rawData) {
  String cleanedText = rawData
      .replaceAll('[{"insert":"', '')
      .replaceAll('"}]', '')
      .replaceAll('\\n', '\n');
  return cleanedText;
}

List<TextSpan> parseRichText(String text) {
  final regex = RegExp(r'(\*\*(.+?)\*\*|\\\"(.+?)\\\"|\d+)');
  final matches = regex.allMatches(text);

  List<TextSpan> spans = [];
  int lastIndex = 0;

  for (var match in matches) {
    if (lastIndex < match.start) {
      spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
    }
    String? boldText = match.group(2) ?? match.group(3) ?? match.group(0);
    if (boldText != null) {
      spans.add(TextSpan(
        text: boldText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
    }
    lastIndex = match.end;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(text: text.substring(lastIndex)));
  }

  return spans;
}

String removeLastEvaluation(String text) {
  final lastLinePattern = RegExp(r'\*\*평가:\s.+?\*\*$', multiLine: true);
  text = text.replaceAll(lastLinePattern, '').trim();
  text = text.replaceAll(RegExp(r'\s*-\s*'), '\n');
  return text.trim();
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

  // 추가된 부분 시작 -----------------------------------------
  final ColorsModel _colorsModel = ColorsModel();
  Map<DateTime, Map<String, dynamic>> _historyMap = {};
  DateTime? _recentTime;
  DateTime? _selectTime;
  Map<String, dynamic> _recentEvaluation = {};
  Map<String, dynamic> _selectEvaluation = {};
  // 추가된 부분 끝 -------------------------------------------

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

    List<Map<String, dynamic>> evaluations = await _evaluationHistory;
    if (evaluations.isNotEmpty) {
      // Map으로 관리
      for (var eval in evaluations) {
        DateTime dt = _parseDateTimeFromString(eval['time']);
        _historyMap[dt] = eval;
      }

      List<DateTime> timeList = _historyMap.keys.toList();
      timeList.sort((a, b) => b.compareTo(a));

      _recentTime = timeList.isNotEmpty ? timeList.first : null;
      _recentEvaluation = _recentTime != null ? _historyMap[_recentTime]! : {};

      // 지난 결과용 selectTime 설정(가장 최근 외 하나가 있다면 두번째로 최근값)
      if (timeList.length > 1) {
        _selectTime = timeList[1];
        _selectEvaluation = _historyMap[_selectTime]!;
      }

    }

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

  DateTime _parseDateTimeFromString(String rawTime) {
    // rawTime: YYYYMMDDHHMMSS 형식 가정
    // 실제 DB 구조에 따라 수정 필요할 수 있음
    if (rawTime.length >= 8) {
      String yearStr = rawTime.substring(0, 4);
      String monthStr = rawTime.substring(4, 6);
      String dayStr = rawTime.substring(6, 8);

      int year = int.tryParse(yearStr) ?? 2000;
      int month = int.tryParse(monthStr) ?? 1;
      int day = int.tryParse(dayStr) ?? 1;

      int hour = 0;
      int minute = 0;
      int second = 0;

      if (rawTime.length >= 10) {
        hour = int.tryParse(rawTime.substring(8, 10)) ?? 0;
      }
      if (rawTime.length >= 12) {
        minute = int.tryParse(rawTime.substring(10, 12)) ?? 0;
      }
      if (rawTime.length >= 14) {
        second = int.tryParse(rawTime.substring(12, 14)) ?? 0;
      }

      return DateTime(year, month, day, hour, minute, second);
    }
    return DateTime.now();
  }

  String _formatDateFromDateTime(DateTime dateTime) {
    String year = DateFormat('yyyy').format(dateTime);
    String month = DateFormat('MM').format(dateTime);
    String day = DateFormat('dd').format(dateTime);
    String hour = DateFormat('hh').format(dateTime);
    String period = DateFormat('a').format(dateTime) == 'AM' ? '오전' : '오후';

    return '$year년 $month월 $day일 $period $hour시';
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  // 최근 결과 표시
                  if (_recentTime != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Text(
                        "${_recentTime?.month}월 ${_recentTime?.day}일 ${_userModel.nm ?? ""}의 글쓰기 역량은 ...",
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cafe24Oneprettynight',
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),
                  if (_recentEvaluation.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDebateIconWithArrow(
                            screenWidth, screenHeight, _recentEvaluation),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 15, bottom: 50),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _recentEvaluation['rating'] ?? '알 수 없음',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: _getRatingColor(
                                        _recentEvaluation['rating'] ?? ''),
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
                  if (_recentEvaluation.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: _buildEvaluationCard(_recentEvaluation),
                    ),
                  const SizedBox(height: 20),
                  // 추가된 부분 시작: 지난 결과 조회하기 ---------------------------------
                  if (_historyMap.length > 1) // 기록이 2개 이상일 경우에만 지난 결과 조회
                    Container(
                      width: screenWidth,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F1E5E),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 10),
                        child: Center(
                          child: Text(
                            "지난 결과 조회하기",
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cafe24Oneprettynight',
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  if (_historyMap.length > 1)
                    const SizedBox(height: 20),
                  if (_historyMap.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: selectDateWidget(screenWidth),
                    ),
                  if (_historyMap.length > 1 && _selectTime != null)
                    const SizedBox(height: 20),
                  if (_historyMap.length > 1 && _selectTime != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Text(
                        "   ${_selectTime?.month}월 ${_selectTime?.day}일 ${_userModel.nm ?? ""}의 글쓰기 역량은 ...",
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cafe24Oneprettynight',
                        ),
                      ),
                    ),
                  if (_historyMap.length > 1 && _selectTime != null)
                    const SizedBox(height: 15),
                  if (_historyMap.length > 1 && _selectTime != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDebateIconWithArrow(
                            screenWidth, screenHeight, _selectEvaluation),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 15, bottom: 50),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _selectEvaluation['rating'] ?? '알 수 없음',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: _getRatingColor(
                                        _selectEvaluation['rating'] ?? ''),
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
                  if (_historyMap.length > 1 && _selectTime != null)
                    const SizedBox(height: 20),
                  if (_historyMap.length > 1 && _selectTime != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: _buildEvaluationCard(_selectEvaluation),
                    ),
                  const SizedBox(height: 20),
                  // 추가된 부분 끝: 지난 결과 조회하기 -----------------------------------
                ],
              ),
            ),
    );
  }

  Widget _buildDebateIconWithArrow(
      double screenWidth, double screenHeight, Map<String, dynamic> evaluation) {
    double debateImageWidth =
        screenWidth * 0.5 > 402 ? 402 : screenWidth * 0.5;
    double arrowPadding = 0.0;

    String recentRating = evaluation['rating'] ?? '알 수 없음';

    if (recentRating == '상') {
      arrowPadding = 300;
    } else if (recentRating == '중') {
      arrowPadding = 155;
    } else if (recentRating == '하') {
      arrowPadding = 6;
    }

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
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF0F1E5E),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                "평가 결과: $rating 등급",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cafe24Oneprettynight',
                ),
              ),
            ),
          ),
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
                      color: const Color(0xFFe0e6f8),
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
                    height: 200,
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
                            color: Colors.black,
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
                      color: const Color(0xFFe0e6f8),
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

  // 추가된 부분 시작: selectDateWidget -----------------------------------------
  Widget selectDateWidget(double screenWidth) {
    bool isExpanded = false;
    return StatefulBuilder(builder: (BuildContext context, stateSetter) {
      // 최근 기록 제외
      List<DateTime> dates = _historyMap.keys.toList();
      dates.sort((a, b) => b.compareTo(a));
      if (dates.isNotEmpty) {
        dates.removeAt(0);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "날짜 선택",
            style: TextStyle(
                fontSize: 20,
                color: _colorsModel.gr1,
                fontFamily: 'Cafe24Oneprettynight'),
          ),
          const SizedBox(height: 5),
          Container(
            height: 60,
            width: screenWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _colorsModel.gr3, width: 1),
              borderRadius: isExpanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8))
                  : const BorderRadius.all(Radius.circular(8)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                selectedItemHighlightColor: _colorsModel.selectedBoxColor,
                itemHighlightColor: _colorsModel.main.withOpacity(0.7),
                buttonDecoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: isExpanded
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8))
                      : const BorderRadius.all(Radius.circular(8)),
                ),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset("assets/icons/caret_down.png"),
                  ),
                ),
                itemPadding: const EdgeInsets.only(left: 0),
                dropdownMaxHeight: 200,
                onMenuStateChange: (changed) {
                  stateSetter(() {
                    isExpanded = changed;
                  });
                },
                dropdownDecoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8)),
                  color: _colorsModel.wh,
                ),
                hint: SizedBox(
                  height: 50,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Text(
                        '날짜를 선택해주세요',
                        style: TextStyle(
                            fontSize: 16,
                            color: _colorsModel.gr1,
                            fontFamily: 'Cafe24Oneprettynight'),
                      ),
                    ),
                  ),
                ),
                items: dates
                    .map((item) => DropdownMenuItem<DateTime>(
                          value: item,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: FittedBox(
                              child: Text(
                                _formatDateFromDateTime(item),
                                style: TextStyle(
                                    fontSize: 20,
                                    color: _colorsModel.gr1,
                                    fontFamily: 'Cafe24Oneprettynight'),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
                value: _selectTime,
                onChanged: (value) {
                  setState(() {
                    _selectTime = value;
                    _selectEvaluation = _historyMap[_selectTime] ?? {};
                  });
                },
                buttonHeight: 40,
                buttonWidth: 90,
                itemHeight: 40,
              ),
            ),
          ),
        ],
      );
    });
  }
  // 추가된 부분 끝: selectDateWidget -----------------------------------------
}
