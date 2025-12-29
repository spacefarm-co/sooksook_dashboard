import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(FirebaseAuth.instance, GoogleSignIn()));

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._auth, this._googleSignIn);

  // 현재 유저 상태 확인 스트림
  Stream<User?> get authStateChange => _auth.authStateChanges();

  // Google 로그인 실행
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // 사용자가 취소한 경우

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
