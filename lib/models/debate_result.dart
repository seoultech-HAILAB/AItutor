class DebateResult {
  var category;  // String
  var reason1;   // String
  var reason2;   // String
  var evaluation;  // String
  var detail;    // String
  var interaction1;  // String
  var interaction2;  // String
  var explain;   // String
  var isSuccess;  // 평가가 이뤄졌는지 여부

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
