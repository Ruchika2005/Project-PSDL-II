import 'package:flutter/material.dart';
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
      }
      // Navigation is handled by auth state changes
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  Future<void> login(String email, String password, BuildContext context) async {
    state = true;
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      // Navigation is handled by auth state changes
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  void logOut() {
    _authRepository.signOut();
  }
}

