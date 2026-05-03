// Re-export ChatMessage and ChatSession from chat_provider for backward compatibility.
// Old screens that import this file will get the same types as the new chat_provider.
export '../providers/chat_provider.dart' show ChatMessage, ChatSession;
