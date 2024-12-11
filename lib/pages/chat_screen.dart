import 'package:aitutor/models/chat_model.dart';
import 'package:aitutor/models/colors_model.dart';
import 'package:aitutor/models/docs_model.dart';
import 'package:aitutor/models/user_model.dart';
import 'package:aitutor/providers/page_provider.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/services/chat_services.dart';
import 'package:aitutor/services/classification_platform.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/dialogs.dart';
import 'package:aitutor/widgets/note_widget.dart';
import 'package:aitutor/widgets/pdf_viewer_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final ColorsModel _colorsModel = ColorsModel();
  final ScrollController _scrollController = ScrollController();

  PageProvider _pageProvider = PageProvider();
  List<Map<String, dynamic>> _messages = [];
  UserModel _userModel = UserModel();
  String _prompt = "";

  // initState는 현재 코드 클래스 호출시 최초 1회 호출되는 함수이다
  // 현재 코드 페이지를 호출할 때 가장 먼저 작업할 함수들을 넣어주면 된다
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // provider를 사용시 초기에는 정보를 바로 못받아오는 경우가 있어서
      // 최초 1회 빌드 후 호출하게 해둠
      promptInit();
      userInit();
    });

    @override
    Widget build(BuildContext context) {
      _pageProvider = Provider.of<PageProvider>(context, listen: true);
      bool isWeb =
          ClassificationPlatform().classifyWithScreenSize(context: context) ==
              2;

      return bodyWidget(isWeb);
    }
  }

  @override
  Widget build(BuildContext context) {
    _pageProvider = Provider.of<PageProvider>(context, listen: true);
    // 가로 사이즈에 따라서 플랫폼 구별
    bool isWeb =
        ClassificationPlatform().classifyWithScreenSize(context: context) == 2;

    return bodyWidget(isWeb);
  }

  FocusNode _textFocus = FocusNode();

  Widget bodyWidget(isWeb) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    if (_pageProvider.selectChatModel.type == 'argument') {
      Color _iconColor = _colorsModel.lightGreen;
      DocsModel docsModel = _pageProvider.selectDocsModel;

      if (docsModel.iconNm == "상") {
        _iconColor = _colorsModel.lightPink;
      } else if (docsModel.iconNm == "중") {
        _iconColor = _colorsModel.lightGreen;
      } else if (docsModel.iconNm == "하") {
        _iconColor = _colorsModel.lightYellow;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.015),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.972,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFF0F1E5E),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: _iconColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              width: 45,
                              height: 45,
                              child: Center(
                                child: SelectableText(
                                  "${docsModel.iconNm}",
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cafe24Oneprettynight'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Center(
                              child: SelectableText(
                                "${docsModel.title ?? ''}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Cafe24Oneprettynight'),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: screenWidth * 0.47,
                child: const SingleChildScrollView(
                  child: NoteWidget(), // NoteWidget이 스크롤 가능하게 변경됨
                ),
              ),
              Container(
                width: screenWidth * 0.47,
                height: screenHeight * 0.8,
                // decoration: BoxDecoration(
                //   borderRadius: BorderRadius.circular(4),
                //   border: Border.all(color: _colorsModel.bl, width: 2),
                // ),
                child: GestureDetector(
                  onTap: () {
                    // 바탕 터치시 키보드를 내리기 위함
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: Column(
                    children: [
                      Expanded(
                        // Expanded를 써야 ListView가 차지할 크기를 알 수 있기에 사용할 수 있는 크기를 전부 사용하라는 의미
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 15, right: 15),
                              child: _buildMessage(
                                  _messages[index], screenWidth * 0.32),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 10, left: 15, right: 15),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                maxLines: null, // 엔터를 눌러 다음 줄을 생성하기 위함
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) {
                                  _sendMessage();
                                },
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Cafe24Oneprettynight',
                                ),
                                decoration: InputDecoration(
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        _sendMessage();
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Image.asset(
                                              "assets/icons/send.png"),
                                        ),
                                      ),
                                    ),
                                  ),
                                  hintText: '메시지를 입력해주세요',
                                  hintStyle: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Cafe24Oneprettynight',
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 15),
                                  border: InputBorder.none,
                                  disabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _colorsModel.textInputBorder,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _colorsModel.textInputBorder,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _colorsModel.main,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _colorsModel.textInputBorder,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _colorsModel.textInputBorder,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return GestureDetector(
        onTap: () {
          // 바탕 터치시 키보드를 내리기 위함
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          children: [
            Expanded(
              // Expanded를 써야 ListView가 차지할 크기를 알 수 있기에 사용할 수 있는 크기를 전부 사용하라는 의미
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: isWeb
                        ? const EdgeInsets.only(left: 60, right: 60)
                        : const EdgeInsets.only(left: 15, right: 15),
                    child: _buildMessage(_messages[index], screenWidth * 0.8),
                  );
                },
              ),
            ),
            Padding(
              padding: isWeb
                  ? const EdgeInsets.only(bottom: 40, left: 60, right: 60)
                  : const EdgeInsets.only(bottom: 40, left: 15, right: 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _textFocus,
                      controller: _controller,
                      maxLines: null, // 엔터를 눌러 다음 줄을 생성하기 위함
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Cafe24Oneprettynight',
                      ),
                      decoration: InputDecoration(
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              _sendMessage();
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset("assets/icons/send.png"),
                              ),
                            ),
                          ),
                        ),
                        hintText: '메시지를 입력해주세요',
                        hintStyle: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Cafe24Oneprettynight',
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        border: InputBorder.none,
                        disabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _colorsModel.textInputBorder,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          // borderSide: BorderSide.none,
                          borderSide: BorderSide(
                            color: _colorsModel.textInputBorder,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _colorsModel.main,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _colorsModel.textInputBorder,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _colorsModel.textInputBorder,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // 서버에 저장된 대화기록을 불러오는 함수
  // 이전대화까지 포함하여 GPT API통신시 함께 보낼 수 있다
  Future<void> _loadChatMessages() async {
    List<Map<String, dynamic>> messages = [];

    // if (_pageProvider.selectChatModel.type == 'stress') {
    //   messages = await _chatServices.loadTodayChatMessages(chatModelKey: _pageProvider.selectChatModel.key, uid: _userModel.uid ?? "");
    // } else {
    //   messages = await _chatServices.loadChatMessages(chatModelKey: _pageProvider.selectChatModel.key, uid: _userModel.uid ?? "");
    // }
    messages = await _chatServices.loadChatMessages(
        chatModelKey: _pageProvider.selectChatModel.key,
        uid: _userModel.uid ?? "");
    setState(() {
      _messages = messages;
      _messages.reversed; // 뒤집어서 정렬
    });
    _scrollToBottom();
  }

  void _sendMessage() async {
    // 비어있는 값이면 return처리
    if (_controller.text.isEmpty) return;

    String userMessage = _controller.text;

    setState(() {
      _controller.clear();
      _messages.add({
        'role': 'user', // 사용자가 보낸 메세지의 role은 user
        'content': userMessage,
        'time': DateTime.now().toIso8601String(),
      });
    });
    await _chatServices.saveChatMessage(
        key: _pageProvider.selectChatModel.key,
        uid: _userModel.uid ?? "",
        role: 'user',
        message: userMessage);

    final assistantMessage = await _chatServices.getResponse(
        _messages.map((msg) {
          return {
            'role': msg['role'],
            'content': msg['content'],
          };
        }).toList(),
        _prompt,
        _pageProvider.gptKey);

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': assistantMessage,
        'time': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();
    await _chatServices.saveChatMessage(
        key: _pageProvider.selectChatModel.key,
        uid: _userModel.uid ?? "",
        role: 'assistant',
        message: assistantMessage);

    /// 대화종료 관련
    if (assistantMessage.contains('토론이 종료되었') ||
        assistantMessage.contains('대화가 종료되었')) {
      if (_pageProvider.selectChatModel.type == 'stress') {
        List resList = await ChatServices().endStressConversation(
            _pageProvider.selectChatModel.key,
            _userModel.uid ?? "",
            _userModel.nm ?? "",
            _pageProvider.gptKey,
            _pageProvider.selectChatModel.type);
        print('stress resList ${resList}');
        bool isGo = await Dialogs().showDialogWithTimer(context);

        if (isGo) {
          if (resList.first) {
            // _pageProvider.updateIsFromChat(true);
            // _pageProvider.updateChatEvaluations(resList.last);
            _pageProvider.updatePage(4);
          } else {
            Dialogs().onlyContentOneActionDialog(
                context: context,
                content: '분석 중 오류\n${resList.last}',
                firstText: '확인');
          }
        }
      } else {
        List resList = await ChatServices().endDebateConversation(
            _pageProvider.selectChatModel.key,
            _userModel.uid ?? "",
            _userModel.nm ?? "",
            _pageProvider.gptKey,
            _pageProvider.selectChatModel.type);

        bool isGo = await Dialogs().showDialogWithTimer(context);

        if (isGo) {
          if (resList.first) {
            // _pageProvider.updateIsFromChat(true);
            // _pageProvider.updateChatEvaluations(resList.last);
            _pageProvider.updatePage(2);
          } else {
            Dialogs().onlyContentOneActionDialog(
                context: context,
                content: '분석 중 오류\n${resList.last}',
                firstText: '확인');
          }
        }
      }
    }
  }

  // 유저가 메세지 입력 후 자동으로 아래로 스크롤되게 하여 메세지가 가려지지않도록 함
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // 12:08형태로 보여주기 위해 parsing
  String _formatTime(String time) {
    try {
      String dateString = DateFormat('HH:mm').format(DateTime.parse(time));

      return dateString;
    } catch (e) {
      return '';
    }
  }

  List<TextSpan> _getMessageTextSpans(String message) {
    final urlPattern = RegExp(r'https?:\/\/[^\s]+');
    final List<TextSpan> spans = [];
    int start = 0;

    for (final match in urlPattern.allMatches(message)) {
      if (match.start > start) {
        spans.add(TextSpan(text: message.substring(start, match.start)));
      }

      spans.add(TextSpan(
        text: match.group(0),
        style:
            TextStyle(color: Colors.blue, fontFamily: 'Cafe24Oneprettynight'),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _launchURL(match.group(0)!);
          },
      ));

      start = match.end;
    }

    if (start < message.length) {
      spans.add(TextSpan(text: message.substring(start)));
    }

    return spans;
  }

  Widget _buildMessage(Map<String, dynamic> message, double width) {
    bool isUser = message['role'] == 'user';

    // 이미지 경로를 chatModel.type에 따라 설정
    String imagePath;
    switch (_pageProvider.selectChatModel.type) {
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
        imagePath = "assets/icons/stress.png"; // 기본 이미지 경로 설정
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          isUser
              ? Container()
              : ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12), // 둥근 사각형을 위해 모서리 반경 설정
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  ),
                ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(10),
            constraints: BoxConstraints(maxWidth: width),
            decoration: BoxDecoration(
              color:
                  isUser ? _colorsModel.userTextBox : _colorsModel.gptTextBox,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                SelectableText.rich(
                  TextSpan(
                    children: _getMessageTextSpans(message['content'] ?? ""),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontFamily: 'Cafe24Oneprettynight'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        enableJavaScript: true,
        enableDomStorage: true,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  // 서버에서 유저정보를 가져옴
  Future<void> userInit() async {
    List resList =
        await UserServices().getUserModel(uid: AuthService().getUid());

    if (resList.first) {
      setState(() {
        _userModel = resList.last;
      });
      await UserServices().updateLinkedTime(
          uid: _userModel.uid, chatModelKey: _pageProvider.selectChatModel.key);
      // await _loadChatMessages();
      if (_messages.isEmpty) {
        _addInitialMessage();
      }
    }
  }

  // 서버에서 프롬프트 로드
  Future<void> promptInit() async {
    List resList =
        await _chatServices.getPrompt(key: _pageProvider.selectChatModel.key);
    if (resList.first) {
      setState(() {
        _prompt = resList.last;
      });
    }
  }

  void _addInitialMessage() {
    setState(() {
      String initialMessage;

      if (_pageProvider.selectChatModel.type == 'stress') {
        initialMessage = '안녕 만나서 반가워! 나는 연우라고 해. 너는 이름이 뭐야?';
      } else if (_pageProvider.selectChatModel.type == 'debate') {
        initialMessage = '안녕! 나는 오늘 너와 함께 토론을 진행할 AI 튜터야. 만나서 반가워.';
      } else {
        initialMessage =
            '안녕하세요! 저는 글쓰기 도와주는 AI 튜터입니다. 저와 함께 대화하며 왼쪽 글쓰기 칸을 채워나가 봅시다! \n\n'
            '아래는 국내 인공지능 법률 초기 입법에 대한 읽기자료입니다. 읽기자료를 모두 읽은 후 대화를 시작해주세요. \n\n'
            '링크: https://drive.google.com/file/d/1WL6aUt39ZZCT5hACFs9vvtvI3oGESw6W/view?usp=drive_link';
      }

      _messages.add({
        'role': 'assistant',
        'content': initialMessage,
        'time': DateTime.now().toIso8601String(),
      });
    });
  }
}
