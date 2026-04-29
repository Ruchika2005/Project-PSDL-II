import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/group_model.dart';
import '../../../models/expense_model.dart';
import '../controller/expense_controller.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final GroupModel group;
  const AddExpenseScreen({super.key, required this.group});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SplitType _splitType = SplitType.equal;
  String? _paidBy;
  
  final Map<String, TextEditingController> _splitControllers = {};

  @override
  void initState() {
    super.initState();
    for (var memberId in widget.group.members) {
      _splitControllers[memberId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      double amount = double.parse(_amountController.text);
      List<ExpenseSplit> splits = [];

      if (_splitType == SplitType.equal) {
        double splitAmount = amount / widget.group.members.length;
        splits = widget.group.members.map((id) => ExpenseSplit(userId: id, amount: splitAmount)).toList();
      } else {
        for (var memberId in widget.group.members) {
          double val = double.tryParse(_splitControllers[memberId]!.text) ?? 0.0;
          splits.add(ExpenseSplit(userId: memberId, amount: val));
        }
      }

      ref.read(expenseControllerProvider.notifier).addExpense(
        groupId: widget.group.id,
        description: _descController.text.trim(),
        amount: amount,
        paidBy: _paidBy ?? FirebaseAuth.instance.currentUser!.uid,
        splits: splits,
        splitType: _splitType,
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(expenseControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (val) => val!.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) => val!.isEmpty ? 'Enter amount' : null,
                  ),
                  const SizedBox(height: 16),
                  // Payer Selection
                  DropdownButtonFormField<String>(
                    value: _paidBy ?? widget.group.members.first,
                    items: widget.group.members.map((name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text('Paid by: $name'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _paidBy = val),
                    decoration: const InputDecoration(
                      labelText: 'Payer',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SplitType>(
                    value: _splitType,
                    items: SplitType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _splitType = val!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Split Type',
                      prefixIcon: Icon(Icons.pie_chart),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_splitType != SplitType.equal) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Enter splits for each member:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    ...widget.group.members.map((name) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextFormField(
                          controller: _splitControllers[name],
                          decoration: InputDecoration(
                            labelText: 'Member: $name',
                            suffixText: _splitType == SplitType.percentage ? '%' : '₹',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text('SAVE EXPENSE'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
