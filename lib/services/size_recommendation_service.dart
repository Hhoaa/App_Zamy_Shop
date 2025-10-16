class SizeRecommendationService {
  // Bảng size guide dựa trên số đo
  static const Map<String, Map<String, dynamic>> sizeGuide = {
    'S': {
      'chest': {'min': 82, 'max': 85},
      'waist': {'min': 64, 'max': 66},
      'hip': {'min': 90, 'max': 92},
      'weight': {'min': 42, 'max': 47},
    },
    'M': {
      'chest': {'min': 86, 'max': 89},
      'waist': {'min': 67, 'max': 70},
      'hip': {'min': 93, 'max': 96},
      'weight': {'min': 48, 'max': 53},
    },
    'L': {
      'chest': {'min': 90, 'max': 93},
      'waist': {'min': 71, 'max': 74},
      'hip': {'min': 97, 'max': 100},
      'weight': {'min': 54, 'max': 59},
    },
    'XL': {
      'chest': {'min': 94, 'max': 97},
      'waist': {'min': 75, 'max': 78},
      'hip': {'min': 101, 'max': 104},
      'weight': {'min': 60, 'max': 65},
    },
  };

  // Gợi ý size dựa trên số đo
  static String? recommendSize({
    required double chest,
    required double waist,
    required double hip,
    required double weight,
  }) {
    // Tìm size phù hợp nhất
    String? bestSize;
    int bestScore = -1;

    for (final entry in sizeGuide.entries) {
      final size = entry.key;
      final measurements = entry.value;
      
      int score = 0;
      
      // Kiểm tra vòng ngực
      if (chest >= measurements['chest']!['min'] && 
          chest <= measurements['chest']!['max']) {
        score += 3;
      } else if (chest >= measurements['chest']!['min'] - 2 && 
                 chest <= measurements['chest']!['max'] + 2) {
        score += 1;
      }
      
      // Kiểm tra vòng eo
      if (waist >= measurements['waist']!['min'] && 
          waist <= measurements['waist']!['max']) {
        score += 3;
      } else if (waist >= measurements['waist']!['min'] - 2 && 
                 waist <= measurements['waist']!['max'] + 2) {
        score += 1;
      }
      
      // Kiểm tra vòng mông
      if (hip >= measurements['hip']!['min'] && 
          hip <= measurements['hip']!['max']) {
        score += 3;
      } else if (hip >= measurements['hip']!['min'] - 2 && 
                 hip <= measurements['hip']!['max'] + 2) {
        score += 1;
      }
      
      // Kiểm tra cân nặng
      if (weight >= measurements['weight']!['min'] && 
          weight <= measurements['weight']!['max']) {
        score += 2;
      } else if (weight >= measurements['weight']!['min'] - 3 && 
                 weight <= measurements['weight']!['max'] + 3) {
        score += 1;
      }
      
      if (score > bestScore) {
        bestScore = score;
        bestSize = size;
      }
    }
    
    // Chỉ trả về size nếu có ít nhất 3 điểm (một số đo phù hợp)
    return bestScore >= 3 ? bestSize : null;
  }

  // Lấy thông tin chi tiết về size
  static Map<String, dynamic>? getSizeInfo(String size) {
    return sizeGuide[size];
  }

  // Kiểm tra xem size có phù hợp không
  static bool isSizeFit({
    required String size,
    required double chest,
    required double waist,
    required double hip,
    required double weight,
  }) {
    final measurements = sizeGuide[size];
    if (measurements == null) return false;
    
    return chest >= measurements['chest']!['min'] && 
           chest <= measurements['chest']!['max'] &&
           waist >= measurements['waist']!['min'] && 
           waist <= measurements['waist']!['max'] &&
           hip >= measurements['hip']!['min'] && 
           hip <= measurements['hip']!['max'] &&
           weight >= measurements['weight']!['min'] && 
           weight <= measurements['weight']!['max'];
  }

  // Lấy danh sách tất cả size
  static List<String> getAllSizes() {
    return sizeGuide.keys.toList();
  }

  // Tạo thông báo gợi ý size
  static String createSizeRecommendationMessage({
    required double chest,
    required double waist,
    required double hip,
    required double weight,
  }) {
    final recommendedSize = recommendSize(
      chest: chest,
      waist: waist,
      hip: hip,
      weight: weight,
    );
    
    if (recommendedSize == null) {
      return 'Dựa trên số đo của bạn (Ngực: ${chest}cm, Eo: ${waist}cm, Mông: ${hip}cm, Cân nặng: ${weight}kg), chúng tôi khuyên bạn nên liên hệ trực tiếp để được tư vấn size phù hợp nhất.';
    }
    
    final sizeInfo = getSizeInfo(recommendedSize);
    return 'Dựa trên số đo của bạn (Ngực: ${chest}cm, Eo: ${waist}cm, Mông: ${hip}cm, Cân nặng: ${weight}kg), chúng tôi khuyên bạn nên chọn size **$recommendedSize**.\n\n'
           'Size $recommendedSize phù hợp với:\n'
           '• Vòng ngực: ${sizeInfo!['chest']!['min']}-${sizeInfo['chest']!['max']}cm\n'
           '• Vòng eo: ${sizeInfo['waist']!['min']}-${sizeInfo['waist']!['max']}cm\n'
           '• Vòng mông: ${sizeInfo['hip']!['min']}-${sizeInfo['hip']!['max']}cm\n'
           '• Cân nặng: ${sizeInfo['weight']!['min']}-${sizeInfo['weight']!['max']}kg';
  }
}
