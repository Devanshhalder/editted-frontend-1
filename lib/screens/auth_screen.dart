import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool signUp = false;
  bool obscurePassword = true;
  bool _submitting = false;

  // Selected language state ('en', 'hi', 'bn', 'mr', 'ta', 'pa', 'gu', 'ur')
  String _selectedLanguage = 'en';

  final formKey = GlobalKey<FormState>();

  late final AnimationController _controller;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // Translation Map for standard login strings
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'welcome': 'Welcome back',
      'createAccount': 'Create your account',
      'welcomeSub': 'Sign in to continue to your artisan dashboard.',
      'createAccountSub': 'Start showcasing your craft with KarigarKart.',
      'fullName': 'Full name',
      'enterName': 'Enter your name',
      'pleaseEnterName': 'Please enter your name',
      'phoneOrEmail': 'Phone or email',
      'enterPhoneOrEmail': 'Enter your phone or email',
      'pleaseEnterPhoneOrEmail': 'Please enter your phone or email',
      'password': 'Password',
      'enterPassword': 'Enter your password',
      'showPassword': 'Show password',
      'hidePassword': 'Hide password',
      'passwordLength': 'Use at least 4 characters',
      'loginToShop': 'Login to your shop',
      'createSeller': 'Create seller account',
      'alreadyHaveAccount': 'Already have an account?',
      'newArtisan': 'New artisan?',
      'login': 'Login',
      'createAnAccount': 'Create an account',
    },
    'hi': {
      'welcome': 'स्वागत है',
      'createAccount': 'अपना खाता बनाएं',
      'welcomeSub': 'अपने कारीगर डैशबोर्ड पर जारी रखने के लिए साइन इन करें।',
      'createAccountSub': 'कारीगरकार्ट के साथ अपनी कला का प्रदर्शन शुरू करें।',
      'fullName': 'पूरा नाम',
      'enterName': 'अपना नाम दर्ज करें',
      'pleaseEnterName': 'कृपया अपना नाम दर्ज करें',
      'phoneOrEmail': 'फोन या ईमेल',
      'enterPhoneOrEmail': 'अपना फोन या ईमेल दर्ज करें',
      'pleaseEnterPhoneOrEmail': 'कृपया अपना फोन या ईमेल दर्ज करें',
      'password': 'पासवर्ड',
      'enterPassword': 'अपना पासवर्ड दर्ज करें',
      'showPassword': 'पासवर्ड दिखाएं',
      'hidePassword': 'पासवर्ड छुपाएं',
      'passwordLength': 'कम से कम 4 अक्षरों का प्रयोग करें',
      'loginToShop': 'अपनी दुकान में लॉगिन करें',
      'createSeller': 'विक्रेता खाता बनाएं',
      'alreadyHaveAccount': 'क्या आपके पास पहले से एक खाता है?',
      'newArtisan': 'नए कारीगर?',
      'login': 'लॉगिन',
      'createAnAccount': 'खाता बनाएं',
    },
    'bn': {
      'welcome': 'স্বাগতম',
      'createAccount': 'আপনার অ্যাকাউন্ট তৈরি করুন',
      'welcomeSub': 'আপনার কারিগর ড্যাশবোর্ডে প্রবেশ করতে সাইন ইন করুন।',
      'createAccountSub': 'কারিগরকার্টের সাথে আপনার শিল্প প্রদর্শন শুরু করুন।',
      'fullName': 'সম্পূর্ণ নাম',
      'enterName': 'আপনার নাম লিখুন',
      'pleaseEnterName': 'দয়া করে আপনার নাম লিখুন',
      'phoneOrEmail': 'ফোন বা ইমেল',
      'enterPhoneOrEmail': 'আপনার ফোন বা ইমেল লিখুন',
      'pleaseEnterPhoneOrEmail': 'দয়া করে আপনার ফোন বা ইমেল লিখুন',
      'password': 'পাসওয়ার্ড',
      'enterPassword': 'আপনার পাসওয়ার্ড লিখুন',
      'showPassword': 'পাসওয়ার্ড দেখান',
      'hidePassword': 'পাসওয়ার্ড লুকান',
      'passwordLength': 'কমপক্ষে ৪টি অক্ষর ব্যবহার করুন',
      'loginToShop': 'আপনার দোকানে লগইন করুন',
      'createSeller': 'বিক্রেতা অ্যাকাউন্ট তৈরি করুন',
      'alreadyHaveAccount': 'ইতিমধ্যেই একটি অ্যাকাউন্ট আছে?',
      'newArtisan': 'নতুন কারিগর?',
      'login': 'লগইন',
      'createAnAccount': 'অ্যাকাউন্ট তৈরি করুন',
    },
    'mr': {
      'welcome': 'पुन्हा स्वागत आहे',
      'createAccount': 'तुमचे खाते तयार करा',
      'welcomeSub': 'तुमच्या कारागीर डॅशबोर्डवर जाण्यासाठी साइन इन करा.',
      'createAccountSub': 'कारीगरकार्टसह तुमची कला प्रदर्शित करण्यास सुरुवात करा.',
      'fullName': 'पूर्ण नाव',
      'enterName': 'तुमचे नाव प्रविष्ट करा',
      'pleaseEnterName': 'कृपया तुमचे नाव प्रविष्ट करा',
      'phoneOrEmail': 'फोन किंवा ईमेल',
      'enterPhoneOrEmail': 'तुमचा फोन किंवा ईमेल प्रविष्ट करा',
      'pleaseEnterPhoneOrEmail': 'कृपया तुमचा फोन किंवा ईमेल प्रविष्ट करा',
      'password': 'पासवर्ड',
      'enterPassword': 'तुमचा पासवर्ड प्रविष्ट करा',
      'showPassword': 'पासवर्ड दाखवा',
      'hidePassword': 'पासवर्ड लपवा',
      'passwordLength': 'कमीत कमी ४ अक्षरे वापरा',
      'loginToShop': 'तुमच्या दुकानात लॉगिन करा',
      'createSeller': 'विक्रेता खाते तयार करा',
      'alreadyHaveAccount': 'आधीच खाते आहे?',
      'newArtisan': 'नवीन कारागीर?',
      'login': 'लॉगिन',
      'createAnAccount': 'खाते तयार करा',
    },
    'ta': {
      'welcome': 'மீண்டும் வருக',
      'createAccount': 'உங்கள் கணக்கை உருவாக்கவும்',
      'welcomeSub': 'உங்கள் கைவினைஞர் டாஷ்போர்டைத் தொடர உள்நுழையவும்.',
      'createAccountSub': 'காரிகர்கார்ட்டில் உங்கள் கைவினைப் பொருட்களைக் காண்பிக்கத் தொடங்குங்கள்.',
      'fullName': 'முழு பெயர்',
      'enterName': 'உங்கள் பெயரை உள்ளிடவும்',
      'pleaseEnterName': 'தயவுசெய்து உங்கள் பெயரை உள்ளிடவும்',
      'phoneOrEmail': 'தொலைபேசி அல்லது மின்னஞ்சல்',
      'enterPhoneOrEmail': 'தொலைபேசி அல்லது மின்னஞ்சலை உள்ளிடவும்',
      'pleaseEnterPhoneOrEmail': 'தயவுசெய்து தொலைபேசி அல்லது மின்னஞ்சலை உள்ளிடவும்',
      'password': 'கடவுச்சொல்',
      'enterPassword': 'கடவுச்சொல்லை உள்ளிடவும்',
      'showPassword': 'கடவுச்சொல்லைக் காட்டு',
      'hidePassword': 'கடவுச்சொல்லை மறை',
      'passwordLength': 'குறைந்தது 4 எழுத்துகளைப் பயன்படுத்தவும்',
      'loginToShop': 'உங்கள் கடையில் உள்நுழையவும்',
      'createSeller': 'விற்பனையாளர் கணக்கை உருவாக்கவும்',
      'alreadyHaveAccount': 'ஏற்கனவே கணக்கு உள்ளதா?',
      'newArtisan': 'புதிய கைவினைஞரா?',
      'login': 'உள்நுழைவு',
      'createAnAccount': 'கணக்கை உருவாக்கவும்',
    },
    'pa': {
      'welcome': 'ਜੀ ਆਇਆਂ ਨੂੰ',
      'createAccount': 'ਆਪਣਾ ਖਾਤਾ ਬਣਾਓ',
      'welcomeSub': 'ਆਪਣੇ ਕਾਰੀਗਰ ਡੈਸ਼ਬੋਰਡ \'ਤੇ ਜਾਰੀ ਰੱਖਣ ਲਈ ਸਾਈਨ ਇਨ ਕਰੋ।',
      'createAccountSub': 'ਕਾਰੀਗਰਕਾਰਟ ਨਾਲ ਆਪਣੀ ਕਲਾ ਦਾ ਪ੍ਰਦਰਸ਼ਨ ਸ਼ੁਰੂ ਕਰੋ।',
      'fullName': 'ਪੂਰਾ ਨਾਮ',
      'enterName': 'ਆਪਣਾ ਨਾਮ ਦਰਜ ਕਰੋ',
      'pleaseEnterName': 'ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਨਾਮ ਦਰਜ ਕਰੋ',
      'phoneOrEmail': 'ਫੋਨ ਜਾਂ ਈਮੇਲ',
      'enterPhoneOrEmail': 'ਆਪਣਾ ਫੋਨ ਜਾਂ ਈਮੇਲ ਦਰਜ ਕਰੋ',
      'pleaseEnterPhoneOrEmail': 'ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਫੋਨ ਜਾਂ ਈਮੇਲ ਦਰਜ ਕਰੋ',
      'password': 'ਪਾਸਵਰਡ',
      'enterPassword': 'ਆਪਣਾ ਪਾਸਵਰਡ ਦਰਜ ਕਰੋ',
      'showPassword': 'ਪਾਸਵਰਡ ਦਿਖਾਓ',
      'hidePassword': 'ਪਾਸਵਰਡ ਛੁਪਾਓ',
      'passwordLength': 'ਘੱਟੋ-ਘੱਟ 4 ਅੱਖਰਾਂ ਦੀ ਵਰਤੋਂ ਕਰੋ',
      'loginToShop': 'ਆਪਣੀ ਦੁਕਾਨ ਵਿੱਚ ਲੌਗਇਨ ਕਰੋ',
      'createSeller': 'ਵਿਕਰੇਤਾ ਖਾਤਾ ਬਣਾਓ',
      'alreadyHaveAccount': 'ਕੀ ਪਹਿਲਾਂ ਹੀ ਇੱਕ ਖਾਤਾ ਹੈ?',
      'newArtisan': 'ਨਵੇਂ ਕਾਰੀਗਰ?',
      'login': 'ਲੌਗਇਨ',
      'createAnAccount': 'ਖਾਤਾ ਬਣਾਓ',
    },
    'gu': {
      'welcome': 'સ્વાગત છે',
      'createAccount': 'તમારું એકાઉન્ટ બનાવો',
      'welcomeSub': 'તમારા કારીગર ડેશબોર્ડ પર ચાલુ રાખવા માટે સાઇન ઇન કરો.',
      'createAccountSub': 'કારીગરકાર્ટ સાથે તમારી કળા પ્રદર્શિત કરવાનું શરૂ કરો.',
      'fullName': 'પૂરું નામ',
      'enterName': 'તમારું નામ દાખલ કરો',
      'pleaseEnterName': 'કૃપા કરીને તમારું નામ દાખલ કરો',
      'phoneOrEmail': 'ફોન અથવા ઇમેઇલ',
      'enterPhoneOrEmail': 'તમારો ફોન અથવા ઇમેઇલ દાખલ કરો',
      'pleaseEnterPhoneOrEmail': 'કૃપા કરીને તમારો ફોન અથવા ઇમેઇલ દાખલ કરો',
      'password': 'પાસવર્ડ',
      'enterPassword': 'તમારો પાસવર્ડ દાખલ કરો',
      'showPassword': 'પાસવર્ડ બતાવો',
      'hidePassword': 'પાસવર્ડ છુપાવો',
      'passwordLength': 'ઓછામાં ઓછા 4 અક્ષરોનો ઉપયોગ કરો',
      'loginToShop': 'તમારી દુકાનમાં લૉગિન કરો',
      'createSeller': 'વિક્રેતા એકાઉન્ટ બનાવો',
      'alreadyHaveAccount': 'પહેલેથી જ એકાઉન્ટ છે?',
      'newArtisan': 'નવા કારીગર?',
      'login': 'લૉગિન',
      'createAnAccount': 'એકાઉન્ટ બનાવો',
    },
    'ur': {
      'welcome': 'خوش آمدید',
      'createAccount': 'اپنا اکاؤنٹ بنائیں',
      'welcomeSub': 'اپنے کاریگر ڈیش بورڈ پر جانے کے لیے سائن ان کریں۔',
      'createAccountSub': 'کاریگرکارٹ کے ساتھ اپنے فن کا مظاہرہ شروع کریں۔',
      'fullName': 'پورا نام',
      'enterName': 'اپنا نام درج کریں',
      'pleaseEnterName': 'براہ کرم اپنا نام درج کریں',
      'phoneOrEmail': 'فون یا ای میل',
      'enterPhoneOrEmail': 'اپنا فون یا ای میل درج کریں',
      'pleaseEnterPhoneOrEmail': 'براہ کرم اپنا فون یا ای میل درج کریں',
      'password': 'پاس ورڈ',
      'enterPassword': 'اپنا پاس ورڈ درج کریں',
      'showPassword': 'پاس ورڈ دکھائیں',
      'hidePassword': 'پاس ورڈ چھپائیں',
      'passwordLength': 'کم از کم 4 حروف استعمال کریں',
      'loginToShop': 'اپنی دکان میں لاگ ان کریں',
      'createSeller': 'بیچنے والے کا اکاؤنٹ بنائیں',
      'alreadyHaveAccount': 'پہلے سے اکاؤنٹ موجود ہے؟',
      'newArtisan': 'نئے کاریگر؟',
      'login': 'لاگ ان',
      'createAnAccount': 'اکاؤنٹ بنائیں',
    },
  };

  String _t(String key) {
    return _localizedStrings[_selectedLanguage]?[key] ??
        _localizedStrings['en']![key]!;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pageFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.72,
        curve: Curves.easeOutCubic,
      ),
    );

    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.72,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.42,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoScale = Tween<double>(
      begin: 0.965,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.58,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchMode() {
    if (_submitting) return;

    FocusScope.of(context).unfocus();

    setState(() {
      signUp = !signUp;
      obscurePassword = true;
    });

    formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    FocusScope.of(context).unfocus();

    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
    });

    AppScope.of(context).login();
  }

  Color _textColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _mutedColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Color _surfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  Color _backgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _mutedColor(context)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surfaceColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _mutedColor(context).withOpacity(0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _mutedColor(context).withOpacity(0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.saffron,
          width: 1.8,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: _inputDecoration(
        context: context,
        label: label,
        hint: hint,
        icon: icon,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _backgroundColor(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/loginbackground.jpeg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                    const Color(0xFF171412).withOpacity(.62),
                    const Color(0xFF171412).withOpacity(.88),
                  ]
                      : [
                    const Color(0xFFFFF8F2).withOpacity(.62),
                    const Color(0xFFFFF8F2).withOpacity(.84),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -55,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.saffron.withOpacity(.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -75,
            left: -65,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.forest.withOpacity(.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: FadeTransition(
                    opacity: _pageFade,
                    child: SlideTransition(
                      position: _pageSlide,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          16,
                          22,
                          20,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceColor(context).withOpacity(.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _surfaceColor(context).withOpacity(.95),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .shadow
                                  .withOpacity(.11),
                              blurRadius: 32,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Language Selector
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.clay.withOpacity(0.2),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedLanguage,
                                      isDense: true,
                                      icon: const Icon(
                                        Icons.language_rounded,
                                        size: 18,
                                        color: AppColors.clay,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _textColor(context),
                                      ),
                                      onChanged: (String? newLang) {
                                        if (newLang != null) {
                                          setState(() {
                                            _selectedLanguage = newLang;
                                          });
                                        }
                                      },
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'en',
                                          child: Text('English'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'hi',
                                          child: Text('हिन्दी'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'bn',
                                          child: Text('বাংলা'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'mr',
                                          child: Text('मराठी'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'ta',
                                          child: Text('தமிழ்'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'pa',
                                          child: Text('ਪੰਜਾਬੀ'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'gu',
                                          child: Text('ગુજરાતી'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'ur',
                                          child: Text('اردو'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              FadeTransition(
                                opacity: _logoFade,
                                child: ScaleTransition(
                                  scale: _logoScale,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        0,
                                        8,
                                        4,
                                      ),
                                      child: Image.asset(
                                        'assets/karigarkart_login_logo.png',
                                        width: 300,
                                        height: 185,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _StaggeredEntrance(
                                animation: _controller,
                                begin: 0.12,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  transitionBuilder: (child, animation) {
                                    final curved = CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    );

                                    return FadeTransition(
                                      opacity: curved,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, .035),
                                          end: Offset.zero,
                                        ).animate(curved),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    key: ValueKey(signUp.toString() +
                                        _selectedLanguage),
                                    children: [
                                      Text(
                                        signUp
                                            ? _t('createAccount')
                                            : _t('welcome'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -.4,
                                          color: _textColor(context),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        signUp
                                            ? _t('createAccountSub')
                                            : _t('welcomeSub'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: _mutedColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, .035),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                                child: signUp
                                    ? Column(
                                  key: const ValueKey('signup-name'),
                                  children: [
                                    _StaggeredEntrance(
                                      animation: _controller,
                                      begin: 0.22,
                                      child: _buildInputField(
                                        label: _t('fullName'),
                                        hint: _t('enterName'),
                                        icon:
                                        Icons.person_outline_rounded,
                                        textInputAction:
                                        TextInputAction.next,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return _t('pleaseEnterName');
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 13),
                                  ],
                                )
                                    : const SizedBox(
                                  key: ValueKey('login-no-name'),
                                ),
                              ),
                              _StaggeredEntrance(
                                animation: _controller,
                                begin: 0.30,
                                child: _buildInputField(
                                  label: _t('phoneOrEmail'),
                                  hint: _t('enterPhoneOrEmail'),
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return _t('pleaseEnterPhoneOrEmail');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 13),
                              _StaggeredEntrance(
                                animation: _controller,
                                begin: 0.38,
                                child: TextFormField(
                                  obscureText: obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: _inputDecoration(
                                    context: context,
                                    label: _t('password'),
                                    hint: _t('enterPassword'),
                                    icon: Icons.lock_outline_rounded,
                                    suffixIcon: IconButton(
                                      tooltip: obscurePassword
                                          ? _t('showPassword')
                                          : _t('hidePassword'),
                                      onPressed: _submitting
                                          ? null
                                          : () {
                                        setState(() {
                                          obscurePassword =
                                          !obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: _mutedColor(context),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 4) {
                                      return _t('passwordLength');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 19),
                              _StaggeredEntrance(
                                animation: _controller,
                                begin: 0.46,
                                child: SizedBox(
                                  height: 56,
                                  child: _AnimatedButton(
                                    onTap: _submit,
                                    child: AnimatedSwitcher(
                                      duration:
                                      const Duration(milliseconds: 180),
                                      child: Container(
                                        key: ValueKey(_submitting),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              AppColors.ink,
                                              Color(0xFF3B3530),
                                            ],
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .shadow
                                                  .withOpacity(.12),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: _submitting
                                              ? const SizedBox(
                                            width: 21,
                                            height: 21,
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                              : Text(
                                            signUp
                                                ? _t('createSeller')
                                                : _t('loginToShop'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    signUp
                                        ? _t('alreadyHaveAccount')
                                        : _t('newArtisan'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _mutedColor(context),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _switchMode,
                                    child: Text(
                                      signUp
                                          ? _t('login')
                                          : _t('createAnAccount'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.clay,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({
    required this.animation,
    required this.begin,
    required this.child,
  });

  final AnimationController animation;
  final double begin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double end = (begin + 0.40).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  const _AnimatedButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}