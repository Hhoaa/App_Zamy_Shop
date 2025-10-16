import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ShippingPolicyScreen extends StatelessWidget {
  const ShippingPolicyScreen({super.key});

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
          'Chính sách vận chuyển',
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
                'CHÍNH SÁCH VẬN CHUYỂN',
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
            
            // Delivery time section
            const Text(
              'THỜI GIAN GIAO HÀNG',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Delivery time table
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
                            'STT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'KHU VỰC VẬN CHUYỂN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'THỜI GIAN',
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
                  _buildTableRow('1', 'Nội thành Hà Nội', 'Từ 01 – 03 ngày làm việc', true),
                  _buildTableRow('2', 'Ngoại thành & các thành phố lớn', 'Từ 03 – 05 ngày làm việc', false),
                  _buildTableRow('3', 'Các khu vực khác', 'Từ 04 – 07 ngày làm việc', true),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Shipping fees section
            const Text(
              'PHÍ VẬN CHUYỂN',
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
                    '• Miễn phí vận chuyển cho đơn hàng từ 500.000 VNĐ',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Phí vận chuyển: 30.000 VNĐ cho đơn hàng dưới 500.000 VNĐ',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Phí vận chuyển nhanh (1-2 ngày): 50.000 VNĐ',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Delivery process section
            const Text(
              'QUY TRÌNH GIAO HÀNG',
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
                  _buildProcessStep('1', 'Xác nhận đơn hàng', 'Chúng tôi sẽ xác nhận đơn hàng trong vòng 2 giờ'),
                  SizedBox(height: 16),
                  _buildProcessStep('2', 'Chuẩn bị hàng', 'Đóng gói và chuẩn bị hàng hóa'),
                  SizedBox(height: 16),
                  _buildProcessStep('3', 'Giao hàng', 'Đối tác vận chuyển sẽ giao hàng đến bạn'),
                  SizedBox(height: 16),
                  _buildProcessStep('4', 'Xác nhận nhận hàng', 'Kiểm tra và xác nhận nhận hàng'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Contact section
            const Text(
              'LIÊN HỆ HỖ TRỢ',
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
                    'Nếu bạn có bất kỳ thắc mắc nào về vận chuyển, vui lòng liên hệ:',
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

  Widget _buildTableRow(String stt, String area, String time, bool isEven) {
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
              stt,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              area,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              time,
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

class _buildProcessStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _buildProcessStep(this.step, this.title, this.description);

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
