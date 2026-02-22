class Question {
  final String question;
  final List<String> options;
  final int correctIndex; // for checking answer later

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class Exam {
  final String id;
  final String title;
  final String date;
  final String time;
  final List<Question> questions; // added

  Exam({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.questions,
  });
}
