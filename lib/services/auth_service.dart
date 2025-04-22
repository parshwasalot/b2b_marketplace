import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:b2b_marketplace/models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _initializeUser();
  }

  void _initializeUser() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserData();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('users').doc(_user!.uid).get();

      if (doc.exists) {
        _userModel = UserModel.fromJson({'id': doc.id, ...doc.data()!});
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String name,
    String userType,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _fetchUserData();
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to create account'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during sign up';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use';
      } else if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('Error during sign up: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to login';

      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('Error during sign in: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email';

      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid';
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('Error sending password reset email: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
