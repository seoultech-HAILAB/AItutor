class DebateResult {
  String? category;
  String? reason1;
  String? reason2;
  String? evaluation;
  String? detail;
  String? interaction1;
  String? interaction2;
  String? explain;
  bool? isSuccess;

  DebateResult({
    this.category,
    this.reason1,
    this.reason2,
    this.evaluation,
    this.detail,
    this.interaction1,
    this.interaction2,
    this.explain,
    this.isSuccess,
  });

  // Add this factory constructor
  factory DebateResult.fromJson(Map<String, dynamic> json) {
    return DebateResult(
      category: json['category'] as String?,
      reason1: json['reason1'] as String?,
      reason2: json['reason2'] as String?,
      evaluation: json['evaluation'] as String?,
      detail: json['detail'] as String?,
      interaction1: json['interaction1'] as String?,
      interaction2: json['interaction2'] as String?,
      explain: json['explain'] as String?,
      isSuccess: json['isSuccess'] as bool?,
    );
  }

  List returnModels(String content) {
    try {
      List<DebateResult> results = [];
      // 주석 부분 추출
      int firstCategoryIndex = content.indexOf('[');
      String comment = content.substring(0, firstCategoryIndex).trim();
      String remainingContent = content.substring(firstCategoryIndex).trim();

      final RegExp regex = RegExp(
        r'\[([^\]]+)\]:\s*(.*?)\s*/\s*(.*?)\s*->\s*([^\n]+)\n(.*?)\n(1\..*?)\n(2\..*?)\n:\s*(.*?)(?=\[|$)',
        dotAll: true,
      );
      final matches = regex.allMatches(remainingContent);

      for (var match in matches) {
        String category = match.group(1)!.trim();      // [주장을 지지하는 근거 제시]
        String reason1 = match.group(2)!.trim();       // 제시한 근거가 주장과 관련이 없음
        String reason2 = match.group(3)!.trim();       // 주장과 직접적인 연관이 있는 근거를 제시함
        String evaluation = match.group(4)!.trim();    // 적절함(중)
        String detail = match.group(5)!.trim();        // 아래와 같은 근거를 제시함
        String interaction1 = match.group(6)!.trim();  // 1. 토론 1단계에서 했던 학생의 첫번째 의견
        String interaction2 = match.group(7)!.trim();  // 2. 토론 1단계에서 했던 학생의 두번째 의견
        String explain = match.group(8)!.trim();       // 상대방 논리의 허점을 드러내는 반론을 제시했는지를 나타냄

        results.add(DebateResult(
          category: category,
          reason1: reason1,
          reason2: reason2,
          evaluation: evaluation,
          detail: detail,
          interaction1: interaction1,
          interaction2: interaction2,
          explain: explain,
          isSuccess: true,
        ));
      }

      // matches가 비어있는 경우, 평가 결과가 제대로 파싱되지 않았을 가능성이 있음
      if (results.isEmpty) {
        results.add(DebateResult(
          isSuccess: false,
          detail: content,
          category: '',
          evaluation: '',
        ));
      }

      return [comment, results];
    } catch (e) {
      print("EvaluationResult error : $e");
      return [content, List<DebateResult>.from([])];
    }
  }
}

