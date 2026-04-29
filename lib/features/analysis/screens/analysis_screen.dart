import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../finance/controller/finance_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/record_model.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analysis'),
      ),
      body: recordsAsync.when(
        data: (records) {
          final expenseRecords = records.where((r) => r.type == RecordType.expense).toList();
          
          // Group by category
          final Map<String, double> categorySpending = {};
          double totalExpense = 0;
          for (var r in expenseRecords) {
            categorySpending[r.category] = (categorySpending[r.category] ?? 0) + r.amount;
            totalExpense += r.amount;
          }

          return categoriesAsync.when(
            data: (categories) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (expenseRecords.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Text('No expense data to analyze yet.', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                      ))
                    else ...[
                      // Total Spending Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Text('Total Spending', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('₹${totalExpense.toStringAsFixed(2)}', 
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.error)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Chart
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 60,
                            sections: categorySpending.entries.map((entry) {
                              final category = categories.firstWhere((c) => c.name == entry.key, 
                                orElse: () => categories.first);
                              return PieChartSectionData(
                                color: category.color,
                                value: entry.value,
                                title: '${(entry.value / totalExpense * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Breakdown List
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      ...categorySpending.entries.map((entry) {
                        final category = categories.firstWhere((c) => c.name == entry.key, orElse: () => categories.first);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: category.color.withValues(alpha: 0.2),
                              child: Icon(category.icon, color: category.color),
                            ),
                            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: LinearProgressIndicator(
                              value: entry.value / totalExpense,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(category.color),
                            ),
                            trailing: Text('₹${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      }),
                    ]
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, trace) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
