/// Route paths used with `go_router`.
abstract final class AppRoutes {
  static const String splash = '/splash';

  // Auth
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';

  /// The only route a signed-in user with an unverified email can reach.
  static const String verifyEmail = '/verify-email';

  // Student
  static const String home = '/home';
  static const String reports = '/reports';
  static const String campusReports = '/campus';
  static const String profile = '/profile';
  static const String reportIncident = '/report';

  // Staff
  static const String staffDashboard = '/staff';
  static const String staffProfile = '/staff/profile';

  // Shared by both roles
  static const String incidentDetailsPattern = '/incident/:id';
  static String incidentDetails(String id) => '/incident/$id';
  static String editIncident(String id) => '/incident/$id/edit';

  static const Set<String> authRoutes = {login, signUp, forgotPassword};
  static const Set<String> studentOnlyRoutes = {
    home,
    reports,
    campusReports,
    profile,
    reportIncident,
  };

  static bool isStaffRoute(String location) =>
      location == staffDashboard || location.startsWith('$staffDashboard/');
}
