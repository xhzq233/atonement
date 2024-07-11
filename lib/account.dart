/// atonement - account
/// Created by xhz on 7/10/24
library;

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'log.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

late final Box<String> _userBox;

final Rx<LocalAccount> currentUser = LocalAccount.empty.obs;

bool get hasAccount => currentUser.value.id != LocalAccount.empty.id;

String get displayName => currentUser.value.displayName;

void initAccount() async {
  _userBox = await Hive.openBox<String>('user');
  _signInGoogle();
}

class LocalAccount {
  final String displayName;
  final String email;
  final String photoUrl;
  final String id;
  String? idToken;

  static final LocalAccount empty = LocalAccount(
    displayName: 'Unknown',
    email: 'Unknown',
    photoUrl: '',
    id: 'Unknown',
  );

  LocalAccount({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.id,
    this.idToken,
  });
}

void _signInGoogle() async {
  final signedIn = await _googleSignIn.isSignedIn();

  _googleSignIn.onCurrentUserChanged.listen(_handleGoogleAccount);
  if (_googleSignIn.currentUser != null && signedIn) {
    _handleGoogleAccount(_googleSignIn.currentUser);
  } else {
    final localUser = _userBox.containsKey('displayName');
    if (localUser) {
      _handleLocalAccount();
    } else {
      _googleSignIn.signInSilently(reAuthenticate: true);
    }
  }
}

Future<void> handleSignOut() async {
  fireLogI('User $displayName signed out');
  _userBox.clear();
  currentUser.value = LocalAccount.empty;
  try {
    await _googleSignIn.signOut();
  } catch (error) {
    fireLogE(error.toString());
    SmartDialog.showToast(error.toString());
  }
}

Future<void> handleNoWebSignIn() async {
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
  String? idToken;
  try {
    final GoogleSignInAuthentication signInAuthentication = await account.authentication;
    idToken = signInAuthentication.idToken;
  } catch (e) {
    fireLogE(e.toString());
    SmartDialog.showToast(e.toString());
  }
  _userBox.put('displayName', account.displayName ?? 'Unknown');
  _userBox.put('email', account.email);
  _userBox.put('photoUrl', account.photoUrl ?? '');
  _userBox.put('id', account.id);
  if (idToken != null) _userBox.put('idToken', idToken);
  _handleLocalAccount();
}

void _handleLocalAccount() {
  currentUser.value = LocalAccount(
    displayName: _userBox.get('displayName') ?? 'Unknown',
    email: _userBox.get('email') ?? 'Unknown',
    photoUrl: _userBox.get('photoUrl') ?? '',
    id: _userBox.get('id') ?? 'Unknown',
    idToken: _userBox.get('idToken'),
  );
  fireLogI('User signed in $displayName, email ${currentUser.value.email}');
}
