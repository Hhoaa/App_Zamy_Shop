import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SizeGuideScreen extends StatelessWidget {
  const SizeGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: const Text(
          'Hướng dẫn chọn size',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main title
            const Center(
              child: Text(
                'HƯỚNG DẪN CHỌN SIZE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Underline
            Center(
              child: Container(
                width: 100,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Size chart section
            const Text(
              'ZAMY BẢNG THÔNG SỐ CHỌN SIZE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Size chart table
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8B4B8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            'SIZE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'NGỰC (cm)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'EO (cm)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'MÔNG (cm)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'CÂN NẶNG (kg)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Table rows
                  _buildSizeRow('S', '82-85', '64-66', '90-92', '42-47', true),
                  _buildSizeRow('M', '86-89', '67-70', '93-96', '48-53', false),
                  _buildSizeRow('L', '90-93', '71-74', '97-100', '54-59', true),
                  _buildSizeRow('XL', '94-97', '75-78', '101-104', '60-65', false),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Measurement guide section
            const Text(
              'HƯỚNG DẪN ĐO',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMeasurementStep('1', 'Vòng ngực', 'Đo vòng ngực tại vị trí rộng nhất, thường là qua núm vú'),
                  SizedBox(height: 16),
                  _buildMeasurementStep('2', 'Vòng eo', 'Đo vòng eo tại vị trí nhỏ nhất, thường là trên rốn'),
                  SizedBox(height: 16),
                  _buildMeasurementStep('3', 'Vòng mông', 'Đo vòng mông tại vị trí rộng nhất'),
                  SizedBox(height: 16),
                  _buildMeasurementStep('4', 'Cân nặng', 'Cân trọng lượng cơ thể (kg)'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Tips section
            const Text(
              'LƯU Ý KHI CHỌN SIZE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Đo cơ thể khi mặc đồ lót mỏng hoặc không mặc gì',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Sử dụng thước dây mềm để đo chính xác',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Đo vào buổi sáng khi cơ thể ở trạng thái bình thường',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Nếu số đo nằm giữa 2 size, hãy chọn size lớn hơn',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Mỗi sản phẩm có thể có form dáng khác nhau, vui lòng tham khảo thêm mô tả sản phẩm',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Contact section
            const Text(
              'CẦN HỖ TRỢ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nếu bạn vẫn chưa chắc chắn về size, hãy liên hệ với chúng tôi:',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '📞 Hotline: 1900 1234',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '📧 Email: support@zamy.com',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '💬 Chat trực tuyến: 24/7',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeRow(String size, String chest, String waist, String hip, String weight, bool isEven) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEven ? AppColors.cardBackground : const Color(0xFFF8F8F8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              size,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              chest,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              waist,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              hip,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              weight,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _buildMeasurementStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _buildMeasurementStep(this.step, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.accentRed,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
