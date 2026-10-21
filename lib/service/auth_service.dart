import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  Stream<User?> get authState => _auth.authStateChanges();
  Stream<DocumentSnapshot<Map<String, dynamic>>> userBanStatusStream(
    String uid,
  ) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        return "Email belum diverifikasi. Silakan cek email Anda.";
      }

      // 🔒 Cek apakah user diblokir
      final isBanned = await _isUserBanned(userCredential.user!.uid);
      if (isBanned) {
        await _auth.signOut();
        return "Akun Anda telah diblokir oleh admin.";
      }

      await _createOrUpdateUser(userCredential.user!);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  Future<String?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.sendEmailVerification();
      await _createOrUpdateUser(userCredential.user!);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        final isBanned = await _isUserBanned(user.uid);
        if (isBanned) {
          await signOut();
          throw FirebaseAuthException(
            code: "user-disabled",
            message: "Akun Anda telah diblokir oleh admin.",
          );
        }

        await _createOrUpdateUser(user);
      }

      return user;
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<void> _createOrUpdateUser(User user) async {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final docSnapshot = await userDoc.get();

    final googleName = user.displayName?.trim() ?? '';
    final emailName = user.email != null && user.email!.contains('@')
        ? user.email!.split('@')[0].trim()
        : '';
    final resolvedName = googleName.isNotEmpty
        ? googleName
        : (emailName.isNotEmpty ? emailName : 'User${user.uid.substring(0, 5)}');
    final googlePhoto = user.photoURL?.trim() ?? '';

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'username': resolvedName.toLowerCase().replaceAll(' ', '_'),
        'displayName': resolvedName,
        'photoUrl': googlePhoto,
        'role': 'user',
        'isBanned': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      final existingData = docSnapshot.data() ?? {};
      final Map<String, dynamic> updates = {
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Sinkronkan foto Google asli jika di Firestore masih kosong atau placeholder
      final currentPhoto = (existingData['photoUrl'] as String?)?.trim() ?? '';
      if (googlePhoto.isNotEmpty &&
          (currentPhoto.isEmpty ||
              currentPhoto.contains('dicebear.com') ||
              currentPhoto.contains('default_profile'))) {
        updates['photoUrl'] = googlePhoto;
      }

      // Sinkronkan nama Google asli jika di Firestore masih default 'Pengguna Nimexx'
      final currentName = (existingData['displayName'] as String?)?.trim() ?? '';
      if (googleName.isNotEmpty &&
          (currentName.isEmpty ||
              currentName == 'Pengguna Nimexx' ||
              currentName.startsWith('User'))) {
        updates['displayName'] = googleName;
      }

      await userDoc.set(updates, SetOptions(merge: true));
    }
  }

  Future<String?> getUserRole(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'user';
  }

  // 🔒 Tambahan: Cek apakah user diblokir
  Future<bool> _isUserBanned(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['isBanned'] == true;
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "Format email salah.";
      case 'user-disabled':
        return "Akun ini dinonaktifkan.";
      case 'user-not-found':
        return "Pengguna tidak ditemukan.";
      case 'wrong-password':
        return "Password salah.";
      case 'email-already-in-use':
        return "Email sudah digunakan.";
      case 'weak-password':
        return "Password terlalu lemah.";
      default:
        return e.message ?? "Terjadi kesalahan autentikasi.";
    }
  }
}
