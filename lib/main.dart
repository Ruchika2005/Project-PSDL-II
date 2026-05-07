import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_checker.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'features/groups/controller/group_controller.dart';

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

    return MaterialApp(
      title: 'SplitExpense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthChecker(),
    );
  }
}
