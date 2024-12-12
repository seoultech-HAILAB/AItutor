import 'package:aitutor/models/chat_model.dart';
import 'package:aitutor/models/colors_model.dart';
import 'package:aitutor/models/user_model.dart';
import 'package:aitutor/pages/chat_screen.dart';
import 'package:aitutor/providers/page_provider.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/services/chat_services.dart';
import 'package:aitutor/services/classification_platform.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/toast_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class SelectTypePage extends StatefulWidget {
  const SelectTypePage({Key? key}) : super(key: key);

  @override
  State<SelectTypePage> createState() => _SelectTypePageState();
}

class _SelectTypePageState extends State<SelectTypePage> {
  ColorsModel _colorsModel = ColorsModel();
  bool _loading = false;
  List<ChatModel> _chatModels = []; // 서버에 저장된 타입들을 저장하는 변수
  PageProvider _pageProvider = PageProvider();
  UserModel _userModel = UserModel();
  Map _linkedTimeMap = {}; // 접속기록
  Map _hasEvaluateHistory = {};

  @override
  void initState() {
    super.initState();
    userInit();
    typesInit(); // 서버에서 타입리스트 로드
  }

  @override
  Widget build(BuildContext context) {
    print("SelectTypePage build called");
    print("_chatModels length: ${_chatModels.length}");
    _pageProvider = Provider.of<PageProvider>(context, listen: true);
    var screenWidth = MediaQuery.of(context).size.width;

    // 가로 사이즈에 따라서 플랫폼 구별
    bool isWeb =
        ClassificationPlatform().classifyWithScreenSize(context: context) == 2;

    return Stack(
      children: [
        !isWeb
            ? Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                        itemCount: _chatModels.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                left: 15, right: 15, bottom: 30),
                            child: typeWidget(
                                _chatModels[index], screenWidth, isWeb),
                          );
                        }),
                  ),
                ],
              ) // 모바일일 경우에 UI
            : Padding(
                padding: const EdgeInsets.only(left: 60, right: 60, bottom: 30),
                child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, //1 개의 행에 보여줄 item 개수
                      childAspectRatio: 3 / 1.5, //item 의 가로, 세로의 비율 TODO: 여기야!
                      mainAxisSpacing: 30, //수직 Padding
                      crossAxisSpacing: 100, //수평 Padding
                    ),
                    itemCount: _chatModels.length,
                    itemBuilder: (BuildContext context, int index) {
                      return typeWidget(_chatModels[index], screenWidth, isWeb);
                    }),
              ), // 웹일 경우의 UI
        _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: _colorsModel.main,
                ),
              )
            : Container(),
      ],
    );
  }

  Widget typeWidget(ChatModel chatModel, screenWidth, bool isWeb) {
    print("typeWidget called for: ${chatModel.name}");

    // 이미지 경로를 chatModel.type에 따라 설정
    String imagePath;
    switch (chatModel.type) {
      case "argument":
        imagePath = "assets/icons/argument.png";
        break;
      case "debate":
        imagePath = "assets/icons/debate.png";
        break;
      case "stress":
        imagePath = "assets/icons/stress.png";
        break;
      default:
        imagePath = "assets/icons/default.png"; // 기본 이미지 경로 설정
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _colorsModel.skeyBlue,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12), // 둥근 사각형을 위해 모서리 반경 설정
                  child: Container(
                    width: 80,
                    height: 80,
                    child: Image.asset(imagePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${chatModel.key ?? ''}",
                      style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Cafe24Oneprettynight'),
                    ),
                    Text(
                      "${_linkedTimeMap[chatModel.key] ?? "${chatModel.key}와 대화해보세요!"}",
                      style: TextStyle(
                          fontSize: 25,
                          color: const Color(0xff3d3d3d),
                          fontFamily: 'Cafe24Oneprettynight'),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ToastWidget().showToast('준비중인 기능입니다!');
                  },
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset("assets/icons/dots.png"),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "${chatModel.explain ?? ''}",
              style: TextStyle(
                  fontSize: 25,
                  color: const Color(0xff3d3d3d),
                  fontFamily: 'Cafe24Oneprettynight'),
              textAlign: TextAlign.left,
            ),
            !isWeb
                ? const SizedBox(
                    height: 20,
                  )
                : const Spacer(), // 넓힐 수 있는 최대 간격을 넓혀줌
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40),
              child: GestureDetector(
                onTap: () {
                  // 채팅화면에서 사용할 모델 업데이트
                  _pageProvider.updateChatModel(chatModel);
                  if (chatModel.type == "argument") {
                    _pageProvider.updatePage(5);
                  } else {
                    _pageProvider.updatePage(1);
                  }
                },
                child: MouseRegion(
                  // 마우스를 감지하여 마우스 모양을 띄워줌
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorsModel.wh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Center(
                        child: Text(
                          _getButtonText(chatModel.type),
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cafe24Oneprettynight'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            _hasEvaluateHistory[chatModel.key] == true
                ? Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40),
                    child: GestureDetector(
                      onTap: () async {
                        _pageProvider.updateIsFromChat(false);
                        _pageProvider.updateChatModel(chatModel);
                        if (chatModel.type == "debate") {
                          _pageProvider.updatePage(2);
                        } else if (chatModel.type == "stress") {
                          _pageProvider.updatePage(4);
                        } else if (chatModel.type == "argument") {
                          _pageProvider.updatePage(6);
                        }
                      },
                      child: MouseRegion(
                        // 마우스를 감지하여 마우스 모양을 띄워줌
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _colorsModel.wh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            child: Center(
                              child: Text(
                                "평가 기록 보기",
                                style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cafe24Oneprettynight'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  String _getButtonText(String type) {
    switch (type) {
      case "argument":
        return "글쓰기 시작하기";
      case "debate":
        return "독서토론 시작하기";
      case "stress":
        return "상담 시작하기";
      default:
        return "대화 시작";
    }
  }

  Future<void> typesInit() async {
    setState(() {
      _loading = true;
    });
    print("typesInit called");
    List typesResList = await ChatServices().getTypeList(); // 서버에서 타입리스트 로드
    print("typesResList: $typesResList");

    if (typesResList.first) {
      List<ChatModel> chatModels = typesResList.last;
      Map hasEvaluateHistory = {};

      for (int i = 0; i < chatModels.length; i++) {
        String chatModelKey = chatModels[i].key ?? "";
        bool isHas = await ChatServices().hasEvaluateHistory(
            uid: AuthService().getUid(), chatModelKey: chatModelKey);
        hasEvaluateHistory[chatModelKey] = isHas;
      }

      setState(() {
        _hasEvaluateHistory = hasEvaluateHistory;
        _chatModels = typesResList.last;
      });
    }

    setState(() {
      _loading = false;
    });
  }

  // 서버에서 유저정보를 가져옴
  Future<void> userInit() async {
    List resList =
        await UserServices().getUserModel(uid: AuthService().getUid());
    if (resList.first) {
      UserModel userModel = resList.last;
      Map linkedTime = userModel.linkedTime ?? {};
      Map linkedTimeMap = {};
      if (linkedTime.isNotEmpty) {
        List modeList = linkedTime.keys.toList();
        for (int i = 0; i < modeList.length; i++) {
          linkedTimeMap[modeList[i]] =
              timeDifference(linkedTime[modeList[i]] ?? "");
        }
      }
      setState(() {
        _userModel = userModel;
        _linkedTimeMap = linkedTimeMap;
      });
    }
  }

  String timeDifference(String timestamp) {
    DateTime inputTime = DateTime.parse(timestamp);
    DateTime now = DateTime.now();

    Duration difference = now.difference(inputTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}일 전';
    } else {
      int months = difference.inDays ~/ 30;
      return '${months}개월 전';
    }
  }
}
