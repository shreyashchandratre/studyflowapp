// Legacy auth service — kept as stub so old imports compile.
// All auth now goes through AuthProvider → Firebase Auth.

class AuthService {
  Future<Map<String, dynamic>> register(
      String name, String email, String password) async =>
      throw Exception('Use Firebase Auth via AuthProvider.');

  Future<Map<String, dynamic>> login(String email, String password) async =>
      throw Exception('Use Firebase Auth via AuthProvider.');
}
