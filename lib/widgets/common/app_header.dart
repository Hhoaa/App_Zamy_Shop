import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : leading,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ZamyHeader extends StatelessWidget {
  final List<Widget>? actions;
  final String? currentPage;

  const ZamyHeader({
    super.key,
    this.actions,
    this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          const Text(
            'ZAMY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Navigation menu
          if (currentPage != null) ...[
            _buildNavItem('SALE', currentPage == 'sale'),
            _buildNavItem('ĐẦM', currentPage == 'dress'),
            _buildNavItem('ÁO', currentPage == 'shirt'),
            _buildNavItem('QUẦN', currentPage == 'pants'),
            _buildNavItem('CHÂN VÁY', currentPage == 'skirt'),
            _buildNavItem('LOOKBOOK', currentPage == 'lookbook'),
          ],
          const Spacer(),
          // Action icons
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  Widget _buildNavItem(String text, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: isActive
            ? const Border(
                bottom: BorderSide(color: AppColors.accentRed, width: 2),
              )
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? AppColors.accentRed : AppColors.textPrimary,
        ),
      ),
    );
  }
}
