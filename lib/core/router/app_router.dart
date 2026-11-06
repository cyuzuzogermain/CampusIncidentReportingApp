import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/incident_repository.dart';
import '../../logic/cubits/auth/auth_cubit.dart';
import '../../logic/cubits/incident_list/all_incidents_cubit.dart';
import '../../logic/cubits/incident_list/my_incidents_cubit.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/sign_up_screen.dart';
import '../../presentation/screens/incident/incident_details_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/report/edit_incident_screen.dart';
import '../../presentation/screens/report/report_incident_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/staff/staff_dashboard_screen.dart';
import '../../presentation/screens/staff/staff_shell.dart';
import '../../presentation/screens/student/campus_reports_screen.dart';
import '../../presentation/screens/student/home_screen.dart';
import '../../presentation/screens/student/my_reports_screen.dart';
import '../../presentation/screens/student/student_shell.dart';
import 'app_routes.dart';
import 'router_redirect.dart';

/// Builds the app's [GoRouter]. Redirects re-run whenever [AuthCubit] emits.
GoRouter createRouter(AuthCubit authCubit) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _StreamListenable(authCubit.stream),
    redirect: (context, state) =>
        resolveRedirect(authCubit.state, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Student shell: Home, My Reports, Campus Reports, Profile, plus a
      // center "+" button.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => MyIncidentsCubit(
                context.read<IncidentRepository>(),
                uid: authCubit.state.user?.uid ?? '',
              )..start(),
            ),
            // Created the first time the Campus tab is opened.
            BlocProvider(
              create: (context) =>
                  AllIncidentsCubit(context.read<IncidentRepository>())
                    ..start(),
            ),
          ],
          child: StudentShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, state) => const MyReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.campusReports,
                builder: (context, state) => const CampusReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Pushed above the student shell.
      GoRoute(
        path: AppRoutes.reportIncident,
        builder: (context, state) => const ReportIncidentScreen(),
      ),

      // Staff shell: Dashboard and Profile.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BlocProvider(
          create: (context) =>
              AllIncidentsCubit(context.read<IncidentRepository>())..start(),
          child: StaffShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staffDashboard,
                builder: (context, state) => const StaffDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staffProfile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Shared by both roles. Students can open anyone's report, read-only
      // unless they filed it; the Firestore rules enforce who may change
      // what.
      GoRoute(
        path: AppRoutes.incidentDetailsPattern,
        // Keyed by id so going from one report straight to another (for
        // example by changing the URL on the web) rebuilds the screen and its
        // cubits instead of reusing the previous report's.
        builder: (context, state) => IncidentDetailsScreen(
          key: ValueKey('details-${state.pathParameters['id']}'),
          incidentId: state.pathParameters['id']!,
        ),
        routes: [
          // The reporter's edit form, while the report is still Submitted.
          GoRoute(
            path: 'edit',
            builder: (context, state) => EditIncidentScreen(
              key: ValueKey('edit-${state.pathParameters['id']}'),
              incidentId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Adapts a stream into a [Listenable] for `refreshListenable`.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
