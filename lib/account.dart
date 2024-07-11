/// atonement - account
/// Created by xhz on 7/10/24
library;

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'log.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
  'email',
  // 'https://www.googleapis.com/auth/cloud-platform',
]);

final Rx<LocalAccount> currentUser = LocalAccount.empty.obs;

bool get hasAccount => currentUser.value != LocalAccount.empty;

String get displayName => currentUser.value.displayName;

void initAccount() async {
  FirebaseAuth.instance.authStateChanges().listen(_handleLocalAccount);

  _googleSignIn.onCurrentUserChanged.listen(_handleGoogleAccount);
}

class LocalAccount {
  final String displayName;
  final String email;
  final String photoUrl;
  final String phoneNumber;
  final String id;
  final List<UserInfo> providers;

  static const LocalAccount empty = LocalAccount(
    displayName: 'Unknown',
    email: 'Unknown',
    photoUrl: '',
    id: 'Unknown',
    phoneNumber: 'Unknown',
    providers: [],
  );

  const LocalAccount({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.phoneNumber,
    required this.id,
    required this.providers,
  });
}

Future<void> handleSignOut() async {
  try {
    await FirebaseAuth.instance.signOut();
  } catch (error) {
    fireLogE(error.toString());
    SmartDialog.showToast(error.toString());
  }
}

Future<void> handleNoWebGoogleSignIn() async {
  try {
    await _googleSignIn.signIn();
  } catch (error) {
    fireLogE(error.toString());
    SmartDialog.showToast(error.toString());
  }
}

void _handleGoogleAccount(GoogleSignInAccount? account) async {
  fireLogI('Google account changed: $account');
  if (account == null) return;
  try {
    final GoogleSignInAuthentication signInAuthentication = await account.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: signInAuthentication.accessToken,
      idToken: signInAuthentication.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }
}

void _handleLocalAccount(User? user) {
  if (user == null) {
    if (currentUser.value == LocalAccount.empty) {
      fireLogI('User not signed in, trying to sign in silently...');
      _googleSignIn.signInSilently(reAuthenticate: true);
    } else {
      fireLogI('User $displayName signed out');
      currentUser.value = LocalAccount.empty;
    }
    return;
  }
  currentUser.value = LocalAccount(
    displayName: user.displayName ?? 'Unknown',
    email: user.email ?? 'Unknown',
    photoUrl: user.photoURL ?? '',
    id: user.uid,
    phoneNumber: user.phoneNumber ?? 'Unknown',
    providers: user.providerData,
  );
  fireLogI('User signed in $displayName, email ${currentUser.value.email}');
}
