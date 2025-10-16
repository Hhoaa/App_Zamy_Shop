import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/review.dart';
import '../../services/supabase_review_service.dart';
import 'review_item_widget.dart';

class ReviewsListWidget extends StatefulWidget {
  final int productId;
  final Function(Review)? onReply;

  const ReviewsListWidget({
    super.key, 
    required this.productId,
    this.onReply,
  });

  @override
  State<ReviewsListWidget> createState() => _ReviewsListWidgetState();
}

class _ReviewsListWidgetState extends State<ReviewsListWidget> {
  List<Review> _reviews = [];
  bool _isLoading = true;
  Map<String, dynamic> _reviewStats = {};
  int? _selectedRatingFilter;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews({int? ratingFilter}) async {
    try {
      setState(() => _isLoading = true);
      
      final reviews = await SupabaseReviewService.getProductReviews(
        widget.productId, 
        ratingFilter: ratingFilter,
      );
      final stats = await SupabaseReviewService.getProductReviewStats(widget.productId);
      
      setState(() {
        _reviews = reviews;
        _reviewStats = stats;
        _selectedRatingFilter = ratingFilter;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEE4D2D)),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with rating summary
          _buildHeader(),
          
          const SizedBox(height: 16),
          
          // Rating filter tabs
          _buildRatingFilterTabs(),
          
          const SizedBox(height: 4),
          
          // Reviews list or empty state
          if (_reviews.isEmpty)
            _buildEmptyState()
          else
            ..._reviews.map((review) => ReviewItemWidget(
              review: review,
              onReply: () => widget.onReply?.call(review),
            )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final averageRating = _reviewStats['averageRating'] ?? 0.0;
    final totalReviews = _reviewStats['totalReviews'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ĐÁNH GIÁ SẢN PHẨM',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF222222),
              letterSpacing: 0.5,
            ),
          ),
          
          if (totalReviews > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Rating score
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFEE4D2D),
                          ),
                        ),
                        const Text(
                          ' trên 5',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          color: index < averageRating.floor()
                              ? const Color(0xFFEE4D2D)
                              : const Color(0xFFD8D8D8),
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
                
                const SizedBox(width: 24),
                
                // Rating distribution - Ẩn khi có filter
                if (_selectedRatingFilter == null)
                  Expanded(
                    child: _buildRatingDistribution(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final totalReviews = _reviewStats['totalReviews'] ?? 0;
    final ratingDistribution = _reviewStats['ratingDistribution'] ?? {};

    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final count = ratingDistribution[rating] ?? 0;
        final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                '$rating',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star,
                color: Color(0xFFEE4D2D),
                size: 12,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEE4D2D),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRatingFilterTabs() {
    final ratingDistribution = _reviewStats['ratingDistribution'] ?? {};
    final totalReviews = _reviewStats['totalReviews'] ?? 0;
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterTab(
            label: 'Tất Cả',
            count: totalReviews,
            isSelected: _selectedRatingFilter == null,
            onTap: () => _loadReviews(),
          ),
          const SizedBox(width: 8),
          ...List.generate(5, (index) {
            final rating = 5 - index;
            final count = ratingDistribution[rating] ?? 0;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterTab(
                label: '$rating Sao',
                count: count,
                isSelected: _selectedRatingFilter == rating,
                onTap: () => _loadReviews(ratingFilter: rating),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEE4D2D).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFEE4D2D) : const Color(0xFFD8D8D8),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isSelected ? const Color(0xFFEE4D2D) : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có đánh giá',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}