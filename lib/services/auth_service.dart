import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;
  // Connexion
  Future<String> loginUser({required String email, required String password}) async {
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        return "success";
      } else {
        return "Veuillez remplir tous les champs";
      }
    } catch (e) {
      return e.toString();
    }
  }
  // Inscription
  Future<String> signUpUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? bio,
    String? specialty,
    required String role,
  }) async { String res = "Une erreur s'est produite";
    try { if (email.isNotEmpty && password.isNotEmpty && fullName.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,);
        String uid = cred.user!.uid;
        UserModel baseUser = UserModel(uid: uid, email: email, fullName: fullName,
          phoneNumber: phoneNumber,
          role: role,
        );await _firestore.collection('users').doc(uid).set(baseUser.toMap());
        if (role == 'doctor') {
          DoctorModel doctorProfile = DoctorModel(
            uid: uid,
            fullName: fullName,
            specialty: specialty ?? 'Non spécifié',
            clinicName: 'Non spécifié',
            address: '',
            price: 0,
            bio: bio ?? 'Diplômes non renseignés',
          );
          await _firestore.collection('doctors').doc(uid).set(doctorProfile.toMap());
        }
        res = "success";
      } else {
        res = "Veuillez remplir tous les champs";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }
}