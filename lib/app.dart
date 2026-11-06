import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/incident_repository.dart';
import 'logic/cubits/auth/auth_cubit.dart';

/// The root widget. It provides the repositories and the session-wide
/// [AuthCubit], then hands navigation to `go_router`.
class CampusIncidentApp extends StatefulWidget {
  const CampusIncidentApp({
    super.key,
    required this.authRepository,
    required this.incidentRepository,
  });

  final AuthRepository authRepository;
  final IncidentRepository incidentRepository;

  @override
  State<CampusIncidentApp> createState() => _CampusIncidentAppState();
}

class _CampusIncidentAppState extends State<CampusIncidentApp> {
  // Created once for the app's lifetime; not rebuilt with setState.
  late final AuthCubit _authCubit = AuthCubit(widget.authRepository);
  late final GoRouter _router = createRouter(_authCubit);

  @override
  void dispose() {
    _router.dispose();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider.value(value: widget.incidentRepository),
      ],
      child: BlocProvider.value(
        value: _authCubit,
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
