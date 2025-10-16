class CurrencyFormatter {
  static String formatVND(double amount) {
    // Format số tiền thành định dạng Việt Nam đồng
    String formatted = amount.toStringAsFixed(0);
    
    // Thêm dấu phẩy cho hàng nghìn
    if (formatted.length > 3) {
      String result = '';
      int count = 0;
      
      for (int i = formatted.length - 1; i >= 0; i--) {
        if (count == 3) {
          result = ',' + result;
          count = 0;
        }
        result = formatted[i] + result;
        count++;
      }
      
      formatted = result;
    }
    
    return '$formatted ₫';
  }
}
