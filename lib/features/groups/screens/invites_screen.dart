import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/group_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/invite_model.dart';

class InvitesScreen extends ConsumerWidget {
  const InvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(userInvitesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Invitations'),
      ),
      body: invitesAsync.when(
        data: (invites) {
          if (invites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No invitations or pending payments', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          
          final pendingInvites = invites.where((i) => i.status == InviteStatus.pending).toList();
          final acceptedInvites = invites.where((i) => i.status == InviteStatus.accepted).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pendingInvites.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0, left: 4.0),
                  child: Text('NEW INVITATIONS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2)),
                ),
                ...pendingInvites.map((invite) => _InviteCard(invite: invite)),
                const SizedBox(height: 24),
              ],
              if (acceptedInvites.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0, left: 4.0),
                  child: Text('PENDING PAYMENTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1.2)),
                ),
                ...acceptedInvites.map((invite) => _InviteCard(invite: invite)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  final InviteModel invite;
  const _InviteCard({required this.invite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.group, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invite.groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Invited by ${invite.creatorName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invite.status == InviteStatus.accepted ? 'Debt to Pay' : 'Initial Balance', 
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('₹${invite.moneyOwed.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (invite.status == InviteStatus.accepted)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => ref.read(groupControllerProvider.notifier).markInviteAsPaid(invite, context),
                    child: const Text('DONE / PAID', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    onPressed: () => ref.read(groupControllerProvider.notifier).respondToInvite(invite, true, context),
                    child: const Text('ACCEPT INVITE'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
