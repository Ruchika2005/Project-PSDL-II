import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/auth_repository.dart';
import '../repository/user_repository.dart';
import '../../../models/user_model.dart';

final authControllerProvider = NotifierProvider<AuthController, bool>(AuthController.new);

final authStateChangeProvider = StreamProvider((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.authStateChange;
});

class AuthController extends Notifier<bool> {
  late AuthRepository _authRepository;
  late UserRepository _userRepository;

  @override
  bool build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _userRepository = ref.watch(userRepositoryProvider);
    return false; // loading state
  }

  Stream get authStateChange => _authRepository.authStateChange;

  Future<void> signUp(String name, String email, String password, BuildContext context) async {
    state = true;
    try {
      final userCred = await _authRepository.signUpWithEmailAndPassword(email, password);
      if (userCred != null && userCred.user != null) {
        final userModel = UserModel(
          id: userCred.user!.uid,
          name: name,
          email: email,
        );
        await _userRepository.createUser(userModel);
        
        // Sign out immediately so they have to log in manually as requested
        await _authRepository.signOut();
        
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Account Created!'),
              content: const Text('Your account has been created successfully. Please login to continue.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to login screen
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String message = 'An error occurred';
        if (e.code == 'email-already-in-use') {
          message = 'This email is already registered. Please login instead.';
        } else if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        }
        _showErrorDialog(context, 'Signup Failed', message);
      }
    } catch (e) {
      if (context.mounted) _showErrorDialog(context, 'Error', e.toString());
    }
    state = false;
  }

  Future<void> login(String email, String password, BuildContext context) async {
    state = true;
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String message = 'Invalid email or password';
        if (e.code == 'user-not-found') {
          message = 'No user found with this email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password. Please try again.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is badly formatted.';
        }
        _showErrorDialog(context, 'Login Failed', message);
      }
    } catch (e) {
      if (context.mounted) _showErrorDialog(context, 'Error', e.toString());
    }
    state = false;
  }

  void signOut() {
    _authRepository.signOut();
  }

  void showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              signOut();
              // Clear the navigation stack to ensure we go back to AuthChecker's LoginScreen
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('LOGOUT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> syncUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _userRepository.getUser(user.uid);
      if (userData == null) {
        final userModel = UserModel(
          id: user.uid,
          name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          email: user.email ?? '',
        );
        await _userRepository.createUser(userModel);
      }
    }
  }
}

