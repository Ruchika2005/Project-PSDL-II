import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../groups/screens/dashboard_screen.dart'; // Existing Groups Screen
import '../../records/screens/records_screen.dart'; // New Records Screen
import '../../accounts/screens/accounts_screen.dart'; // Accounts Screen
import '../../categories/screens/categories_screen.dart'; // Categories Screen
import '../../analysis/screens/analysis_screen.dart'; // Analysis Screen
import '../../budgets/screens/budgets_screen.dart'; // Budgets Screen
import '../../finance/controller/finance_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/screens/profile_screen.dart';
import '../../auth/screens/help_guidance_screen.dart';
import '../../groups/controller/group_controller.dart';
import '../../groups/screens/invites_screen.dart';
import '../../../core/constants/app_colors.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize default data for new users in Firestore
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).syncUserProfile();
      ref.read(accountsControllerProvider.notifier).ensureDefaultAccounts();
      ref.read(categoriesControllerProvider.notifier).ensureDefaultCategories();
    });
  }

  final List<Widget> _screens = [
    const RecordsScreen(),
    const AnalysisScreen(),
    const BudgetsScreen(),
    const AccountsScreen(),
    const CategoriesScreen(),
    const DashboardScreen(), // Reusing the Groups tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXPENSEFLOW+',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentIndex == 0 
                    ? 'Records' 
                    : _currentIndex == 1 
                        ? 'Analysis' 
                        : _currentIndex == 2 
                            ? 'Budgets' 
                            : _currentIndex == 3 
                                ? 'Accounts' 
                                : _currentIndex == 4 
                                    ? 'Categories' 
                                    : 'Groups',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_currentIndex == 5) // Groups tab
            ref.watch(userInvitesProvider).when(
              data: (invites) => Badge(
                label: Text(invites.length.toString()),
                isLabelVisible: invites.isNotEmpty,
                backgroundColor: AppColors.error,
                child: IconButton(
                  icon: const Icon(Icons.mail_outline_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InvitesScreen()),
                  ),
                  tooltip: 'Invites',
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      drawer: _buildDrawer(context, ref),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budgets'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Accounts'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Drawer(
      child: Column(
        children: [
          userAsync.when(
            data: (user) => UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                key: ValueKey(user?.profilePhoto),
                backgroundColor: Colors.white,
                backgroundImage: user?.profilePhoto.isNotEmpty == true 
                    ? FileImage(File(user!.profilePhoto)) 
                    : null,
                child: user?.profilePhoto.isEmpty == true || user == null
                    ? Text(
                        user?.name[0].toUpperCase() ?? 'U',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
              accountName: Text(user?.name ?? 'User'),
              accountEmail: Text(user?.email ?? ''),
              decoration: const BoxDecoration(color: AppColors.primary),
            ),
            loading: () => const DrawerHeader(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const DrawerHeader(child: Center(child: Text('Error'))),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Help/Guidance'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpGuidanceScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              ref.read(authControllerProvider.notifier).showLogoutConfirmation(context);
            },
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
