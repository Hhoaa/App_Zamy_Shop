import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class VNPayService {
  // VNPay configuration theo chuẩn C# VNPay Library
  static const String _vnpayUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String _returnUrl = 'zamyapp://vnpay-return';
  static const String _tmnCode = 'X49PI1WG'; // TMN Code từ tài liệu VNPay
  static const String _secretKey = 'LKSOAAPCIUWUKVZKDMXZVYPUTOQGXXPH'; // Secret key từ tài liệu
  
  // Mock payment mode để test
  static const bool _useMockPayment = false;

  /// Lấy IP của thiết bị
  static Future<String> _getDeviceIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting device IP: $e');
    }
    return '127.0.0.1';
  }

  /// Tạo HMAC SHA512 theo chuẩn ví dụ Django (vnpay.py)
  static String _hmacSHA512(String key, String inputData) {
    final keyBytes = utf8.encode(key);
    final inputBytes = utf8.encode(inputData);
    final hmacSha512 = Hmac(sha512, keyBytes);
    final digest = hmacSha512.convert(inputBytes);
    return digest.toString().toLowerCase();
  }

  /// Tạo URL thanh toán VNPay theo chuẩn C# VNPay Library
  static Future<String?> createPaymentUrl({
    required int orderId,
    required double amount,
    required String orderInfo,
    required String returnUrl,
  }) async {
    try {
      print('[DEBUG] Tạo URL thanh toán VNPay theo chuẩn C#...');
      print('[DEBUG] Order ID: $orderId');
      print('[DEBUG] Amount: $amount');
      print('[DEBUG] Order Info: $orderInfo');
      
      // Lấy IP của thiết bị
      final ipAddress = await _getDeviceIP();
      print('[DEBUG] IP Address: $ipAddress');
      
      // Tạo timestamp theo format VNPay: yyyyMMddHHmmss
      final now = DateTime.now();
      final createDate = '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      
      // Tạo expire date (15 phút sau)
      final expireTime = now.add(Duration(minutes: 15));
      final expireDate = '${expireTime.year.toString().padLeft(4, '0')}${expireTime.month.toString().padLeft(2, '0')}${expireTime.day.toString().padLeft(2, '0')}${expireTime.hour.toString().padLeft(2, '0')}${expireTime.minute.toString().padLeft(2, '0')}${expireTime.second.toString().padLeft(2, '0')}';
      
      print('[DEBUG] CreateDate: $createDate');
      print('[DEBUG] ExpireDate: $expireDate');
      
      // Tạo TxnRef đơn giản hơn (chỉ số, không có ký tự đặc biệt)
      // VNPay yêu cầu TxnRef chỉ chứa số và chữ cái, không có dấu gạch ngang
      final simpleTxnRef = orderId.toString();
      print('[DEBUG] Original Order ID: $orderId');
      print('[DEBUG] Simple TxnRef: $simpleTxnRef');
      
      // Tạo params theo đúng thứ tự như tài liệu VNPay
      final vnpParams = <String, String>{
        'vnp_Version': '2.1.0',
        'vnp_Command': 'pay',
        'vnp_TmnCode': _tmnCode,
        'vnp_Amount': (amount * 100).toInt().toString(), // Nhân 100 như tài liệu
        'vnp_CreateDate': createDate,
        'vnp_ExpireDate': expireDate, // Thêm expire date theo tài liệu
        'vnp_CurrCode': 'VND',
        'vnp_IpAddr': ipAddress,
        'vnp_Locale': 'vn',
        'vnp_OrderInfo': 'Thanh toan don hang $simpleTxnRef', // Tiếng Việt không dấu
        'vnp_OrderType': 'other',
        'vnp_ReturnUrl': returnUrl,
        'vnp_TxnRef': simpleTxnRef,
      };

      print('[DEBUG] VNPay params: $vnpParams');

      // Tạo query string với URL encode như C# VNPay Library
      final sortedParams = Map.fromEntries(
        vnpParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      
      String _encodeValueForVnPay(String value) {
        // Mimic Python urllib.parse.quote_plus: encode then convert spaces to '+'
        return Uri.encodeQueryComponent(value).replaceAll('%20', '+');
      }

      final queryStringParts = <String>[];
      for (final entry in sortedParams.entries) {
        if (entry.value.isNotEmpty) {
          // Keys stay as-is, values encoded with plus for spaces
          queryStringParts.add('${entry.key}=${_encodeValueForVnPay(entry.value)}');
        }
      }
      final queryString = queryStringParts.join('&');

      print('[DEBUG] Query string: $queryString');

      // Tạo secure hash theo chuẩn Django sample (HMAC SHA512 trên chuỗi đã URL-encode)
      final secureHash = _hmacSHA512(_secretKey, queryString);
      
      print('[DEBUG] Sign data: $queryString');
      print('[DEBUG] Generated SecureHash: $secureHash');

      // Tạo URL cuối cùng
      final finalUrl = '$_vnpayUrl?$queryString&vnp_SecureHash=$secureHash';
      
      print('[DEBUG] Payment URL created successfully');
      print('[DEBUG] Final URL: $finalUrl');
      
      return finalUrl;
    } catch (e, stackTrace) {
      print('[DEBUG] Lỗi tạo URL thanh toán VNPay: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Hiển thị VNPay payment với WebView
  static Future<void> showPayment({
    required BuildContext context,
    required String paymentUrl,
    required Function(Map<String, String>) onPaymentSuccess,
    required Function(Map<String, String>) onPaymentError,
  }) async {
    try {
      print('[DEBUG] Hiển thị VNPay payment với WebView...');
      
      // Nếu dùng mock payment
      if (_useMockPayment) {
        await _showMockPaymentDialog(
          context: context,
          onPaymentSuccess: onPaymentSuccess,
          onPaymentError: onPaymentError,
        );
        return;
      }
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VNPayWebView(
            paymentUrl: paymentUrl,
            onPaymentSuccess: onPaymentSuccess,
            onPaymentError: onPaymentError,
          ),
        ),
      );
    } catch (e) {
      print('[DEBUG] Lỗi hiển thị VNPay payment: $e');
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi thanh toán'),
          content: Text('Không thể mở trang thanh toán VNPay.\n\nLỗi: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onPaymentError({'error': 'Cannot open VNPay: $e'});
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  /// Hiển thị mock payment dialog để test
  static Future<void> _showMockPaymentDialog({
    required BuildContext context,
    required Function(Map<String, String>) onPaymentSuccess,
    required Function(Map<String, String>) onPaymentError,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('VNPay Test Payment'),
        content: const Text(
          'Đây là chế độ test. Chọn kết quả thanh toán:',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onPaymentError({'vnp_ResponseCode': '24', 'error': 'User cancelled'});
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onPaymentError({'vnp_ResponseCode': '51', 'error': 'Insufficient balance'});
            },
            child: const Text('Thất bại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onPaymentSuccess({
                'vnp_ResponseCode': '00',
                'vnp_TransactionStatus': '00',
                'vnp_TxnRef': 'test_${DateTime.now().millisecondsSinceEpoch}',
                'vnp_Amount': '40000000',
                'vnp_OrderInfo': 'Test payment',
              });
            },
            child: const Text('Thành công'),
          ),
        ],
      ),
    );
  }

  /// Xác thực secure hash từ VNPay response theo chuẩn C# VNPay Library
  static bool verifySecureHash(Map<String, String> params, String receivedHash) {
    try {
      // Loại bỏ vnp_SecureHash và vnp_SecureHashType như C# VNPay Library
      final paramsToHash = Map<String, String>.from(params);
      paramsToHash.remove('vnp_SecureHash');
      paramsToHash.remove('vnp_SecureHashType');
      
      // Sắp xếp params theo alphabet
      final sortedParams = Map.fromEntries(
        paramsToHash.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      
      // Tạo query string với URL encode (quote_plus style: space -> '+')
      String _encodeValueForVnPay(String value) {
        return Uri.encodeQueryComponent(value).replaceAll('%20', '+');
      }

      final queryStringParts = <String>[];
      for (final entry in sortedParams.entries) {
        if (entry.value.isNotEmpty) {
          queryStringParts.add('${entry.key}=${_encodeValueForVnPay(entry.value)}');
        }
      }
      final queryString = queryStringParts.join('&');
      
      // Tạo hash từ params (HMAC SHA512) khớp Django sample
      final calculatedHash = _hmacSHA512(_secretKey, queryString);
      
      print('[DEBUG] Received hash: $receivedHash');
      print('[DEBUG] Calculated hash: $calculatedHash');
      
      return calculatedHash.toLowerCase() == receivedHash.toLowerCase();
    } catch (e) {
      print('[DEBUG] Error verifying hash: $e');
      return false;
    }
  }

  /// Kiểm tra kết quả thanh toán có thành công không
  static bool isPaymentSuccess(Map<String, String> result) {
    final responseCode = result['vnp_ResponseCode'];
    final transactionStatus = result['vnp_TransactionStatus'];
    
    print('[DEBUG] Response Code: $responseCode');
    print('[DEBUG] Transaction Status: $transactionStatus');
    
    return responseCode == '00' && (transactionStatus == null || transactionStatus == '00');
  }

  /// Lấy thông báo kết quả thanh toán
  static String getPaymentMessage(Map<String, String> result) {
    final responseCode = result['vnp_ResponseCode'] ?? '';
    
    final messages = {
      '00': 'Giao dịch thành công',
      '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường).',
      '09': 'Giao dịch không thành công do: Thẻ/Tài khoản của khách hàng chưa đăng ký dịch vụ InternetBanking tại ngân hàng.',
      '10': 'Giao dịch không thành công do: Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần',
      '11': 'Giao dịch không thành công do: Đã hết hạn chờ thanh toán. Xin quý khách vui lòng thực hiện lại giao dịch.',
      '12': 'Giao dịch không thành công do: Thẻ/Tài khoản của khách hàng bị khóa.',
      '13': 'Giao dịch không thành công do Quý khách nhập sai mật khẩu xác thực giao dịch (OTP). Xin quý khách vui lòng thực hiện lại giao dịch.',
      '24': 'Giao dịch không thành công do: Khách hàng hủy giao dịch',
      '51': 'Giao dịch không thành công do: Tài khoản của quý khách không đủ số dư để thực hiện giao dịch.',
      '65': 'Giao dịch không thành công do: Tài khoản của Quý khách đã vượt quá hạn mức giao dịch trong ngày.',
      '75': 'Ngân hàng thanh toán đang bảo trì.',
      '79': 'Giao dịch không thành công do: KH nhập sai mật khẩu thanh toán quá số lần quy định. Xin quý khách vui lòng thực hiện lại giao dịch',
      '99': 'Các lỗi khác (lỗi còn lại, không có trong danh sách mã lỗi đã liệt kê)',
    };
    
    return messages[responseCode] ?? 'Giao dịch không thành công. Mã lỗi: $responseCode';
  }
}

/// VNPay WebView Screen
class VNPayWebView extends StatefulWidget {
  final String paymentUrl;
  final Function(Map<String, String>) onPaymentSuccess;
  final Function(Map<String, String>) onPaymentError;

  const VNPayWebView({
    super.key,
    required this.paymentUrl,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<VNPayWebView> createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) {
            print('[DEBUG] Page started: $url');
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            print('[DEBUG] Page finished: $url');
            setState(() => _isLoading = false);
            
            // Inject JavaScript để fix lỗi timer
            _controller.runJavaScript('''
              try {
                if (typeof timer === 'undefined') {
                  window.timer = null;
                }
              } catch(e) {
                console.log('Timer fix applied');
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            print('[DEBUG] WebView error: ${error.description}');
            print('[DEBUG] Error type: ${error.errorType}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('[DEBUG] Navigation to: ${request.url}');
            
            // Kiểm tra URL return từ VNPay
            if (request.url.contains('vnpay-return') || 
                request.url.contains('vnp_ResponseCode')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handlePaymentResult(String url) {
    print('[DEBUG] Xử lý kết quả thanh toán từ URL: $url');
    
    try {
      final uri = Uri.parse(url);
      final params = <String, String>{};
      
      uri.queryParameters.forEach((key, value) {
        params[key] = value;
      });
      
      print('[DEBUG] Payment result params: $params');
      
      // Xác thực secure hash nếu có
      final receivedHash = params['vnp_SecureHash'];
      if (receivedHash != null && receivedHash.isNotEmpty) {
        final isValid = VNPayService.verifySecureHash(params, receivedHash);
        print('[DEBUG] Hash verification: ${isValid ? "VALID" : "INVALID"}');
        
        if (!isValid) {
          widget.onPaymentError({
            'error': 'Invalid secure hash',
            'message': 'Chữ ký không hợp lệ'
          });
          Navigator.pop(context);
          return;
        }
      }
      
      // Kiểm tra kết quả thanh toán
      if (VNPayService.isPaymentSuccess(params)) {
        print('[DEBUG] Payment SUCCESS');
        widget.onPaymentSuccess(params);
      } else {
        print('[DEBUG] Payment FAILED');
        widget.onPaymentError(params);
      }
      
      Navigator.pop(context);
    } catch (e, stackTrace) {
      print('[DEBUG] Error handling payment result: $e');
      print('[DEBUG] Stack trace: $stackTrace');
      widget.onPaymentError({'error': e.toString()});
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xác nhận'),
                content: const Text('Bạn có chắc muốn hủy thanh toán?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Không'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      widget.onPaymentError({
                        'vnp_ResponseCode': '24',
                        'error': 'User cancelled'
                      });
                      Navigator.pop(context); // Close WebView
                    },
                    child: const Text('Có'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải trang thanh toán...',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}