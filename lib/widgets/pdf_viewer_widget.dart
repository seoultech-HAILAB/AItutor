import 'dart:async';

import 'package:aitutor/models/colors_model.dart';
import 'package:aitutor/providers/page_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerWidget extends StatefulWidget {
  const PdfViewerWidget();

  @override
  _PdfViewerWidgetState createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  ColorsModel _colorsModel = ColorsModel();
  PageProvider _pageProvider = PageProvider();
  final int initialPage = 1;
  late PdfController _pdfController;
  bool _pdfControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loadPdf();
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      // assets 폴더에서 PDF 파일을 로드합니다.
      final data = await rootBundle.load('assets/docs/${_pageProvider.selectDocsModel.doc}.pdf');
      final bytes = data.buffer.asUint8List();
      _pdfController = PdfController(
          document: PdfDocument.openData(
              bytes
          ),
          initialPage: initialPage
      );
      setState(() {
        _pdfControllerInitialized = true;
        _pdfController;
      });
    } catch (e) {
      print("Error loading PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    _pageProvider = Provider.of<PageProvider>(context, listen: true);

    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorsModel.bl),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: screenHeight * 0.72,
            width: screenWidth,
            child: _pdfControllerInitialized
                ? PdfView(
              scrollDirection: Axis.vertical,
              builders: PdfViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
                pageLoaderBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
              ),
              controller: _pdfController,
            )
                : Text("PDF 파일을 로드할 수 없습니다."),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.only(bottom: 10, left: screenWidth * 0.12, right: screenWidth * 0.12),
            child: GestureDetector(
              onTap: () {
                _pageProvider.updateIsNoteApp(true);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _colorsModel.bl),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: Center(
                      child: Text("에세이 작성하기", style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cafe24Oneprettynight'
                      ),),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
