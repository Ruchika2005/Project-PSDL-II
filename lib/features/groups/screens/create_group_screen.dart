import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/group_controller.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _emailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailsController.dispose();
    super.dispose();
  }

  void _createGroup() {
    if (_formKey.currentState!.validate()) {
      final emails = _emailsController.text.split(',').map((e) => e.trim()).toList();
      ref.read(groupControllerProvider.notifier).createGroup(
            _nameController.text.trim(),
            emails,
            context,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(groupControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        prefixIcon: Icon(Icons.group),
                      ),
                      validator: (value) => value != null && value.isNotEmpty ? null : 'Enter group name',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailsController,
                      decoration: const InputDecoration(
                        labelText: 'Member Emails (comma separated)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) => value != null && value.isNotEmpty ? null : 'Enter at least one email',
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading ? null : _createGroup,
                      child: isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('CREATE GROUP'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
