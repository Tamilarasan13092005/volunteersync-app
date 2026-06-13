import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

// ── Demo credentials (always work, no Supabase account needed) ────────────
const _demoEmail = 'alex@volunteersync.io';
const _demoPassword = 'password123';

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  AppUser? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  final _supabase = Supabase.instance.client;

  AuthProvider() {
    _initAuthListener();
    _restoreSession();
  }

  // ── Restore existing Supabase session on app start ─────────────────────
  void _restoreSession() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _user = _buildUser(session.user);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    // No notifyListeners() here — called before widget tree builds
  }

  // ── Listen for Supabase auth state changes (token refresh, signout) ────
  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        _user = _buildUser(session!.user);
        _status = AuthStatus.authenticated;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed &&
          session?.user != null) {
        _user = _buildUser(session!.user);
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    });
  }

  AppUser _buildUser(User supaUser) {
    return AppUser(
      id: supaUser.id,
      name: supaUser.userMetadata?['full_name'] as String? ??
          supaUser.email?.split('@')[0] ??
          'User',
      email: supaUser.email ?? '',
      role: supaUser.userMetadata?['role'] as String? ?? 'admin',
      organization:
          supaUser.userMetadata?['organization'] as String? ?? 'VolunteerSync',
      createdAt: DateTime.tryParse(supaUser.createdAt) ?? DateTime.now(),
      isVerified: supaUser.emailConfirmedAt != null,
    );
  }

  // ── Sign In ─────────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // ── Demo login — always succeeds without Supabase account ────────────
    if (email.trim().toLowerCase() == _demoEmail &&
        password == _demoPassword) {
      _user = AppUser(
        id: 'demo-user-001',
        name: 'Alex Demo',
        email: _demoEmail,
        role: 'Admin',
        organization: 'VolunteerSync',
        createdAt: DateTime(2024, 1, 15),
        isVerified: true,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    // ── Real Supabase login ───────────────────────────────────────────────
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        _user = _buildUser(response.user!);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Invalid email or password.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Register ────────────────────────────────────────────────────────────
  Future<bool> register(
      String name, String email, String password, String org) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name, 'organization': org, 'role': 'admin'},
      );

      if (response.user != null) {
        try {
          await _supabase.from('profiles').insert({
            'id': response.user!.id,
            'full_name': name,
            'email': email.trim(),
            'role': 'admin',
            'organization': org,
          });
        } catch (_) {
          // profiles table may not exist or already has row — ignore
        }

        _user = AppUser(
          id: response.user!.id,
          name: name,
          email: email.trim(),
          role: 'admin',
          organization: org,
          createdAt: DateTime.now(),
          isVerified: false,
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed. Please try again.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Forgot Password ─────────────────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
