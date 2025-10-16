import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/color.dart' as color_model;
import '../../models/size.dart';

class ColorSizeSelector extends StatelessWidget {
  final List<color_model.ColorModel> colors;
  final List<Size> sizes;
  final int? selectedColorId;
  final int? selectedSizeId;
  final Function(int?)? onColorSelected;
  final Function(int?)? onSizeSelected;

  const ColorSizeSelector({
    super.key,
    required this.colors,
    required this.sizes,
    this.selectedColorId,
    this.selectedSizeId,
    this.onColorSelected,
    this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color selector
        if (colors.isNotEmpty) ...[
          const Text(
            'Màu sắc',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: colors.map((color) {
              final isSelected = selectedColorId == color.maMau;
              return GestureDetector(
                onTap: () => onColorSelected?.call(color.maMau),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getColorFromHex(color.maMauHex ?? '#000000'),
                    border: Border.all(
                      color: isSelected ? AppColors.accentRed : AppColors.borderLight,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        // Size selector
        if (sizes.isNotEmpty) ...[
          const Text(
            'Size',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: sizes.map((size) {
              final isSelected = selectedSizeId == size.maSize;
              return GestureDetector(
                onTap: () => onSizeSelected?.call(size.maSize),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.buttonPrimary : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.buttonPrimary : AppColors.borderLight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    size.tenSize,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
