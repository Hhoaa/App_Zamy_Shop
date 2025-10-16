import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/store_location.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';

class FreeStoreInfoScreen extends StatefulWidget {
  const FreeStoreInfoScreen({super.key});

  @override
  State<FreeStoreInfoScreen> createState() => _FreeStoreInfoScreenState();
}

class _FreeStoreInfoScreenState extends State<FreeStoreInfoScreen> {
  MapController _mapController = MapController();
  StoreLocation? _selectedStore;

  @override
  void initState() {
    super.initState();
    _selectedStore = StoreLocation.stores.first;
  }

  void _goToStore(StoreLocation store) {
    _mapController.move(
      LatLng(store.latitude, store.longitude),
      16.0,
    );
    setState(() {
      _selectedStore = store;
    });
  }

  Future<void> _openDirections(StoreLocation store) async {
    final lat = store.latitude;
    final lng = store.longitude;
    
    // Mở Google Maps web trực tiếp
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở Google Maps. Vui lòng kiểm tra kết nối internet.'),
          ),
        );
      }
    }
  }

  Future<void> _callStore(StoreLocation store) async {
    final url = 'tel:${store.phone}';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thực hiện cuộc gọi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Thông tin cửa hàng',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Move to center of all stores
              _mapController.move(
                const LatLng(21.0285, 105.8542), // Center of Hanoi
                12.0,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: const LatLng(21.0285, 105.8542), // Center of Hanoi
                    zoom: 12.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    // OpenStreetMap tiles (completely free)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.zamyshop.app',
                    ),
                    // Store markers
                    MarkerLayer(
                      markers: StoreLocation.stores.map((store) {
                        final isSelected = _selectedStore?.id == store.id;
                        return Marker(
                          point: LatLng(store.latitude, store.longitude),
                          width: isSelected ? 50 : 40,
                          height: isSelected ? 50 : 40,
                          child: GestureDetector(
                            onTap: () => _goToStore(store),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.accentRed : AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: isSelected ? 6 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.store,
                                color: Colors.white,
                                size: isSelected ? 24 : 20,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Store List Section
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Danh sách cửa hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: StoreLocation.stores.length,
                      itemBuilder: (context, index) {
                        final store = StoreLocation.stores[index];
                        final isSelected = _selectedStore?.id == store.id;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentRed.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.accentRed : AppColors.borderLight,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              store.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.accentRed : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.address,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: AppColors.textLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      store.hours,
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.directions),
                                  onPressed: () => _openDirections(store),
                                  tooltip: 'Chỉ đường',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone),
                                  onPressed: () => _callStore(store),
                                  tooltip: 'Gọi điện',
                                ),
                              ],
                            ),
                            onTap: () => _goToStore(store),
                          ),
                        );
                      },
                    ),
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