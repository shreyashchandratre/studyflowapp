// Legacy chat service — kept as stub so old imports compile.
// All actual chat now goes through ChatProvider → CerebrasService.

class ChatService {
  Future<List<dynamic>> getSessions() async => [];
  Future<List<dynamic>> getHistory(String sessionId) async => [];
  Future<void> deleteSession(String sessionId) async {}
}
