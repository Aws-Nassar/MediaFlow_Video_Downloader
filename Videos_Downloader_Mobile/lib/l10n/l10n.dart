import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const localizationsDelegates = [
    _AppLocalizationsDelegate(),
  ];

  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  String get _languageCode => locale.languageCode;

  String tr(String key) {
    return _strings[_languageCode]?[key] ?? _strings['en']?[key] ?? key;
  }

  // Shorthand
  String call(String key) => tr(key);

  static final Map<String, Map<String, String>> _strings = {
    'en': {
      'appName': 'MediaFlow',
      'download': 'Download',
      'history': 'History',
      'settings': 'Settings',
      'urlHint': 'Enter video URL',
      'analyze': 'Analyze',
      'clear': 'Clear',
      'cancel': 'Cancel',
      'paste': 'Paste',
      'format': 'Format',
      'quality': 'Quality',
      'audioOnly': 'Audio only',
      'bestAvailable': 'Best Available',
      'bestAudio': 'Best',
      'downloadPath': 'Download path',
      'concurrentFragments': 'Concurrent fragments',
      'cookiesFile': 'Cookies file',
      'ffmpegEnabled': 'FFmpeg enabled',
      'selectCookies': 'Select cookies file',
      'selectPath': 'Select download path',
      'openDownloads': 'Open downloads folder',
      'theme': 'Theme',
      'dark': 'Dark',
      'light': 'Light',
      'oled': 'OLED Black',
      'language': 'Language',
      'english': 'English',
      'arabic': 'العربية',
      'about': 'About',
      'version': 'Version',
      'fetching': 'Fetching info...',
      'downloading': 'Downloading...',
      'completed': 'Completed',
      'error': 'Error',
      'cancelled': 'Cancelled',
      'idle': 'Ready',
      'noHistory': 'No downloads yet',
      'share': 'Share',
      'openFile': 'Open',
      'delete': 'Delete',
      'confirmDelete': 'Delete this item?',
      'confirmClearHistory': 'Clear all history?',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'save': 'Save',
      'selectExt': 'Select extension',
      'selectQuality': 'Select quality',
      'progressSpeed': 'Speed',
      'progressEta': 'ETA',
      'progressSize': 'Size',
      'progressPercent': 'Percent',
      'consoleLog': 'Console log',
      'ffmpegNotFound': 'FFmpeg not found',
      'ffmpegExtracting': 'Extracting FFmpeg...',
      'ffmpegReady': 'FFmpeg ready',
      'ffmpegFailed': 'FFmpeg extraction failed',
      'retry': 'Retry',
      'invalidUrl': 'Please enter a valid URL',
      'fetchError': 'Failed to fetch video info',
      'downloadSuccess': 'Download completed',
      'downloadError': 'Download failed',
      'appDescription': 'Video downloader powered by yt-dlp',
    },
    'ar': {
      'appName': 'MediaFlow',
      'download': 'تحميل',
      'history': 'السجل',
      'settings': 'الإعدادات',
      'urlHint': 'أدخل رابط الفيديو',
      'analyze': 'تحليل',
      'clear': 'مسح',
      'cancel': 'إلغاء',
      'paste': 'لصق',
      'format': 'الصيغة',
      'quality': 'الجودة',
      'audioOnly': 'صوت فقط',
      'bestAvailable': 'أفضل متاح',
      'bestAudio': 'أفضل',
      'downloadPath': 'مسار التحميل',
      'concurrentFragments': 'القطع المتزامنة',
      'cookiesFile': 'ملف الكوكيز',
      'ffmpegEnabled': 'FFmpeg مفعل',
      'selectCookies': 'اختيار ملف الكوكيز',
      'selectPath': 'اختيار مسار التحميل',
      'openDownloads': 'فتح مجلد التحميلات',
      'theme': 'المظهر',
      'dark': 'داكن',
      'light': 'فاتح',
      'oled': 'OLED أسود',
      'language': 'اللغة',
      'english': 'English',
      'arabic': 'العربية',
      'about': 'حول',
      'version': 'الإصدار',
      'fetching': 'جلب المعلومات...',
      'downloading': 'جارٍ التحميل...',
      'completed': 'مكتمل',
      'error': 'خطأ',
      'cancelled': 'ملغي',
      'idle': 'جاهز',
      'noHistory': 'لا توجد تحميلات سابقة',
      'share': 'مشاركة',
      'openFile': 'فتح',
      'delete': 'حذف',
      'confirmDelete': 'حذف هذا العنصر؟',
      'confirmClearHistory': 'مسح كل السجل؟',
      'yes': 'نعم',
      'no': 'لا',
      'ok': 'موافق',
      'save': 'حفظ',
      'selectExt': 'اختيار الصيغة',
      'selectQuality': 'اختيار الجودة',
      'progressSpeed': 'السرعة',
      'progressEta': 'الوقت المتبقي',
      'progressSize': 'الحجم',
      'progressPercent': 'النسبة',
      'consoleLog': 'سجل الأوامر',
      'ffmpegNotFound': 'FFmpeg غير موجود',
      'ffmpegExtracting': 'جاري استخراج FFmpeg...',
      'ffmpegReady': 'FFmpeg جاهز',
      'ffmpegFailed': 'فشل استخراج FFmpeg',
      'retry': 'إعادة المحاولة',
      'invalidUrl': 'الرجاء إدخال رابط صالح',
      'fetchError': 'فشل في جلب معلومات الفيديو',
      'downloadSuccess': 'اكتمل التحميل',
      'downloadError': 'فشل التحميل',
      'appDescription': 'برنامج تحميل الفيديو باستخدام yt-dlp',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
