// Global state management
class GlobalState {
  static String userId = "";
  static String userName = "";
  static String userRole = ""; // student or teacher
  static String institution = "";

  static void clear() {
    userId = "";
    userName = "";
    userRole = "";
    institution = "";
  }
}
