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
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/phone_utils.dart';

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

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangeProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userRepositoryProvider).getUserStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final userInvitesProvider = StreamProvider<List<InviteModel>>((ref) {
  final authState = ref.watch(authStateChangeProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  final inviteRepo = ref.watch(inviteRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      
      return Stream.fromFuture(userRepo.getUser(user.uid)).asyncExpand((userModel) {
        if (userModel == null) return Stream.value([]);
        
        final emailStream = inviteRepo.getInvitesForUser(userModel.email);
        final phoneStream = inviteRepo.getInvitesForPhone(userModel.phoneNumber);
        
        return Rx.combineLatest2(emailStream, phoneStream, (List<InviteModel> a, List<InviteModel> b) {
          final combined = [...a, ...b];
          // Remove duplicates by ID
          final ids = <String>{};
          return combined.where((i) => ids.add(i.id)).toList();
        });
      });
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
    String? inviteeEmail,
    String? inviteePhone,
    required String inviteeName,
    required double moneyOwed,
    required BuildContext context,
  }) async {
    state = true;
    try {
      final normalizedPhone = inviteePhone != null ? PhoneUtils.normalizePhoneNumber(inviteePhone) : null;
      final inviteRepo = ref.read(inviteRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Not logged in');

      UserModel? targetUser;
      if (inviteeEmail != null && inviteeEmail.isNotEmpty) {
        targetUser = await inviteRepo.findUserByEmail(inviteeEmail);
      } else if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        targetUser = await inviteRepo.findUserByPhoneNumber(normalizedPhone);
      }

      final creatorProfile = await userRepo.getUser(currentUser.uid);
      final creatorName = creatorProfile?.name ?? 'Group Admin';
      
      final inviteId = const Uuid().v4();
      final code = (100000 + Random().nextInt(900000)).toString();
      
      final invite = InviteModel(
        id: inviteId,
        groupId: groupId,
        groupName: groupName,
        creatorName: creatorName,
        creatorId: currentUser.uid,
        inviteeEmail: inviteeEmail?.toLowerCase().trim() ?? '',
        inviteePhone: normalizedPhone ?? '',
        inviteeName: inviteeName,
        code: code,
        moneyOwed: moneyOwed,
        createdAt: DateTime.now(),
        status: InviteStatus.pending,
      );

      await inviteRepo.sendInvite(invite);
      
      if (targetUser == null && normalizedPhone != null && normalizedPhone.isNotEmpty) {
        // Fallback to WhatsApp/SMS if user not registered
        final message = 'Hi $inviteeName, I added you to the group "$groupName" on Split Expense Manager. Install the app to join: https://split-expense.page.link/join';
        
        // Use normalized phone for sending message
        String formattedPhone = normalizedPhone.replaceAll(RegExp(r'\D'), '');
        
        // Handle common Indian number formats
        if (formattedPhone.length == 10) {
          formattedPhone = '91$formattedPhone';
        } else if (formattedPhone.length == 11 && formattedPhone.startsWith('0')) {
          formattedPhone = '91${formattedPhone.substring(1)}';
        } else if (formattedPhone.length == 12 && formattedPhone.startsWith('91')) {
          // Already correct
        }

        final whatsappUrl = 'whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}';
        final waMeUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';
        
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(Uri.parse(waMeUrl))) {
          await launchUrl(Uri.parse(waMeUrl), mode: LaunchMode.externalApplication);
        } else {
          final smsUrl = 'sms:$normalizedPhone?body=${Uri.encodeComponent(message)}';
          if (await canLaunchUrl(Uri.parse(smsUrl))) {
            await launchUrl(Uri.parse(smsUrl));
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(targetUser != null ? 'Invitation sent!' : 'Invitation sent via WhatsApp/SMS!'))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    state = false;
  }

  Future<void> cancelInvite(String inviteId, BuildContext context) async {
    state = true;
    try {
      await ref.read(inviteRepositoryProvider).deleteInvite(inviteId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation cancelled.')));
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
