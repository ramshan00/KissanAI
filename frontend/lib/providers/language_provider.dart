import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isUrdu => _locale.languageCode == 'ur';
  bool get isInitialized => _isInitialized;

  TextDirection get textDirection =>
      isUrdu ? TextDirection.rtl : TextDirection.ltr;

  LanguageProvider() {
    _loadLangPreference();
  }

  Future<void> _loadLangPreference() async {
    try {
      final file = await _getPrefFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final code = content.trim();
        if (code == 'ur') {
          _locale = const Locale('ur');
        } else {
          _locale = const Locale('en');
        }
      }
    } catch (e) {
      debugPrint("Error loading language preference: $e");
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    if (isUrdu) {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('ur');
    }
    notifyListeners();
    await _saveLangPreference();
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    notifyListeners();
    await _saveLangPreference();
  }

  Future<void> _saveLangPreference() async {
    try {
      final file = await _getPrefFile();
      await file.writeAsString(_locale.languageCode);
    } catch (e) {
      debugPrint("Error saving language preference: $e");
    }
  }

  Future<File> _getPrefFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/kissan_lang.txt');
  }

  // Translation Helper Dictionary
  final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome_to_kissan': 'Welcome to KissanAI',
      'welcome_sub': 'AI-Orchestrated Pakistani Agricultural Marketplace',
      'login': 'Login',
      'signup': 'Sign Up',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'enter_phone': 'Enter Phone Number',
      'role': 'Role',
      'farmer': 'Farmer',
      'provider': 'Provider',
      'login_btn': 'Login / Enter Hub',
      'signup_btn': 'Sign Up & Enter Hub',
      'onboarding_1_title': 'AI Agent Smart Match',
      'onboarding_1_body': 'Matched with tractor operators in under 3 minutes.',
      'onboarding_2_title': 'Save 30% on Tractors',
      'onboarding_2_body': 'Rent any tractor this weekend to save big on plowing.',
      'onboarding_3_title': 'Speak & Book Instantly',
      'onboarding_3_body': 'Simply tap the microphone and speak in Roman Urdu or English.',
      'next': 'Next',
      'get_started': 'Get Started',
      'skip': 'Skip',
      'assalamu_alaikum': 'Assalamu Alaikum,',
      'voice_match': 'Voice Match Heavy Machinery',
      'tap_to_speak': 'Tap to speak in Urdu or Roman Urdu',
      'rent_tractor': 'Rent Tractor',
      'tractor_desc': 'Modern plowing machinery',
      'match_harvester': 'Match Harvester',
      'harvester_desc': 'High-efficiency crop reaping',
      'rent_thresher': 'Rent Thresher',
      'thresher_desc': 'Fast Crop threshing services',
      'book_seeder': 'Book Seeder',
      'seeder_desc': 'Precise crop seed sowing',
      'recent_bookings': 'Recent Bookings',
      'no_bookings': 'No recent bookings found.',
      'urgency': 'urgency',
      'details': 'Details',
      'dispute': 'Dispute',
      'home': 'Home',
      'bookings_tab': 'Bookings',
      'settle_broker': 'Settle Broker',
      'profile': 'Profile',
      'gps_tracking': 'GPS Tracking',
      'working_location': 'Working Location:',
      'booking_urgency': 'Booking Urgency:',
      'scheduled_slot': 'Scheduled Slot:',
      'total_price': 'Total Confirmed Price:',
      'got_it': 'Got it',
      'availability_status': 'Availability Status',
      'active_on_matches': 'Active on matches',
      'marked_as_busy': 'Marked as Busy',
      'settle_negotiations': 'Active ResolveAI Settle Broker',
      'select_dispute': 'Select a recent booking dispute to broker resolution.',
      'execute_settle': 'Execute ResolveAI Settle Broker',
      'settlement_logs': 'ResolveAI Settlement reasoning logs',
      'phone_error': 'Please enter a valid phone number.',
      'name_error': 'Please enter your name.',
      'auth_failed': 'Authentication Failed',
    },
    'ur': {
      'welcome_to_kissan': 'کِسان اے آئی میں خوش آمدید',
      'welcome_sub': 'اے آئی سے چلنے والی پاکستان کی زرعی مارکیٹ',
      'login': 'لاگ ان',
      'signup': 'سائن اپ',
      'full_name': 'پورا نام',
      'phone_number': 'فون نمبر',
      'enter_phone': 'فون نمبر درج کریں',
      'role': 'کردار',
      'farmer': 'کِسان',
      'provider': 'سروس فراہم کنندہ',
      'login_btn': 'لاگ ان کریں / آگے بڑھیں',
      'signup_btn': 'سائن اپ کریں اور آگے بڑھیں',
      'onboarding_1_title': 'اے آئی اسمارٹ میچ',
      'onboarding_1_body': '۳ منٹ کے اندر ٹریکٹر آپریٹرز سے خودکار میچنگ۔',
      'onboarding_2_title': 'ٹریکٹر پر ۳۰٪ بچت کریں',
      'onboarding_2_body': 'اس ہفتے کے آخر میں ٹریکٹر کرائے پر لیں اور زبردست بچت کریں۔',
      'onboarding_3_title': 'بولیں اور فوراً بک کریں',
      'onboarding_3_body': 'مائیک کو دبائیں اور اردو یا رومن اردو میں بول کر بکنگ کریں۔',
      'next': 'اگلا',
      'get_started': 'شروع کریں',
      'skip': 'چھوڑیں',
      'assalamu_alaikum': 'السلام علیکم،',
      'voice_match': 'آواز سے ہیوی مشینری بک کریں',
      'tap_to_speak': 'آواز یا نیت کی تفہیم کے لیے مائیک دبائیں',
      'rent_tractor': 'ٹریکٹر کرایہ پر لیں',
      'tractor_desc': 'جدید ہل چلانے کی مشینری',
      'match_harvester': 'ہارویسٹر تلاش کریں',
      'harvester_desc': 'فصل کی کٹائی کے لیے بہترین',
      'rent_thresher': 'تھریشر کرایہ پر لیں',
      'thresher_desc': 'فصل کی گہائی کی تیز سروسز',
      'book_seeder': 'سیڈر بک کریں',
      'seeder_desc': 'بیج بونے کی جدید مشین',
      'recent_bookings': 'حالیہ بکنگز',
      'no_bookings': 'کوئی حالیہ بکنگ نہیں ملی۔',
      'urgency': 'ضرورت',
      'details': 'تفصیلات',
      'dispute': 'شکایت',
      'home': 'ہوم',
      'bookings_tab': 'میری بکنگز',
      'settle_broker': 'فیصلہ پینل',
      'profile': 'پروفائل',
      'gps_tracking': 'جی پی ایس ٹریکنگ',
      'working_location': 'کام کی جگہ:',
      'booking_urgency': 'بکنگ کی ضرورت:',
      'scheduled_slot': 'مقررہ تاریخ:',
      'total_price': 'طے شدہ کل رقم:',
      'got_it': 'ٹھیک ہے',
      'availability_status': 'دستیابی کی صورتحال',
      'active_on_matches': 'کام کے لیے دستیاب',
      'marked_as_busy': 'مصروف',
      'settle_negotiations': 'مسئلہ حل کروانے والا پینل',
      'select_dispute': 'مسئلہ حل کروانے کے لیے بکنگ کا انتخاب کریں۔',
      'execute_settle': 'فیصلہ کروائیں (ResolveAI)',
      'settlement_logs': 'ResolveAI فیصلے کی تفصیلات',
      'phone_error': 'براہ کرم درست فون نمبر درج کریں۔',
      'name_error': 'براہ کرم اپنا نام درج کریں۔',
      'auth_failed': 'لاگ ان ناکام ہوا',
    }
  };

  String translate(String key) {
    if (_localizedValues[locale.languageCode] != null &&
        _localizedValues[locale.languageCode]![key] != null) {
      return _localizedValues[locale.languageCode]![key]!;
    }
    // fallback to English
    return _localizedValues['en']?[key] ?? key;
  }
}
