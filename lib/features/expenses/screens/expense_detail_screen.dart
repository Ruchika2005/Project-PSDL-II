import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/expense_model.dart';
import '../../../models/group_model.dart';
import '../../groups/controller/group_controller.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../repository/bill_repository.dart';

final billDataProvider = FutureProvider.family<String?, String>((ref, expenseId) {
  return ref.watch(billRepositoryProvider).getBill(expenseId);
});

class ExpenseDetailScreen extends ConsumerWidget {
  final ExpenseModel expense;
  final GroupModel group;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.group,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberNamesAsync = ref.watch(memberNamesProvider(group));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    expense.description,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(expense.createdAt),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Paid By Section
            _buildSectionTitle(context, 'PAID BY'),
            const SizedBox(height: 12),
            memberNamesAsync.when(
              data: (map) => _buildMemberTile(
                context,
                map[expense.paidBy] ?? expense.paidBy,
                expense.amount,
                isPayer: true,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildMemberTile(context, expense.paidBy, expense.amount, isPayer: true),
            ),
            
            const SizedBox(height: 32),

            // Split Details Section
            _buildSectionTitle(context, 'SPLIT DETAILS'),
            const SizedBox(height: 12),
            memberNamesAsync.when(
              data: (map) => Column(
                children: expense.splits.map((split) {
                  final name = map[split.userId] ?? split.userId;
                  return _buildMemberTile(context, name, split.amount);
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Column(
                children: expense.splits.map((split) => _buildMemberTile(context, split.userId, split.amount)).toList(),
              ),
            ),
            
            // Bill Photo Section
            if (expense.billImageUrl != null && expense.billImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'BILL PHOTO'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showFullScreenImage(context, expense.billImageUrl!),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (expense.billImageUrl != null)
                          ref.watch(billDataProvider(expense.id)).when(
                            data: (base64Data) {
                              if (base64Data == null) {
                                // Fallback for old local paths
                                return _buildBillImage(expense.billImageUrl!);
                              }
                              return _buildBillImage('base64:$base64Data');
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text('Error: $e')),
                          )
                        else
                          const Center(child: Icon(Icons.image_not_supported)),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.bottomRight,
                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
            
            // Split Type Info
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                ),
                child: Text(
                  'Split Type: ${expense.splitType.name.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.5,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillImage(String billUrl, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (billUrl.startsWith('base64:')) {
      try {
        final bytes = base64Decode(billUrl.substring(7));
        return Image.memory(bytes, height: height, width: width, fit: fit);
      } catch (e) {
        return const Center(child: Icon(Icons.broken_image));
      }
    } else if (billUrl.startsWith('http')) {
      return Image.network(billUrl, height: height, width: width, fit: fit);
    } else {
      final file = File(billUrl);
      if (file.existsSync()) {
        return Image.file(file, height: height, width: width, fit: fit);
      }
      return Container(
        color: Colors.grey[200],
        height: height,
        width: width,
        child: const Icon(Icons.image_not_supported),
      );
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: _buildBillImage(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, String name, double amount, {bool isPayer = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPayer 
              ? AppColors.success.withOpacity(0.5) 
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: isPayer ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isPayer ? AppColors.success : Theme.of(context).colorScheme.primary).withOpacity(0.1),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: isPayer ? AppColors.success : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isPayer ? AppColors.success : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
