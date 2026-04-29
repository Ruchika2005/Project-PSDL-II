import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../groups/screens/dashboard_screen.dart'; // Existing Groups Screen
import '../../records/screens/records_screen.dart'; // New Records Screen
import '../../accounts/screens/accounts_screen.dart'; // Accounts Screen
import '../../categories/screens/categories_screen.dart'; // Categories Screen
import '../../analysis/screens/analysis_screen.dart'; // Analysis Screen
import '../../budgets/screens/budgets_screen.dart'; // Budgets Screen
import '../../finance/controller/finance_controller.dart';

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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
}
