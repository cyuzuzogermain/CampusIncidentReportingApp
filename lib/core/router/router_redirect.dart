import '../../logic/cubits/auth/auth_cubit.dart';
import 'app_routes.dart';

/// Works out where a user may go, given their session and the requested
/// [location]. Returns the path to redirect to, or `null` to allow it.
///
/// This is a pure function so the role rules can be unit-tested without a
/// router.
String? resolveRedirect(AuthState auth, String location) {
  final onAuthRoute = AppRoutes.authRoutes.contains(location);
  final onSplash = location == AppRoutes.splash;

  switch (auth.status) {
    case AuthStatus.unknown:
      // Still loading the session or profile. Stay on an auth screen (so a
      // sign-in in progress keeps its spinner); otherwise wait on the splash.
      return onAuthRoute || onSplash ? null : AppRoutes.splash;

    case AuthStatus.unauthenticated:
      return onAuthRoute ? null : AppRoutes.login;

    case AuthStatus.authenticated:
      final home = auth.isStaff ? AppRoutes.staffDashboard : AppRoutes.home;
      if (onAuthRoute || onSplash) return home;

      // Students must never reach staff routes, and staff use their own shell.
      if (!auth.isStaff && AppRoutes.isStaffRoute(location)) return home;
      if (auth.isStaff && AppRoutes.studentOnlyRoutes.contains(location)) {
        return home;
      }
      return null;
  }
}
