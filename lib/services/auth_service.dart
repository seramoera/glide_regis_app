import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:org_registration_app/models/orgs.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  //  Stream for auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  ///  Check if the user already has registration data
  Future<bool> hasUserRegistration(String uid) async {
    try {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;
      return data["hasRegistered"] ==
          true; // 🔹 consistent with RegistrationScreen
    } catch (e) {
      debugPrint("Error checking registration: $e");
      return false;
    }
  }

  ///  Save registration details to Firestore
  Future<void> saveUserRegistration(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection("users")
          .doc(uid)
          .set(data, SetOptions(merge: true));
      // merge:true ensures we don’t overwrite auth info if already exists
    } catch (e) {
      debugPrint("Error saving registration: $e");
      rethrow;
    }
  }

  /// Sign up with email & password
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      // create a Firestore user doc right away with just email
      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "email": email,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Signup failed: ${e.code} - ${e.message}");
    } catch (e) {
      throw Exception("Signup failed: $e");
    }
  }

  /// Login with email & password
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Unknown error during login");
    }
  }

  Future<void> registerToOrg(String uid, Org org) async {
    try {
      await _firestore.collection("users").doc(uid).set({
        "registeredOrgs": FieldValue.arrayUnion([
          {
            "id": org.id,
            "name": org.name,
            "imageUrl": org.imageUrl,
            "category": org.category,
            "status": org.status,
            "fee": org.fee,
          }
        ])
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error registering org: $e");
      rethrow;
    }
  }

  Future<void> unregisterFromOrg(String uid, Org org) async {
    try {
      await _firestore.collection("users").doc(uid).update({
        "registeredOrgs": FieldValue.arrayRemove([
          {
            "id": org.id,
            "name": org.name,
            "imageUrl": org.imageUrl,
            "category": org.category,
            "status": org.status,
            "fee": org.fee,
          }
        ])
      });
    } catch (e) {
      debugPrint("Error unregistering org: $e");
      rethrow;
    }
  }

  Future<List<Org>> getUserRegisteredOrgs(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();
    if (!doc.exists) return [];
    final data = doc.data()!;
    if (data["registeredOrgs"] == null) return [];
    return (data["registeredOrgs"] as List)
        .map((orgData) => Org(
              id: orgData["id"],
              name: orgData["name"],
              description: orgData["description"] ?? "",
              fee: orgData["fee"],
              status: orgData["status"],
              imageUrl: orgData["imageUrl"],
              category: orgData["category"],
            ))
        .toList();
  }

  /// Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    notifyListeners();
  }

  Future<void> deleteUser(String uid) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection("users").doc(uid).delete();
      debugPrint("User $uid deleted from Firestore.");
    } catch (e) {
      debugPrint("Error deleting user from Firestore: $e");
      rethrow;
    }
  }

  /// Get user registration data
  Future<Map<String, dynamic>?> getUserRegistration(String uid) async {
    try {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return doc.data();
    } catch (e) {
      debugPrint("Error fetching user registration: $e");
      return null;
    }
  }
}
