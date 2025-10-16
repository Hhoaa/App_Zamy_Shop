import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/user_address.dart';
import '../../services/supabase_address_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class AddEditAddressScreen extends StatefulWidget {
  final UserAddress? address; // null nếu là thêm mới, có giá trị nếu là chỉnh sửa

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isDefault = false;
  String _addressType = 'home';
  int? _currentUserId;

  final List<Map<String, String>> _addressTypes = [
    {'value': 'home', 'label': 'Nhà riêng'},
    {'value': 'office', 'label': 'Văn phòng'},
    {'value': 'other', 'label': 'Khác'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    final user = await SupabaseAuthService.getCurrentUser();
    _currentUserId = user?.maNguoiDung;

    if (widget.address != null) {
      // Chỉnh sửa địa chỉ
      final address = widget.address!;
      _fullNameController.text = address.fullName;
      _phoneController.text = address.phone;
      _addressLine1Controller.text = address.addressLine1;
      _addressLine2Controller.text = address.addressLine2 ?? '';
      _wardController.text = address.ward ?? '';
      _districtController.text = address.district ?? '';
      _cityController.text = address.city;
      _postalCodeController.text = address.postalCode ?? '';
      _isDefault = address.isDefault;
      _addressType = address.addressType;
    } else {
      // Thêm địa chỉ mới - set mặc định nếu chưa có địa chỉ nào
      if (_currentUserId != null) {
        final hasAddresses = await SupabaseAddressService.hasAddresses(_currentUserId!);
        _isDefault = !hasAddresses;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: widget.address == null ? 'Thêm địa chỉ' : 'Chỉnh sửa địa chỉ',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin người nhận
              _buildSectionTitle('Thông tin người nhận'),
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _fullNameController,
                label: 'Họ và tên *',
                hint: 'Nhập họ và tên người nhận',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _phoneController,
                label: 'Số điện thoại *',
                hint: 'Nhập số điện thoại',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  final phoneRegex = RegExp(r'^[0-9\s\-\+\(\)]+$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Địa chỉ
              _buildSectionTitle('Địa chỉ'),
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _addressLine1Controller,
                label: 'Địa chỉ *',
                hint: 'Số nhà, tên đường',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _addressLine2Controller,
                label: 'Địa chỉ bổ sung',
                hint: 'Tòa nhà, căn hộ, số tầng...',
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _wardController,
                      label: 'Phường/Xã',
                      hint: 'Phường/Xã',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _districtController,
                      label: 'Quận/Huyện',
                      hint: 'Quận/Huyện',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      label: 'Tỉnh/Thành phố *',
                      hint: 'TP.HCM, Hà Nội...',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tỉnh/thành phố';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _postalCodeController,
                      label: 'Mã bưu điện',
                      hint: '700000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Loại địa chỉ
              _buildSectionTitle('Loại địa chỉ'),
              const SizedBox(height: 16),
              
              _buildAddressTypeSelector(),
              
              const SizedBox(height: 32),
              
              // Đặt làm mặc định
              if (widget.address == null || !widget.address!.isDefault)
                _buildDefaultAddressToggle(),
              
              const SizedBox(height: 40),
              
              // Nút lưu
              AppButton(
                text: widget.address == null ? 'Thêm địa chỉ' : 'Cập nhật địa chỉ',
                onPressed: _isLoading ? null : _saveAddress,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildAddressTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: _addressTypes.map((type) {
          final isSelected = _addressType == type['value'];
          return InkWell(
            onTap: () {
              setState(() {
                _addressType = type['value']!;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentRed.withOpacity(0.05) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      type['label']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.accentRed : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check,
                      color: AppColors.accentRed,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultAddressToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đặt làm địa chỉ mặc định',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Địa chỉ này sẽ được chọn mặc định khi đặt hàng',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDefault,
            onChanged: (value) {
              setState(() {
                _isDefault = value;
              });
            },
            activeColor: AppColors.accentRed,
          ),
        ],
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final address = UserAddress(
        id: widget.address?.id ?? 0,
        userId: _currentUserId!,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isEmpty 
            ? null 
            : _addressLine2Controller.text.trim(),
        ward: _wardController.text.trim().isEmpty 
            ? null 
            : _wardController.text.trim(),
        district: _districtController.text.trim().isEmpty 
            ? null 
            : _districtController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty 
            ? null 
            : _postalCodeController.text.trim(),
        isDefault: _isDefault,
        addressType: _addressType,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.address == null) {
        // Thêm mới
        await SupabaseAddressService.addAddress(address);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm địa chỉ thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Cập nhật
        await SupabaseAddressService.updateAddress(address);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật địa chỉ thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
