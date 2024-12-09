
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:aitutor/models/colors_model.dart';
import 'package:aitutor/pages/argument_history_page.dart';
import 'package:aitutor/pages/debate_history_page.dart';
import 'package:aitutor/providers/page_provider.dart';
import 'package:aitutor/services/argument_services.dart';
import 'package:aitutor/services/auth_service.dart';
import 'package:aitutor/services/user_services.dart';
import 'package:aitutor/widgets/dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quil;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tuple/tuple.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:aitutor/services/chat_services.dart';


class NoteWidget extends StatefulWidget {
  const NoteWidget({Key? key,}) : super(key: key);

  @override
  State<NoteWidget> createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  ColorsModel _colorsModel = ColorsModel();
  bool _loading = false;
  PageProvider _pageProvider = PageProvider();
  late quil.QuillController _quillController;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _quillController = quil.QuillController.basic();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loadNote();
    });
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() {
      _loading = true;
    });

    try {
      final contents = jsonEncode(_quillController.document.toDelta().toJson());
      final uid = AuthService().getUid(); // 유저의 uid 가져오기
      final chatServices = ChatServices();

      // Evaluate the content
      List evaluatePromptRes = await chatServices.getEvalulatePrompt(key: 'AI 글쓰기 튜터');
      if (!evaluatePromptRes.first) {
        throw Exception('Error: Unable to retrieve evaluation prompt.');
      }
      String evaluatePrompt = evaluatePromptRes.last;
      String finalPrompt = evaluatePrompt.replaceAll('<content>', contents);

      // GPT API 응답 요청
      String response = await chatServices.getResponse(
        [
          {'role': 'user', 'content': contents}
        ],
        finalPrompt,
        Provider.of<PageProvider>(context, listen: false).gptKey,
      );

      // 현재 시간을 Firebase-friendly 형식으로 변환
      final now = DateTime.now();
      final formattedTime = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";

      // Firebase 데이터베이스 경로 수정
      await FirebaseDatabase.instance
          .ref('Chat/AI 글쓰기 튜터/History/$uid/AI LAW/$formattedTime') // 형식에 맞는 시간 사용
          .set({
        'contents': contents,
        'response': response, // Evaluation response 저장
      });

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트가 성공적으로 저장되었습니다.')),
      );

      // Navigate to ArgumentHistoryPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ArgumentHistoryPage(),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트를 저장하는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _loadNote() async {
    setState(() {
      _loading = true;
    });

    try {
      final contents = await _storage.read(key: '${_pageProvider.selectDocsModel.title}note');
      if (contents != null) {
        final document = quil.Document.fromJson(jsonDecode(contents));
        _quillController = quil.QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _quillController = quil.QuillController.basic();
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트를 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    _pageProvider = Provider.of<PageProvider>(context, listen: true);

    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Stack(
        children: [
          quilBody(context, screenWidth, screenHeight),
          _loading ? Center(child: CircularProgressIndicator(color: _colorsModel.main,),) : Container(),
        ],
      ),
    );
  }

  Widget quilBody(context, screenWidth, screenHeight) {
    return Container(
      height: screenHeight * 0.8,
      width: screenWidth * 0.47,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _colorsModel.bl, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            quil.QuillToolbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuillToolbarHistoryButton(
                      isUndo: true,
                      controller: _quillController,
                    ),
                    QuillToolbarHistoryButton(
                      isUndo: false,
                      controller: _quillController,
                    ),
                    QuillToolbarToggleStyleButton(
                      options: const QuillToolbarToggleStyleButtonOptions(),
                      controller: _quillController,
                      attribute: Attribute.bold,
                    ),
                    QuillToolbarToggleStyleButton(
                      options: const QuillToolbarToggleStyleButtonOptions(),
                      controller: _quillController,
                      attribute: Attribute.italic,
                    ),
                    QuillToolbarToggleStyleButton(
                      controller: _quillController,
                      attribute: Attribute.underline,
                    ),
                    QuillToolbarClearFormatButton(
                      controller: _quillController,
                    ),
                    const VerticalDivider(),
                    QuillToolbarCustomButton(
                      controller: _quillController,
                    ),
                    const VerticalDivider(),
                    QuillToolbarColorButton(
                      controller: _quillController,
                      isBackground: false,
                    ),
                    QuillToolbarColorButton(
                      controller: _quillController,
                      isBackground: true,
                    ),
                    const VerticalDivider(),
                    QuillToolbarToggleCheckListButton(
                      controller: _quillController,
                    ),
                    QuillToolbarToggleStyleButton(
                      controller: _quillController,
                      attribute: Attribute.ol,
                    ),
                    QuillToolbarToggleStyleButton(
                      controller: _quillController,
                      attribute: Attribute.ul,
                    ),
                    QuillToolbarToggleStyleButton(
                      controller: _quillController,
                      attribute: Attribute.inlineCode,
                    ),
                    QuillToolbarToggleStyleButton(
                      controller: _quillController,
                      attribute: Attribute.blockQuote,
                    ),
                    QuillToolbarIndentButton(
                      controller: _quillController,
                      isIncrease: true,
                    ),
                    QuillToolbarIndentButton(
                      controller: _quillController,
                      isIncrease: false,
                    ),
                    const VerticalDivider(),
                    QuillToolbarLinkStyleButton(controller: _quillController),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: quil.QuillEditor.basic(
                  configurations: quil.QuillEditorConfigurations(
                    controller: _quillController,
                    autoFocus: false,
                    showCursor: true,
                    textSelectionThemeData: TextSelectionThemeData(
                      cursorColor: _colorsModel.bl,
                      selectionColor: _colorsModel.bl,
                      selectionHandleColor: _colorsModel.bl,
                    ),
                    customStyles: DefaultStyles(
                      paragraph: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 20,
                          color: _colorsModel.bl,
                          fontFamily: 'Cafe24Oneprettynight'
                        ),
                        const VerticalSpacing(0, 0), // verticalSpacing
                        const VerticalSpacing(0, 0), // lineSpacing
                        null, // decoration
                      ),
                      color: _colorsModel.bl,
                    ),
                    sharedConfigurations: const quil.QuillSharedConfigurations(
                      locale: Locale('ko'),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: screenWidth * 0.15,
              decoration: BoxDecoration(
                color: _colorsModel.gr4,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _colorsModel.bl, width: 2),
              ),
              child: InkWell( // 클릭 가능하도록 InkWell로 감싸기
                onTap: () {
                  _saveNote(); // 버튼 클릭 시 호출할 함수
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    '제출하기',
                    style: TextStyle(
                      color: _colorsModel.bl,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cafe24Oneprettynight',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
