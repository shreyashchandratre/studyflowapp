/// App-wide constants for StudyFlow.
class AppConstants {
  // Cerebras
  static const String cerebrasBaseUrl =
      'https://api.cerebras.ai/v1/chat/completions';
  static const String cerebrasModel = 'llama3.1-8b';
  static const int maxContextChars = 25000;

  // XP rewards
  static const int xpUpload     = 50;
  static const int xpFlashcard  = 20;
  static const int xpPerCorrect = 10; // per correct quiz answer

  // Levels
  static const int xpPerLevel   = 500;

  // Quiz
  static const int quizCount    = 10;
  static const int flashcardCount = 15;

  // Firestore collections
  static const String colUsers     = 'users';
  static const String colMaterials = 'materials';
  static const String colDocs      = 'docs';
  static const String colFlashcards = 'flashcards';
  static const String colScores    = 'scores';
}
