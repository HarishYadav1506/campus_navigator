class SessionManager {
  SessionManager._();

  static String? email;
  static String? role; // 'student', 'prof', 'admin'

  static bool get isLoggedIn => email != null;

  static void setUser({
    required String newEmail,
    required String newRole,
  }) {
    email = newEmail;
    role = newRole;
  }

  static void clear() {
    email = null;
    role = null;
  }
}

