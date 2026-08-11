# StudyFlow — Project Architecture

## Overview

StudyFlow is a cross-platform Flutter application (Android, iOS, Desktop) that uses Firebase for auth and storage, and the Cerebras Cloud API (llama3.1-8b) for all AI features. There is no custom backend server — everything runs client-side or through Firebase/Cerebras directly.

---

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    Flutter App                           │
│                                                          │
│  ┌──────────┐  ┌────────────┐  ┌──────────────────────┐ │
│  │  Screens │→ │  Providers │→ │      Services        │ │
│  │  (UI)    │  │  (State)   │  │  (Firebase/Cerebras) │ │
│  └──────────┘  └────────────┘  └──────────────────────┘ │
└────────────────────┬─────────────────────┬───────────────┘
                     │                     │
        ┌────────────▼──────────┐  ┌───────▼──────────────┐
        │     Firebase          │  │   Cerebras Cloud API  │
        │  - Firebase Auth      │  │   llama3.1-8b         │
        │  - Firestore DB       │  │   (SSE Streaming)     │
        └───────────────────────┘  └──────────────────────┘
```

---

## Layer Breakdown

### 1. Screens (UI Layer)
Each screen is a StatefulWidget or StatelessWidget that reads from Providers via `context.watch<>()` and calls Provider methods via `context.read<>()`. No screen ever touches Firebase or Cerebras directly.

```
lib/screens/
├── login_screen.dart         — Email/password login form
├── signup_screen.dart        — Registration form
├── main_shell.dart           — Root scaffold with bottom nav + rail
├── home/home_screen.dart     — Dashboard (XP card, stats, recent docs)
├── materials/
│   ├── materials_screen.dart     — Document list + upload sheet
│   └── document_detail_screen.dart — Study tools hub per document
├── summary/summary_screen.dart   — Brief/Detailed/Comprehensive summaries
├── quiz/quiz_screen_new.dart     — MCQ quiz with scoring
├── flashcards/flashcards_screen.dart — Flip card viewer
├── chat/chat_screen_new.dart     — Streaming AI chat
├── leaderboard/leaderboard_screen.dart — Top 20 + compare
└── profile/profile_screen_new.dart   — User stats + sign out
```

### 2. Providers (State Layer)
All business logic and state lives here. Providers extend `ChangeNotifier` and use `notifyListeners()` to push updates to the UI.

```
lib/providers/
├── auth_provider.dart         — Firebase Auth state, login, register, logout
├── materials_provider.dart    — Documents CRUD, summaries, quiz, flashcards
├── chat_provider.dart         — Streaming chat history, session management
└── gamification_provider.dart — XP, streak, leaderboard, compare
```

### 3. Services (Data Layer)
Pure data access — no UI, no state.

```
lib/services/
├── firebase_service.dart   — All Firestore reads/writes
├── cerebras_service.dart   — All Cerebras AI calls (streaming + one-shot)
└── pdf_service.dart        — On-device PDF text extraction (Syncfusion)
```

Stub services (legacy, all return empty):
- `auth_service.dart`, `chat_service.dart`, `document_service.dart`, `resource_service.dart`, `search_service.dart`

---

## Firestore Database Design

```
users/                          ← collection
  {uid}/                        ← document (one per user)
    username: string
    email: string
    xp: number
    streak: number
    quizzesTaken: number
    avgAccuracy: number
    lastActiveDate: timestamp

materials/                      ← collection
  {uid}/                        ← document (one per user)
    docs/                       ← sub-collection
      {docId}/                  ← document (one per uploaded file)
        title: string
        rawText: string
        uploadedAt: timestamp
        summaries: {            ← cached after first generation
          brief: string
          detailed: string
          comprehensive: string
        }
        flashcards/             ← sub-collection
          {cardId}/
            front: string
            back: string

scores/                         ← collection (denormalized for leaderboard)
  {uid}/
    xp: number
    streak: number
    quizzesTaken: number
    avgAccuracy: number
    username: string
```

**Why denormalized scores collection?**
Firestore cannot do cross-user queries efficiently on the `users` collection without a composite index. The `scores` collection is a flat, denormalized copy kept in sync via `_syncScores()` after every XP update — allows a single `orderBy('xp').limit(20)` query for the leaderboard.

---

## Authentication Flow

```
App Start
    │
    ▼
Firebase.initializeApp()
    │
    ▼
AuthProvider listens to _auth.authStateChanges() stream
    │
    ├─── User is null → LoginScreen
    │
    └─── User exists → fetch UserModel from Firestore → MainShell
```

Login flow:
```
User taps Sign In
    │
    ▼
AuthProvider.login(email, password)
    │
    ▼
FirebaseAuth.signInWithEmailAndPassword()
    │
    ├─── Success → authStateChanges fires → _onAuthStateChanged → MainShell
    └─── Failure → FirebaseAuthException → _authMessage() → error snackbar
```

---

## Data Flow — Document Upload

```
User picks PDF in _UploadSheet
    │
    ▼
PdfService.extractText(bytes)  ← runs in Isolate via compute()
    │
    ▼
MaterialsProvider.saveDocument(title, rawText)
    │
    ▼
FirebaseService.saveDocument() → Firestore materials/{uid}/docs/{newId}
    │
    ▼
FirebaseService.addXp(50) → Firestore users/{uid}.xp += 50
                           → _syncScores() → scores/{uid}
    │
    ▼
_documents.insert(0, doc) → notifyListeners() → UI rebuilds
```

---

## Data Flow — AI Chat (Streaming)

```
User types message → taps Send
    │
    ▼
ChatScreenNew._send()
  → builds context string from ALL documents:
    "=== Title ===\n{rawText}\n\n=== Title2 ===\n..."
    │
    ▼
ChatProvider.sendMessage(text, studyMaterial: context)
  → adds user ChatMessage to _messages list
  → adds placeholder assistant ChatMessage ""
  → notifyListeners() → UI shows empty bubble
    │
    ▼
CerebrasService.streamChat(history, systemPrompt)
  → POST https://api.cerebras.ai/v1/chat/completions
    body: { stream: true, model: "llama3.1-8b", messages: [...] }
    │
    ▼
SSE stream received token by token
  → each token: _streamingContent += token
  → _messages[last] = ChatMessage(content: _streamingContent)
  → notifyListeners() → bubble updates live
    │
    ▼
Stream ends → _history.add assistant message → _isSending = false
```

---

## XP & Gamification Flow

```
Action               XP      Where
─────────────────────────────────────────────────
Upload document    +50 XP   MaterialsProvider.saveDocument()
Generate flashcards +20 XP  MaterialsProvider.generateFlashcards()
Correct quiz answer +10 XP  QuizScreenNew._showResults()
                             → FirebaseService.recordQuizResult()
```

After every XP change:
```
FirebaseService.addXp(n)
    → users/{uid}.xp += n  (FieldValue.increment)
    → _syncScores() → scores/{uid} updated
    → GamificationProvider.refreshUser() → UI updates
```

---

## Navigation Structure

```
_AuthGate
├── LoginScreen
│   └── SignupScreen
└── MainShell (IndexedStack)
    ├── [0] HomeScreen
    ├── [1] MaterialsScreen
    │       └── DocumentDetailScreen
    │               ├── SummaryScreen
    │               ├── FlashcardsScreen
    │               └── QuizScreenNew
    ├── [2] ChatScreenNew
    ├── [3] LeaderboardScreen
    └── [4] ProfileScreenNew
```

`MainShell` uses `IndexedStack` — all 5 screens are kept alive simultaneously. Navigation between tabs does not rebuild screens, preserving scroll position and state.

On mobile: `BottomNavigationBar`
On desktop (width > 720px): `NavigationRail`

---

## Key Technical Decisions

| Decision | Why | Trade-off |
|---|---|---|
| Firebase instead of custom backend | No server to maintain, auth + DB in one SDK | Vendor lock-in, Firestore pricing at scale |
| Cerebras instead of OpenAI | ~10x faster inference for llama3.1-8b | Less capable than GPT-4, API key exposed in .env |
| SSE streaming for chat | Token-by-token UI feels responsive | More complex state management in provider |
| Denormalized scores collection | Single query for leaderboard | Must keep in sync manually after every XP change |
| compute() for PDF extraction | Runs in background isolate, doesn't block UI | Slightly higher memory usage |
| IndexedStack for navigation | Preserves state across tabs | All screens initialized on first launch |
| Context-injection RAG | Simple, no vector DB needed | Hits token limits on large documents (truncated at 25k chars) |
| typedef DocumentProvider = MaterialsProvider | Backward compat for old screens | Confusing naming in codebase |
