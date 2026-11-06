import 'package:campus_incident_app/core/router/app_routes.dart';
import 'package:campus_incident_app/core/router/router_redirect.dart';
import 'package:campus_incident_app/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('resolveRedirect', () {
    test('unknown session waits on the splash screen', () {
      const auth = AuthState.unknown();
      expect(resolveRedirect(auth, AppRoutes.home), AppRoutes.splash);
      expect(resolveRedirect(auth, AppRoutes.splash), isNull);
      // A sign-in in progress stays on its screen.
      expect(resolveRedirect(auth, AppRoutes.login), isNull);
    });

    test('signed-out users are sent to login', () {
      const auth = AuthState.unauthenticated();
      expect(resolveRedirect(auth, AppRoutes.home), AppRoutes.login);
      expect(resolveRedirect(auth, AppRoutes.staffDashboard), AppRoutes.login);
      expect(resolveRedirect(auth, AppRoutes.signUp), isNull);
      expect(resolveRedirect(auth, AppRoutes.forgotPassword), isNull);
    });

    test('students go to the student shell and never reach staff routes', () {
      final auth = AuthState.authenticated(testStudent);
      expect(resolveRedirect(auth, AppRoutes.login), AppRoutes.home);
      expect(resolveRedirect(auth, AppRoutes.splash), AppRoutes.home);
      expect(resolveRedirect(auth, AppRoutes.staffDashboard), AppRoutes.home);
      expect(resolveRedirect(auth, AppRoutes.staffProfile), AppRoutes.home);
      expect(resolveRedirect(auth, AppRoutes.reports), isNull);
      expect(resolveRedirect(auth, AppRoutes.campusReports), isNull);
      expect(resolveRedirect(auth, AppRoutes.incidentDetails('x')), isNull);
      expect(resolveRedirect(auth, AppRoutes.editIncident('x')), isNull);
    });

    test('staff go to the staff shell', () {
      final auth = AuthState.authenticated(testStaff);
      expect(resolveRedirect(auth, AppRoutes.login), AppRoutes.staffDashboard);
      expect(resolveRedirect(auth, AppRoutes.home), AppRoutes.staffDashboard);
      expect(
        resolveRedirect(auth, AppRoutes.reportIncident),
        AppRoutes.staffDashboard,
      );
      expect(
        resolveRedirect(auth, AppRoutes.campusReports),
        AppRoutes.staffDashboard,
      );
      expect(resolveRedirect(auth, AppRoutes.staffDashboard), isNull);
      expect(resolveRedirect(auth, AppRoutes.incidentDetails('x')), isNull);
    });
  });
}
