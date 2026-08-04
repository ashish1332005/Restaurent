import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { english, hindi, hinglish }

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.english;

  void setLanguage(AppLanguage language) {
    state = language;
  }

  String translate(String key) {
    switch (state) {
      case AppLanguage.hindi:
        return _hindiTranslations[key] ?? key;
      case AppLanguage.hinglish:
        return _hinglishTranslations[key] ?? key;
      case AppLanguage.english:
        return _englishTranslations[key] ?? key;
    }
  }

  static const Map<String, String> _englishTranslations = {
    'admin_title': 'Restaurant Admin',
    'waiter_title': 'Waiter Dashboard',
    'kitchen_title': 'Kitchen Display System',
    'pos_title': 'Cashier POS & Billing',
    'add_employee': 'Add Employee',
    'take_order': 'Take Order',
    'send_to_kitchen': 'Send to Kitchen',
    'request_bill': 'Request Bill',
    'order_ready': 'Food Ready to Serve',
    'pay_subscription': 'Pay ₹500 & Activate Subscription',
  };

  static const Map<String, String> _hindiTranslations = {
    'admin_title': 'रेस्तरां एडमिन',
    'waiter_title': 'वेटर डैशबोर्ड',
    'kitchen_title': 'रसोई डिस्प्ले सिस्टम',
    'pos_title': 'कैशियर बिलिंग',
    'add_employee': 'कर्मचारी जोड़ें',
    'take_order': 'ऑर्डर लें',
    'send_to_kitchen': 'रसोई में भेजें',
    'request_bill': 'बिल का अनुरोध करें',
    'order_ready': 'खाना तैयार है',
    'pay_subscription': '₹500 दें और सब्सक्राइब करें',
  };

  static const Map<String, String> _hinglishTranslations = {
    'admin_title': 'Restaurant Owner Control',
    'waiter_title': 'Waiter Order Panel',
    'kitchen_title': 'Kitchen Order View',
    'pos_title': 'Cashier Counter Billing',
    'add_employee': 'Naya Staff Add Karo',
    'take_order': 'Customer Order Lo',
    'send_to_kitchen': 'Kitchen Me Bhejo',
    'request_bill': 'Bill Counter Ko Bhejo',
    'order_ready': 'Khana Serve Ke Liye Ready Hai',
    'pay_subscription': '₹500 Pay Karke Account Start Karo',
  };
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);
