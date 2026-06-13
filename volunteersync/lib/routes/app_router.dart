import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../features/auth/screens/landing_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/volunteers/screens/volunteers_screen.dart';
import '../features/events/screens/events_screen.dart';
import '../features/attendance/screens/attendance_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/ai_chat/screens/ai_chat_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../widgets/common/main_shell.dart';

class AppRouter {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String volunteers = '/volunteers';
  static const String events = '/events';
  static const String attendance = '/attendance';
  static const String reports = '/reports';
  static const String aiChat = '/ai-chat';
  static const String settings = '/settings';

  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: landing,
      redirect: (ctx, state) {
        final auth = ctx.read<AuthProvider>();

        // While session is being restored, don't redirect yet
        if (auth.status == AuthStatus.initial) return null;

        final isAuth = auth.isAuthenticated;
        final isAuthRoute = state.matchedLocation == landing ||
            state.matchedLocation == login ||
            state.matchedLocation == register ||
            state.matchedLocation == forgotPassword;

        if (!isAuth && !isAuthRoute) return login;
        if (isAuth && isAuthRoute) return dashboard;
        return null;
      },
      routes: [
        GoRoute(path: landing, builder: (_, __) => const LandingScreen()),
        GoRoute(path: login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: register, builder: (_, __) => const RegisterScreen()),
        GoRoute(
            path: forgotPassword,
            builder: (_, __) => const ForgotPasswordScreen()),
        ShellRoute(
          builder: (ctx, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
                path: dashboard,
                builder: (_, __) => const DashboardScreen()),
            GoRoute(
                path: volunteers,
                builder: (_, __) => const VolunteersScreen()),
            GoRoute(
                path: events, builder: (_, __) => const EventsScreen()),
            GoRoute(
                path: attendance,
                builder: (_, __) => const AttendanceScreen()),
            GoRoute(
                path: reports, builder: (_, __) => const ReportsScreen()),
            GoRoute(
                path: aiChat, builder: (_, __) => const AiChatScreen()),
            GoRoute(
                path: settings,
                builder: (_, __) => const SettingsScreen()),
          ],
        ),
      ],
    );
  }
}
