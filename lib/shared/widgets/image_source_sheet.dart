import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Shows a bottom sheet letting the user pick an image from the camera or the
/// gallery, then returns the selected [XFile] (or null if cancelled / failed).
///
/// Errors (e.g. permission denied, no camera) are surfaced via a SnackBar so
/// the caller doesn't have to handle them.
Future<XFile?> pickImageWithSource(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surf(context),
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.xl,
          AppSizes.lg,
          AppSizes.xl,
          AppSizes.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.brd(sheetContext),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Pilih sumber foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textP(sheetContext),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _SourceOption(
              icon: Icons.photo_camera_rounded,
              label: 'Kamera',
              subtitle: 'Ambil foto langsung',
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            const SizedBox(height: AppSizes.sm),
            _SourceOption(
              icon: Icons.photo_library_rounded,
              label: 'Galeri',
              subtitle: 'Pilih dari galeri',
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return null;

  try {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    return image;
  } catch (e) {
    if (context.mounted) {
      final msg = source == ImageSource.camera
          ? 'Gagal membuka kamera. Pastikan izin kamera diaktifkan.'
          : 'Gagal membuka galeri. Pastikan izin galeri diaktifkan.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
    return null;
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surfMuted(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.brd(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textP(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textT(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textT(context),
            ),
          ],
        ),
      ),
    );
  }
}
