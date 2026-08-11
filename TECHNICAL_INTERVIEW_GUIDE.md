# StudyFlow — Technical Interview Guide

---

## 1. "Explain This Project" — Interview Answers

### 30-Second Answer
"StudyFlow is a cross-platform Flutter app that uses Firebase for auth and storage, and the Cerebras AI API to turn uploaded study documents into summaries, quizzes, and flashcards. Users earn XP for every action and can compare stats on a leaderboard."

### 1-Minute Answer
"StudyFlow is an AI-powered study tool built with Flutter that runs on Android, iOS, and desktop. Users upload PDFs or paste text, and the app uses the Cerebras llama3.1-8b model to generate three levels of summaries, 15 flashcards, and a 10-question multiple-choice quiz — all from the same document. There's a streaming AI chat that injects all the user's documents as context so the AI answers are grounded in their actual material. On the backend I used Firebase Auth for authentication and Firestore as the database. Every action — uploading, completing a quiz, generating flashcards — awards XP, and there's a leaderboard pulling from a denormalized Firestore collection."

### 3-Minute Technical Answer
"The app follows a three-layer architecture: Screens handle UI, Providers manage state using Flutter's Provider pattern with ChangeNotifier, and Services handle external data access.

Authentication is entirely Firebase Auth — on app start, the AuthProvider listens to Firebase's authStateChanges stream. If the user is authenticated it fetches their UserModel from Firestore and navigates to the MainShell; otherwise it shows the login screen.

All document storage is Firestore. Each user has their own subcollection at `materials/{uid}/docs/` where documents are stored with their raw text and cached AI summaries. Flashcards are stored in a further subcollection under each document.

For AI, I use the Cerebras Cloud API which is OpenAI-compatible but significantly faster for llama3.1-8b. The chat uses Server-Sent Events streaming — each token updates the message bubble in real-time. The summaries and quiz generation use one-shot completions that return JSON which the app parses.

The chat implements a context-injection approach: before sending any user message, the app concatenates all of the user's uploaded documents into a system prompt, so the AI answers questions based on their actual material first, then falls back to general knowledge.

For the leaderboard I maintain a denormalized `scores` collection in Firestore that's kept in sync after every XP change, enabling a single ordered query to get the top 20 users without scanning the entire users collection.

PDF extraction runs in a background Dart isolate via compute() using the Syncfusion library, so it never blocks the UI thread."

### 5-Minute Deep Technical Answer
Add to the above:

"The state management is entirely unidirectional. A widget calls `context.read<Provider>().someMethod()` which updates internal state and calls `notifyListeners()`. Widgets listening via `context.watch<Provider>()` automatically rebuild. No widget ever touches Firebase or the AI API directly.

The streaming chat is the most complex piece. In ChatProvider.sendMessage(), I immediately add a placeholder assistant ChatMessage with empty content to the messages list and call notifyListeners() — this causes the bubble to appear instantly. Then I start consuming the SSE stream from CerebrasService.streamChat(). Each token is appended to _streamingContent and the last message in the list is replaced with the updated content — another notifyListeners() call. This gives a live typewriter effect. When the stream ends, the final content is added to the _history list which is sent with the next message to maintain conversation context.

For the leaderboard, the problem is Firestore doesn't allow cross-user queries efficiently. My solution: a `scores` collection where every document has the same structure — uid as document ID, xp, streak, username. After every XP change, _syncScores() re-reads the user doc and writes to scores. The leaderboard query is just `collection('scores').orderBy('xp', descending: true).limit(20)` — O(1) index scan.

The XP calculation for quiz results is interesting. When a quiz finishes, I read the current quizzesTaken count and avgAccuracy from Firestore, then compute the new rolling average: `newAvg = ((oldAvg * oldCount) + accuracy) / (oldCount + 1)`. This avoids storing every individual quiz result while keeping the average accurate.

The streak logic runs on every app open in touchActivity(). I compare lastActiveDate to today: same day = no change, exactly 1 day ago = increment streak, more than 1 day = reset to 1. This is correct for calendar-day streaks.

The app also handles the PDF extraction performance concern: Syncfusion's PDF parser is CPU-intensive for large files, so it's dispatched to a separate isolate using Flutter's compute() function which sends the bytes to a background thread and returns the extracted string."

---

## 2. Important Files — Deep Dive

### `lib/main.dart`
**Purpose:** App entry point. Initializes Firebase and dotenv before runApp(), wraps everything in MultiProvider.

**Why it matters:** The order matters — `WidgetsFlutterBinding.ensureInitialized()` must be called before any async work. Firebase.initializeApp() must complete before any Firestore/Auth calls. dotenv.load() must complete before CerebrasService reads the API key.

**Interview question:** "Why do you call ensureInitialized() in main()?"
**Answer:** Flutter needs the widget binding set up before you can use platform channels, which Firebase and file I/O depend on. Without it, calling Firebase.initializeApp() would throw.

---

### `lib/services/firebase_service.dart`
**Purpose:** Single gateway for all Firestore operations. Every read and write goes through this class.

**Key methods:**

`touchActivity(UserModel current)` — Called on every app open. Implements streak logic:
```dart
final daysDiff = now.difference(last).inDays;
if (daysDiff == 1) newStreak += 1;   // consecutive
else if (daysDiff > 1) newStreak = 1; // reset
// daysDiff == 0: same day, no change
```

`recordQuizResult()` — Rolling average accuracy calculation:
```dart
final newAvg = oldCount == 0
    ? accuracy
    : ((oldAvg * oldCount) + accuracy) / (oldCount + 1);
final xpEarned = correctAnswers * AppConstants.xpPerCorrect;
```

`_syncScores()` — Denormalized write after every XP change:
```dart
await _db.collection('scores').doc(_uid).set({
  'xp': data['xp'], 'streak': data['streak'], ...
}, SetOptions(merge: true));
```

`saveDocument()` — Creates a new Firestore document ref, builds the DocumentModel with the ref's auto-generated ID, then saves:
```dart
final ref = _db.collection('materials').doc(_uid).collection('docs').doc();
// ref.id is the auto-generated Firestore ID
```

**Interview questions:**
- "Why do you use FieldValue.increment() instead of reading then writing?"
  → Atomic — avoids race conditions if two devices update XP simultaneously.
- "Why is there a separate scores collection?"
  → Firestore can't efficiently query across all users' documents. The denormalized scores collection enables O(1) leaderboard reads.
- "What happens if _syncScores() fails?"
  → The error is caught and logged but not re-thrown. The XP update already succeeded — scores will be out of sync until next XP update. This is a known weakness.

---

### `lib/services/cerebras_service.dart`
**Purpose:** All AI calls. Two modes: `streamChat()` for live chat (SSE), `complete()` for one-shot generation (summaries, quiz, flashcards).

**streamChat() internals:**
```dart
// Uses http.Client.send() for a streaming response
final request = http.Request('POST', uri)
  ..headers['Accept'] = 'text/event-stream'
  ..body = jsonEncode({..., 'stream': true});
final response = await client.send(request);

// Reads SSE line by line
await for (final chunk in response.stream.transform(utf8.decoder)) {
  // Parse "data: {...}" lines
  // Extract choices[0].delta.content
  // yield the token
}
```

**parseJsonList() / parseJsonObject()** — Static helpers that strip markdown code fences (```json) from LLM output before JSON.decode(). LLMs often wrap JSON in markdown even when told not to.

**Interview questions:**
- "Why use streaming for chat but not for summaries?"
  → Chat benefits from the typewriter feel — users see the response building. Summaries are shown all at once in a text block, so streaming adds complexity without UX benefit.
- "What happens if the API key is missing?"
  → _hasKey returns false. streamChat() yields a warning string. complete() throws an exception caught by the provider.
- "How do you handle SSE parsing?"
  → Buffer incoming chunks, split on newlines, look for lines starting with "data: ", skip "[DONE]", parse JSON and extract choices[0].delta.content.

---

### `lib/providers/materials_provider.dart`
**Purpose:** Central provider for all document operations. Bridges UI ↔ Firebase + Cerebras.

**getSummaries() — two-level caching:**
```
1. Check _summaryCache (in-memory Map)
2. Check doc.summaries (Firestore-cached on DocumentModel)
3. Call CerebrasService.complete() to generate fresh
4. Store in _summaryCache + write back to Firestore via cacheSummaries()
```

**generateFlashcards() — three-level caching:**
```
1. Check _flashcardCache (in-memory)
2. Check Firestore sub-collection via fetchFlashcards()
3. Generate via CerebrasService.complete()
4. Save to Firestore via saveFlashcards()
5. Award +20 XP
```

**Interview questions:**
- "Why cache summaries back to Firestore?"
  → Cerebras calls cost money and take 3-10 seconds. Caching means the user only pays that cost once per document.
- "What's the difference between isLoading and isUploading?"
  → isLoading covers fetch operations (showing a spinner over the list). isUploading covers the upload + save flow (shows a dedicated uploading state with progress bar).
- "What is DocumentProvider?"
  → A typedef: `typedef DocumentProvider = MaterialsProvider`. Old screens used the name DocumentProvider — this alias lets them compile without changes.

---

### `lib/providers/chat_provider.dart`
**Purpose:** Manages chat message list and streaming state.

**Key pattern — streaming message update:**
```dart
// Add placeholder
_messages.add(ChatMessage(role: 'assistant', content: ''));
notifyListeners(); // bubble appears immediately

// Update token by token
await for (final token in _ai.streamChat(...)) {
    _streamingContent = (_streamingContent ?? '') + token;
    _messages[_messages.length - 1] =
        ChatMessage(role: 'assistant', content: _streamingContent!);
    notifyListeners(); // bubble updates live
}
```

**Context building in ChatScreenNew._send():**
```dart
final context_ = docProv.documents
    .map((d) => '=== ${d.title} ===\n${d.rawText}')
    .join('\n\n');
// This concatenation of ALL documents is sent as studyMaterial
// to ChatProvider.sendMessage()
```

**Interview questions:**
- "What happens if the user sends another message while the AI is still responding?"
  → `if (text.trim().isEmpty || _isSending) return;` — the second message is silently dropped. This is a known limitation.
- "How is conversation history maintained?"
  → The `_history` list stores all previous `{role, content}` pairs and is sent with every new request to Cerebras. startNewSession() clears it.
- "What if the context string exceeds the token limit?"
  → In CerebrasService, the context is truncated to 25,000 characters (AppConstants.maxContextChars) before being added to the system prompt.

---

### `lib/providers/auth_provider.dart`
**Purpose:** Wraps Firebase Auth with a ChangeNotifier interface.

**Auth state listener:**
```dart
AuthProvider() {
  _auth.authStateChanges().listen(_onAuthStateChanged);
}
// This stream fires on: login, logout, token refresh, app restart
// _AuthGate rebuilds whenever isAuthenticated changes
```

**Error mapping:**
```dart
String _authMessage(String code) {
  switch (code) {
    case 'user-not-found': return 'No account found...';
    case 'wrong-password': return 'Incorrect password.';
    // etc.
  }
}
```

**Interview questions:**
- "How does the app know if the user is already logged in when it restarts?"
  → Firebase persists the auth token locally. On restart, authStateChanges() fires with the existing user before _AuthGate even renders.
- "What does context.mounted check prevent?"
  → After an async operation, the widget might have been disposed. Calling setState() or Navigator on a disposed widget throws. `if (!mounted) return` prevents this.

---

### `lib/screens/main_shell.dart`
**Purpose:** Root navigation shell — builds the screen list once in initState(), uses IndexedStack to keep all tabs alive.

**Why IndexedStack:**
```dart
IndexedStack(
  index: _tab,
  children: _screens, // all 5 screens exist simultaneously
)
```
Switching tabs doesn't rebuild the screen — state (scroll position, loaded data) is preserved.

**Responsive layout:**
```dart
LayoutBuilder(builder: (ctx, constraints) {
  if (constraints.maxWidth > 720) return _buildDesktop(ctx); // NavigationRail
  return _buildMobile(); // BottomNavigationBar
});
```

**Interview questions:**
- "What's the downside of IndexedStack?"
  → All screens initialize on first app open, even if the user never visits some tabs. This means initState() runs for all screens immediately — could trigger unnecessary network calls.
- "Why build _screens in initState() and not in build()?"
  → If _screens were built in build(), every setState() call would recreate the widget instances, destroying their internal state and triggering re-initialization.

---

### `lib/screens/materials/materials_screen.dart`
**Purpose:** Document list with swipe-to-delete and upload sheet.

**Dismissible for delete:**
```dart
Dismissible(
  key: Key(doc.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (_) async {
    return await showDialog<bool>(...); // confirm dialog
  },
  onDismissed: (_) => context.read<MaterialsProvider>().deleteDocument(doc.id),
)
```

**PDF upload pipeline in _UploadSheet:**
```
FilePicker.platform.pickFiles(withData: true)
    → file.bytes ?? File(file.path!).readAsBytes()
    → PdfService.extractText(bytes)  // background isolate
    → MaterialsProvider.saveDocument(title, text)
    → Navigator.pop() + SnackBar
```

**Interview questions:**
- "Why do you check both file.bytes and file.path?"
  → On web, file.path is null — bytes come from withData: true. On mobile, bytes may be null for large files — fall back to reading from path.
- "What does confirmDismiss do?"
  → Intercepts the swipe before deletion, shows a dialog, and only proceeds if the user confirms. Returns false cancels the dismiss animation.

---

### `lib/screens/quiz/quiz_screen_new.dart`
**Purpose:** Quiz flow — generate, answer, score, record to Firestore.

**Answer validation:**
```dart
void _answer(int idx) {
  if (_answered) return; // prevent double-tap
  final correct = q['answer'].toString();
  final isCorrect = opts[idx].toString() == correct;
  setState(() { _selectedIdx = idx; _answered = true; if (isCorrect) _score++; });
}
```

**Results + Firestore write:**
```dart
void _showResults() {
  FirebaseService().recordQuizResult(
    correctAnswers: _score, totalQuestions: total);
  context.read<GamificationProvider>().refreshUser(); // refresh XP display
}
```

**Interview questions:**
- "Why call FirebaseService() directly in the screen instead of through a provider?"
  → This is a minor architectural inconsistency — it should go through GamificationProvider. Calling the service directly bypasses the provider layer.
- "How does the animated option color work?"
  → AnimatedContainer with duration 250ms changes color/border based on _answered state. If correct → green. If wrong selection → red. Correct answer always shows green after answering.

---

### `lib/screens/flashcards/flashcards_screen.dart`
**Purpose:** 3D flip card animation using Matrix4 transforms.

**Flip animation:**
```dart
// _ctrl is AnimationController 0→1
// angle = _anim.value * pi  (0 to 180 degrees)
Transform(
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.001) // perspective
    ..rotateY(angle),
  child: isFront ? _CardFace(front) : mirror(_CardFace(back))
)
```

**Why setEntry(3, 2, 0.001)?**
This sets the perspective in the 4x4 transformation matrix. Without it, the rotation looks flat/2D. The value 0.001 gives a subtle 3D perspective effect.

**Height preservation trick:**
Two invisible copies of both faces are rendered with `maintainSize: true` so the Stack always adopts the height of the taller face. The visible face fills that height via `Positioned.fill`.

**Interview questions:**
- "Why does didUpdateWidget reset the animation?"
  → When PageView swipes to a new card, the widget rebuilds with a new FlashcardModel. didUpdateWidget resets the flip state so the new card always starts face-up.

---

## 3. Technology Explanations

### Flutter / Dart
**Why used:** Single codebase for Android, iOS, Windows, macOS, Linux. Dart compiles to native ARM code — not a webview. Widget tree with reactive rebuilds.
**How it works here:** Stateful/Stateless widgets, Provider for state, LayoutBuilder for responsive UI.
**Alternatives:** React Native (JS bridge overhead), Kotlin/Swift (separate codebases).

### Firebase Auth
**Why used:** Handles email/password auth, token management, persistence across app restarts — all without a custom server.
**How it works here:** authStateChanges() stream drives the _AuthGate widget. FirebaseAuthException codes are mapped to user-friendly messages.
**Alternatives:** Custom JWT server (more control but more work), Supabase Auth.

### Firestore
**Why used:** NoSQL document database with real-time capabilities, offline support, scales automatically.
**How it works here:** Hierarchical collections — users → materials/{uid}/docs → flashcards. Denormalized scores collection for leaderboard.
**Alternatives:** Firebase Realtime DB (flat JSON, harder to query), Supabase (PostgreSQL, SQL queries).

### Cerebras Cloud API
**Why used:** OpenAI-compatible API running llama3.1-8b at ~10x faster inference than standard GPU hosting. Critical for the streaming chat UX.
**How it works here:** SSE streaming for chat (tokens arrive live), standard POST for summaries/quiz/flashcards.
**Alternatives:** OpenAI GPT-4 (more capable, slower, expensive), Gemini (Google SDK available for Flutter).

### Provider (State Management)
**Why used:** Official Flutter recommendation. Simple ChangeNotifier pattern, minimal boilerplate, good performance.
**How it works here:** 4 top-level providers injected at app root via MultiProvider. Screens watch specific providers, rebuilding only when that provider's state changes.
**Alternatives:** Riverpod (more type-safe), BLoC (more boilerplate, good for complex flows), GetX (opinionated).

### Syncfusion Flutter PDF
**Why used:** On-device PDF text extraction — no server upload needed. Runs in compute() isolate so it doesn't block the UI.
**Alternatives:** Native PDF APIs (platform-specific), server-side extraction (requires backend).

---

## 4. Interview Questions by Level

### Beginner
**Q: What is a StatefulWidget vs StatelessWidget?**
A: StatelessWidget has no mutable state — it renders from its constructor parameters only. StatefulWidget has a State object that can change via setState(), triggering a rebuild. In this app, HomeScreen is StatefulWidget (loads data in initState), _XpCard is StatelessWidget (only renders what it's given).

**Q: What is Provider?**
A: A state management package. A ChangeNotifier holds state and calls notifyListeners() when it changes. Widgets that call context.watch<T>() rebuild when T notifies. context.read<T>() gets the instance without subscribing to rebuilds.

**Q: What is Firebase Auth?**
A: Google's authentication service. Handles user registration, login, token issuance and refresh. In this app, the authStateChanges() stream tells the app whether a user is logged in — persists across app restarts automatically.

---

### Intermediate
**Q: How does the IndexedStack work and why use it?**
A: IndexedStack keeps all children in the widget tree simultaneously but only renders the one at the current index. Unlike PageView or Navigator, switching tabs never disposes the screens — state is preserved. Used here so the Chat screen doesn't lose its message history when the user switches to Materials and back.

**Q: Explain the Firestore data model.**
A: Hierarchical NoSQL. Users have their own document in `users/{uid}`. Their study materials live in `materials/{uid}/docs/{docId}`. Flashcards are in a sub-collection of each doc. A separate `scores` collection is a denormalized copy for leaderboard queries — kept in sync after every XP update.

**Q: How does PDF extraction work without a server?**
A: The user picks a file with FilePicker. The bytes are passed to PdfService.extractText() which calls Syncfusion's PdfTextExtractor inside a Dart isolate via compute(). The isolate runs in a separate thread, so heavy CPU work doesn't freeze the UI. The extracted string is returned to the main thread and saved to Firestore.

---

### Advanced
**Q: Explain the SSE streaming implementation.**
A: An http.Request is sent with `Accept: text/event-stream` and `stream: true` in the body. http.Client.send() returns a StreamedResponse. The response.stream is decoded as UTF-8 and split into lines. Lines starting with "data: " contain JSON with `choices[0].delta.content` — the token. Each token is yielded from the async* generator. The provider appends each token to the current message and calls notifyListeners(), causing the bubble to update live.

**Q: How does the rolling average accuracy work?**
A: `newAvg = ((oldAvg * oldCount) + newAccuracy) / (oldCount + 1)`. This is an incremental mean calculation — mathematically equivalent to averaging all values but only requires storing the current average and count, not every individual quiz score.

**Q: What is the race condition risk with FieldValue.increment()?**
A: If two devices simultaneously update XP using a read-modify-write approach (read xp, add, write back), they could both read the same value and one update would be lost. FieldValue.increment() is an atomic server-side operation — Firestore applies the increment regardless of the current value, so concurrent updates are safe.

---

### Expert / System Design
**Q: How would you scale this if you had 100,000 users?**
A:
1. Firestore scales automatically — no changes needed for reads/writes.
2. The `scores` collection leaderboard query is already indexed — still fast at 100k users.
3. The Cerebras API is external — concurrent AI calls would hit rate limits. Add a queue system (Cloud Tasks or a simple counter) to throttle requests per user.
4. The context-injection RAG approach sends the full document text with every message. At scale this is expensive. Replace with proper vector search (Pinecone/Weaviate) — chunk documents into 500-token pieces, embed them, search for top-K relevant chunks at query time.
5. Cold start on Cerebras: first request after inactivity is slow. Implement a simple "warm" ping on app foreground.

**Q: What security vulnerabilities exist?**
A:
1. The Cerebras API key is in .env and bundled into the app binary. Malicious users can extract it with reverse engineering tools. Solution: proxy all AI calls through a Cloud Function that holds the key server-side.
2. Firestore security rules: if rules aren't set correctly, users could read/write other users' data. The app assumes rules restrict `materials/{uid}/docs` to authenticated users where `request.auth.uid == uid`.
3. firebase_options.dart contains Firebase config values (apiKey, appId). These are public by design for Firebase web/mobile clients — Firebase security is enforced by Firestore Rules and Auth, not by keeping these values secret.

**Q: The chat sends ALL documents as context. What problems does this cause?**
A:
1. Token limit: context is hard-truncated at 25,000 chars. Documents beyond that are silently ignored.
2. Cost: every message re-sends the full context. With 10 documents of 5,000 chars each = 50,000 chars per message → expensive.
3. Relevance: the LLM has to find relevant sections in a large context window, which reduces answer quality.
Solution: implement chunked RAG — split each document into 300-500 token chunks, embed them with a text embedding model, store vectors in Firestore or a vector DB, and at query time retrieve only the top 3-5 most relevant chunks.

**Q: Why is calling FirebaseService() directly in QuizScreenNew an architectural problem?**
A: It bypasses the provider layer. If you later want to mock FirebaseService in tests, or change how quiz results are recorded, you'd need to change the screen code rather than just the provider. The correct approach is `context.read<GamificationProvider>().recordQuizResult(score, total)` — keeping all business logic in the provider and all external service calls in the service layer.

---

## 5. Weak Areas to Study

### Must Know Before Interview
1. **How Firestore security rules work** — the app assumes rules are set correctly but they aren't in the codebase
2. **The full SSE streaming flow** — line by line, what "data: [DONE]" means, why you buffer chunks
3. **How FieldValue.increment() prevents race conditions** — know the read-modify-write problem
4. **Why IndexedStack preserves state** vs Navigator.push()
5. **The rolling average formula** in recordQuizResult()

### Most Likely Interview Topics
1. State management pattern (Provider + ChangeNotifier + notifyListeners)
2. Firebase Auth flow (authStateChanges stream, token persistence)
3. Firestore data model (why denormalized scores collection)
4. Streaming chat implementation
5. PDF extraction in isolate via compute()

### Technical Weaknesses in Current Code
1. **QuizScreenNew calls FirebaseService directly** — should go through GamificationProvider
2. **API key in .env bundled in app** — extractable via reverse engineering
3. **All documents sent as chat context** — hits token limits, expensive, degrades quality at scale
4. **_syncScores() failure is silently ignored** — scores collection can drift out of sync
5. **No retry logic on Firestore writes** — a failed save is lost
6. **IndexedStack initializes all screens on first launch** — causes unnecessary data fetches

### Potential Bugs
1. **Streak calculation**: uses `DateTime.now()` locally — if user changes device timezone, streak could be miscounted
2. **Chat context**: if a document's rawText contains `===` the title separator pattern breaks the context string
3. **Flashcard flip reset**: didUpdateWidget checks `old.card.id != widget.card.id` but FlashcardModel.fromMap() always generates empty id — this check may never be true, causing cards not to reset when swiping
4. **isLoading not reset on error in generateQuiz**: `_setLoading(false)` is in finally block — should be fine, but check error path

### What to Improve Before an Interview
1. Read the Firestore Security Rules documentation
2. Understand Flutter's rendering pipeline (build → layout → paint)
3. Know the difference between StatefulWidget lifecycle methods (initState, didChangeDependencies, didUpdateWidget, dispose)
4. Be able to draw the auth flow from cold start to MainShell on a whiteboard
5. Understand what happens if Firebase.initializeApp() is called twice
