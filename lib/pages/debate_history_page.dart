import 'package:aitutor/models/colors_model.dart';
import 'package:aitutor/models/debate_result.dart';
import 'package:aitutor/models/user_model.dart';
import 'package:aitutor/providers/page_provider.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/services/chat_services.dart';
import 'package:aitutor/services/classification_platform.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class DebateHistoryPage extends StatefulWidget {
  const DebateHistoryPage({Key? key}) : super(key: key);

  @override
  State<DebateHistoryPage> createState() => _DebateHistoryPageState();
}

class _DebateHistoryPageState extends State<DebateHistoryPage> {

  PageProvider _pageProvider = PageProvider();
  final ColorsModel _colorsModel = ColorsModel();
  UserModel _userModel = UserModel();
  Map _historyMap = {};  // {Datetime time : {'comment': , 'result': List<DebateResult>}}
  DateTime? _selectTime;
  String _comment = '';
  List<DebateResult> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      userInit();
    });
  }

  @override
  Widget build(BuildContext context) {
    _pageProvider = Provider.of<PageProvider>(context, listen: true);

    var screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = ClassificationPlatform().classifyWithScreenSize(context: context) == 2;

    print('_results ${_results}');
    return Stack(
      children: [
        ListView(
          children: [
            const SizedBox(height: 15,),
            _pageProvider.isFromChat ? Container() : selectDateWidget(screenWidth, isWeb),
            _pageProvider.isFromChat ? Container() : const SizedBox(height: 15,),
            _comment.isEmpty ? Container() : Padding(
              padding: const EdgeInsets.only(left: 60, right: 60),
              child: Text("${_comment}", style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontFamily: 'Cafe24Oneprettynight'
              ), textAlign: TextAlign.center, ),
            ),
            _comment.isEmpty ? Container() : const SizedBox(height: 15,),
            _results.isEmpty ? _comment.isNotEmpty ? Container() : Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: Text("아직 대화 기록이 없습니다", style: TextStyle(
                  fontSize: 16,
                  color: _colorsModel.gr1,
                  fontFamily: 'Cafe24Oneprettynight'
                ),),
              ),
            )
                : evaluateWidget(screenWidth, isWeb, _results),  // _results 전체를 전달
          ],
        ),
        _loading ? Center(child: CircularProgressIndicator(color: _colorsModel.main,),) : Container()
      ],
    );
  }

  Widget evaluateWidget(double screenWidth, bool isWeb, List<DebateResult> evaluationResults) {
    // 각 evaluationResult의 explain 부분을 기준으로 가장 큰 높이를 계산
    double maxExplainHeight = evaluationResults.map((result) {
      final textPainter = TextPainter(
        text: TextSpan(text: ": ${result.explain}", style: const TextStyle(fontSize: 16, fontFamily: 'Cafe24Oneprettynight')),
        textDirection: ui.TextDirection.ltr,
        maxLines: null,
      );
      textPainter.layout(maxWidth: screenWidth - 120); // padding 고려

      return textPainter.height;
    }).reduce((curr, next) => curr > next ? curr : next);

    // 전체 텍스트를 고려하여 가장 큰 높이를 계산
    double maxHeight = evaluationResults.map((result) {
      final combinedText = [
        result.detail,
        result.interaction1,
        result.reason1,
        result.interaction2,
        result.reason2
      ].join("\n");

      final textPainter = TextPainter(
        text: TextSpan(text: combinedText, style: const TextStyle(fontSize: 16, fontFamily: 'Cafe24Oneprettynight')),
        textDirection: ui.TextDirection.ltr,
        maxLines: null,
      );
      textPainter.layout(maxWidth: (screenWidth - 120) / evaluationResults.length - 30); // padding 고려

      // 설명 텍스트와 상자의 기본 padding을 고려한 높이
      return textPainter.height + maxExplainHeight + 160; // 추가 여백 포함
    }).reduce((curr, next) => curr > next ? curr : next);

    return Padding(
      padding: isWeb
          ? const EdgeInsets.only(left: 60, right: 60, bottom: 30)
          : const EdgeInsets.only(left: 15, right: 15, bottom: 10),
      child: Row(
        children: evaluationResults.map((evaluationResult) {
          Color evaluationColor = _colorsModel.blue;

          if (evaluationResult.evaluation.toString().contains('상')) {
            evaluationColor = _colorsModel.blue;
          } else if (evaluationResult.evaluation.toString().contains('중')) {
            evaluationColor = _colorsModel.orange;
          } else if (evaluationResult.evaluation.toString().contains('하')) {
            evaluationColor = _colorsModel.red;
          }

          // Interaction 번호 처리
          String interaction1 = evaluationResult.interaction1!;
          if (interaction1.startsWith("1.")) {
            interaction1 = interaction1.substring(2).trim();
          } else {
            interaction1 = "1. $interaction1";
          }

          String interaction2 = evaluationResult.interaction2!;
          if (interaction2.startsWith("2.")) {
            interaction2 = interaction2.substring(2).trim();
          } else {
            interaction2 = "2. $interaction2";
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10), // 각 박스 간의 간격 조정
              child: Container(
                height: maxHeight + 100, // 모든 항목의 높이를 동일하게 설정
                decoration: BoxDecoration(
                  color: _colorsModel.gr4,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category (center aligned, larger font)
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "${evaluationResult.category}",
                          style: const TextStyle(
                            fontSize: 20, // 글씨 크기를 키움
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cafe24Oneprettynight'
                          ),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      // Explain (left aligned, starts with ":")
                      Container(
                        height: maxExplainHeight + 40, // 최대 explain 높이를 설정하여 높이를 통일
                        child: Text(
                          ": ${evaluationResult.explain}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontFamily: 'Cafe24Oneprettynight'
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(height: 10,), // Explain 밑에 간격 추가
                      // Evaluation (center aligned)
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "${evaluationResult.evaluation}",
                          style: TextStyle(
                            fontSize: 16,
                            color: evaluationColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cafe24Oneprettynight'
                          ),
                        ),
                      ),
                      const SizedBox(height: 20,),
                      // Details (left aligned in a white box)
                      Expanded( // 이 부분을 추가하여 흰색 박스가 남은 공간을 채우도록 수정
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: SingleChildScrollView( // 스크롤 가능하도록 수정
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title '[평가 근거]'
                                const Text(
                                  "[평가 근거]",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'Cafe24Oneprettynight'
                                  ),
                                ),
                                const SizedBox(height: 10,), // 한줄 띄움
                                // Detail
                                Text(
                                  "${evaluationResult.detail}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontFamily: 'Cafe24Oneprettynight'
                                  ),
                                ),
                                const SizedBox(height: 10,), // 한줄 띄움
                                // Interaction 1
                                Text(
                                  interaction1,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontFamily: 'Cafe24Oneprettynight'
                                  ),
                                ),
                                // Reason 1 with right arrow
                                Text(
                                  "→ ${evaluationResult.reason1}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cafe24Oneprettynight'
                                  ),
                                ),
                                const SizedBox(height: 10,), // 한줄 띄움
                                // Interaction 2
                                Text(
                                  interaction2,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontFamily: 'Cafe24Oneprettynight'
                                  ),
                                ),
                                // Reason 2 with right arrow
                                Text(
                                  "→ ${evaluationResult.reason2}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cafe24Oneprettynight'
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }








  Widget selectDateWidget(screenWidth, isWeb) {
    bool _isExpanded = false;
    return StatefulBuilder(builder: (BuildContext context, stateSetter) {
      return Padding(
        padding: isWeb ? const EdgeInsets.only(left: 60, right: 60) : const EdgeInsets.only(left: 15, right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("날짜 선택", style: TextStyle(
              fontSize: 20,
              color: _colorsModel.gr1,
              fontFamily: 'Cafe24Oneprettynight'
            ),),
            const SizedBox(height: 5,),
            Container(
              height: 60,
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _colorsModel.gr3, width: 1),
                borderRadius: _isExpanded ? const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8)
                ) : const BorderRadius.all(Radius.circular(8)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton2(
                  selectedItemHighlightColor: _colorsModel.selectedBoxColor,
                  itemHighlightColor: _colorsModel.main.withOpacity(0.7),
                  buttonDecoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: _isExpanded ? const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8)
                    ) : const BorderRadius.all(Radius.circular(8)),
                  ),
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset("assets/icons/caret_down.png"),
                    ),
                  ),
                  itemPadding: EdgeInsets.only(left: 0),
                  dropdownMaxHeight: 200,
                  onMenuStateChange: (changed) {
                    stateSetter(() {
                      _isExpanded = changed;
                    });
                  },
                  dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.only(bottomRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
                    color: _colorsModel.wh,
                  ),
                  hint: Container(
                    height: 50,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Text(
                          '날짜를 선택해주세요',
                          style: TextStyle(
                            fontSize: 16,
                            color: _colorsModel.gr1,
                            fontFamily: 'Cafe24Oneprettynight'
                          ),
                        ),
                      ),
                    ),
                  ),
                  items: _historyMap.keys.toList()
                      .map((item) => DropdownMenuItem<DateTime>(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: FittedBox(
                        child: Text(
                          '${formatDateTime(item)}',
                          style: TextStyle(
                            fontSize: 20,
                            color: _colorsModel.gr1,
                            fontFamily: 'Cafe24Oneprettynight'
                          ),
                        ),
                      ),
                    ),
                  ))
                      .toList(),
                  value: _selectTime,
                  onChanged: (value) {
                    String comment = '';
                    List<DebateResult> results = [];

                    if (_historyMap.isNotEmpty) {
                      Map dataMap = _historyMap[value] ?? {};
                      comment = dataMap['comment'] ?? '';
                      results = List<DebateResult>.from(dataMap['result'] ?? []);
                    }

                    setState(() {
                      _selectTime = value;
                      _comment = comment;
                      _results = results;
                    });
                  },
                  buttonHeight: 40,
                  buttonWidth: 90,
                  itemHeight: 40,
                ),
              ),
            ),
          ],
        ),
      );
    });
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

      if (_pageProvider.isFromChat) {
        List chatEvaluations = _pageProvider.chatEvaluations;
        if (chatEvaluations.isNotEmpty) {
          setState(() {
            _comment = chatEvaluations.first;
            _results = List<DebateResult>.from(chatEvaluations.last);
          });
        }
      } else {
        List historyResList = await ChatServices().getDebateHistory(uid: _userModel.uid, chatModelKey: _pageProvider.selectChatModel.key);
        if (historyResList.first) {
          Map historyMap = historyResList.last; // {Datetime time : {'comment': , 'result': List<DebateResult>}}

          List timeList = historyMap.keys.toList();
          timeList.sort((a, b) => b.compareTo(a));

          Map<DateTime, Map<String, dynamic>> tempHistoryMap = {};
          for (DateTime time in timeList) {
            tempHistoryMap[time] = historyMap[time];
          }

          historyMap = tempHistoryMap;

          DateTime? selectTime;
          String comment = '';
          List<DebateResult> results = [];

          if (historyMap.isNotEmpty) {
            selectTime = historyMap.keys.toList().first;

            Map dataMap = historyMap[selectTime] ?? {};
            comment = dataMap['comment'] ?? '';
            results = List<DebateResult>.from(dataMap['result'] ?? []);
          }

          setState(() {
            _historyMap = historyMap;
            _selectTime = selectTime;
            _comment = comment;
            _results = results;
          });
        } else {
          Dialogs().onlyContentOneActionDialog(context: context, content: '기록 로드 중 오류\n${historyResList.last}', firstText: '확인');
        }
      }
    }

    setState(() {
      _loading = false;
    });
  }

  String formatDateTime(DateTime dateTime) {
    String year = DateFormat('yyyy').format(dateTime);
    String month = DateFormat('MM').format(dateTime);
    String day = DateFormat('dd').format(dateTime);
    String hour = DateFormat('hh').format(dateTime);
    String period = DateFormat('a').format(dateTime) == 'AM' ? '오전' : '오후';

    return '$year년 $month월 $day일 $period $hour시';
  }
}
