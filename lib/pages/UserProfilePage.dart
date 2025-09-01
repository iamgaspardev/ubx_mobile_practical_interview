import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:ubx_practical_mobile/widgets/DetailedCardOptions.dart';
import 'package:ubx_practical_mobile/providers/user_provider.dart';
import 'package:ubx_practical_mobile/providers/app_lock_provider.dart';

class ProfilePageContent extends StatelessWidget {
  const ProfilePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(context, userProvider),
                  const SizedBox(height: 20),
                  _buildProfileOptions(context, userProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileAvatar(context, userProvider),
          const SizedBox(height: 20),
          Text(
            userProvider.getUserDisplayName(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage Your Profile',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, UserProvider userProvider) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.withValues(alpha: 0.8), Colors.greenAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: userProvider.hasProfileImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: _buildProfileImage(userProvider),
                )
              : const Icon(Icons.person, size: 60, color: Colors.white),
        ),
        _buildCameraButton(context, userProvider),
      ],
    );
  }

  Widget _buildProfileImage(UserProvider userProvider) {
    final imageUrl = userProvider.getProfileImageUrl();

    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.person, size: 60, color: Colors.white);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: 120,
      height: 120,
      headers: {
        'User-Agent': 'UBX-Mobile-App/1.0',
        'Cache-Control': 'no-cache',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        // Show loading indicator
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          child: const Icon(Icons.error, size: 40, color: Colors.white),
        );
      },
    );
  }

  Widget _buildCameraButton(BuildContext context, UserProvider userProvider) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => _showImageSourceDialog(context, userProvider),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(Icons.camera_alt, size: 20, color: Colors.green[600]),
        ),
      ),
    );
  }

  Widget _buildProfileOptions(BuildContext context, UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          DetailedCardOption(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: userProvider.user?.email ?? 'No email',
            onTap: () => _updateLastActiveTime(context),
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          DetailedCardOption(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notifications',
            onTap: () => _updateLastActiveTime(context),
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 30),
          _buildLogoutButton(context, userProvider),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, UserProvider userProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: userProvider.isLoading
            ? null
            : () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[50],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: userProvider.isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.green[600],
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Logout',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageSourceBottomSheet(context, userProvider),
    );
  }

  Widget _buildImageSourceBottomSheet(
    BuildContext context,
    UserProvider userProvider,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Update Profile Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    context: context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _handleImageSelection(
                      context,
                      ImageSource.camera,
                      userProvider,
                    ),
                  ),
                  _buildImageSourceOption(
                    context: context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _handleImageSelection(
                      context,
                      ImageSource.gallery,
                      userProvider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (userProvider.hasProfileImage)
                TextButton(
                  onPressed: () => _removeProfileImage(context, userProvider),
                  child: Text(
                    'Remove Current Picture',
                    style: TextStyle(color: Colors.red[600], fontSize: 16),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.35,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.green[600]),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(
    BuildContext context,
    ImageSource source,
    UserProvider userProvider,
  ) async {
    Navigator.pop(context);

    // Get app lock provider
    final appLockProvider = Provider.of<AppLockProvider>(
      context,
      listen: false,
    );

    try {
      // DISABLE app lock BEFORE opening camera/gallery
      appLockProvider.setImageProcessingActive(true);

      final ImagePicker picker = ImagePicker();

      // error handling specifically for platform exceptions
      XFile? imageFile;
      try {
        imageFile = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
      } on PlatformException catch (platformError) {
        String errorMessage =
            'Unable to access ${source == ImageSource.camera ? 'camera' : 'gallery'}';

        switch (platformError.code) {
          case 'camera_access_denied':
            errorMessage =
                'Camera permission denied. Please enable camera access in device settings.';
            break;
          case 'photo_access_denied':
            errorMessage =
                'Gallery permission denied. Please enable photo access in device settings.';
            break;
          case 'invalid_image':
            errorMessage =
                'Invalid image selected. Please try a different image.';
            break;
          default:
            errorMessage =
                'Permission denied. Please enable ${source == ImageSource.camera ? 'camera' : 'photo'} access in device settings.';
        }

        _showSnackBar(context, errorMessage);

        // Re-enable app lock after error
        appLockProvider.setImageProcessingActive(false);
        return;
      }

      if (imageFile == null) {
        // User cancelled - re-enable app lock
        appLockProvider.setImageProcessingActive(false);
        return;
      }

      // Continue with image processing while lock is disabled
      final File file = File(imageFile.path);
      if (!await file.exists()) {
        _showSnackBar(context, 'Selected image file not found');
        appLockProvider.setImageProcessingActive(false);
        return;
      }

      // Check file size (5MB limit)
      final int fileSizeInBytes = await file.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 5) {
        _showSnackBar(
          context,
          'Image size (${fileSizeInMB.toStringAsFixed(1)} MB) exceeds 5MB limit',
        );
        appLockProvider.setImageProcessingActive(false);
        return;
      }

      _showSnackBar(context, 'Uploading profile picture...');

      // Upload to server while lock is still disabled
      final success = await userProvider.updateProfileImage(imageFile.path);

      if (success) {
        _showSnackBar(context, 'Profile picture updated successfully!');
      } else {
        _showSnackBar(
          context,
          userProvider.errorMessage ?? 'Failed to upload profile picture',
        );
      }

      // Re-enable app lock after completion
      appLockProvider.setImageProcessingActive(false);
    } catch (e) {
      _showSnackBar(context, 'An error occurred while selecting the image');

      // Re-enable app lock on any error
      appLockProvider.setImageProcessingActive(false);
    }
  }

  Future<void> _removeProfileImage(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    Navigator.pop(context);

    // Get app lock provider
    final appLockProvider = Provider.of<AppLockProvider>(
      context,
      listen: false,
    );

    try {
      // Disable app lock during image removal
      appLockProvider.setImageProcessingActive(true);

      _showSnackBar(context, 'Removing profile picture...');

      final success = await userProvider.removeProfileImage();

      if (success) {
        _showSnackBar(context, 'Profile picture removed successfully!');
      } else {
        _showSnackBar(
          context,
          userProvider.errorMessage ?? 'Failed to remove profile picture',
        );
      }

      // Re-enable app lock after completion
      appLockProvider.setImageProcessingActive(false);
    } catch (e) {
      _showSnackBar(context, 'Failed to remove profile picture');

      // Re-enable app lock on error
      appLockProvider.setImageProcessingActive(false);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _updateLastActiveTime(BuildContext context) {
    final appLockProvider = Provider.of<AppLockProvider>(
      context,
      listen: false,
    );
    appLockProvider.updateLastActiveTime();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => _performLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    Navigator.of(context).pop();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final appLockProvider = Provider.of<AppLockProvider>(
      context,
      listen: false,
    );

    await userProvider.logout();
    appLockProvider.setUserLoggedOut();
    appLockProvider.unlockApp();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}
