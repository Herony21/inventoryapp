// lib/auth/auth_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ===============================
///  MODELO LIGERO DE USUARIO
/// ===============================
@immutable
class AppUser {
  final String id;
  final String email;
  final String displayName;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  /// Crea AppUser a partir del User de Supabase.
  factory AppUser.fromSupabase(User u) {
    // Primero intenta metadata['name'], luego user.userMetadata?['full_name'],
    // y si no hay, usa la parte local del email como fallback.
    final meta = u.userMetadata ?? const {};
    final name = (meta['name'] as String?) ??
        (meta['full_name'] as String?) ??
        u.email?.split('@').first ??
        'usuario';
    return AppUser(
      id: u.id,
      email: u.email ?? '',
      displayName: name,
    );
  }
}

/// ===============================
///  PROVEEDORES DE AUTENTICACIÓN
/// ===============================

/// Stream de la sesión actual (null cuando no hay sesión).
/// ÚSALO para redirección automática con GoRouter (refreshListenable/redirect).
final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = Supabase.instance.client;
  // Mapeamos solo la sesión de los cambios auth.
  return client.auth.onAuthStateChange.map((event) => event.session);
});

/// `User?` actual (más directo que leer Session.user).
final currentUserProvider = Provider<User?>((ref) {
  final client = Supabase.instance.client;
  return client.auth.currentUser;
});

/// `AppUser?` derivado del User actual, con displayName "bonito".
final appUserProvider = Provider<AppUser?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return AppUser.fromSupabase(user);
});

/// Acciones de autenticación (login, registro, logout, etc.)
final authActionsProvider = Provider((ref) => AuthActions._());

/// ===============================
///  ACCIONES DE AUTENTICACIÓN
/// ===============================
class AuthActions {
  AuthActions._();

  final _auth = Supabase.instance.client.auth;

  /// Iniciar sesión con email/contraseña.
  Future<void> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Completa tu correo y contraseña.');
      }
      await _auth.signInWithPassword(email: email, password: password);
      // ❌ No navegues manualmente: el router redirige con authSessionProvider.
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo iniciar sesión. $e');
    }
  }

  /// Registrarse con email/contraseña.
  /// Si quiere forzar login automático tras signup, puedes hacer signIn luego.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Completa correo y contraseña.');
      }

      final resp = await _auth.signUp(
        email: email,
        password: password,
        data: displayName == null || displayName.trim().isEmpty
            ? null
            : {'name': displayName.trim()},
      );

      // Dependiendo de tu configuración de Supabase, es posible que requiera
      // confirmar email. Puedes decidir si haces login directo aquí o dejas
      // que el usuario confirme por correo:
      // if (resp.user != null) { await signIn(email, password); }

      if (resp.user == null) {
        // Si hay email confirmation, este caso es normal.
        // Puedes notificar al usuario que revise su correo.
        return;
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo registrar. $e');
    }
  }

  /// Cerrar sesión.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // ❌ No navegues manualmente: el router te llevará a /auth.
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo cerrar sesión. $e');
    }
  }

  /// Enviar correo para restablecer contraseña.
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) throw Exception('Ingresa tu correo.');
      // Si necesitas ruta de deep link, pásala en emailRedirectTo.
      await _auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo enviar el correo de restablecimiento. $e');
    }
  }

  /// Actualiza displayName del usuario en userMetadata.
  Future<void> updateDisplayName(String name) async {
    try {
      final trimmed = name.trim();
      if (trimmed.isEmpty) throw Exception('El nombre no puede estar vacío.');
      await _auth.updateUser(
        UserAttributes(data: {'name': trimmed}),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('No se pudo actualizar el perfil. $e');
    }
  }
}
