class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final opts = (map['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return QuizQuestion(
      question: map['question']?.toString() ?? '',
      options: opts,
      answer: map['answer']?.toString() ?? (opts.isNotEmpty ? opts[0] : ''),
      explanation: map['explanation']?.toString() ?? '',
    );
  }
}
