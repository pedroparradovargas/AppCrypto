import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Servicio de autenticacion con Firebase Auth + Firestore
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Usuario actual de Firebase
  User? get currentUser => _auth.currentUser;

  /// Stream de cambios de autenticacion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registrar con email y password
  Future<UserProfile> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    final profile = UserProfile(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    // Guardar perfil en Firestore (con timeout para evitar cuelgues)
    try {
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(profile.toJson())
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error guardando perfil en Firestore: $e');
      // El usuario ya fue creado en Firebase Auth, continuar sin bloquear
    }

    return profile;
  }

  /// Iniciar sesion con email y password
  Future<UserProfile?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Actualizar ultimo login en Firestore (con timeout)
    try {
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .update({'lastLogin': DateTime.now().toIso8601String()})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error actualizando lastLogin en Firestore: $e');
    }

    try {
      return await getUserProfile(credential.user!.uid);
    } catch (e) {
      debugPrint('Error obteniendo perfil: $e');
      return null;
    }
  }

  /// Enviar email de recuperacion de contraseña
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Cerrar sesion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Obtener perfil de usuario desde Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!);
    }
    return null;
  }

  /// Actualizar registro de biometria en Firestore
  Future<void> updateBiometricRegistration(String uid, bool registered) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'biometricRegistered': registered});
  }

  /// Actualizar perfil de usuario
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}
