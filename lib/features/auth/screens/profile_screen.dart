import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../groups/controller/group_controller.dart';
import '../controller/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndTransformImage() async {
    try {
      // 1. Multimedia: Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      // 2. Image Transformation: Crop and Rotate
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Transform Profile Photo',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.black,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            activeControlsWidgetColor: AppColors.primary,
          ),
          IOSUiSettings(
            title: 'Transform Profile Photo',
          ),
        ],
      );

      if (croppedFile != null) {
        // Evict old image from cache to ensure it reloads even if path is same
        final user = ref.read(currentUserProvider).value;
        if (user != null && user.profilePhoto.isNotEmpty) {
          await FileImage(File(user.profilePhoto)).evict();
        }

        // 3. Save transformation result
        if (mounted) {
          await ref.read(authControllerProvider.notifier).updateProfilePhoto(croppedFile.path, context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User details not found.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Photo with Camera Overlay
                GestureDetector(
                  onTap: _pickAndTransformImage,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          key: ValueKey(user.profilePhoto),
                          radius: 60,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: user.profilePhoto.isNotEmpty 
                              ? FileImage(File(user.profilePhoto)) 
                              : null,
                          child: user.profilePhoto.isEmpty
                              ? Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 48, 
                                    fontWeight: FontWeight.bold, 
                                    color: AppColors.primary
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded, 
                            size: 20, 
                            color: Colors.black
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                if (user.profilePhoto.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      // Evict before clearing
                      await FileImage(File(user.profilePhoto)).evict();
                      if (mounted) {
                        await ref.read(authControllerProvider.notifier).updateProfilePhoto('', context);
                      }
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                    label: const Text('Clear Photo', style: TextStyle(color: Colors.redAccent)),
                  ),
                const SizedBox(height: 32),
                
                // Info Section
                _buildInfoTile(context, Icons.email_outlined, 'Email', user.email),
                const SizedBox(height: 16),
                _buildInfoTile(context, Icons.phone_android_outlined, 'Phone Number', user.phoneNumber),
                
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PREFERENCES', 
                    style: TextStyle(
                      color: Colors.grey, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2
                    )
                  ),
                ),
                const SizedBox(height: 12),
                _buildThemeTile(context, ref),
                
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).showLogoutConfirmation(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('LOGOUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: Colors.redAccent.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, 
            color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('Dark Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Switch.adaptive(
            value: isDark,
            activeColor: AppColors.primary,
            onChanged: (val) => ref.read(themeControllerProvider.notifier).toggleTheme(val),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
