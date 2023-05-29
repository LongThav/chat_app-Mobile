import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project/constants/firestore_constan.dart';
import 'package:project/internate_loading/loadingstatus.dart';
import 'package:project/model/chatuser_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLogic extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences sharedPreferences;

  Loadingstatus  _loadingstatus = Loadingstatus.uninitialized;
  Loadingstatus get loadingstatus => _loadingstatus;

  AuthLogic(
      {required this.googleSignIn,
      required this.firebaseAuth,
      required this.firebaseFirestore,
      required this.sharedPreferences});

  String? getFirebaseUserId() {
    return sharedPreferences.getString(FirestoreConstants.id);
  }

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn &&
        sharedPreferences.getString(FirestoreConstants.id)?.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleGoogleSignIn() async {
    _loadingstatus = Loadingstatus.authenticating;
    notifyListeners();

    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? firebaseUser =
          (await firebaseAuth.signInWithCredential(credential)).user;

      if (firebaseUser != null) {
        final QuerySnapshot result = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
            .get();
        final List<DocumentSnapshot> document = result.docs;
        if (document.isEmpty) {
          firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(firebaseUser.uid)
              .set({
            FirestoreConstants.displayName: firebaseUser.displayName,
            FirestoreConstants.photoUrl: firebaseUser.photoURL,
            FirestoreConstants.id: firebaseUser.uid,
            "createdAt: ": DateTime.now().millisecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null
          });

          User? currentUser = firebaseUser;
          await sharedPreferences.setString(FirestoreConstants.id, currentUser.uid);
          await sharedPreferences.setString(
              FirestoreConstants.displayName, currentUser.displayName ?? "");
          await sharedPreferences.setString(
              FirestoreConstants.photoUrl, currentUser.photoURL ?? "");
          await sharedPreferences.setString(
              FirestoreConstants.phoneNumber, currentUser.phoneNumber ?? "");
        } else {
          DocumentSnapshot documentSnapshot = document[0];
          ChatUser userChat = ChatUser.fromDocument(documentSnapshot);
          await sharedPreferences.setString(FirestoreConstants.id, userChat.id);
          await sharedPreferences.setString(
              FirestoreConstants.displayName, userChat.displayName);
          await sharedPreferences.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
          await sharedPreferences.setString(
              FirestoreConstants.phoneNumber, userChat.phoneNumber);
        }
        _loadingstatus = Loadingstatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _loadingstatus = Loadingstatus.authenticateError;
        notifyListeners();
        return false;
      }
    } else {
      _loadingstatus = Loadingstatus.authenticateCanceled;
      notifyListeners();
      return false;
    }
  }

  Future<void> googleSignOut() async {
    _loadingstatus = Loadingstatus.uninitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
