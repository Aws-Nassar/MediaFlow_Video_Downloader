import 'dart:ui';

import '../models/media_models.dart';

class AppStrings {
  final Locale locale;

  const AppStrings(this.locale);

  bool get isArabic => locale.languageCode == 'ar';

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  String _t(String key) {
    final language = _values[locale.languageCode] ?? _values['en']!;
    return language[key] ?? _values['en']![key] ?? key;
  }

  String get appName => _t('appName');
  String get appTagline => _t('appTagline');
  String get analyze => _t('analyze');
  String get queue => _t('queue');
  String get library => _t('library');
  String get settings => _t('settings');
  String get newDownload => _t('newDownload');
  String get pasteLink => _t('pasteLink');
  String get analyzeSubtitle => _t('analyzeSubtitle');
  String get urlHint => _t('urlHint');
  String get video => _t('video');
  String get audio => _t('audio');
  String get download => _t('download');
  String get analyzing => _t('analyzing');
  String get enterAtLeastOneLink => _t('enterAtLeastOneLink');
  String get supportedSources => _t('supportedSources');
  String get paste => _t('paste');
  String get clear => _t('clear');
  String get demoLinks => _t('demoLinks');
  String get active => _t('active');
  String get needsAttention => _t('needsAttention');
  String get recent => _t('recent');
  String get nothingDownloading => _t('nothingDownloading');
  String get nothingDownloadingBody => _t('nothingDownloadingBody');
  String get noLibrary => _t('noLibrary');
  String get noLibraryBody => _t('noLibraryBody');
  String get search => _t('search');
  String get searchHint => _t('searchHint');
  String get outputFolder => _t('outputFolder');
  String get outputFolderHint => _t('outputFolderHint');
  String get concurrency => _t('concurrency');
  String get concurrencyHint => _t('concurrencyHint');
  String get theme => _t('theme');
  String get language => _t('language');
  String get dark => _t('dark');
  String get light => _t('light');
  String get oled => _t('oled');
  String get system => _t('system');
  String get about => _t('about');
  String get driveTitle => _t('driveTitle');
  String get driveBody => _t('driveBody');
  String get driveNoAccount => _t('driveNoAccount');
  String get driveNoButton => _t('driveNoButton');
  String get driveRestricted => _t('driveRestricted');
  String get legalNote => _t('legalNote');
  String get retry => _t('retry');
  String get retryFailed => _t('retryFailed');
  String get copyLink => _t('copyLink');
  String get copyFailedLinks => _t('copyFailedLinks');
  String get openInBrowser => _t('openInBrowser');
  String get remove => _t('remove');
  String get cancel => _t('cancel');
  String get details => _t('details');
  String get dismiss => _t('dismiss');
  String get batchFinished => _t('batchFinished');
  String get batchWithIssues => _t('batchWithIssues');
  String get batchFinishedBody => _t('batchFinishedBody');
  String get downloaded => _t('downloaded');
  String get failed => _t('failed');
  String get skipped => _t('skipped');
  String get cancelled => _t('cancelled');
  String get completed => _t('completed');
  String get totalSize => _t('totalSize');
  String get elapsed => _t('elapsed');
  String get items => _t('items');
  String get downloadComplete => _t('downloadComplete');
  String get downloadCompleteBody => _t('downloadCompleteBody');
  String get openLibrary => _t('openLibrary');
  String get fileActionsLater => _t('fileActionsLater');
  String get linkCopied => _t('linkCopied');
  String get failedLinksCopied => _t('failedLinksCopied');
  String get addedToQueue => _t('addedToQueue');
  String get engineLabel => _t('engineLabel');
  String get phaseLabel => _t('phaseLabel');
  String get noFailures => _t('noFailures');
  String get item => _t('item');
  String get source => _t('source');
  String get link => _t('link');
  String get error => _t('error');
  String get technicalDetails => _t('technicalDetails');
  String get close => _t('close');
  String get removeFromLibrary => _t('removeFromLibrary');
  String get removeFromLibraryBody => _t('removeFromLibraryBody');
  String get removeConfirm => _t('removeConfirm');
  String get keep => _t('keep');
  String get settingsAppearance => _t('settingsAppearance');
  String get settingsDownloads => _t('settingsDownloads');
  String get settingsDrive => _t('settingsDrive');
  String get settingsAbout => _t('settingsAbout');
  String get version => _t('version');
  String get fakeEngine => _t('fakeEngine');
  String get noTelemetry => _t('noTelemetry');
  String get batchSummary => _t('batchSummary');
  String get retryOnlyFailed => _t('retryOnlyFailed');
  String get all => _t('all');
  String get list => _t('list');
  String get grid => _t('grid');
  String get removeJob => _t('removeJob');
  String get linkCopiedShort => _t('linkCopiedShort');
  String get copy => _t('copy');
  String get closeShort => _t('closeShort');
  String get showDetails => _t('showDetails');
  String get hideDetails => _t('hideDetails');
  String get sourceUnknown => _t('sourceUnknown');
  String get sourceDrive => _t('sourceDrive');
  String get sourceDirect => _t('sourceDirect');
  String get sourceGeneric => _t('sourceGeneric');
  String get demoHint => _t('demoHint');
  String get openQueue => _t('openQueue');
  String get save => _t('save');
  String get saved => _t('saved');

  String statusLabel(JobStatus status) => _t('status_${status.name}');

  String errorMessage(MediaFlowErrorCode code) => _t('error_${code.name}');

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appName': 'MediaFlow',
      'appTagline': 'Local-first media downloader',
      'analyze': 'Analyze',
      'queue': 'Queue',
      'library': 'Library',
      'settings': 'Settings',
      'newDownload': 'New download',
      'pasteLink': 'Paste a link',
      'analyzeSubtitle':
          'Paste a video, audio, or link-shared Drive folder. One link per line for a batch.',
      'urlHint': 'https://...',
      'video': 'Video',
      'audio': 'Audio',
      'download': 'Download',
      'analyzing': 'Analyzing…',
      'enterAtLeastOneLink': 'Enter at least one link.',
      'supportedSources': 'Supported sources',
      'paste': 'Paste',
      'clear': 'Clear',
      'demoLinks': 'Try a demo batch',
      'active': 'active',
      'needsAttention': 'Needs attention',
      'recent': 'Recent',
      'nothingDownloading': 'Nothing downloading',
      'nothingDownloadingBody':
          'Paste a link to start. Failed items will stay here with a retry action.',
      'noLibrary': 'No downloads yet',
      'noLibraryBody': 'Completed downloads will appear here.',
      'search': 'Search',
      'searchHint': 'Search title, source, or link',
      'outputFolder': 'Output folder',
      'outputFolderHint': 'Downloads/MediaFlow',
      'concurrency': 'Concurrent downloads',
      'concurrencyHint': 'Lower this if a site rate-limits you.',
      'theme': 'Theme',
      'language': 'Language',
      'dark': 'Dark',
      'light': 'Light',
      'oled': 'OLED',
      'system': 'System',
      'about': 'About',
      'driveTitle': 'Google Drive',
      'driveBody':
          'Link-shared files and folders work without a Google account. The app reads the shared folder and downloads each file directly.',
      'driveNoAccount': 'No Google sign-in, OAuth, or API key is used.',
      'driveNoButton':
          'A missing download button is not a block; the app still downloads the files.',
      'driveRestricted':
          'If a file needs sign-in or the owner disabled downloads, it is skipped and reported. It is not bypassed.',
      'legalNote':
          'Download only content you have the right to download. Respect site terms and copyright.',
      'retry': 'Retry',
      'retryFailed': 'Retry failed',
      'copyLink': 'Copy link',
      'copyFailedLinks': 'Copy failed links',
      'openInBrowser': 'Open in browser',
      'remove': 'Remove',
      'cancel': 'Cancel',
      'details': 'Details',
      'dismiss': 'Dismiss',
      'batchFinished': 'Batch finished',
      'batchWithIssues': 'Batch finished with issues',
      'batchFinishedBody': 'The rest of the batch kept going.',
      'downloaded': 'downloaded',
      'failed': 'failed',
      'skipped': 'skipped',
      'cancelled': 'cancelled',
      'completed': 'completed',
      'totalSize': 'Total size',
      'elapsed': 'Elapsed',
      'items': 'items',
      'downloadComplete': 'Download complete',
      'downloadCompleteBody': 'The file is ready in your library.',
      'openLibrary': 'Open library',
      'fileActionsLater':
          'Open and share will be enabled when the download engine is wired.',
      'linkCopied': 'Link copied.',
      'failedLinksCopied': 'Failed links copied.',
      'addedToQueue': 'Added to the queue.',
      'engineLabel': 'Engine',
      'phaseLabel': 'Phase',
      'noFailures': 'No failures',
      'item': 'Item',
      'source': 'Source',
      'link': 'Link',
      'error': 'Error',
      'technicalDetails': 'Technical details',
      'close': 'Close',
      'removeFromLibrary': 'Remove from library',
      'removeFromLibraryBody':
          'This removes the entry from MediaFlow. It does not delete the file from disk.',
      'removeConfirm': 'Remove entry',
      'keep': 'Keep',
      'settingsAppearance': 'Appearance',
      'settingsDownloads': 'Downloads',
      'settingsDrive': 'Google Drive',
      'settingsAbout': 'About',
      'version': 'Version',
      'fakeEngine': 'Fake engine (Phase 2 scaffold)',
      'noTelemetry': 'No telemetry by default. No account required.',
      'batchSummary': 'Batch summary',
      'retryOnlyFailed': 'Only failed items are retried.',
      'all': 'All',
      'list': 'List',
      'grid': 'Grid',
      'removeJob': 'Remove job',
      'linkCopiedShort': 'Copied',
      'copy': 'Copy',
      'closeShort': 'Close',
      'showDetails': 'Show details',
      'hideDetails': 'Hide details',
      'sourceUnknown': 'Unknown source',
      'sourceDrive': 'Google Drive',
      'sourceDirect': 'Direct link',
      'sourceGeneric': 'Supported link',
      'demoHint':
          'Demo batch: one success, one login error, and a mixed Drive folder.',
      'openQueue': 'Open queue',
      'save': 'Save',
      'saved': 'Saved.',
      'status_queued': 'Queued',
      'status_probing': 'Analyzing',
      'status_downloading': 'Downloading',
      'status_processing': 'Processing',
      'status_completed': 'Completed',
      'status_failed': 'Failed',
      'status_skipped': 'Skipped',
      'status_cancelled': 'Cancelled',
      'error_invalidUrl': 'The link is invalid.',
      'error_unsupportedUrl': 'This link is not supported yet.',
      'error_loginRequired':
          'This item needs sign-in. Add cookies or open it in your browser.',
      'error_cookiesExpired': 'Your cookies expired. Update them and retry.',
      'error_permissionDenied':
          'This account does not have access to this item.',
      'error_downloadRestricted': 'The owner disabled downloads for this file.',
      'error_policyBlocked': "Your organization's policy blocks this file.",
      'error_drmProtected':
          'This content is protected and cannot be downloaded.',
      'error_paywalled': 'This content is behind a paywall.',
      'error_geoBlocked': 'This content is not available in your region.',
      'error_rateLimited': 'The site is limiting downloads. Try again later.',
      'error_quotaExceeded':
          'Google Drive is temporarily limiting this file. Try again later.',
      'error_notFound': 'The link is invalid or the item was removed.',
      'error_emptyCollection': 'This folder has no downloadable files.',
      'error_formatUnavailable':
          'No downloadable format is available for this item.',
      'error_liveUnavailable':
          'This live stream is not available for recording.',
      'error_driveLayoutChanged':
          'The Drive folder layout changed and could not be read.',
      'error_zipFailed': 'The ZIP could not be created.',
      'error_diskFull':
          'Not enough disk space. Free space or change the folder.',
      'error_network':
          'The connection was interrupted. Retry when you are back online.',
      'error_engineMissing': 'The download engine is not available.',
      'error_ffmpegMissing':
          'FFmpeg is missing, so this format cannot be processed.',
      'error_cancelled': 'Cancelled.',
      'error_unknown': 'Something unexpected happened.',
    },
    'ar': {
      'appName': 'ميديا فلو',
      'appTagline': 'تنزيل وسائط محلي أولًا',
      'analyze': 'تحليل',
      'queue': 'قائمة الانتظار',
      'library': 'المكتبة',
      'settings': 'الإعدادات',
      'newDownload': 'تنزيل جديد',
      'pasteLink': 'الصق رابطًا',
      'analyzeSubtitle':
          'الصق رابط فيديو أو صوت أو مجلد Drive مشترك. رابط واحد في كل سطر للدفعات.',
      'urlHint': 'https://...',
      'video': 'فيديو',
      'audio': 'صوت',
      'download': 'تنزيل',
      'analyzing': 'جارٍ التحليل…',
      'enterAtLeastOneLink': 'أدخل رابطًا واحدًا على الأقل.',
      'supportedSources': 'المصادر المدعومة',
      'paste': 'لصق',
      'clear': 'مسح',
      'demoLinks': 'جرّب دفعة تجريبية',
      'active': 'نشط',
      'needsAttention': 'يحتاج إلى انتباه',
      'recent': 'الأحدث',
      'nothingDownloading': 'لا يوجد شيء قيد التنزيل',
      'nothingDownloadingBody':
          'الصق رابطًا للبدء. ستبقى العناصر الفاشلة هنا مع زر لإعادة المحاولة.',
      'noLibrary': 'لا توجد تنزيلات بعد',
      'noLibraryBody': 'ستظهر التنزيلات المكتملة هنا.',
      'search': 'بحث',
      'searchHint': 'ابحث في العنوان أو المصدر أو الرابط',
      'outputFolder': 'مجلد الحفظ',
      'outputFolderHint': 'Downloads/MediaFlow',
      'concurrency': 'التنزيلات المتزامنة',
      'concurrencyHint': 'خفّض العدد إذا كان الموقع يحدّ من التنزيلات.',
      'theme': 'المظهر',
      'language': 'اللغة',
      'dark': 'داكن',
      'light': 'فاتح',
      'oled': 'OLED',
      'system': 'النظام',
      'about': 'حول',
      'driveTitle': 'Google Drive',
      'driveBody':
          'تعمل الملفات والمجلدات المشتركة عبر الرابط دون حساب Google. يقرأ التطبيق المجلد المشترك وينزّل كل ملف مباشرة.',
      'driveNoAccount':
          'لا يتم استخدام تسجيل دخول Google أو OAuth أو مفتاح API.',
      'driveNoButton':
          'غياب زر التنزيل ليس حظرًا؛ ما زال التطبيق ينزّل الملفات.',
      'driveRestricted':
          'إذا كان الملف يتطلب تسجيل الدخول أو أوقف المالك التنزيل، فسيتم تخطيه وإخبارك بالسبب. لا يتم تجاوز القيود.',
      'legalNote':
          'نزّل فقط المحتوى الذي تملك حق تنزيله. احترم شروط المواقع وحقوق النشر.',
      'retry': 'إعادة المحاولة',
      'retryFailed': 'إعادة محاولة الفاشلة',
      'copyLink': 'نسخ الرابط',
      'copyFailedLinks': 'نسخ روابط الفاشلة',
      'openInBrowser': 'فتح في المتصفح',
      'remove': 'إزالة',
      'cancel': 'إلغاء',
      'details': 'التفاصيل',
      'dismiss': 'إغلاق',
      'batchFinished': 'انتهت الدفعة',
      'batchWithIssues': 'انتهت الدفعة مع مشكلات',
      'batchFinishedBody': 'استمر باقي الدفعة في العمل.',
      'downloaded': 'تم تنزيله',
      'failed': 'فشل',
      'skipped': 'تم تخطيه',
      'cancelled': 'ملغى',
      'completed': 'مكتمل',
      'totalSize': 'الحجم الإجمالي',
      'elapsed': 'الوقت',
      'items': 'عناصر',
      'downloadComplete': 'اكتمل التنزيل',
      'downloadCompleteBody': 'الملف جاهز في المكتبة.',
      'openLibrary': 'فتح المكتبة',
      'fileActionsLater': 'سيتم تفعيل فتح الملف ومشاركته بعد ربط محرك التنزيل.',
      'linkCopied': 'تم نسخ الرابط.',
      'failedLinksCopied': 'تم نسخ روابط العناصر الفاشلة.',
      'addedToQueue': 'تمت الإضافة إلى قائمة الانتظار.',
      'engineLabel': 'المحرك',
      'phaseLabel': 'المرحلة',
      'noFailures': 'لا توجد إخفاقات',
      'item': 'عنصر',
      'source': 'المصدر',
      'link': 'الرابط',
      'error': 'الخطأ',
      'technicalDetails': 'تفاصيل تقنية',
      'close': 'إغلاق',
      'removeFromLibrary': 'إزالة من المكتبة',
      'removeFromLibraryBody':
          'يزيل هذا الإدخال من ميديا فلو، ولا يحذف الملف من القرص.',
      'removeConfirm': 'إزالة الإدخال',
      'keep': 'إبقاء',
      'settingsAppearance': 'المظهر',
      'settingsDownloads': 'التنزيلات',
      'settingsDrive': 'Google Drive',
      'settingsAbout': 'حول',
      'version': 'الإصدار',
      'fakeEngine': 'محرك تجريبي (هيكل المرحلة 2)',
      'noTelemetry': 'لا توجد قياسات عن بُعد افتراضيًا. لا حاجة إلى حساب.',
      'batchSummary': 'ملخص الدفعة',
      'retryOnlyFailed': 'تتم إعادة محاولة العناصر الفاشلة فقط.',
      'all': 'الكل',
      'list': 'قائمة',
      'grid': 'شبكة',
      'removeJob': 'إزالة المهمة',
      'linkCopiedShort': 'تم النسخ',
      'copy': 'نسخ',
      'closeShort': 'إغلاق',
      'showDetails': 'إظهار التفاصيل',
      'hideDetails': 'إخفاء التفاصيل',
      'sourceUnknown': 'مصدر غير معروف',
      'sourceDrive': 'Google Drive',
      'sourceDirect': 'رابط مباشر',
      'sourceGeneric': 'رابط مدعوم',
      'demoHint':
          'دفعة تجريبية: نجاح واحد، وخطأ تسجيل دخول، ومجلد Drive مختلط.',
      'openQueue': 'فتح قائمة الانتظار',
      'save': 'حفظ',
      'saved': 'تم الحفظ.',
      'status_queued': 'في الانتظار',
      'status_probing': 'جارٍ التحليل',
      'status_downloading': 'جارٍ التنزيل',
      'status_processing': 'جارٍ المعالجة',
      'status_completed': 'مكتمل',
      'status_failed': 'فشل',
      'status_skipped': 'تم تخطيه',
      'status_cancelled': 'ملغى',
      'error_invalidUrl': 'الرابط غير صالح.',
      'error_unsupportedUrl': 'هذا الرابط غير مدعوم بعد.',
      'error_loginRequired':
          'هذا العنصر يحتاج إلى تسجيل الدخول. أضف ملفات تعريف الارتباط أو افتحه في المتصفح.',
      'error_cookiesExpired':
          'انتهت صلاحية ملفات تعريف الارتباط. حدّثها ثم أعد المحاولة.',
      'error_permissionDenied':
          'لا يملك هذا الحساب إذنًا للوصول إلى هذا العنصر.',
      'error_downloadRestricted': 'أوقف المالك التنزيل لهذا الملف.',
      'error_policyBlocked': 'سياسة مؤسستك تمنع هذا الملف.',
      'error_drmProtected': 'هذا المحتوى محمي ولا يمكن تنزيله.',
      'error_paywalled': 'هذا المحتوى خلف جدار دفع.',
      'error_geoBlocked': 'هذا المحتوى غير متاح في منطقتك.',
      'error_rateLimited': 'الموقع يحدّ من التنزيلات. أعد المحاولة لاحقًا.',
      'error_quotaExceeded':
          'Google Drive يحدّ مؤقتًا من هذا الملف. أعد المحاولة لاحقًا.',
      'error_notFound': 'الرابط غير صالح أو تم حذف العنصر.',
      'error_emptyCollection': 'لا يحتوي هذا المجلد على ملفات قابلة للتنزيل.',
      'error_formatUnavailable': 'لا يوجد تنسيق قابل للتنزيل لهذا العنصر.',
      'error_liveUnavailable': 'هذا البث المباشر غير متاح للتسجيل.',
      'error_driveLayoutChanged': 'تغيّر تخطيط مجلد Drive وتعذّرت قراءته.',
      'error_zipFailed': 'تعذّر إنشاء ملف ZIP.',
      'error_diskFull': 'لا توجد مساحة كافية. أفرغ مساحة أو غيّر المجلد.',
      'error_network': 'انقطع الاتصال. أعد المحاولة عند عودة الشبكة.',
      'error_engineMissing': 'محرك التنزيل غير متوفر.',
      'error_ffmpegMissing':
          'FFmpeg غير متوفر، لذا لا يمكن معالجة هذا التنسيق.',
      'error_cancelled': 'تم الإلغاء.',
      'error_unknown': 'حدث خطأ غير متوقع.',
    },
  };
}
