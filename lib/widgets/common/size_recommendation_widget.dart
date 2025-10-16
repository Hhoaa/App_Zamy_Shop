import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/size_recommendation_api.dart';

class CollapsibleSizeRecommendationWidget extends StatefulWidget {
  final Function(String) onSizeRecommended;

  const CollapsibleSizeRecommendationWidget({
    super.key,
    required this.onSizeRecommended,
  });

  @override
  State<CollapsibleSizeRecommendationWidget> createState() =>
      _CollapsibleSizeRecommendationWidgetState();
}

class _CollapsibleSizeRecommendationWidgetState
    extends State<CollapsibleSizeRecommendationWidget> {
  bool _isExpanded = false;
  final _formKey = GlobalKey<FormState>();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String? _recommendedSize;
  String? _recommendationMessage;
  bool _isCalculating = false;

  @override
  void dispose() {
    _chestController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _calculateSize() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });
    try {
      final res = await SizeRecommendationApi.recommend(
        height: _heightController.text,
        weight: _weightController.text,
        bust: _chestController.text,
        waist: _waistController.text,
        hip: _hipController.text,
        useGemini: true,
      );
      setState(() {
        _recommendedSize = (res['size'] as String?)?.toUpperCase();
        _recommendationMessage =
            res['notes'] as String? ?? 'Đề xuất từ hệ thống';
        _isCalculating = false;
      });
      if (_recommendedSize != null) widget.onSizeRecommended(_recommendedSize!);
    } catch (e) {
      setState(() {
        _isCalculating = false;
        _recommendationMessage =
            'Không gọi được API gợi ý size. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.straighten, color: AppColors.accentRed, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Gợi ý size dựa trên số đo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _heightController,
                            label: 'Chiều cao (cm)',
                            icon: Icons.height,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNumberField(
                            controller: _weightController,
                            label: 'Cân nặng (kg)',
                            icon: Icons.monitor_weight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _chestController,
                            label: 'Ngực (cm)',
                            icon: Icons.straighten,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNumberField(
                            controller: _waistController,
                            label: 'Eo (cm)',
                            icon: Icons.straighten,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _hipController,
                            label: 'Mông (cm)',
                            icon: Icons.straighten,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: SizedBox(),
                        ), // Empty space for alignment
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Calculate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCalculating ? null : _calculateSize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isCalculating
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Gợi ý size',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),

                    // Recommendation result
                    if (_recommendationMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _recommendedSize != null
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _recommendedSize != null
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _recommendedSize != null
                                      ? Icons.check_circle
                                      : Icons.info,
                                  color:
                                      _recommendedSize != null
                                          ? Colors.green
                                          : Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _recommendedSize != null
                                        ? 'Size: $_recommendedSize'
                                        : 'Không tìm thấy size phù hợp',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _recommendedSize != null
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _recommendationMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
        labelStyle: const TextStyle(fontSize: 12),
        hintStyle: const TextStyle(fontSize: 12),
      ),
      style: const TextStyle(fontSize: 14),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập $label';
        }
        final number = double.tryParse(value);
        if (number == null || number <= 0) {
          return 'Vui lòng nhập số hợp lệ';
        }
        // Special validation for height
        if (label.contains('Chiều cao')) {
          if (number < 100 || number > 250) {
            return 'Chiều cao từ 100-250cm';
          }
        }
        // Special validation for weight
        if (label.contains('Cân nặng')) {
          if (number < 20 || number > 200) {
            return 'Cân nặng từ 20-200kg';
          }
        }
        return null;
      },
    );
  }
}
