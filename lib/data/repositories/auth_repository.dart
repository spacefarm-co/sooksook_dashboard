import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(FirebaseAuth.instance, GoogleSignIn()));

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._auth, this._googleSignIn);

  Stream<User?> get authStateChange => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Google 로그인 팝업 호출 (구글 계정 선택)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 2. [핵심] Firebase에 넘기기 전에 이메일 도메인 검사
      if (!googleUser.email.endsWith('@spacefarm.co.kr')) {
        // 도메인이 다르면 구글 로그인 세션도 바로 끊고 종료 (Firebase 회원가입 안 됨)
        await _googleSignIn.disconnect();
        throw FirebaseAuthException(code: 'restricted-domain', message: 'spacefarm.co.kr 계정만 회원가입 및 로그인이 가능합니다.');
      }

      // 3. 도메인이 통과된 경우에만 Firebase 자격 증명 생성 및 로그인 실행
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 이 시점에 Firebase User가 생성되거나 로그인됩니다.
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
