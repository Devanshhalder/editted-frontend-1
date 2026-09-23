import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../theme.dart';
import 'catalog_local_db.dart';

class AppState extends ChangeNotifier {
  bool isLoggedIn = false;
  bool isDarkMode = false;
  bool highContrastMode = false;

  static const String _loggedInKey = 'karigarkart_logged_in';

  Future<void> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    isLoggedIn = preferences.getBool(_loggedInKey) ?? false;
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void setHighContrastMode(bool value) {
    if (highContrastMode == value) return;
    highContrastMode = value;
    notifyListeners();
  }

  String language = 'English';
  bool isChangingLanguage = false;
  String? draftImagePath;
  String studioPreset = 'Pure White';
  String studioAspectRatio = '1:1';
  String? editingProductId;

  void setStudioSettings({String? preset, String? aspectRatio}) {
    if (preset != null && preset.isNotEmpty) studioPreset = preset;
    if (aspectRatio != null && aspectRatio.isNotEmpty) studioAspectRatio = aspectRatio;
    notifyListeners();
  }

  String profileName = 'Anshika Thakur';
  String businessName = 'Anshi Handicrafts';
  String contactInfo = '+91 9000000000';
  String pehchanId = '';
  String giTag = '';
  String artisanAffiliation = '';

  bool get isIdentityVerified =>
      pehchanId.trim().isNotEmpty ||
          giTag.trim().isNotEmpty ||
          artisanAffiliation.trim().isNotEmpty;

  Product draft = Product(
    id: 'draft',
    title: '',
    description: '',
    price: 1499,
    category: 'Textiles',
    color: AppColors.clay,
    published: false,
    syncStatus: 'queued',
  );

  final List<Product> products = [
    Product(
      id: '1',
      title: 'Indigo Block Print Stole',
      description: 'Hand block printed cotton stole made with natural indigo dyes.',
      price: 1299,
      category: 'Textiles',
      color: const Color(0xFF426B93),
      stock: 4,
      imagePath: 'assets/s1.png',
    ),
    Product(
      id: '2',
      title: 'Terracotta Planter',
      description: 'Earthy, hand-thrown planter with a warm matte finish.',
      price: 899,
      category: 'Pottery',
      color: const Color(0xFFC86B42),
      stock: 7,
      imagePath: 'assets/s2.png',
    ),
    Product(
      id: '3',
      title: 'Cane Storage Basket',
      description: 'Durable handwoven cane basket for everyday spaces.',
      price: 1599,
      category: 'Basketry',
      color: const Color(0xFFB78A4A),
      stock: 2,
      imagePath: 'assets/s3.png',
    ),
  ];

  // Map of translations using exact literal UI strings as keys
  static final Map<String, Map<String, String>> _translations = {
    'English': {
      // Navigation & Hub Tabs
      'Dashboard': 'Dashboard',
      'Inquiries': 'Inquiries',
      'Disputes': 'Disputes',

      // Tier Titles & Subtitles
      'Gold Artisan': 'Gold Artisan',
      'Silver Artisan': 'Silver Artisan',
      'Bronze Artisan': 'Bronze Artisan',
      'products toward Gold': 'products toward Gold',

      // Dashboard Strings
      'Business Dashboard': 'Business Dashboard',
      'Your virtual business manager': 'Your virtual business manager',
      'Today': 'Today',
      'This Week': 'This Week',
      'This Month': 'This Month',
      'Sales Trend': 'Sales Trend',
      'Performance overview': 'Performance overview',
      'Product Performance': 'Product Performance',
      'Top performing inventory': 'Top performing inventory',
      'Revenue & Net Profit': 'Revenue & Net Profit',
      'Total products': 'Total products',
      'Inventory value': 'Inventory value',
      'Recent Activity': 'Recent Activity',
      'Low Stock Products': 'Low Stock Products',
      'Product Views': 'Product Views',
      'Est. Orders': 'Est. Orders',
      'Conversion': 'Conversion',
      'in stock': 'in stock',
      'value': 'value',
      'Active Listings': 'Active Listings',
      'In Review / Draft': 'In Review / Draft',
      'Pending Sync': 'Pending Sync',
      'My Catalog': 'My Catalog',
      'Search products or categories': 'Search products or categories',
      'Live': 'Live',
      'Drafts': 'Drafts',
      'Total': 'Total',
      'Newest': 'Newest',
      '6AM': '6AM',
      '9AM': '9AM',
      '12': '12',
      '3PM': '3PM',
      '6PM': '6PM',
      '9PM': '9PM',
      'Now': 'Now',
      'Mon': 'Mon',
      'Tue': 'Tue',
      'Wed': 'Wed',
      'Thu': 'Thu',
      'Fri': 'Fri',
      'Sat': 'Sat',
      'Sun': 'Sun',
      'W1': 'W1',
      'W2': 'W2',
      'W3': 'W3',
      'W4': 'W4',
      'W5': 'W5',

      // Inquiry Tab
      '40 Terracotta Planters requested': '40 Terracotta Planters requested',
      '25 Indigo Block Print Stoles requested': '25 Indigo Block Print Stoles requested',
      '15 Cane Storage Baskets requested': '15 Cane Storage Baskets requested',
      'Quote': 'Quote',

      // Dispute Tab
      'Disputes / Returns': 'Disputes / Returns',
      'Buyer says the terracotta planters arrived damaged. Keep the dispatch evidence with this case.':
      'Buyer says the terracotta planters arrived damaged. Keep the dispatch evidence with this case.',
      'Upload Packaging Video': 'Upload Packaging Video',
      'Packaging Video Added': 'Packaging Video Added',
      'QC video is queued with the dispute record.': 'QC video is queued with the dispute record.',
    },
    'Hindi': {
      // Navigation & Hub Tabs
      'Dashboard': 'डैशबोर्ड',
      'Inquiries': 'पूछताछ',
      'Disputes': 'विवाद',

      // Tier Titles & Subtitles
      'Gold Artisan': 'स्वर्ण कारीगर',
      'Silver Artisan': 'रजत कारीगर',
      'Bronze Artisan': 'कांस्य कारीगर',
      'products toward Gold': 'गोल्ड श्रेणी के लिए उत्पाद',

      // Dashboard Strings
      'Business Dashboard': 'बिजनेस डैशबोर्ड',
      'Your virtual business manager': 'आपका वर्चुअल बिजनेस मैनेजर',
      'Today': 'आज',
      'This Week': 'इस सप्ताह',
      'This Month': 'इस महीने',
      'Sales Trend': 'बिक्री का रुझान',
      'Performance overview': 'प्रदर्शन का अवलोकन',
      'Product Performance': 'उत्पाद प्रदर्शन',
      'Top performing inventory': 'श्रेष्ठ प्रदर्शन करने वाला स्टॉक',
      'Revenue & Net Profit': 'राजस्व और शुद्ध लाभ',
      'Total products': 'कुल उत्पाद',
      'Inventory value': 'इन्वेंटरी मूल्य',
      'Recent Activity': 'हाल की गतिविधि',
      'Low Stock Products': 'कम स्टॉक वाले उत्पाद',
      'Product Views': 'उत्पाद व्यूज',
      'Est. Orders': 'अनुमानित ऑर्डर',
      'Conversion': 'कन्वर्जन',
      'in stock': 'स्टॉक में',
      'value': 'मूल्य',
      'Active Listings': 'सक्रिय लिस्टिंग',
      'In Review / Draft': 'समीक्षा में / ड्राफ्ट',
      'Pending Sync': 'सिंक लंबित',
      'My Catalog': 'मेरा कैटलॉग',
      'Search products or categories': 'उत्पाद या श्रेणियां खोजें',
      'Live': 'लाइव',
      'Drafts': 'ड्राफ्ट',
      'Total': 'कुल',
      'Newest': 'नवीनतम',
      '6AM': 'सुबह 6 बजे',
      '9AM': 'सुबह 9 बजे',
      '12': 'दोपहर 12 बजे',
      '3PM': 'दोपहर 3 बजे',
      '6PM': 'शाम 6 बजे',
      '9PM': 'रात 9 बजे',
      'Now': 'अभी',
      'Mon': 'सोम',
      'Tue': 'मंगल',
      'Wed': 'बुध',
      'Thu': 'गुरु',
      'Fri': 'शुक्र',
      'Sat': 'शनि',
      'Sun': 'रवि',
      'W1': 'हफ़्ता 1',
      'W2': 'हफ़्ता 2',
      'W3': 'हफ़्ता 3',
      'W4': 'हफ़्ता 4',
      'W5': 'हफ़्ता 5',

      // Inquiry Tab
      '40 Terracotta Planters requested': '40 टेराकोटा प्लांटर्स का अनुरोध',
      '25 Indigo Block Print Stoles requested': '25 इंडिगो ब्लॉक प्रिंट स्टोल का अनुरोध',
      '15 Cane Storage Baskets requested': '15 केन स्टोरेज टोकरियों का अनुरोध',
      'Quote': 'कोट दें',

      // Dispute Tab
      'Disputes / Returns': 'विवाद / वापसी',
      'Buyer says the terracotta planters arrived damaged. Keep the dispatch evidence with this case.':
      'खरीदार का कहना है कि टेराकोटा गमले क्षतिग्रस्त पहुंचे हैं। इस मामले के साथ पैकिंग का प्रमाण रखें।',
      'Upload Packaging Video': 'पैकिंग वीडियो अपलोड करें',
      'Packaging Video Added': 'पैकिंग वीडियो जोड़ा गया',
      'QC video is queued with the dispute record.': 'क्यूसी वीडियो विवाद रिकॉर्ड के साथ सहेजा गया है।',
    },
  };

  /// Translate key according to current selected language
  String tr(String key) {
    // Standardize selected language identifier (supports 'Hindi', 'hi', 'hi_IN', etc.)
    final currentLang = (language.toLowerCase().contains('hi')) ? 'Hindi' : 'English';

    final langMap = _translations[currentLang];
    if (langMap != null && langMap.containsKey(key)) {
      return langMap[key]!;
    }

    return _translations['English']?[key] ?? key;
  }

  Future<void> restoreCatalog() async {
    try {
      final local = await CatalogLocalDb.loadProducts();
      if (local.isEmpty) {
        await CatalogLocalDb.saveProducts(products);
      } else {
        products
          ..clear()
          ..addAll(local);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('KarigarKart catalog restore error: $e');
    }
  }

  void _persistCatalog() {
    CatalogLocalDb.saveProducts(products).catchError((error) {
      debugPrint('KarigarKart catalog persistence error: $error');
    });
  }

  void login() {
    isLoggedIn = true;
    notifyListeners();
    _saveLoginState(true);
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
    _saveLoginState(false);
  }

  Future<void> _saveLoginState(bool value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_loggedInKey, value);
    } catch (e) {
      debugPrint('KarigarKart session persistence error: $e');
    }
  }

  Future<void> setLanguage(String value) async {
    if (value == language) return;
    isChangingLanguage = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    language = value;
    isChangingLanguage = false;
    notifyListeners();
  }

  void setDraftImage(String path) {
    draftImagePath = path;
    notifyListeners();
  }

  void updateDraft({
    String? title,
    String? description,
    int? price,
    String? category,
  }) {
    if (title != null) draft.title = title;
    if (description != null) draft.description = description;
    if (price != null) draft.price = price;
    if (category != null) draft.category = category;
    notifyListeners();
  }

  void beginEditProduct(String id) {
    final index = products.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final product = products[index];
    editingProductId = id;
    draft = Product(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      category: product.category,
      color: product.color,
      published: product.published,
      stock: product.stock,
      syncStatus: product.syncStatus,
      syncConflict: product.syncConflict,
      syncError: product.syncError,
      imagePath: product.imagePath,
      attributes: List<String>.from(product.attributes),
      marketplaceStatuses: Map<String, String>.from(product.marketplaceStatuses),
    );
    draftImagePath = product.imagePath;
    notifyListeners();
  }

  void clearEditingProduct() {
    editingProductId = null;
    draftImagePath = null;
  }

  void publishDraft() {
    if (editingProductId != null) {
      final index = products.indexWhere((item) => item.id == editingProductId);
      if (index >= 0) {
        final product = products[index];
        product
          ..title = draft.title
          ..description = draft.description
          ..price = draft.price
          ..category = draft.category
          ..imagePath = draftImagePath
          ..attributes = List<String>.from(draft.attributes)
          ..marketplaceStatuses = Map<String, String>.from(draft.marketplaceStatuses)
          ..syncStatus = 'queued'
          ..syncError = null;
        _persistCatalog();
      }
      clearEditingProduct();
      notifyListeners();
      return;
    }

    draft.published = true;
    draft.id = DateTime.now().millisecondsSinceEpoch.toString();
    draft.syncStatus = 'queued';
    draft.syncConflict = false;
    draft.imagePath = draftImagePath;
    products.insert(0, draft);
    draft = Product(
      id: 'draft',
      title: '',
      description: '',
      price: 1499,
      category: 'Textiles',
      color: AppColors.clay,
      published: false,
      syncStatus: 'queued',
    );
    draftImagePath = null;
    _persistCatalog();
    notifyListeners();
  }

  void updateProduct(
      String id, {
        String? title,
        String? description,
        int? price,
        String? category,
        int? stock,
        String? imagePath,
        List<String>? attributes,
        Map<String, String>? marketplaceStatuses,
      }) {
    final index = products.indexWhere((product) => product.id == id);
    if (index < 0) return;
    final product = products[index];
    if (title != null) product.title = title;
    if (description != null) product.description = description;
    if (price != null) product.price = price;
    if (category != null) product.category = category;
    if (stock != null) product.stock = stock;
    if (imagePath != null) product.imagePath = imagePath;
    if (attributes != null) product.attributes = List<String>.from(attributes);
    if (marketplaceStatuses != null) {
      product.marketplaceStatuses = Map<String, String>.from(marketplaceStatuses);
    }
    product.syncStatus = 'queued';
    product.syncError = null;
    _persistCatalog();
    notifyListeners();
  }

  void deleteProduct(String id) {
    products.removeWhere((product) => product.id == id);
    _persistCatalog();
    notifyListeners();
  }

  void restoreProduct(Product product) {
    if (products.any((item) => item.id == product.id)) return;
    products.insert(0, product);
    _persistCatalog();
    notifyListeners();
  }

  void markProductProcessing(String id) => _setSyncState(id, 'processing');
  void markProductSynced(String id) => _setSyncState(id, 'published');

  void markProductFailed(String id, String error) {
    final index = products.indexWhere((product) => product.id == id);
    if (index < 0) return;
    products[index].syncStatus = 'failed';
    products[index].syncError = error;
    _persistCatalog();
    notifyListeners();
  }

  void markProductConflict(String id, {String? localVersion, String? remoteVersion}) {
    final index = products.indexWhere((product) => product.id == id);
    if (index < 0) return;
    products[index].syncConflict = true;
    products[index].syncStatus = 'failed';
    products[index].syncError = 'Sync conflict: ${remoteVersion ?? 'remote version changed'}';
    _persistCatalog();
    notifyListeners();
  }

  void resolveProductConflict(String id, {required bool keepLocal}) {
    final index = products.indexWhere((product) => product.id == id);
    if (index < 0) return;
    products[index].syncConflict = false;
    products[index].syncStatus = keepLocal ? 'queued' : 'published';
    products[index].syncError = null;
    _persistCatalog();
    notifyListeners();
  }

  void _setSyncState(String id, String status) {
    final index = products.indexWhere((product) => product.id == id);
    if (index < 0) return;
    products[index].syncStatus = status;
    products[index].syncError = null;
    _persistCatalog();
    notifyListeners();
  }

  void saveProduct(Product product) {
    final index = products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }
    product.syncStatus = 'queued';
    _persistCatalog();
    notifyListeners();
  }

  Future<void> clearLocalCatalog() async {
    products.clear();
    draft = Product(
      id: 'draft',
      title: '',
      description: '',
      price: 1499,
      category: 'Textiles',
      color: AppColors.clay,
      published: false,
      syncStatus: 'queued',
    );
    draftImagePath = null;
    editingProductId = null;
    await CatalogLocalDb.clear();
    notifyListeners();
  }

  void updateProfile({required String name, required String business, required String contact}) {
    profileName = name.trim();
    businessName = business.trim();
    contactInfo = contact.trim();
    notifyListeners();
  }

  void updateArtisanIdentity({required String pehchanId, required String giTag, required String affiliation}) {
    this.pehchanId = pehchanId.trim();
    this.giTag = giTag.trim();
    artisanAffiliation = affiliation.trim();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}