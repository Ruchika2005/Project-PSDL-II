import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:split_expense/features/expenses/controller/expense_controller.dart';
import 'package:uuid/uuid.dart';
import '../repository/group_repository.dart';
import '../../../models/group_model.dart';
import '../../../models/user_model.dart';
import '../../auth/repository/user_repository.dart';
import '../../auth/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:split_expense/features/expenses/controller/expense_controller.dart';
import '../repository/invite_repository.dart';
import '../../../models/invite_model.dart';

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

final userInvitesProvider = StreamProvider<List<InviteModel>>((ref) {
  final authState = ref.watch(authStateChangeProvider);
  return authState.when(
    data: (user) {
      if (user == null || user.email == null) return Stream.value([]);
      return ref.watch(inviteRepositoryProvider).getInvitesForUser(user.email!);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final memberNamesProvider = FutureProvider.family<Map<String, String>, GroupModel>((ref, group) async {
  final userRepo = ref.watch(userRepositoryProvider);
  Map<String, String> nameMap = {};
  
  // Fetch names for all members (including creator)
  final futures = group.members.map((uid) => userRepo.getUser(uid));
  final users = await Future.wait(futures);
  
  for (int i = 0; i < group.members.length; i++) {
    final user = users[i];
    if (user != null) {
      nameMap[group.members[i]] = user.name;
    }
  }
  
  // Ensure creator is also handled if not in members list for some reason
  if (!nameMap.containsKey(group.createdBy)) {
    final creator = await userRepo.getUser(group.createdBy);
    if (creator != null) {
      nameMap[group.createdBy] = creator.name;
    }
  }
  
  return nameMap;
});

final groupInvitesProvider = StreamProvider.family<List<InviteModel>, String>((ref, groupId) {
  final inviteRepo = ref.watch(inviteRepositoryProvider);
  return inviteRepo.getInvitesForGroup(groupId);
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

      // Use UID for database integrity, UI will resolve names
      List<String> finalMembers = [currentUser.uid];
      // memberNames from the dialog are ignored for now as we use the invite system
      // but if you want to add people by name manually (without IDs), they can stay as names
      // My name resolver handles both IDs and Names.
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

  Future<void> inviteMember({
    required String groupId,
    required String groupName,
    required String inviteeEmail,
    required String inviteeName,
    required double moneyOwed,
    required BuildContext context,
  }) async {
    state = true;
    try {
      final inviteRepo = ref.read(inviteRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Not logged in');

      // 1. Check if user exists
      final targetUser = await inviteRepo.findUserByEmail(inviteeEmail);
      if (targetUser == null) {
        throw Exception('No user found with email: $inviteeEmail. They must sign up first.');
      }

      // 2. Check if already invited (pending)
      final existingInvites = await inviteRepo.getInvitesForGroup(groupId).first;
      final existingInvite = existingInvites.firstWhere(
        (i) => i.inviteeEmail.toLowerCase() == inviteeEmail.toLowerCase(),
        orElse: () => InviteModel(
          id: '', groupId: '', groupName: '', inviteeEmail: '', inviteeName: '', 
          moneyOwed: 0, creatorName: '', creatorId: '', status: InviteStatus.pending,
          code: '', createdAt: DateTime.now()
        ),
      );

      final creatorProfile = await userRepo.getUser(currentUser.uid);
      final creatorName = creatorProfile?.name ?? 'Group Admin';

      if (existingInvite.id.isNotEmpty) {
        // Update existing invite
        final updatedInvite = existingInvite.copyWith(
          moneyOwed: moneyOwed,
          inviteeName: inviteeName,
          creatorName: creatorName,
        );
        await inviteRepo.sendInvite(updatedInvite);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation amount updated!')));
        }
      } else {
        // Create new invite
        final inviteId = const Uuid().v4();
        final code = (100000 + Random().nextInt(900000)).toString();
        
        final invite = InviteModel(
          id: inviteId,
          groupId: groupId,
          groupName: groupName,
          creatorName: creatorName,
          creatorId: currentUser.uid,
          inviteeEmail: inviteeEmail.toLowerCase().trim(),
          inviteeName: inviteeName,
          code: code,
          moneyOwed: moneyOwed,
          createdAt: DateTime.now(),
          status: InviteStatus.pending,
        );
        await inviteRepo.sendInvite(invite);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Invitation Sent!'),
              content: Text('A request has been sent to $inviteeEmail. They can accept it from their Invites section.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  Future<void> respondToInvite(InviteModel invite, bool accept, BuildContext context) async {
    state = true;
    try {
      final inviteRepo = ref.read(inviteRepositoryProvider);
      
      if (accept) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw Exception('Not logged in');
        
        // Add member UID to group
        await _groupRepository.addMemberToGroup(invite.groupId, currentUser.uid);
        await inviteRepo.updateInviteStatus(invite.id, InviteStatus.accepted);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined group successfully!')));
        }
      } else {
        await inviteRepo.updateInviteStatus(invite.id, InviteStatus.rejected);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error responding to invite: $e')));
      }
    }
    state = false;
  }

  Future<void> markInviteAsPaid(InviteModel invite, BuildContext context) async {
    state = true;
    try {
      final inviteRepo = ref.read(inviteRepositoryProvider);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Not logged in');

      // 1. Update invite status
      await inviteRepo.updateInviteStatus(invite.id, InviteStatus.settled);

      // 2. Create actual settlement in expense records
      await ref.read(expenseControllerProvider.notifier).settleDebt(
            groupId: invite.groupId,
            from: currentUser.uid,
            to: invite.creatorId,
            amount: invite.moneyOwed,
            context: context,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment marked as DONE! Sender notified.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error marking as paid: $e')));
      }
    }
    state = false;
  }

  Future<void> deleteGroup(String groupId, BuildContext context) async {
    state = true;
    try {
      await _groupRepository.deleteGroup(groupId);
      if (context.mounted) {
        Navigator.pop(context); // Go back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group deleted successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting group: $e')));
      }
    }
    state = false;
  }
}
