import 'package:aitutor/models/colors_model.dart';
import 'package:aitutor/models/debate_result.dart';
import 'package:aitutor/models/user_model.dart';
import 'package:aitutor/providers/page_provider.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/services/chat_services.dart';
import 'package:aitutor/services/classification_platform.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/dialogs.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:dropdown_button2/dropdown_button2.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:aitutor/services/size_calculate.dart';
import 'dart:ui' as ui;

class DebateHistoryPage extends StatefulWidget {
  const DebateHistoryPage({super.key});

  @override
  State<DebateHistoryPage> createState() => _DebateHistoryPageState();
}

class _DebateHistoryPageState extends State<DebateHistoryPage> {
  PageProvider _pageProvider = PageProvider();
  final ColorsModel _colorsModel = ColorsModel();
  UserModel _userModel = UserModel();
  Map _historyMap =
      {}; // {Datetime time : {'comment': , 'result': List<DebateResult>}}
  DateTime? _recentTime;
  DateTime? _selectTime;
  String _recentComment = '';
  List<DebateResult> _selectResults = [];
  List<DebateResult> _recentResults = [];
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
    bool isWeb =
        ClassificationPlatform().classifyWithScreenSize(context: context) == 2;

    return Stack(
      children: [
        ListView(
          children: [
            const SizedBox(
              height: 15,
            ),
            // _pageProvider.isFromChat
            //     ? Container()
            //     : selectDateWidget(screenWidth, isWeb),
            _pageProvider.isFromChat
                ? Container()
                : const SizedBox(
                    height: 15,
                  ),
            _recentComment.isEmpty
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(left: 60, right: 60),
                    child: Text(
                      _recentComment,
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontFamily: 'Cafe24Oneprettynight'),
                      textAlign: TextAlign.center,
                    ),
                  ),
            _recentComment.isEmpty
                ? Container()
                : const SizedBox(
                    height: 15,
                  ),
            _recentResults.isEmpty
                ? _recentComment.isNotEmpty
                    ? Container()
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60.0),
                          child: Text(
                            "아직 대화 기록이 없습니다",
                            style: TextStyle(
                                fontSize: 16,
                                color: _colorsModel.gr1,
                                fontFamily: 'Cafe24Oneprettynight'),
                          ),
                        ),
                      )
                : Column(
                    children: [
                      const SizedBox(height: 8),
                      recentEvaluateWidget(
                          screenWidth, screenWidth, isWeb, _recentResults),
                      evaluateWidget(
                          screenWidth, screenWidth, isWeb, _selectResults),
                    ],
                  ),
          ],
        ),
        _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: _colorsModel.main,
                ),
              )
            : Container()
      ],
    );
  }

  Widget recentEvaluateWidget(double screenWidth, double screenHeight,
      bool isWeb, List<DebateResult> evaluationResults) {
    Color averageColor = Colors.black;

    double debateImageWidth = SizeCalculate().widthCalculate(screenWidth, 402);
    double arrowPadding = 0.0;

    arrowPadding = (debateImageWidth - 99) / 2;

    String averageResult = getAverageResult(evaluationResults);

    if (averageResult == '탁월함') {
      averageColor = Colors.green;
      arrowPadding = 325; // Move arrow to rightmost position
    } else if (averageResult == '우수함') {
      averageColor = Colors.green[300]!;
      arrowPadding = 250; // Move arrow to right position
    } else if (averageResult == '적절함') {
      averageColor = Colors.orange;
      arrowPadding = 170; // Move arrow to center position
    } else if (averageResult == '보통') {
      averageColor = Colors.orange[300]!;
      arrowPadding = 95; // Move arrow to left position
    } else if (averageResult == '미흡함') {
      averageColor = Colors.red;
      arrowPadding = 15; // Move arrow to leftmost position
    }

    // 각 evaluationResult의 explain 부분을 기준으로 가장 큰 높이를 계산
    double maxExplainHeight = evaluationResults.map((result) {
      final textPainter = TextPainter(
        text: TextSpan(
            text: ": ${result.explain}",
            style: const TextStyle(
                fontSize: 16, fontFamily: 'Cafe24Oneprettynight')),
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
        text: TextSpan(
            text: combinedText,
            style: const TextStyle(
                fontSize: 16, fontFamily: 'Cafe24Oneprettynight')),
        textDirection: ui.TextDirection.ltr,
        maxLines: null,
      );
      textPainter.layout(
          maxWidth: (screenWidth - 120) / evaluationResults.length -
              30); // padding 고려

      // 설명 텍스트와 상자의 기본 padding을 고려한 높이
      return textPainter.height + maxExplainHeight + 160; // 추가 여백 포함
    }).reduce((curr, next) => curr > next ? curr : next);

    return Padding(
      padding: isWeb
          ? const EdgeInsets.only(left: 60, right: 60, bottom: 30)
          : const EdgeInsets.only(left: 15, right: 15, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------------------------
          // 헤더
          // ----------------------------------------------------------------------
          Container(
            width: screenWidth,
            decoration: const BoxDecoration(
              color: Color(0xFF0F1E5E), // 변경된 색상
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Center(
                child: Text(
                  "${_userModel.nm ?? ""}님의 비판적 사고능력",
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cafe24Oneprettynight',
                      color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ----------------------------------------------------------------------
          // 최근 결과 요약
          // ----------------------------------------------------------------------
          Text(
            "${_recentTime?.month}월 ${_recentTime?.day}일 ${_userModel.nm ?? ""}님의 비판적 사고능력은 ...",
            style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cafe24Oneprettynight'),
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: SizedBox(
                          width: debateImageWidth,
                          height: SizeCalculate()
                              .heightCalculate(screenHeight, 208),
                          child: Image.asset("assets/icons/debateIcon.png"),
                        ),
                      ),
                      SizedBox(
                        height:
                            SizeCalculate().heightCalculate(screenHeight, 70),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: arrowPadding, bottom: 20),
                    child: SizedBox(
                      width: SizeCalculate().widthCalculate(screenWidth, 120),
                      height:
                          SizeCalculate().heightCalculate(screenHeight, 100),
                      child: Image.asset("assets/icons/arrowRed.png"),
                    ),
                  ),
                ],
              ),
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
                        fontFamily: 'Cafe24Oneprettynight'),
                  ),
                  const TextSpan(
                      text: ' 정도의 비판적 사고능력을 보여주고 있어요!',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cafe24Oneprettynight')),
                ])),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: evaluationResults.map((evaluationResult) {
              // Color evaluationColor = Colors.grey;

              // if (evaluationResult.evaluation.toString().contains('상')) {
              //   evaluationColor = Colors.green;
              // } else if (evaluationResult.evaluation.toString().contains('중')) {
              //   evaluationColor = Colors.orange;
              // } else if (evaluationResult.evaluation.toString().contains('하')) {
              //   evaluationColor = Colors.red;
              // }

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
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    height: maxHeight + 250,
                    decoration: BoxDecoration(
                      color: _colorsModel.gr4,
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
                    // ----------------------------------------------------------------------
                    // 평가 카테고리
                    // ----------------------------------------------------------------------
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E5E),
                            border: Border.all(
                                color: const Color(0xFF0F1E5E), width: 6),
                          ),
                          child: Center(
                            child: Text(
                              "${evaluationResult.category}",
                              style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cafe24Oneprettynight'),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        // ----------------------------------------------------------------------
                        // 평가 결과
                        // ----------------------------------------------------------------------
                        // Padding(
                        //   padding:
                        //       const EdgeInsets.only(left: 10.0, right: 10.0),
                        //   child: Align(
                        //     alignment: Alignment.center,
                        //     child: Container(
                        //       width: screenWidth * 0.6,
                        //       height: 50,
                        //       decoration: BoxDecoration(
                        //           color: evaluationColor.withOpacity(0.2)),
                        //       child: Center(
                        //         child: Text(
                        //           "${evaluationResult.evaluation}",
                        //           style: const TextStyle(
                        //               fontSize: 24,
                        //               color: Colors.black,
                        //               fontWeight: FontWeight.bold,
                        //               fontFamily: 'Cafe24Oneprettynight'),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, right: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var i = 0; i < 3; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: evaluationResult.evaluation
                                                .toString()
                                                .contains(i == 0
                                                    ? '하'
                                                    : i == 1
                                                        ? '중'
                                                        : '상')
                                            ? (i == 0
                                                ? Colors.red.withOpacity(0.2)
                                                : i == 1
                                                    ? Colors.orange
                                                        .withOpacity(0.2)
                                                    : Colors.green
                                                        .withOpacity(0.2))
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          i == 0
                                              ? '부족함(하)'
                                              : i == 1
                                                  ? '적절함(중)'
                                                  : '탁월함(상)',
                                          style: TextStyle(
                                            fontSize: 24,
                                            color: Colors.black.withOpacity(
                                              evaluationResult.evaluation
                                                      .toString()
                                                      .contains(i == 0
                                                          ? '하'
                                                          : i == 1
                                                              ? '중'
                                                              : '상')
                                                  ? 1.0
                                                  : 0.3,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        // ----------------------------------------------------------------------
                        // 평가 근거
                        // ----------------------------------------------------------------------
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              width: screenWidth * 0.6,
                              height: maxHeight,
                              padding: const EdgeInsets.all(10),
                              color: Colors.white,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "[평가 근거]",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        "${evaluationResult.detail}",
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      // Interaction 1
                                      Text(
                                        interaction1,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      // Reason 1 with right arrow
                                      Text(
                                        "→ ${evaluationResult.reason1}",
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ), // 한줄 띄움
                                      // Interaction 2
                                      Text(
                                        interaction2,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      // Reason 2 with right arrow
                                      Text(
                                        "→ ${evaluationResult.reason2}",
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget evaluateWidget(double screenWidth, double screenHeight, bool isWeb,
      List<DebateResult> evaluationResults) {
    Color averageColor = Colors.black;

    double debateImageWidth = SizeCalculate().widthCalculate(screenWidth, 402);
    double arrowPadding = 0.0;

    arrowPadding = (debateImageWidth - 99) / 2;

    String averageResult = getAverageResult(evaluationResults);

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

    // 각 evaluationResult의 explain 부분을 기준으로 가장 큰 높이를 계산
    double maxExplainHeight = evaluationResults.map((result) {
      final textPainter = TextPainter(
        text: TextSpan(
            text: ": ${result.explain}",
            style: const TextStyle(
                fontSize: 16, fontFamily: 'Cafe24Oneprettynight')),
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
        text: TextSpan(
            text: combinedText,
            style: const TextStyle(
                fontSize: 16, fontFamily: 'Cafe24Oneprettynight')),
        textDirection: ui.TextDirection.ltr,
        maxLines: null,
      );
      textPainter.layout(
          maxWidth: (screenWidth - 120) / evaluationResults.length -
              30); // padding 고려

      // 설명 텍스트와 상자의 기본 padding을 고려한 높이
      return textPainter.height + maxExplainHeight + 160; // 추가 여백 포함
    }).reduce((curr, next) => curr > next ? curr : next);

    return Padding(
      padding: isWeb
          ? const EdgeInsets.only(left: 60, right: 60, bottom: 30)
          : const EdgeInsets.only(left: 15, right: 15, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------------------------
          // 헤더
          // ----------------------------------------------------------------------
          Container(
            width: screenWidth,
            decoration: const BoxDecoration(
              color: Color(0xFF0F1E5E), // 변경된 색상
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
          const SizedBox(height: 20),
          // ----------------------------------------------------------------------
          // 날짜 선택
          // ----------------------------------------------------------------------
          selectDateWidget(screenWidth, isWeb),
          const SizedBox(
            height: 20,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "   ${_selectTime?.month}월 ${_selectTime?.day}일 ${_userModel.nm ?? ""}님의 학업 스트레스는 ...",
              textAlign: TextAlign.left,
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cafe24Oneprettynight'),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          // ----------------------------------------------------------------------
          // 평가 결과 요약
          // ----------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: SizedBox(
                          width: debateImageWidth,
                          height: SizeCalculate()
                              .heightCalculate(screenHeight, 208),
                          child: Image.asset("assets/icons/debateIcon.png"),
                        ),
                      ),
                      SizedBox(
                        height:
                            SizeCalculate().heightCalculate(screenHeight, 70),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: arrowPadding, bottom: 20),
                    child: SizedBox(
                      width: SizeCalculate().widthCalculate(screenWidth, 470),
                      height:
                          SizeCalculate().heightCalculate(screenHeight, 100),
                      child: Image.asset("assets/icons/arrowRed.png"),
                    ),
                  ),
                ],
              ),
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
                        fontFamily: 'Cafe24Oneprettynight'),
                  ),
                  const TextSpan(
                      text: ' 정도의 비판적 사고능력을 보여주고 있어요!',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cafe24Oneprettynight')),
                ])),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: evaluationResults.map((evaluationResult) {
              // Color evaluationColor = Colors.grey;

              // if (evaluationResult.evaluation.toString().contains('상')) {
              //   evaluationColor = Colors.green;
              // } else if (evaluationResult.evaluation.toString().contains('중')) {
              //   evaluationColor = Colors.orange;
              // } else if (evaluationResult.evaluation.toString().contains('하')) {
              //   evaluationColor = Colors.red;
              // }

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
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    height: maxHeight + 250,
                    decoration: BoxDecoration(
                      color: _colorsModel.gr4,
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
                    // ----------------------------------------------------------------------
                    // 평가 카테고리
                    // ----------------------------------------------------------------------
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E5E),
                            border: Border.all(
                                color: const Color(0xFF0F1E5E), width: 6),
                          ),
                          child: Center(
                            child: Text(
                              "${evaluationResult.category}",
                              style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cafe24Oneprettynight'),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        // ----------------------------------------------------------------------
                        // 평가 결과
                        // ----------------------------------------------------------------------
                        // Padding(
                        //   padding:
                        //       const EdgeInsets.only(left: 10.0, right: 10.0),
                        //   child: Align(
                        //     alignment: Alignment.center,
                        //     child: Container(
                        //       width: screenWidth * 0.6,
                        //       height: 50,
                        //       decoration: BoxDecoration(
                        //           color: evaluationColor.withOpacity(0.2)),
                        //       child: Center(
                        //         child: Text(
                        //           "${evaluationResult.evaluation}",
                        //           style: const TextStyle(
                        //               fontSize: 24,
                        //               color: Colors.black,
                        //               fontWeight: FontWeight.bold,
                        //               fontFamily: 'Cafe24Oneprettynight'),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, right: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var i = 0; i < 3; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: evaluationResult.evaluation
                                                .toString()
                                                .contains(i == 0
                                                    ? '하'
                                                    : i == 1
                                                        ? '중'
                                                        : '상')
                                            ? (i == 0
                                                ? Colors.red.withOpacity(0.2)
                                                : i == 1
                                                    ? Colors.orange
                                                        .withOpacity(0.2)
                                                    : Colors.green
                                                        .withOpacity(0.2))
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          i == 0
                                              ? '부족함(하)'
                                              : i == 1
                                                  ? '적절함(중)'
                                                  : '탁월함(상)',
                                          style: TextStyle(
                                            fontSize: 24,
                                            color: Colors.black.withOpacity(
                                              evaluationResult.evaluation
                                                      .toString()
                                                      .contains(i == 0
                                                          ? '하'
                                                          : i == 1
                                                              ? '중'
                                                              : '상')
                                                  ? 1.0
                                                  : 0.3,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        // ----------------------------------------------------------------------
                        // 평가 근거
                        // ----------------------------------------------------------------------
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              width: screenWidth * 0.6,
                              height: maxHeight,
                              padding: const EdgeInsets.all(10),
                              color: Colors.white,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "[평가 근거]",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        "${evaluationResult.detail}",
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      // Interaction 1
                                      Text(
                                        interaction1,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      // Reason 1 with right arrow
                                      Text(
                                        "→ ${evaluationResult.reason1}",
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      // Interaction 2
                                      Text(
                                        interaction2,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                      // Reason 2 with right arrow
                                      Text(
                                        "→ ${evaluationResult.reason2}",
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cafe24Oneprettynight'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget selectDateWidget(double screenWidth, bool isWeb) {
    bool isExpanded = false;
    return StatefulBuilder(builder: (BuildContext context, stateSetter) {
      // Get all dates except the most recent one
      List<DateTime> dates = _historyMap.keys.toList().cast<DateTime>();
      dates.sort((a, b) => b.compareTo(a)); // Sort in descending order
      if (dates.isNotEmpty) {
        dates.removeAt(0); // Remove the most recent date
      }

      return Padding(
        padding: isWeb
            ? const EdgeInsets.only(left: 0, right: 0)
            : const EdgeInsets.only(left: 15, right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "날짜 선택",
              style: TextStyle(
                  fontSize: 20,
                  color: _colorsModel.gr1,
                  fontFamily: 'Cafe24Oneprettynight'),
            ),
            const SizedBox(
              height: 5,
            ),
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
                                  formatDateTime(item),
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
                    List<DebateResult> results = [];

                    if (_historyMap.isNotEmpty) {
                      Map dataMap = _historyMap[value] ?? {};
                      results =
                          List<DebateResult>.from(dataMap['result'] ?? []);
                    }

                    setState(() {
                      _selectTime = value;
                      _selectResults = results;
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

    List resList =
        await UserServices().getUserModel(uid: AuthService().getUid());

    if (resList.first) {
      setState(() {
        _userModel = resList.last;
      });

      if (_pageProvider.isFromChat) {
        List chatEvaluations = _pageProvider.chatEvaluations;
        if (chatEvaluations.isNotEmpty) {
          setState(() {
            _recentComment = chatEvaluations.first;
            _recentResults = List<DebateResult>.from(chatEvaluations.last);
          });
        }
      } else {
        List historyResList = await ChatServices().getDebateHistory(
            uid: _userModel.uid,
            chatModelKey: _pageProvider.selectChatModel.key);
        if (historyResList.first) {
          Map historyMap = historyResList
              .last; // {Datetime time : {'comment': , 'result': List<DebateResult>}}

          List timeList = historyMap.keys.toList();
          timeList.sort((a, b) => b.compareTo(a));

          Map<DateTime, Map<String, dynamic>> tempHistoryMap = {};
          for (DateTime time in timeList) {
            tempHistoryMap[time] = historyMap[time];
          }

          historyMap = tempHistoryMap;

          DateTime? selectTime;
          DateTime? recentTime;
          String recentComment = '';
          List<DebateResult> selectResults = [];
          List<DebateResult> recentResults = [];

          if (historyMap.isNotEmpty) {
            // selectTime = historyMap.keys.toList().first;
            List timeList = historyMap.keys.toList();
            if (timeList.length > 1) {
              selectTime = timeList[1];

              Map selectResultMap = historyMap[selectTime] ?? {};
              selectResults =
                  List<DebateResult>.from(selectResultMap['result'] ?? []);
            }

            recentTime = timeList.first;
            Map recentResultMap = historyMap[recentTime] ?? {};
            recentComment = recentResultMap['comment'] ?? '';
            recentResults =
                List<DebateResult>.from(recentResultMap['result'] ?? []);

            if (selectTime != null) {}
          }

          setState(() {
            _historyMap = historyMap;
            _recentTime = recentTime;
            _selectTime = selectTime;
            _recentComment = recentComment;
            _recentResults = recentResults;
            _selectResults = selectResults;
          });
        } else {
          Dialogs().onlyContentOneActionDialog(
              // ignore: use_build_context_synchronously
              context: context,
              content: '기록 로드 중 오류\n${historyResList.last}',
              firstText: '확인');
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

  String getAverageResult(List<DebateResult> results) {
    int countHigh = 0;
    int countMedium = 0;
    int countLow = 0;

    for (DebateResult result in results) {
      if (result.evaluation.toString().contains('상')) {
        countHigh++;
      } else if (result.evaluation.toString().contains('중')) {
        countMedium++;
      } else if (result.evaluation.toString().contains('하')) {
        countLow++;
      }
    }

    if (countHigh == 4) {
      return '탁월함';
    } else if ((countHigh > 1) && (countMedium > 1) && (countLow < 1)) {
      return '우수함';
    } else if (countMedium == 4) {
      return '적절함';
    } else if ((countMedium < 1) && (countLow > 1) && (countHigh > 1)) {
      return '보통';
    } else if (countLow == 4) {
      return '미흡함';
    } else {
      return '해당 없음';
    }
  }
}
