import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../repository/group_repository.dart';
import '../../../models/group_model.dart';
import '../../../models/user_model.dart';
import '../../auth/repository/user_repository.dart';
import '../../auth/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

final groupControllerProvider = NotifierProvider<GroupController, bool>(GroupController.new);

final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final authState = ref.watch(authStateChangeProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(groupRepositoryProvider).getUserGroups(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final groupStreamProvider = StreamProvider.family<GroupModel, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroup(groupId);
});

final currentUserProvider = FutureProvider((ref) {
  final authState = ref.watch(authStateChangeProvider);
  return authState.when(
    data: (user) {
      if (user == null) return null;
      return ref.watch(userRepositoryProvider).getUser(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

class GroupController extends Notifier<bool> {
  late GroupRepository _groupRepository;

  @override
  bool build() {
    _groupRepository = ref.watch(groupRepositoryProvider);
    return false; // Loading state
  }

  Future<void> createGroup(String name, List<String> memberNames, BuildContext context) async {
    state = true;
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Ensure creator is in the members list
      final userProfile = await ref.read(userRepositoryProvider).getUser(currentUser.uid);
      String creatorName = userProfile?.name ?? 'Me';
      
      List<String> finalMembers = [creatorName];
      for (var m in memberNames) {
        if (m.trim().isNotEmpty && !finalMembers.contains(m.trim())) {
          finalMembers.add(m.trim());
        }
      }

      final groupId = const Uuid().v4();
      final group = GroupModel(
        id: groupId,
        name: name,
        members: finalMembers,
        createdBy: currentUser.uid,
      );

      await _groupRepository.createGroup(group);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  Future<void> addMember(String groupId, String name, BuildContext context) async {
    state = true;
    try {
      await _groupRepository.addMemberToGroup(groupId, name.trim());
      
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }
}
