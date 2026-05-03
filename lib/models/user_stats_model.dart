// Re-export UserModel as UserStats for backward compatibility.
// Old screens that import this will get the same type as the new providers.
export '../models/user_model.dart' show UserModel;

// Alias so `UserStats` still resolves in old code
typedef UserStats = UserModel;
