import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 SIGN UP FUNCTION
  Future<String?> signUpUser({
    required String name,
    required String phone,
    required String location,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // ✅ Password match check
      if (password != confirmPassword) {
        return "Passwords do not match";
      }

      // ✅ Create user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = userCredential.user!.uid;

      // ✅ Store in Firestore (public collection)
      await _firestore.collection("public").doc(uid).set({
        "uid": uid,
        "name": name.trim(),
        "phone": phone.trim(),
        "location": location.trim(),
        "email": email.trim(),
        "createdAt": Timestamp.now(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "Email already in use";
      } else if (e.code == 'weak-password') {
        return "Password is too weak";
      } else if (e.code == 'invalid-email') {
        return "Invalid email format";
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}