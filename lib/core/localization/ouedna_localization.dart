import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  arabic,
  french,
  english;

  Locale get locale => switch (this) {
        AppLanguage.arabic => const Locale('ar'),
        AppLanguage.french => const Locale('fr'),
        AppLanguage.english => const Locale('en'),
      };

  bool get isRtl => this == AppLanguage.arabic;

  String get code => locale.languageCode;

  String get label => switch (this) {
        AppLanguage.arabic => 'العربية',
        AppLanguage.french => 'Français',
        AppLanguage.english => 'English',
      };

  TranslateLanguage get translationLanguage => switch (this) {
        AppLanguage.arabic => TranslateLanguage.arabic,
        AppLanguage.french => TranslateLanguage.french,
        AppLanguage.english => TranslateLanguage.english,
      };

  static AppLanguage fromCode(String? code) => switch (code) {
        'fr' => AppLanguage.french,
        'en' => AppLanguage.english,
        _ => AppLanguage.arabic,
      };
}

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._(this._preferences, this._language);

  static const _languageKey = 'ouedna_app_language';

  final SharedPreferences _preferences;
  AppLanguage _language;

  AppLanguage get language => _language;

  static Future<AppLanguageController> load(
      SharedPreferences preferences) async {
    return AppLanguageController._(
      preferences,
      AppLanguage.fromCode(preferences.getString(_languageKey)),
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    await _preferences.setString(_languageKey, language.code);
  }
}

class LanguageScope extends InheritedNotifier<AppLanguageController> {
  const LanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope is required above this widget.');
    return scope!.notifier!;
  }

  static AppLanguage languageOf(BuildContext context) =>
      controllerOf(context).language;
}

class OuednaStrings {
  const OuednaStrings._(this._language);

  final AppLanguage _language;

  static OuednaStrings of(BuildContext context) =>
      OuednaStrings._(LanguageScope.languageOf(context));

  String text(String key, {Map<String, String> values = const {}}) {
    var value =
        (_all[_language]?[key] ?? _all[AppLanguage.arabic]?[key] ?? key);
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  String get appName => text('app_name');

  static const _all = <AppLanguage, Map<String, String>>{
    AppLanguage.arabic: {
      'app_name': 'وادنا',
      'official_platform': 'المنصة السياحية الرسمية',
      'desert_heart': 'قلب الصحراء ينبض هنا',
      'welcome_intro':
          'مرحباً بك في وادنا، منصتك لاكتشاف كنوز وادي سوف. من القباب التاريخية إلى الواحات الخضراء وسط الرمال الذهبية، خطط لرحلتك واستكشف الأماكن التي تهمك.',
      'heritage_archive': 'أرشيف وذكريات وادي سوف التاريخية',
      'interactive_maps': 'خرائط تفاعلية ومسارات سياحية دقيقة',
      'start_exploring': 'ابدأ رحلة الاستكشاف',
      'enter_as_guest': 'دخول مباشر كزائر',
      'choose_language': 'اللغة',
      'settings': 'الإعدادات',
      'change_language': 'تغيير اللغة',
      'change_theme': 'تبديل المظهر',
      'privacy_policy': 'سياسة الخصوصية',
      'app_update': 'تحديث التطبيق',
      'update_available': 'يتوفر تحديث {version}',
      'update_description': 'يتوفر إصدار أحدث من وادنا لتحسين الأداء والأمان.',
      'later': 'لاحقاً',
      'view_update': 'عرض التحديث',
      'home': 'الرئيسية',
      'places': 'المعالم',
      'map': 'الخريطة',
      'favorites': 'المفضلة',
      'community': 'المجتمع',
      'discover_el_oued': 'اكتشف وادي سوف\nبعيون محلية',
      'start_your_journey': 'ابدأ رحلتك',
      'home_intro':
          'دليل سياحي عملي للمعالم، التجارب، والذاكرة المحلية في ولاية الوادي.',
      'explore_places': 'استكشف المعالم',
      'nearby_places': 'أماكن قريبة وتجارب موثوقة',
      'plan_route': 'خطط وصولك بسهولة',
      'suggest_place': 'اقترح معلماً جديداً',
      'suggest_place_info': 'أرسل المكان بالدبوس والصورة للمراجعة قبل النشر',
      'database_required': 'تتطلب هذه الخدمة اتصالاً بقاعدة البيانات',
      'my_itinerary': 'خط رحلتي',
      'my_itinerary_info': 'أنشئ برنامجاً حسب وقتك واهتماماتك',
      'emergency_help': 'مساعدة عاجلة',
      'emergency_help_info':
          'اتصال مباشر بالطوارئ ومشاركة موقع الضحية بموافقتك',
      'live_data_notice':
          'محتوى وادنا يتصل مباشرة بالبيانات المنشورة من لوحة الإدارة، لتبقى المعلومات محدثة للزوار.',
      'ouedna_map': 'خريطة وادنا',
      'published_places': '{count} معلم منشور',
      'standard_map': 'الخريطة العادية',
      'satellite_map': 'صور القمر الصناعي',
      'map_layer': 'طبقة الخريطة',
      'refresh': 'تحديث',
      'all': 'الكل',
      'my_location': 'موقعي الحالي',
      'map_center': 'مركز الخريطة',
      'details': 'تفاصيل',
      'start_journey': 'ابدأ الرحلة',
      'close': 'إغلاق',
      'no_coordinates':
          'لا توجد إحداثيات منشورة حالياً. ستظهر المعالم هنا بمجرد اعتمادها من لوحة الإدارة.',
      'map_load_error': 'تعذر تحميل الخريطة — إعادة المحاولة',
      'search_place': 'ابحث عن معلم أو مكان',
      'no_matching_places': 'لا توجد معالم منشورة مطابقة للبحث.',
      'places_load_error': 'تعذر تحميل المعالم حالياً.',
      'retry': 'إعادة المحاولة',
      'translation_loading': 'جارٍ الترجمة…',
      'translation_original': 'عرض النص الأصلي',
      'translation_error': 'تعذرت الترجمة الآن. يظهر النص الأصلي.',
      'location_service_disabled': 'خدمة تحديد الموقع غير مفعلة على الجهاز.',
      'page_load_error':
          'تعذر عرض هذه الصفحة حالياً. أغلق التطبيق وافتحه من جديد، ثم تحقق من اتصال الإنترنت.',
      'navigate_to_place': 'ابدأ الملاحة إلى المكان',
      'in_app_navigation': 'الملاحة داخل التطبيق',
      'add_review': 'أضف رأيك',
      'about_place': 'نبذة عن المكان',
      'location_on_map': 'الموقع على الخريطة',
      'photos': 'الصور',
      'discover_more': 'استكشف المزيد في تطبيق وادنا:',
      'favorites_load_error': 'تعذر تحميل المفضلة حالياً.',
      'no_saved_places': 'لم تحفظ أي معلم بعد.',
      'no_saved_places_info':
          'اضغط على رمز القلب في تفاصيل أي معلم لإضافته هنا.',
    },
    AppLanguage.french: {
      'app_name': 'Ouedna',
      'official_platform': 'Plateforme touristique officielle',
      'desert_heart': 'Le cœur du désert bat ici',
      'welcome_intro':
          'Bienvenue sur Ouedna, votre plateforme pour découvrir les trésors d’El Oued. Des coupoles historiques aux oasis vertes au milieu des sables dorés, planifiez votre trajet et explorez les lieux qui vous intéressent.',
      'heritage_archive': 'Archives et mémoire historique d’El Oued',
      'interactive_maps': 'Cartes interactives et itinéraires précis',
      'start_exploring': 'Commencer à explorer',
      'enter_as_guest': 'Continuer en tant que visiteur',
      'choose_language': 'Langue',
      'settings': 'Paramètres',
      'change_language': 'Changer de langue',
      'change_theme': 'Changer le thème',
      'privacy_policy': 'Politique de confidentialité',
      'app_update': 'Mettre à jour l’application',
      'update_available': 'Mise à jour {version} disponible',
      'update_description':
          'Une nouvelle version d’Ouedna améliore les performances et la sécurité.',
      'later': 'Plus tard',
      'view_update': 'Voir la mise à jour',
      'home': 'Accueil',
      'places': 'Lieux',
      'map': 'Carte',
      'favorites': 'Favoris',
      'community': 'Communauté',
      'discover_el_oued': 'Découvrez El Oued\navec un regard local',
      'start_your_journey': 'Commencez votre voyage',
      'home_intro':
          'Un guide pratique pour les lieux, les expériences et la mémoire locale de la wilaya d’El Oued.',
      'explore_places': 'Explorer les lieux',
      'nearby_places': 'Lieux proches et expériences fiables',
      'plan_route': 'Planifiez votre trajet simplement',
      'suggest_place': 'Suggérer un nouveau lieu',
      'suggest_place_info':
          'Envoyez le lieu avec son repère et sa photo pour validation avant publication',
      'database_required':
          'Ce service nécessite une connexion à la base de données',
      'my_itinerary': 'Mon itinéraire',
      'my_itinerary_info':
          'Créez un programme selon votre temps et vos centres d’intérêt',
      'emergency_help': 'Aide d’urgence',
      'emergency_help_info':
          'Appel direct aux urgences et partage volontaire de la localisation',
      'live_data_notice':
          'Le contenu d’Ouedna est relié directement aux données publiées depuis le panneau d’administration afin de rester à jour.',
      'ouedna_map': 'Carte Ouedna',
      'published_places': '{count} lieux publiés',
      'standard_map': 'Carte standard',
      'satellite_map': 'Imagerie satellite',
      'map_layer': 'Fond de carte',
      'refresh': 'Actualiser',
      'all': 'Tous',
      'my_location': 'Ma position',
      'map_center': 'Centrer la carte',
      'details': 'Détails',
      'start_journey': 'Démarrer le trajet',
      'close': 'Fermer',
      'no_coordinates':
          'Aucune coordonnée publiée pour le moment. Les lieux apparaîtront ici après validation dans le panneau d’administration.',
      'map_load_error': 'Impossible de charger la carte — Réessayer',
      'search_place': 'Rechercher un lieu',
      'no_matching_places':
          'Aucun lieu publié ne correspond à votre recherche.',
      'places_load_error': 'Impossible de charger les lieux pour le moment.',
      'retry': 'Réessayer',
      'translation_loading': 'Traduction en cours…',
      'translation_original': 'Afficher le texte original',
      'translation_error':
          'La traduction est indisponible. Le texte original est affiché.',
      'location_service_disabled':
          'Le service de localisation est désactivé sur cet appareil.',
      'page_load_error':
          'Cette page ne peut pas être affichée. Fermez puis rouvrez l’application et vérifiez votre connexion Internet.',
      'navigate_to_place': 'Démarrer la navigation vers ce lieu',
      'in_app_navigation': 'Navigation dans l’application',
      'add_review': 'Ajouter votre avis',
      'about_place': 'À propos de ce lieu',
      'location_on_map': 'Localisation sur la carte',
      'photos': 'Photos',
      'discover_more': 'Découvrez-en plus dans l’application Ouedna :',
      'favorites_load_error':
          'Impossible de charger vos favoris pour le moment.',
      'no_saved_places': 'Vous n’avez encore enregistré aucun lieu.',
      'no_saved_places_info':
          'Touchez le cœur dans les détails d’un lieu pour l’ajouter ici.',
    },
    AppLanguage.english: {
      'app_name': 'Ouedna',
      'official_platform': 'Official tourism platform',
      'desert_heart': 'The heart of the desert beats here',
      'welcome_intro':
          'Welcome to Ouedna, your platform for discovering the treasures of El Oued. From historic domes to green oases among golden sands, plan your route and explore the places that interest you.',
      'heritage_archive': 'El Oued historical archive and memories',
      'interactive_maps': 'Interactive maps and accurate routes',
      'start_exploring': 'Start exploring',
      'enter_as_guest': 'Continue as a visitor',
      'choose_language': 'Language',
      'settings': 'Settings',
      'change_language': 'Change language',
      'change_theme': 'Change theme',
      'privacy_policy': 'Privacy policy',
      'app_update': 'Update application',
      'update_available': 'Update {version} is available',
      'update_description':
          'A newer version of Ouedna improves performance and security.',
      'later': 'Later',
      'view_update': 'View update',
      'home': 'Home',
      'places': 'Places',
      'map': 'Map',
      'favorites': 'Favorites',
      'community': 'Community',
      'discover_el_oued': 'Discover El Oued\nthrough local eyes',
      'start_your_journey': 'Start your journey',
      'home_intro':
          'A practical guide to places, experiences, and local memory across El Oued Province.',
      'explore_places': 'Explore places',
      'nearby_places': 'Nearby places and trusted experiences',
      'plan_route': 'Plan your route easily',
      'suggest_place': 'Suggest a new place',
      'suggest_place_info':
          'Send a map pin and photo for review before publication',
      'database_required': 'This service requires a database connection',
      'my_itinerary': 'My itinerary',
      'my_itinerary_info': 'Create a plan based on your time and interests',
      'emergency_help': 'Emergency help',
      'emergency_help_info':
          'Direct emergency calls and voluntary location sharing',
      'live_data_notice':
          'Ouedna content connects directly to information published from the admin panel, keeping visitor information current.',
      'ouedna_map': 'Ouedna map',
      'published_places': '{count} published places',
      'standard_map': 'Standard map',
      'satellite_map': 'Satellite imagery',
      'map_layer': 'Map layer',
      'refresh': 'Refresh',
      'all': 'All',
      'my_location': 'My location',
      'map_center': 'Center map',
      'details': 'Details',
      'start_journey': 'Start journey',
      'close': 'Close',
      'no_coordinates':
          'No published coordinates are currently available. Places will appear here after approval in the admin panel.',
      'map_load_error': 'Unable to load the map — Try again',
      'search_place': 'Search for a landmark or place',
      'no_matching_places': 'No published places match your search.',
      'places_load_error': 'Unable to load places right now.',
      'retry': 'Try again',
      'translation_loading': 'Translating…',
      'translation_original': 'Show original text',
      'translation_error':
          'Translation is unavailable. The original text is shown.',
      'location_service_disabled':
          'Location services are disabled on this device.',
      'page_load_error':
          'This page cannot be displayed right now. Close and reopen the app, then check your Internet connection.',
      'navigate_to_place': 'Start navigation to this place',
      'in_app_navigation': 'In-app navigation',
      'add_review': 'Add your review',
      'about_place': 'About this place',
      'location_on_map': 'Location on the map',
      'photos': 'Photos',
      'discover_more': 'Explore more in the Ouedna app:',
      'favorites_load_error': 'Unable to load favorites right now.',
      'no_saved_places': 'You have not saved any places yet.',
      'no_saved_places_info':
          'Tap the heart in a place’s details to add it here.',
    },
  };
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    this.foregroundColor,
    this.compact = false,
  });

  final Color? foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.controllerOf(context);
    final strings = OuednaStrings.of(context);
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;

    return PopupMenuButton<AppLanguage>(
      tooltip: strings.text('change_language'),
      initialValue: controller.language,
      onSelected: controller.setLanguage,
      itemBuilder: (context) => AppLanguage.values
          .map(
            (language) => PopupMenuItem(
              value: language,
              child: Row(
                children: [
                  Icon(
                    controller.language == language
                        ? Icons.check_circle_rounded
                        : Icons.language_rounded,
                    color: controller.language == language
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(language.label),
                ],
              ),
            ),
          )
          .toList(growable: false),
      child: compact
          ? Icon(Icons.language_rounded, color: color)
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: color.withOpacity(.55)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    controller.language.label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
    );
  }
}

class OnDeviceTranslationService {
  OnDeviceTranslationService._();

  static final instance = OnDeviceTranslationService._();

  final _modelManager = OnDeviceTranslatorModelManager();
  final _cache = <String, String>{};
  Future<String> translateFromArabic(
    String text,
    AppLanguage targetLanguage,
  ) async {
    final sourceText = text.trim();
    if (sourceText.isEmpty || targetLanguage == AppLanguage.arabic) {
      return text;
    }

    final cacheKey = '${targetLanguage.code}::$sourceText';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final sourceCode = TranslateLanguage.arabic.bcpCode;
    final targetCode = targetLanguage.translationLanguage.bcpCode;
    if (!await _modelManager.isModelDownloaded(sourceCode)) {
      await _modelManager.downloadModel(sourceCode);
    }
    if (!await _modelManager.isModelDownloaded(targetCode)) {
      await _modelManager.downloadModel(targetCode);
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.arabic,
      targetLanguage: targetLanguage.translationLanguage,
    );
    try {
      final result = await translator.translateText(sourceText);
      _cache[cacheKey] = result;
      return result;
    } finally {
      translator.close();
    }
  }
}

class AutoTranslatedText extends StatefulWidget {
  const AutoTranslatedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  State<AutoTranslatedText> createState() => _AutoTranslatedTextState();
}

class _AutoTranslatedTextState extends State<AutoTranslatedText> {
  Future<String>? _translation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translation = _requestTranslation();
  }

  @override
  void didUpdateWidget(covariant AutoTranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _translation = _requestTranslation();
  }

  Future<String> _requestTranslation() {
    final language = LanguageScope.languageOf(context);
    return OnDeviceTranslationService.instance.translateFromArabic(
      widget.text,
      language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.languageOf(context);
    if (language == AppLanguage.arabic || widget.text.trim().isEmpty) {
      return _text(widget.text);
    }

    return FutureBuilder<String>(
      future: _translation,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.trim().isNotEmpty) {
          return _text(snapshot.data!);
        }
        return _text(widget.text);
      },
    );
  }

  Widget _text(String value) => Text(
        value,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
}
