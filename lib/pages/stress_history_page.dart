import 'dart:ui';

import 'package:aitutor/models/chart_data.dart';
import 'package:aitutor/models/colors_model.dart';
import 'package:aitutor/models/convert_stress_img.dart';
import 'package:flutter/painting.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:aitutor/models/stress_result.dart';
import 'package:aitutor/models/user_model.dart';
import 'package:aitutor/providers/page_provider.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/services/chat_services.dart';
import 'package:aitutor/services/classification_platform.dart';
import 'package:aitutor/services/size_calculate.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';

class StressHistoryPage extends StatefulWidget {
  const StressHistoryPage({Key? key}) : super(key: key);

  @override
  State<StressHistoryPage> createState() => _StressHistoryPageState();
}

class _StressHistoryPageState extends State<StressHistoryPage> {

  PageProvider _pageProvider = PageProvider();
  final ColorsModel _colorsModel = ColorsModel();
  UserModel _userModel = UserModel();
  Map _historyMap = {};  // {Datetime time : StressResult()}
  DateTime? _recentTime;
  DateTime? _selectTime;
  List<StressResult> _results = [];
  StressResult _recentResult = StressResult();
  StressResult _selectResult = StressResult();
  bool _loading = false;
  List<ChartData> _chartData = [];

  // initState는 현재 코드 클래스 호출시 최초 1회 호출되는 함수이다
  // 현재 코드 페이지를 호출할 때 가장 먼저 작업할 함수들을 넣어주면 된다
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // provider를 사용시 초기에는 정보를 바로 못받아오는 경우가 있어서
      // 최초 1회 빌드 후 호출하게 해둠
      dataInit();
    });
  }

  @override
  Widget build(BuildContext context) {
    _pageProvider = Provider.of<PageProvider>(context, listen: true);

    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    // 가로 사이즈에 따라서 플랫폼 구별
    bool isWeb = ClassificationPlatform().classifyWithScreenSize(context: context) == 2;

    return Stack(
      children: [
        ListView(
          children: [
            const SizedBox(height: 15,),
            _recentResult.scores == null ? Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: Text("아직 대화 기록이 없습니다", style: TextStyle(
                  fontSize: 16,
                  color: _colorsModel.gr1,
                  fontFamily: 'Cafe24Oneprettynight'
                ),),
              ),
            ) : Column(
              children: [
                SizedBox(height: 8),
                recentStressWidget(screenWidth, screenHeight, isWeb),
                historyWidget(screenWidth, screenHeight, isWeb),
              ],
            ),
          ],
        ),
        _loading ? Center(child: CircularProgressIndicator(color: _colorsModel.main,),) : Container()
      ],
    );
  }

  Widget historyWidget(screenWidth, screenHeight, isWeb) {
    Map groupDetails = groupDetailsByCategory(_selectResult.scores ?? []);
    double stressImageWidth = SizeCalculate().widthCalculate(screenWidth, 402);
    double arrowPadding = 0.0;
    Color averageColor = Colors.black;

    if (_selectResult.averageScore >= 4.5) {
      averageColor = _colorsModel.red;
      arrowPadding = 10;
    } else if (_selectResult.averageScore >= 3.5) {
      averageColor = Colors.orange;
      arrowPadding = stressImageWidth / 3 - 10;
    } else if (_selectResult.averageScore >= 2.5) {
      averageColor = Colors.yellow;
      arrowPadding = (stressImageWidth / 3) * 2 - 30;
    } else {
      averageColor = Colors.green;
      arrowPadding = (stressImageWidth / 3) * 2.65;
    }

    return Padding(
      padding: isWeb ? const EdgeInsets.only(left: 60, right: 60) : const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20,),
          Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E5E), // 변경된 색상
            ),
            child: const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: Center(
                child: Text("지난 결과 조회하기", style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cafe24Oneprettynight'
                ),),
              ),
            ),
          ),
          const SizedBox(height: 20,),
          SfCartesianChart(
            title: const ChartTitle(
                text: '학업 스트레스 변화 추이',
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cafe24Oneprettynight'
                )),
            primaryXAxis: DateTimeAxis(
              majorGridLines: MajorGridLines(width: 0),
              labelAlignment: LabelAlignment.center,  // 레이블을 중앙에 정렬
              title: AxisTitle(text: '날짜', textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cafe24Oneprettynight'
              )),
            ),
            primaryYAxis: NumericAxis(
              title: const AxisTitle(text: '스트레스 수준', textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cafe24Oneprettynight'
              )),
              majorGridLines: const MajorGridLines(width: 0),
              minimum: 0,
              maximum: 5,
              interval: 1, // 자동 간격 설정
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                switch (details.value.toInt()) {
                  case 0:
                    return ChartAxisLabel('', const TextStyle(color: Colors.transparent, fontFamily: 'Cafe24Oneprettynight'));  // 0에 대한 처리 (투명 라벨)
                  case 1:
                    return ChartAxisLabel('낮음', const TextStyle(color: Colors.black, fontFamily: 'Cafe24Oneprettynight'));
                  case 2:
                    return ChartAxisLabel('중간', const TextStyle(color: Colors.black, fontFamily: 'Cafe24Oneprettynight'));
                  case 3:
                    return ChartAxisLabel('높음', const TextStyle(color: Colors.black, fontFamily: 'Cafe24Oneprettynight'));
                  case 4:
                    return ChartAxisLabel('매우 높음', const TextStyle(color: Colors.black, fontFamily: 'Cafe24Oneprettynight'));
                  case 5:
                    return ChartAxisLabel('', const TextStyle(color: Colors.transparent, fontFamily: 'Cafe24Oneprettynight'));  // 6에 대한 처리 (투명 라벨)
                  default:
                    return ChartAxisLabel('', const TextStyle(color: Colors.transparent, fontFamily: 'Cafe24Oneprettynight'));
                }
              },
            ),
            series: <CartesianSeries>[
              LineSeries<ChartData, DateTime>(
                dataSource: _chartData,
                xValueMapper: (ChartData data, _) => data.date,
                yValueMapper: (ChartData data, _) => data.stressLevel,
                color: const Color(0xFF0F1E5E),
                dataLabelSettings: const DataLabelSettings(isVisible: false),
              ),
            ],
          ),
          const SizedBox(height: 20,),
          selectDateWidget(screenWidth, isWeb),
          _selectResult.scores == null ? Container() : Column(
            children: [
              const SizedBox(height: 20,),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("   ${_selectTime?.month}월 ${_selectTime?.day}일 ${_userModel.nm ?? ""}님의 학업 스트레스는 ...", 
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cafe24Oneprettynight'
                ),),
              ),
              const SizedBox(height: 15,),
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
                              width: stressImageWidth,
                              height: SizeCalculate().heightCalculate(screenHeight, 208),
                              child: Image.asset("assets/icons/stressIcons.png"),
                            ),
                          ),
                          SizedBox(height: SizeCalculate().heightCalculate(screenHeight, 70),),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: arrowPadding),
                        child: SizedBox(
                          width: SizeCalculate().widthCalculate(screenWidth, 99),
                          height: SizeCalculate().heightCalculate(screenHeight, 100),
                          child: Image.asset("assets/icons/arrowRed.png"),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15, bottom: 50),
                    child: RichText(
                        text: TextSpan(
                            children: [
                              TextSpan(text: '${_selectResult.averageStressDescription} 정도',
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: averageColor, fontFamily: 'Cafe24Oneprettynight'),),
                              const TextSpan(text: '의  스트레스를 겪고 있어요!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Cafe24Oneprettynight')),
                            ])
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: causeWidget(
                          detail: groupDetails['스트레스 원인'],
                          isWeb: isWeb,
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          isHistory: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: symptomWidget(
                          detail: groupDetails['스트레스 증상'],
                          isWeb: isWeb,
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          isHistory: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: solutionWidget(
                          detail: groupDetails['대처 방안'],
                          isWeb: isWeb,
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          isHistory: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],),
      ],),
    );
  }

  Widget recentStressWidget(screenWidth, screenHeight, isWeb) {
    Color averageColor = Colors.black;

    double stressImageWidth = SizeCalculate().widthCalculate(screenWidth, 402);
    double arrowPadding = 0.0;

    if (_recentResult.averageScore >= 4.5) {
      averageColor = _colorsModel.red;
      arrowPadding = 10;
    } else if (_recentResult.averageScore >= 3.5) {
      averageColor = Colors.orange;
      arrowPadding = stressImageWidth / 3 - 10;
    } else if (_recentResult.averageScore >= 2.5) {
      averageColor = Colors.yellow;
      arrowPadding = (stressImageWidth / 3) * 2 - 30;
    } else {
      averageColor = Colors.green;
      arrowPadding = (stressImageWidth / 3) * 2.65;
    }

    Map groupDetails = groupDetailsByCategory(_recentResult.scores ?? []);

    return Padding(
      padding: isWeb ? const EdgeInsets.only(left: 60, right: 60) : const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20,),
          Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E5E), // 변경된 색상
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Center(
                child: Text("${_userModel.nm ?? ""}님의 학업 스트레스", style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cafe24Oneprettynight'
                ),),
              ),
            ),
          ),
          const SizedBox(height: 20,),
          Text("   ${_recentTime?.month}월 ${_recentTime?.day}일 ${_userModel.nm ?? ""}님의 학업 스트레스는 ...", style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cafe24Oneprettynight'
          ),),
          const SizedBox(height: 15,),
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
                          width: stressImageWidth,
                          height: SizeCalculate().heightCalculate(screenHeight, 208),
                          child: Image.asset("assets/icons/stressIcons.png"),
                        ),
                      ),
                      SizedBox(height: SizeCalculate().heightCalculate(screenHeight, 70),),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: arrowPadding),
                    child: SizedBox(
                      width: SizeCalculate().widthCalculate(screenWidth, 99),
                      height: SizeCalculate().heightCalculate(screenHeight, 100),
                      child: Image.asset("assets/icons/arrowRed.png"),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, bottom: 50),
                child: RichText(
                    text: TextSpan(
                        children: [
                          TextSpan(text: '${_recentResult.averageStressDescription} 정도',
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: averageColor, fontFamily: 'Cafe24Oneprettynight'),),
                          const TextSpan(text: '의  스트레스를 겪고 있어요!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Cafe24Oneprettynight')),
                        ])
                ),
              ),
            ],
          ),
          const SizedBox(height: 20,),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 자식 위젯의 높이를 동일하게 맞춤
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10), // 간격 추가
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: causeWidget(
                      detail: groupDetails['스트레스 원인'],
                      isWeb: isWeb,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isHistory: false,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10), // 간격 추가
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: symptomWidget(
                      detail: groupDetails['스트레스 증상'],
                      isWeb: isWeb,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isHistory: false,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10), // 간격 추가
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: solutionWidget(
                      detail: groupDetails['대처 방안'],
                      isWeb: isWeb,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isHistory: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget causeWidget({
    required String detail,
    required bool isWeb,
    required double screenWidth,
    required bool isHistory,
    required double screenHeight,
  }) {

    if (isHistory) {
      return historyBodyWidget(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        title: '스트레스 원인',
        category: 'cause',
        detail: detail,
      );
    } else {
      Map summary = _recentResult.summary['cause'] ?? {};
      Map feedback = _recentResult.feedback['cause'] ?? {};
      String key = summary.isEmpty ? "" : summary.keys.first;
      String imgPath = ConvertStressImg().getStressImg('cause', key);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: _colorsModel.gr4, // 배경 회색
              border: Border.all(
                color: const Color(0xFF0F1E5E),
                width: 4,
              )
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 60, bottom: 10),
              child: Column(
                children: [
                  const SizedBox(height: 30), // 상단 박스와 간격 유지
                  SizedBox(
                    width: screenWidth * 0.6,
                    height: 156,
                    child: Image.asset(imgPath.isNotEmpty ? 'assets/stressIcons/$imgPath' : "assets/icons/board.png"),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: screenWidth * 0.6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC3CDF5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          key,
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
                  const SizedBox(height: 15),
                  summary.isEmpty
                      ? Container()
                      : Container(
                          width: screenWidth * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "[요약]",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "• ${summary[key] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 10),
                  feedback.isEmpty
                      ? Container()
                      : Container(
                          width: screenWidth * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "[상담 튜터의 한 마디]",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "• ${feedback[key] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -5, // 박스를 배경 위로 이동
            left: 0, // 좌측 마진
            right: 0, // 우측 마진
            child: Container(
              width: screenWidth,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E5E), 
                border: Border.all(color: const Color(0xFF0F1E5E), width: 4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  "스트레스 원인",
                  style: const TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cafe24Oneprettynight',
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget historyBodyWidget({
    required double screenWidth,
    required double screenHeight,
    required String title,
    required String category,
    required String detail,
  }) {
    Map summary = (_selectResult.summary ?? {})[category] ?? {};
    Map feedback = (_selectResult.feedback ?? {})[category] ?? {};
    String key = summary.isEmpty ? "" : summary.keys.first;
    String imgPath = ConvertStressImg().getStressImg(category, key);
    String defaultImg;

    if (category == 'cause') {
      defaultImg = "board";
    } else if (category == 'symptom') {
      defaultImg = "headache";
    } else {
      defaultImg = "friends";
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: screenWidth,
          decoration: BoxDecoration(
            color: _colorsModel.gr4,
            border: Border.all(
              color: const Color(0xFF0F1E5E),
              width: 4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 60, bottom: 10),
            child: Column(
              children: [
                const SizedBox(height: 30),
                SizedBox(
                  width: screenWidth * 0.6,
                  height: 156,
                  child: Image.asset(
                    imgPath.isNotEmpty ? 'assets/stressIcons/$imgPath' : "assets/icons/$defaultImg.png",
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: screenWidth * 0.6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3CDF5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        key,
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
                const SizedBox(height: 15),
                summary.isEmpty
                    ? Container()
                    : Container(
                        width: screenWidth * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "[요약]",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Cafe24Oneprettynight',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "• ${summary[key] ?? ""}",
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontFamily: 'Cafe24Oneprettynight',
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 10),
                feedback.isEmpty
                    ? Container()
                    : Container(
                        width: screenWidth * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "[상담 튜터의 한 마디]",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Cafe24Oneprettynight',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "• ${feedback[key] ?? ""}",
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontFamily: 'Cafe24Oneprettynight',
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -5,
          left: 0,
          right: 0,
          child: Container(
            width: screenWidth,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E5E),
              border: Border.all(color: const Color(0xFF0F1E5E), width: 4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cafe24Oneprettynight',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget symptomWidget({
    required String detail,
    required bool isWeb,
    required double screenWidth,
    required bool isHistory,
    required double screenHeight,
  }) {
    if (isHistory) {
      return historyBodyWidget(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        title: '스트레스 증상',
        category: 'symptom',
        detail: detail,
      );
    } else {
      Map summary = _recentResult.summary['symptom'] ?? {};
      Map feedback = _recentResult.feedback['symptom'] ?? {};
      String key = summary.isEmpty ? "" : summary.keys.first;
      String imgPath = ConvertStressImg().getStressImg('symptom', key);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: _colorsModel.gr4,
              border: Border.all(
                color: const Color(0xFF0F1E5E),
                width: 4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 60, bottom: 10),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  SizedBox(
                    width: screenWidth * 0.6,
                    height: 156,
                    child: Image.asset(
                      imgPath.isNotEmpty ? 'assets/stressIcons/$imgPath' : "assets/icons/headache.png",
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: screenWidth * 0.6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC3CDF5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          key,
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
                  const SizedBox(height: 15),
                  summary.isEmpty
                      ? Container()
                      : Container(
                          width: screenWidth * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "[요약]",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "• ${summary[key] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 10),
                  feedback.isEmpty
                      ? Container()
                      : Container(
                          width: screenWidth * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "[상담 튜터의 한 마디]",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "• ${feedback[key] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -5,
            left: 0,
            right: 0,
            child: Container(
              width: screenWidth,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E5E),
                border: Border.all(color: const Color(0xFF0F1E5E), width: 4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  "스트레스 증상",
                  style: const TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cafe24Oneprettynight',
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget solutionWidget({
    required String detail,
    required bool isWeb,
    required double screenWidth,
    required bool isHistory,
    required double screenHeight,
  }) {
    if (isHistory) {
      return historyBodyWidget(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        title: '대처 방안',
        category: 'coping',
        detail: detail,
      );
    } else {
      Map summary = _recentResult.summary['coping'] ?? {};
      Map feedback = _recentResult.feedback['coping'] ?? {};
      String key = summary.isEmpty ? "" : summary.keys.first;
      String imgPath = ConvertStressImg().getStressImg('coping', key);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: _colorsModel.gr4,
              border: Border.all(
                color: const Color(0xFF0F1E5E),
                width: 4,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 60, bottom: 10),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  SizedBox(
                    width: screenWidth * 0.6,
                    height: 156,
                    child: Image.asset(
                      imgPath.isNotEmpty ? 'assets/stressIcons/$imgPath' : "assets/icons/friends.png",
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: screenWidth * 0.6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC3CDF5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          key,
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
                  const SizedBox(height: 15),
                  summary.isEmpty
                      ? Container()
                      : Container(
                          width: screenWidth * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "[요약]",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "• ${summary[key] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 10),
                  feedback.isEmpty
                      ? Container()
                      : Container(
                          width: screenWidth * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "[상담 튜터의 한 마디]",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "• ${feedback[key] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -5,
            left: 0,
            right: 0,
            child: Container(
              width: screenWidth,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E5E),
                border: Border.all(color: const Color(0xFF0F1E5E), width: 4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  "대처 방안",
                  style: const TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cafe24Oneprettynight',
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }


  Widget selectDateWidget(screenWidth, isWeb) {
    bool _isExpanded = false;
    return StatefulBuilder(builder: (BuildContext context, stateSetter) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("[날짜 선택]", style: TextStyle(
            fontSize: 20,
            color: _colorsModel.gr1,
            fontFamily: 'Cafe24Oneprettynight'
          ),),
          const SizedBox(height: 5,),
          Container(
            height: 60,
            width: screenWidth,
            decoration: BoxDecoration(
              color:  Colors.white,
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
                          fontSize: 20,
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
                  setState(() {
                    _selectResult = _historyMap[value] ?? StressResult();
                    _selectTime = value;
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

  Future<void> dataInit() async {
    try {
      setState(() {
        _loading = true;
      });

      List resList = await UserServices().getUserModel(uid: AuthService().getUid());

      if (resList.first) {
        setState(() {
          _userModel = resList.last;
        });

        List historyResList = await ChatServices().getStressHistory(uid: _userModel.uid, chatModelKey: _pageProvider.selectChatModel.key);
        if (historyResList.first) {
          Map historyMap = historyResList.last; // {Datetime time : StressResult(

          // 키인 Datetime을 리스트로 변환하여 정렬
          List timeList = historyMap.keys.toList();
          timeList.sort((a, b) => b.compareTo(a)); // 최신순으로 정렬

          // 정렬된 시간 리스트를 이용하여 새로운 Map 생성
          Map<DateTime, StressResult> tempHistoryMap = {};
          for (DateTime time in timeList) {
            tempHistoryMap[time] = historyMap[time];
          }

          // 기존 historyMap을 정렬된 tempHistoryMap으로 대체
          historyMap = tempHistoryMap;

          DateTime? recentTime;
          DateTime? selectTime;

          StressResult recentResult = StressResult();
          List<StressResult> results = [];
          StressResult selectResult = StressResult();
          if (historyMap.isNotEmpty) {
            List timeList = historyMap.keys.toList();
            if (timeList.length > 1) {
              selectTime = timeList[1];
              selectResult = historyMap[selectTime] ?? StressResult();
            }

            recentTime = timeList.first;
            recentResult = historyMap[recentTime] ?? StressResult();

            for (int i = 0; i < timeList.length; i++) {
              DateTime time = timeList[i];
              results.add(historyMap[time]);
            }
          }

          historyMap.remove(recentTime);

          // 차트 데이터 생성
          List<ChartData> chartData = results.map((result) {
            List<int> scores = result.scores.where((element) => element != 0).toList();
            return ChartData(result.date, calculateAverageScore(scores));
          }).toList();


          setState(() {
            _selectResult = selectResult;
            _recentTime = recentTime;
            _historyMap = historyMap;
            _selectTime = selectTime;
            _recentResult = recentResult;
            _results = results;
            _chartData = chartData;

            _chartData = _chartData.map((data) {
              return ChartData(data.date, data.stressLevel - 1); // 1만큼 감소
            }).toList();

          });
        } else {
          Dialogs().onlyContentOneActionDialog(context: context, content: '기록 로드 중 오류\n${historyResList.last}', firstText: '확인');
        }
      }

      setState(() {
        _loading = false;
      });
    } catch(e) {
      print('error userInit of stress history : $e');
    }
  }

  String getEvaluationDescription(int score) {
    switch (score) {
      case 4:
        return "매우 높음";
      case 3:
        return "높음";
      case 2:
        return "중간";
      case 1:
        return "낮음";
      default:
        return "평가되지 않음";
    }
  }

  String getCategoryName(int index) {
    if (index < 8) {
      return "스트레스 원인";
    } else if (index < 23) {
      return "스트레스 증상";
    } else {
      return "대처 방안";
    }
  }

  Map<String, String> groupDetailsByCategory(List<int> scores) {
    Map<String, String> groupedDetails = {
      "스트레스 원인": "",
      "스트레스 증상": "",
      "대처 방안": "",
    };

    for (int i = 0; i < scores.length; i++) {
      String category = getCategoryName(i);
      String detail = getCategoryDetail(i);
      String evaluation = getEvaluationDescription(scores[i]);

      // 높음 이상일 경우에만 넣음
      if (evaluation.contains('높음')) {
        String beforeEvaluation = groupedDetails[category] ?? "";
        beforeEvaluation += "$detail, ";
        groupedDetails[category] = beforeEvaluation;
      }
    }

    // 마지막 쉼표와 공백 제거
    groupedDetails.forEach((key, value) {
      if (value.endsWith(', ')) {
        groupedDetails[key] = value.substring(0, value.length - 2);
      }
    });

    return groupedDetails;
  }

  String getCategoryDetail(int index) {
    if (index > 28) {
      return '';
    }
    const details = [
      "치열한 경쟁", "과제 부담", "교수님과의 관계", "평가", "학업 부담", "수업 난이도", "수업 참여 부담", "제한된 시간",
      "수면 장애", "만성 피로", "두통", "복부 통증 등의 소화 문제", "손톱 물기", "졸음", "불안감", "우울감", "절망감", "집중 저하", "공격성 증가", "논쟁 경향", "사람들로부터의 고립", "학업에 대한 무관심", "음식 섭취 증가 또는 감소",
      "능동적 대응", "계획 수립 및 수행", "자신에 대한 칭찬", "종교적 신념", "상황에 대한 정보 수집", "감정 표출 및 비밀 공유"
    ];

    return details[index];
  }

  String formatDateTime(DateTime dateTime) {
    String year = DateFormat('yyyy').format(dateTime);
    String month = DateFormat('MM').format(dateTime);
    String day = DateFormat('dd').format(dateTime);
    String hour = DateFormat('hh').format(dateTime);
    String period = DateFormat('a').format(dateTime) == 'AM' ? '오전' : '오후';

    return '$year년 $month월 $day일 $period $hour시';
  }

  double calculateAverageScore(List<int> scores) {
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

}

