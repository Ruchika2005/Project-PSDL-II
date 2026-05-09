import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/screens/auth_checker.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'features/groups/controller/group_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/groups/repository/group_repository.dart';
import 'features/settlement/controller/settlement_controller.dart';
import 'features/settlement/utils/settlement_algorithm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final fcmService = FCMService();
  await fcmService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class RemindedExpensesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  
  void add(String id) {
    state = {...state, id};
  }
}

final remindedExpensesProvider = NotifierProvider<RemindedExpensesNotifier, Set<String>>(RemindedExpensesNotifier.new);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for new invites to show local notifications
    ref.listen(userInvitesProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final invites = next.value!;
        final previousInvites = previous?.value ?? [];
        
        // If we have more invites than before, show a notification for the newest one
        if (invites.length > previousInvites.length) {
          final newInvite = invites.first; // Usually newest are added at top or we just pick one
          ref.read(fcmServiceProvider).showLocalNotification(
            'New Group Invitation',
            'You have been invited to join "${newInvite.groupName}"',
          );
        }
      }
    });

    // Listen for new expenses to show payment reminders after 30 seconds
    ref.listen(allUserExpensesProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId == null) return;

        final expenses = next.value!;
        final previousExpenses = previous?.value ?? [];
        final remindedIds = ref.read(remindedExpensesProvider);

        for (var expense in expenses) {
          // Only process if it's a new expense (not in previous list and not already handled)
          bool isNew = !previousExpenses.any((e) => e.id == expense.id);
          
          if (isNew && !remindedIds.contains(expense.id)) {
            // Check if current user is in splits and NOT the payer
            final userSplit = expense.splits.where((s) => s.userId == currentUserId).toList();
            
            if (userSplit.isNotEmpty && expense.paidBy != currentUserId) {
              // Mark as processed to avoid starting multiple periodic timers for same expense
              ref.read(remindedExpensesProvider.notifier).add(expense.id);

              // 1. Immediate Notification
              Future.microtask(() async {
                try {
                  final group = await ref.read(groupRepositoryProvider).getGroup(expense.groupId).first;
                  ref.read(fcmServiceProvider).showLocalNotification(
                    'New Expense Added 💸',
                    'You owe ₹${userSplit.first.amount.toStringAsFixed(2)} for "${expense.description}" in "${group.name}"',
                  );
                } catch (e) {
                  debugPrint('Error showing immediate notification: $e');
                }
              });

              // 2. Periodic Reminder (Every 30 seconds)
              Timer.periodic(const Duration(seconds: 30), (timer) async {
                try {
                  // Check if the provider is still mounted
                  if (!context.mounted) {
                    timer.cancel();
                    return;
                  }

                  final group = await ref.read(groupRepositoryProvider).getGroup(expense.groupId).first;
                  final settlements = ref.read(settlementProvider(expense.groupId));
                  
                  final totalOwed = settlements
                      .where((t) => t.from == currentUserId)
                      .fold(0.0, (sum, t) => sum + t.amount);

                  if (totalOwed > 0.01) {
                    ref.read(fcmServiceProvider).showLocalNotification(
                      'Payment Reminder ⏰',
                      'Reminder: You still owe a total of ₹${totalOwed.toStringAsFixed(2)} in "${group.name}"',
                    );
                  } else {
                    // Stop reminding once the debt is settled
                    timer.cancel();
                  }
                } catch (e) {
                  debugPrint('Error in periodic reminder: $e');
                  timer.cancel();
                }
              });
            }
          }
        }
      }
    });

    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'SplitExpense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthChecker(),
    );
  }
}
