class AIRecommendationService {
  AIRecommendationService._();

  static const Map<String, List<String>> _pairings = {
    'Paneer Butter Masala': ['Butter Naan', 'Jeera Rice', 'Mango Lassi'],
    'Butter Chicken': ['Garlic Naan', 'Jeera Rice', 'Cold Coffee'],
    'Chicken Biryani': ['Mirchi Ka Salan', 'Raita', 'Coke'],
    'Margherita Pizza': ['Garlic Bread', 'Cheese Dip', 'Iced Tea'],
    'Veg Hakka Noodles': ['Manchurian Gravy', 'Spring Rolls', 'Chilli Chicken'],
  };

  /// Returns AI smart pairing suggestions for chosen menu item
  static List<String> getSmartPairings(String itemName) {
    for (final key in _pairings.keys) {
      if (key.toLowerCase() == itemName.toLowerCase() || itemName.toLowerCase().contains(key.toLowerCase())) {
        return _pairings[key]!;
      }
    }
    return ['Garlic Naan', 'Cold Coffee', 'Gulab Jamun'];
  }

  /// AI Sales & Demand Forecasting analytics data
  static Map<String, dynamic> getForecastAnalytics() {
    return {
      'predictedPeakHours': '8:00 PM - 10:30 PM',
      'forecastedRevenueGrowth': '+18.4% expected this weekend',
      'topPredictedDishes': [
        {'name': 'Paneer Butter Masala', 'demand': 'High (95% confidence)'},
        {'name': 'Butter Naan', 'demand': 'High (92% confidence)'},
        {'name': 'Chicken Biryani', 'demand': 'Moderate (85% confidence)'},
      ],
      'suggestedReorderItems': [
        {'item': 'Paneer / Cottage Cheese', 'quantity': '15 kg'},
        {'item': 'Amul Butter', 'quantity': '20 packs'},
        {'item': 'Basmati Rice', 'quantity': '25 kg'},
      ],
    };
  }
}
