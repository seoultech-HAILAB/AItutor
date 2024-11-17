import 'package:aitutor/models/chat_model.dart';
import 'package:aitutor/models/colors_model.dart';
import 'package:aitutor/models/docs_model.dart';
import 'package:aitutor/models/user_model.dart';
import 'package:aitutor/pages/chat_screen.dart';
import 'package:aitutor/providers/page_provider.dart';
import 'package:aitutor/services/argument_services.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/services/chat_services.dart';
import 'package:aitutor/services/classification_platform.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/pdf_viewer_widget.dart';
import 'package:aitutor/widgets/toast_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ArgumentHome extends StatefulWidget {
  const ArgumentHome({Key? key}) : super(key: key);

  @override
  State<ArgumentHome> createState() => _ArgumentHomeState();
}

class _ArgumentHomeState extends State<ArgumentHome> {
  ColorsModel _colorsModel = ColorsModel();
  bool _loading = false;
  PageProvider _pageProvider = PageProvider();
  UserModel _userModel = UserModel();
  List<DocsModel> _docs = [];
  Map _linkedTimeMap = {};    // 접속기록

  @override
  void initState() {
    super.initState();
    userInit();
    dataInit();
  }

  @override
  Widget build(BuildContext context) {
    _pageProvider = Provider.of<PageProvider>(context, listen: true);

    var screenWidth = MediaQuery.of(context).size.width;

    // 가로 사이즈에 따라서 플랫폼 구별
    bool isWeb = ClassificationPlatform().classifyWithScreenSize(context: context) == 2;

    return Stack(
      children: [
        !isWeb ?
        Column(
          children: [
            const SizedBox(height: 30,),
            typeWidget(screenWidth, isWeb),
            const SizedBox(height: 30,),
            Expanded(
              child: ListView.builder( // 
                  itemCount: _docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 30),
                      child: docWidget(_docs[index], screenWidth, isWeb),
                    );
                  }),
            ),
          ],
        )   // 모바일일 경우에 UI
            :
        Padding(
          padding: const EdgeInsets.only(left: 60, right: 60, top: 0, bottom: 0),
          child: Column(
            children: [
              typeWidget(screenWidth, isWeb),
              const SizedBox(height: 30,),
              Expanded(
                child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( 
                      crossAxisCount: 2, //1 개의 행에 보여줄 item 개수
                      childAspectRatio: 2.5, //item 의 가로, 세로의 비율
                      mainAxisSpacing: 30, //수직 Padding
                      crossAxisSpacing: 100, //수평 Padding
                    ),
                    itemCount: _docs.length,
                    itemBuilder: (BuildContext context, int index) {

                      return docWidget(_docs[index], screenWidth, isWeb);
                    }),
              ),
            ],
          ),
        ),  // 웹일 경우의 UI
        _loading ? Center(child: CircularProgressIndicator(color: _colorsModel.main,),) : Container(),
      ],
    );
  }

  Widget typeWidget(screenWidth, bool isWeb) {
  ChatModel chatModel = _pageProvider.selectChatModel;

  return Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프로필 이미지를 크게 표시
        ClipOval(
          child: chatModel.img == null
              ? Container(
                  width: 80, // 이미지를 크게 표시
                  height: 80,
                  child: Image.asset(
                    "assets/icons/argument.png",
                    fit: BoxFit.cover,
                  ),
                )
              : Image.network(
                  chatModel.img,
                  key: ValueKey(chatModel.img),
                  fit: BoxFit.cover,
                  height: 80, // 이미지를 크게 표시
                  width: 80,
                  errorBuilder: (context, error, stackTrace) {
                    print('img error $error');
                    // 오류났을 경우의 위젯, 기본 사진으로 설정
                    return Container(
                      decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        "assets/icons/argument.png",
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(width: 15), // 프로필 이미지와 말풍선 사이의 간격
        // 말풍선 부분
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[200], // 말풍선의 배경 색상
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "글쓰기 난이도(상·중·하)별 주제를 확인하고, 저와 함께 글쓰기 연습을 하고 싶은 주제를 선택해주세요!", // 챗봇의 말풍선 텍스트
              style: const TextStyle(
                fontSize: 25,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget docWidget(DocsModel docsModel, double screenWidth, bool isWeb) {
    Color _iconColor;

    switch (docsModel.iconNm) {
      case "상":
        _iconColor = _colorsModel.lightPink;
        break;
      case "중":
        _iconColor = _colorsModel.lightGreen;
        break;
      case "하":
        _iconColor = _colorsModel.lightYellow;
        break;
      default:
        _iconColor = _colorsModel.lightGreen;
    }

    String? imagePath;
    if (docsModel.key == "AI LAW") {
      imagePath = "assets/icons/AIAct.png";
    } else if (docsModel.key == "TROLLEY") {
      imagePath = "assets/icons/TrolleyProblem.png";
    }

    Widget content = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 콘텐츠 크기에 따라 높이 자동 조정
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _iconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                width: 50,
                height: 50,
                child: Center(
                  child: Text(
                    docsModel.iconNm ?? '',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cafe24Oneprettynight',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  docsModel.title ?? '',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Cafe24Oneprettynight',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2, // 타이틀이 너무 길 경우 2줄로 제한
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: isWeb ? 600 : screenWidth * 0.8, // 이미지 크기 제한
                  height: isWeb ? 300 : screenWidth * 0.5,
                  fit: BoxFit.contain, // 이미지를 박스 크기에 맞게 조정
                ),
              ),
            ),
          Text(
            docsModel.explain ?? '',
            style: TextStyle(
              fontSize: 25,
              color: _colorsModel.gr2,
              fontFamily: 'Cafe24Oneprettynight',
            ),
            softWrap: true,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    return GestureDetector(
      onTap: docsModel.key == "AI LAW"
          ? () {
              _pageProvider.updateSelectDocsModel(docsModel);
              _pageProvider.updateIsNoteApp(false);
              _pageProvider.updatePage(1);
            }
          : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 700 : screenWidth * 0.9, // 박스 최대 너비 설정
            minHeight: 350, // 박스의 최소 높이 설정 (높이를 약간 키움)
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _colorsModel.wh,
            border: Border.all(color: _colorsModel.bl),
          ),
          child: content,
        ),
      ),
    );
  }


  Future<void> dataInit() async {
    setState(() {
      _loading = true;
    });

    List resList = await ArgumentServices().getDocs();

    setState(() {
      _loading = false;
    });

    if (resList.first) {
      setState(() {
        _docs = resList.last;
      });
    }
  }

  // 서버에서 유저정보를 가져옴
  Future<void> userInit() async {
    List resList = await UserServices().getUserModel(uid: AuthService().getUid());

    if (resList.first) {
      UserModel userModel = resList.last;
      Map linkedTime = userModel.linkedTime ?? {};
      Map linkedTimeMap = {};
      if (linkedTime.isNotEmpty) {
        List modeList = linkedTime.keys.toList();
        for (int i = 0; i < modeList.length; i++) {
          linkedTimeMap[modeList[i]] = timeDifference(linkedTime[modeList[i]] ?? "");
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