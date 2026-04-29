import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../finance/controller/finance_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/record_model.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Spending Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).showLogoutConfirmation(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          final now = DateTime.now();
          final monthlyRecords = records.where((r) => 
            r.date.month == now.month && 
            r.date.year == now.year
          ).toList();

          final expenseRecords = monthlyRecords.where((r) => r.type == RecordType.expense).toList();
          final incomeRecords = monthlyRecords.where((r) => r.type == RecordType.income).toList();
          
          double totalExpense = expenseRecords.fold(0, (sum, r) => sum + r.amount);
          double totalIncome = incomeRecords.fold(0, (sum, r) => sum + r.amount);
          
          // Group by category
          final Map<String, double> categorySpending = {};
          for (var r in expenseRecords) {
            categorySpending[r.category] = (categorySpending[r.category] ?? 0) + r.amount;
          }

          final sortedEntries = categorySpending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return categoriesAsync.when(
            data: (categories) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Row (Income vs Expense)
                    Row(
                      children: [
                        Expanded(
                          child: _AnalysisCard(
                            label: 'Income',
                            amount: totalIncome,
                            color: AppColors.success,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _AnalysisCard(
                            label: 'Expenses',
                            amount: totalExpense,
                            color: AppColors.error,
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    if (expenseRecords.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              Icon(Icons.analytics_outlined, size: 80, color: AppColors.surface),
                              SizedBox(height: 16),
                              Text('Add some expenses to see analysis', 
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      const Text('Spending Distribution', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 24),
                      
                      // Modern Pie Chart
                      Center(
                        child: SizedBox(
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 6,
                                  centerSpaceRadius: 70,
                                  sections: categorySpending.entries.map((entry) {
                                    final category = categories.firstWhere((c) => c.name == entry.key, 
                                      orElse: () => categories.first);
                                    return PieChartSectionData(
                                      color: category.color,
                                      value: entry.value,
                                      title: '',
                                      radius: 25,
                                      badgeWidget: _Badge(category.icon, size: 30, color: category.color),
                                      badgePositionPercentageOffset: 1.1,
                                    );
                                  }).toList(),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('TOTAL', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1.5)),
                                  Text('₹${totalExpense.toStringAsFixed(0)}', 
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      const Text('Category Breakdown', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      ...sortedEntries.map((entry) {
                        final category = categories.firstWhere((c) => c.name == entry.key, orElse: () => categories.first);
                        final percentage = entry.value / totalExpense;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(category.icon, color: category.color, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('₹${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        backgroundColor: AppColors.background,
                                        valueColor: AlwaysStoppedAnimation<Color>(category.color),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 48),
                      const Text('Spending Trend', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 24),

                      // Refined Line Chart
                      Container(
                        height: 300,
                        padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 250,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.background.withValues(alpha: 0.2),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final now = DateTime.now();
                                    final date = DateTime(now.year, now.month - 4 + value.toInt());
                                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(months[date.month - 1], style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                    );
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 250,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) => Text('₹${value.toInt()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: categorySpending.keys.take(3).indexed.map((indexed) {
                              final index = indexed.$1;
                              final catName = indexed.$2;
                              final lineColors = [Colors.blue, Colors.orange, Colors.pink, Colors.teal, Colors.purple];
                              final lineColor = lineColors[index % lineColors.length];
                              final now = DateTime.now();
                              
                              return LineChartBarData(
                                spots: List.generate(6, (index) {
                                  final monthToChart = DateTime(now.year, now.month - 4 + index);
                                  final amount = records
                                      .where((r) => r.category == catName && r.type == RecordType.expense && r.date.month == monthToChart.month && r.date.year == monthToChart.year)
                                      .fold(0.0, (sum, r) => sum + r.amount);
                                  return FlSpot(index.toDouble(), amount);
                                }),
                                isCurved: true,
                                color: lineColor,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: lineColor.withValues(alpha: 0.1),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: categorySpending.keys.take(3).indexed.map((indexed) {
                            final index = indexed.$1;
                            final catName = indexed.$2;
                            final lineColors = [Colors.blue, Colors.orange, Colors.pink, Colors.teal, Colors.purple];
                            final lineColor = lineColors[index % lineColors.length];
                            
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: lineColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(catName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
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

class _AnalysisCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _AnalysisCard({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text('₹${amount.toStringAsFixed(0)}', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _Badge(this.icon, {required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(size * .15),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            offset: const Offset(0, 3),
            blurRadius: 3,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * .6),
    );
  }
}

