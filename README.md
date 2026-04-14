# StudyFlow 🎓

An AI-powered, modern mobile and desktop application crafted with Flutter that supercharges your learning experience. StudyFlow transforms raw documents into interactive study materials — generating intelligent summaries, infinite flashcards, personalized quizzes, and offering a smart AI Chat assistant right out of the box.

## ✨ Features

* **🧠 Smart AI Chat:** Discuss, digest, and query any concepts. StudyFlow uses Hybrid RAG implementation, prioritizing your uploaded study materials as context before defaulting to external knowledge to ensure hyper-relevant answers.
* **📝 Automated Summaries:** Upload PDFs or raw text, and seamlessly read AI-generated Brief, Detailed, and Comprehensive notes.
* **⚡ Intelligent Flashcards:** Goodbye manual flashcard authoring! With a single tap, extract the most crucial concepts from your materials into interactive front/back flashcards.
* **🎯 Dynamic Quizzes:** Test your knowledge. Generates multiple-choice quizzes with built-in instant feedback and detailed explanations for incorrect answers.
* **📈 Gamification & Dashboard Tracking:** Never lose motivation. Earn XP points by uploading materials, completing quizzes, and generating flashcards. View your Study Streak, Quizzes Taken, and Average Quiz Accuracy.
* **👥 Compare Stats:** Search for peers using our local ranking list and compare your XP, streak, and quiz stats head-to-head.
* **🖌️ Minimalist UI:** Complete accessibility-focused light-theme. Thoughtfully designed with off-white backgrounds, navy typography, and teal accents to prevent visual fatigue during long study sessions.

## 🚀 Tech Stack

* **Frontend Engine**: Flutter / Dart
* **AI Provider**: Cerebras Cloud API (`llama3.1-8b`) for blazing-fast local generation.
* **PDF Extraction**: Syncfusion Flutter PDF for on-device parsing.
* **State Management**: Provider

## ⚙️ Local Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shreyashchandratre/studyflowapp.git
   cd studyflowapp
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   * Rename `.env.example` to `.env`
   * Obtain a free API key from [Cloud Cerebras](https://cloud.cerebras.ai)
   * Set your key inside the `.env` file:
     ```env
     CEREBRAS_API_KEY=csk-your_api_key_here
     ```

4. **Run the App:**
   ```bash
   flutter run
   ```


*Built to make learning beautiful and effortless.*
